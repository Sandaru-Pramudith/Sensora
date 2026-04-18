import 'dart:ui';

import 'package:flutter/material.dart';
import 'core (Shared logic, themes, constants)/api_config.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'services/sensora_api.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'reports_page.dart';

class BatchesPage extends StatefulWidget {
  final String initialView;

  const BatchesPage({super.key, this.initialView = 'overview'});

  @override
  State<BatchesPage> createState() => _BatchesPageState();
}

enum _BatchView {
  overview,
  all,
  fresh,
  spoiled,
  notAvailable,
  addBatch,
  removeBatch,
}

enum _BatchState { fresh, spoiled, notAvailable }

class _BatchRecord {
  final String batchId;
  final String fruit;
  final String location;
  final _BatchState state;
  final double humidity;
  final double voc;
  final double? hoursLeft;

  const _BatchRecord({
    required this.batchId,
    required this.fruit,
    required this.location,
    required this.state,
    required this.humidity,
    required this.voc,
    required this.hoursLeft,
  });
}

class _BatchesPageState extends State<BatchesPage> {
  static const double _estimatedTotalHours = 70;

  _BatchView _currentView = _BatchView.overview;
  String? _expandedBatchId;
  String? _selectedBatchIdForRemoval;
  late SensoraApi _api;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentView = _mapInitialView(widget.initialView);
    _api = SensoraApi(ApiConfig.baseUrl);
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiBatches = await _api.getBaskets();
      final parsedRecords = await Future.wait(
        apiBatches.map((batch) async {
          final b = batch as Map<String, dynamic>;
          final id =
              b['basket_id']?.toString() ?? b['batch_id']?.toString() ?? 'N/A';
          final report = id == 'N/A' ? null : await _api.getBasketReport(id);
          final prediction = report?['prediction'] as Map?;
          final latestReading =
              report?['sensor_readings'] is List &&
                  (report?['sensor_readings'] as List).isNotEmpty
              ? (report?['sensor_readings'] as List).first as Map?
              : null;

          final status =
              b['status']?.toString().toLowerCase() ??
              prediction?['status']?.toString().toLowerCase() ??
              'fresh';
          final spoilStage = _toBool(
            b['spoil_stage'] ?? prediction?['spoil_stage'],
          );
          final remainingLifePercentage = _toDouble(
            b['remaining_life_percentage'] ??
                prediction?['remaining_life_percentage'],
          );

          final isEmptyByRule =
              spoilStage == true &&
              (remainingLifePercentage != null &&
                  remainingLifePercentage >= 90);

          _BatchState state;
          if (isEmptyByRule) {
            state = _BatchState.notAvailable;
          } else if (spoilStage == true) {
            state = _BatchState.spoiled;
          } else if (spoilStage == false) {
            state = _BatchState.fresh;
          } else {
            // Fallback for older endpoints that don't send spoil_stage.
            switch (status) {
              case 'not_available':
                state = _BatchState.notAvailable;
                break;
              case 'spoiled':
              case 'spoiling':
              case 'ripe':
                state = _BatchState.spoiled;
                break;
              default:
                state = _BatchState.fresh;
            }
          }
          final directHoursLeft = _toDouble(
            b['hours_left'] ??
                b['time_remaining_hours'] ??
                (b['prediction'] is Map
                    ? (b['prediction'] as Map)['hours_left']
                    : null) ??
                (b['latest_prediction'] is Map
                    ? (b['latest_prediction'] as Map)['hours_left'] ??
                          (b['latest_prediction']
                              as Map)['time_remaining_hours']
                    : null) ??
                prediction?['hours_left'] ??
                prediction?['time_remaining_hours'],
          );
          final derivedHoursLeft = remainingLifePercentage == null
              ? null
              : (remainingLifePercentage.clamp(0.0, 100.0) / 100.0) *
                    _estimatedTotalHours;
          final humidity =
              _toDouble(
                b['humidity'] ??
                    b['hum'] ??
                    latestReading?['humidity'] ??
                    latestReading?['hum'],
              ) ??
              0.0;
          final voc =
              _toDouble(
                b['voc'] ??
                    b['tvoc'] ??
                    latestReading?['voc'] ??
                    latestReading?['tvoc'],
              ) ??
              0.0;

          return _BatchRecord(
            batchId: id,
            fruit: b['fruit_type']?.toString() ?? 'Unknown',
            location: b['location']?.toString() ?? 'Unknown',
            state: state,
            humidity: humidity,
            voc: voc,
            hoursLeft: directHoursLeft ?? derivedHoursLeft,
          );
        }),
      );

      setState(() {
        _records = parsedRecords;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load baskets: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  _BatchView _mapInitialView(String value) {
    switch (value.trim().toLowerCase()) {
      case 'all':
        return _BatchView.all;
      case 'fresh':
        return _BatchView.fresh;
      case 'spoiling':
      case 'spoiled':
        return _BatchView.spoiled;
      case 'notavailable':
      case 'not_available':
      case 'not detected':
      case 'not_detected':
      case 'not_found':
        return _BatchView.notAvailable;
      case 'ripe':
        return _BatchView.spoiled;
      case 'add':
      case 'addbatch':
        return _BatchView.addBatch;
      case 'remove':
      case 'removebatch':
        return _BatchView.removeBatch;
      case 'overview':
      default:
        return _BatchView.overview;
    }
  }

  final TextEditingController _batchIdController = TextEditingController();
  final TextEditingController _fruitController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  _BatchState _newBatchState = _BatchState.fresh;

  List<_BatchRecord> _records = [];

  int get _totalBatches => _records.length;
  int get _urgentBatches => _records
      .where(
        (record) =>
            record.state == _BatchState.spoiled ||
            record.state == _BatchState.notAvailable,
      )
      .length;

  int get _healthPercentage {
    if (_totalBatches == 0) return 0;
    final safeRatio = (_totalBatches - _urgentBatches) / _totalBatches;
    return (safeRatio * 100).round();
  }

  List<_BatchRecord> _recordsByState(_BatchState state) {
    return _records.where((record) => record.state == state).toList();
  }

  int _bananaCount(List<_BatchRecord> records) {
    return records.where((record) => record.fruit == 'Banana').length;
  }

  String _statusLabel(_BatchState state) {
    switch (state) {
      case _BatchState.fresh:
        return 'Fresh';
      case _BatchState.spoiled:
        return 'Spoiled';
      case _BatchState.notAvailable:
        return 'Empty Basket';
    }
  }

  Color _statusColor(_BatchState state) {
    switch (state) {
      case _BatchState.fresh:
        return AppColors.highlightGreen;
      case _BatchState.spoiled:
        return const Color(0xFFDC2626);
      case _BatchState.notAvailable:
        return const Color(0xFFD97706);
    }
  }

  bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _formatMetric(double value) {
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  bool _isExpanded(_BatchRecord item) => _expandedBatchId == item.batchId;

  void _toggleExpanded(_BatchRecord item) {
    setState(() {
      _expandedBatchId = _expandedBatchId == item.batchId ? null : item.batchId;
    });
  }

  Future<void> _addBatch() async {
    final fruit = _fruitController.text.trim();
    final location = _locationController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    if (fruit.isEmpty || location.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please fill fruit name and location.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final availableDevices = await _api.getAvailableDevices();
      String? deviceId;

      if (availableDevices.isNotEmpty) {
        final device = availableDevices.first as Map<String, dynamic>;
        deviceId = device['device_id']?.toString();
      } else {
        final createdDevice = await _api.createDevice({
          'wifi_ssid': 'Auto Provisioned',
          'is_active': true,
        });
        deviceId = createdDevice['device_id']?.toString();
      }

      if (deviceId == null || deviceId.isEmpty) {
        throw Exception(
          'Device provisioning failed because device_id was missing.',
        );
      }

      await _api.createBasket({
        'fruit_type': fruit,
        'location': location,
        'device_id': deviceId,
        'created_by': 1,
      });
      await _fetchBatches();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Basket saved to server with device $deviceId.'),
        ),
      );
      _batchIdController.clear();
      _fruitController.clear();
      _locationController.clear();
      _newBatchState = _BatchState.fresh;
      setState(() {
        _currentView = _BatchView.all;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save batch: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showEditBatchDialog(_BatchRecord record) async {
    final fruitController = TextEditingController(text: record.fruit);
    final locationController = TextEditingController(text: record.location);
    _BatchState selectedState = record.state;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.85),
          title: const Text(
            'Edit Batch',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fruitController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration('Fruit Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration('Location'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<_BatchState>(
                initialValue: selectedState,
                dropdownColor: const Color(0xFF1A3D2E),
                decoration: _fieldDecoration('Status'),
                style: const TextStyle(color: Colors.white),
                items: _BatchState.values
                    .map(
                      (state) => DropdownMenuItem<_BatchState>(
                        value: state,
                        child: Text(_statusLabel(state)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  selectedState = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateBatch(
                  record.batchId,
                  fruitController.text.trim(),
                  locationController.text.trim(),
                  selectedState,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBatch(
    String batchId,
    String fruit,
    String location,
    _BatchState state,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (fruit.isEmpty || location.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fields cannot be empty.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _api.updateBasket(batchId, {
        'fruit_type': fruit,
        'location': location,
      });
      await _fetchBatches();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Basket updated on server.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update basket: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeSelectedBatch() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_selectedBatchIdForRemoval == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select a basket to remove.')),
      );
      return;
    }

    final batchToRemove = _selectedBatchIdForRemoval!;

    setState(() {
      _isLoading = true;
    });

    try {
      await _api.deleteBasket(batchToRemove);
      await _fetchBatches();
      if (!mounted) {
        return;
      }
      setState(() {
        _expandedBatchId = null;
        _selectedBatchIdForRemoval = null;
        _currentView = _BatchView.all;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Basket removed from server.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to remove batch: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _batchIdController.dispose();
    _fruitController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05150D),
      body: AnimatedBackground(
        gradientColors: AppColors.backgroundGradient,
        particleCount: 24,
        particleColor: AppColors.particleColor,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 86),
                  child: _buildCurrentView(),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: GlassBottomNavBar(
                  activeIndex: -1,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      );
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MenuPage()),
                      );
                    } else if (index == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(
                            userId: 'yourUserId',
                            role: 'yourRole',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }
    switch (_currentView) {
      case _BatchView.overview:
        return _buildOverviewPage();
      case _BatchView.all:
        return _buildAllBatchesPage();
      case _BatchView.fresh:
        return _buildConditionPage(
          title: 'Fresh Baskets',
          state: _BatchState.fresh,
          accent: AppColors.highlightGreen,
          icon: Icons.eco,
        );
      case _BatchView.spoiled:
        return _buildConditionPage(
          title: 'Spoiled Baskets',
          state: _BatchState.spoiled,
          accent: const Color(0xFFDC2626),
          icon: Icons.warning_rounded,
        );
      case _BatchView.notAvailable:
        return _buildConditionPage(
          title: 'Empty Baskets',
          state: _BatchState.notAvailable,
          accent: const Color(0xFFD97706),
          icon: Icons.block,
        );
      case _BatchView.addBatch:
        return _buildAddBatchPage();
      case _BatchView.removeBatch:
        return _buildRemoveBatchPage();
    }
  }

  Widget _buildOverviewPage() {
    return Column(
      children: [
        _buildTopBar(
          title: 'Baskets',
          showBack: true,
          onBack: () => Navigator.maybePop(context),
        ),
        _buildOverviewStats(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              _buildOverviewCard(
                title: 'All Baskets',
                subtitle: '$_totalBatches baskets',
                description: '100% Active',
                color: AppColors.info,
                icon: Icons.grid_view_rounded,
                onTap: () => setState(() => _currentView = _BatchView.all),
              ),
              _buildOverviewCard(
                title: 'Fresh Baskets',
                subtitle:
                    '${_recordsByState(_BatchState.fresh).length} baskets',
                description: 'Optimally preserved',
                color: AppColors.highlightGreen,
                icon: Icons.eco_rounded,
                onTap: () => setState(() => _currentView = _BatchView.fresh),
              ),
              _buildOverviewCard(
                title: 'Spoiled Baskets',
                subtitle:
                    '${_recordsByState(_BatchState.spoiled).length} baskets',
                description: 'Needs attention',
                color: const Color(0xFFDC2626),
                icon: Icons.warning_amber_rounded,
                onTap: () => setState(() => _currentView = _BatchView.spoiled),
              ),
              _buildOverviewCard(
                title: 'Empty Baskets',
                subtitle:
                    '${_recordsByState(_BatchState.notAvailable).length} baskets',
                description: 'Fruit presence not detected',
                color: const Color(0xFFD97706),
                icon: Icons.block,
                onTap: () =>
                    setState(() => _currentView = _BatchView.notAvailable),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllBatchesPage() {
    return Column(
      children: [
        _buildTopBar(
          title: 'All Baskets',
          showBack: true,
          onBack: () => setState(() => _currentView = _BatchView.overview),
        ),
        _buildSummaryStats(
          totalLabel: 'Total',
          totalValue: '$_totalBatches',
          secondLabel: 'Health',
          secondValue: '$_healthPercentage%',
          thirdLabel: 'Urgent',
          thirdValue: '$_urgentBatches',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 14,
                    color: Colors.white.withValues(alpha: 0.08),
                    child: Column(
                      children: [
                        _buildTableHeader(),
                        const SizedBox(height: 6),
                        const Divider(color: Colors.white24, height: 1),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _records.length,
                            separatorBuilder: (context, index) =>
                                const Divider(color: Colors.white12, height: 1),
                            itemBuilder: (context, index) =>
                                _buildTableRow(_records[index]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _currentView = _BatchView.removeBatch,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF8AA0),
                          side: BorderSide(
                            color: const Color(
                              0xFFFF8AA0,
                            ).withValues(alpha: 0.5),
                          ),
                          backgroundColor: const Color(0x33FF5D7A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Remove Basket'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            setState(() => _currentView = _BatchView.addBatch),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.highlightGreen,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add New Basket'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddBatchPage() {
    return Column(
      children: [
        _buildTopBar(
          title: 'Add New Basket',
          showBack: true,
          onBack: () => setState(() => _currentView = _BatchView.all),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              borderRadius: 14,
              color: Colors.white.withValues(alpha: 0.08),
              child: Column(
                children: [
                  TextField(
                    controller: _batchIdController,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white70),
                    decoration: _fieldDecoration('Basket ID is auto-generated'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _fruitController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Fruit Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration('Location'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<_BatchState>(
                    initialValue: _newBatchState,
                    dropdownColor: const Color(0xFF1A3D2E),
                    decoration: _fieldDecoration('Status'),
                    style: const TextStyle(color: Colors.white),
                    items: _BatchState.values
                        .map(
                          (state) => DropdownMenuItem<_BatchState>(
                            value: state,
                            child: Text(_statusLabel(state)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _newBatchState = value);
                    },
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addBatch,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.highlightGreen,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Basket'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemoveBatchPage() {
    return Column(
      children: [
        _buildTopBar(
          title: 'Remove Basket',
          showBack: true,
          onBack: () => setState(() => _currentView = _BatchView.all),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Expanded(
                  child: RadioGroup<String>(
                    groupValue: _selectedBatchIdForRemoval,
                    onChanged: (value) {
                      setState(() => _selectedBatchIdForRemoval = value);
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 14,
                      color: Colors.white.withValues(alpha: 0.08),
                      child: ListView.separated(
                        itemCount: _records.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.white12, height: 1),
                        itemBuilder: (context, index) {
                          final record = _records[index];
                          return RadioListTile<String>(
                            value: record.batchId,
                            activeColor: const Color(0xFFFF8AA0),
                            title: Text(
                              '${record.batchId} • ${record.fruit}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${record.location} • ${_statusLabel(record.state)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _removeSelectedBatch,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5D7A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Confirm Remove Basket'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.highlightGreen.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildConditionPage({
    required String title,
    required _BatchState state,
    required Color accent,
    required IconData icon,
  }) {
    final filtered = _recordsByState(state);

    return Column(
      children: [
        _buildTopBar(
          title: title,
          showBack: true,
          onBack: () => setState(() => _currentView = _BatchView.overview),
        ),
        _buildSummaryStats(
          totalLabel: 'Total Baskets',
          totalValue: '${filtered.length}',
          secondLabel: 'Banana',
          secondValue: '${_bananaCount(filtered)}',
          accent: accent,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return _buildConditionCard(
                item: item,
                accent: accent,
                icon: icon,
                isExpanded: _isExpanded(item),
                onArrowTap: () => _toggleExpanded(item),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: filtered.length,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar({
    required String title,
    String? subtitle,
    required bool showBack,
    VoidCallback? onBack,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.headerGreen,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
            child: Column(
              children: [
                Row(
                  children: [
                    if (showBack)
                      _circleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: onBack ?? () => Navigator.maybePop(context),
                      )
                    else
                      const SizedBox(width: AppColors.headerActionSize),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _circleIconButton(
                          icon: Icons.notifications_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '4',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlur,
          sigmaY: AppColors.glassBlur,
        ),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: AppColors.headerActionSize,
            height: AppColors.headerActionSize,
            decoration: BoxDecoration(
              color: AppColors.textWhite.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textWhite.withValues(
                  alpha: AppColors.glassBorderOpacity,
                ),
                width: AppColors.glassBorderWidth,
              ),
            ),
            child: Icon(
              icon,
              size: AppColors.iconMd,
              color: AppColors.textWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: _buildSummaryStats(
        totalLabel: 'Total',
        totalValue: '$_totalBatches',
        secondLabel: 'Health',
        secondValue: '$_healthPercentage%',
        thirdLabel: 'Urgent',
        thirdValue: '$_urgentBatches',
      ),
    );
  }

  Widget _buildSummaryStats({
    required String totalLabel,
    required String totalValue,
    required String secondLabel,
    required String secondValue,
    String? thirdLabel,
    String? thirdValue,
    Color accent = AppColors.highlightGreen,
  }) {
    final showThird = thirdLabel != null && thirdValue != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        color: Colors.white.withValues(alpha: 0.07),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  totalValue,
                  totalLabel,
                  Icons.inventory_2_rounded,
                  accent: accent,
                ),
                _buildDivider(),
                _buildStatItem(
                  secondValue,
                  secondLabel,
                  Icons.favorite_rounded,
                  accent: accent,
                ),
                if (showThird) ...[
                  _buildDivider(),
                  _buildStatItem(
                    thirdValue,
                    thirdLabel,
                    Icons.warning_amber_rounded,
                    accent: accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.16),
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon, {
    required Color accent,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        color: Colors.white.withValues(alpha: 0.07),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: color.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          subtitle: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12),
              children: [
                TextSpan(
                  text: subtitle,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '   $description',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          trailing: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Batch\nId',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Fruit Type',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Location',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Actions',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(_BatchRecord record) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              record.batchId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              '${_fruitEmoji(record.fruit)} ${record.fruit}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record.location,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(record.state).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _statusColor(record.state).withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  _statusLabel(record.state),
                  style: TextStyle(
                    color: _statusColor(record.state),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
              onPressed: () => _showEditBatchDialog(record),
              tooltip: 'Edit batch',
            ),
          ),
        ],
      ),
    );
  }

  String _fruitEmoji(String fruit) {
    switch (fruit) {
      case 'Apple':
        return '🍎';
      case 'Banana':
        return '🍌';
      case 'Strawberry':
        return '🍓';
      case 'Grapes':
        return '🍇';
      case 'Peach':
        return '🍑';
      case 'Orange':
        return '🍊';
      case 'Avocado':
        return '🥑';
      case 'Mango':
        return '🥭';
      default:
        return '🍏';
    }
  }

  Widget _buildConditionCard({
    required _BatchRecord item,
    required Color accent,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onArrowTap,
  }) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      color: Colors.white.withValues(alpha: 0.07),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.7)),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              title: Text(
                item.batchId,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                item.state == _BatchState.notAvailable
                    ? 'Empty Basket'
                    : item.fruit,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              trailing: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                  onPressed: onArrowTap,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: isExpanded ? 18 : 14,
                  ),
                ),
              ),
              onTap: onArrowTap,
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      Text(
                        'Humidity  ${_formatMetric(item.humidity)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'VOC  ${_formatMetric(item.voc)} ppb',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item.hoursLeft != null
                            ? 'LIFETIME REMAINING: ${item.hoursLeft!.toStringAsFixed(1)} HOURS'
                            : 'LIFETIME REMAINING: --',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
