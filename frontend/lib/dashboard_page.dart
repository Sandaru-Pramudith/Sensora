import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'core/app_motion.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
// import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'alert_page.dart';
import 'reports_page.dart';
import 'menu_page.dart';
import 'profile_page.dart';
import 'batches_page.dart';
import 'notifications_page.dart';
import 'core (Shared logic, themes, constants)/api_config.dart';
import 'services/sensora_api.dart';

class DashboardPage extends StatefulWidget {
  final String role;
  final String userId;

  const DashboardPage({super.key, this.role = 'staff', this.userId = ''});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _effectiveUserId;
  late String _effectiveRole;
  String _displayName = 'User';

  late SensoraApi _api;
  bool _isMetricsLoading = true;
  String? _metricsError;

  int _totalBatches = 0;
  int _freshBatches = 0;
  int _spoiledBatches = 0;
  int _emptyBatches = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _api = SensoraApi(ApiConfig.baseUrl);
    _resolveIdentity();
    _loadDisplayName();
    _loadDashboardData();
  }

  bool _isPlaceholderUserId(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'youruserid' ||
        normalized == 'null';
  }

  String _normalizeRole(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'admin' || normalized == 'staff') {
      return normalized;
    }
    return 'staff';
  }

  void _resolveIdentity() {
    final incomingUserId = widget.userId.trim();
    final incomingRole = widget.role.trim();
    final sessionUserId = (UserSession.userId ?? '').trim();
    final sessionRole = (UserSession.role ?? '').trim();

    if (sessionUserId.isNotEmpty) {
      _effectiveUserId = sessionUserId;
      _effectiveRole = _normalizeRole(
        sessionRole.isNotEmpty ? sessionRole : incomingRole,
      );
      return;
    }

    _effectiveUserId = _isPlaceholderUserId(incomingUserId)
        ? ''
        : incomingUserId;
    _effectiveRole = _normalizeRole(incomingRole);

    if (_effectiveUserId.isNotEmpty) {
      UserSession.setCurrentUser(
        userId: _effectiveUserId,
        role: _effectiveRole,
      );
    }
  }

  Future<void> _loadDisplayName() async {
    if (_effectiveUserId.isEmpty) {
      return;
    }

    try {
      final collection = _effectiveRole == 'admin' ? 'admins' : 'staff';
      final doc = await _firestore
          .collection(collection)
          .doc(_effectiveUserId)
          .get();

      if (!doc.exists || !mounted) {
        return;
      }

      final data = doc.data() ?? <String, dynamic>{};
      final fullName = (data['fullName'] ?? '').toString().trim();
      final username = (data['username'] ?? '').toString().trim();
      final resolvedName = fullName.isNotEmpty
          ? fullName
          : (username.isNotEmpty ? username : _displayName);

      setState(() {
        _displayName = resolvedName;
      });
    } catch (_) {
      // Keep the fallback name if profile lookup fails.
    }
  }

  Future<void> _openProfilePage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfilePage(userId: _effectiveUserId, role: _effectiveRole),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadDisplayName();
  }

  bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final v = value?.toString().trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isMetricsLoading = true;
      _metricsError = null;
    });

    try {
      final baskets = await _api.getBaskets();

      int fresh = 0;
      int spoiled = 0;
      int empty = 0;

      for (final item in baskets) {
        final b = Map<String, dynamic>.from(item as Map);

        final spoilStage = _toBool(b['spoil_stage']);
        final remainingLife = _toDouble(b['remaining_life_percentage']);
        final status = (b['status'] ?? '').toString().toLowerCase();

        final isEmpty =
            spoilStage == true && remainingLife != null && remainingLife >= 90;

        if (isEmpty || status == 'not_available') {
          empty++;
        } else if (spoilStage == true ||
            status == 'spoiled' ||
            status == 'spoiling') {
          spoiled++;
        } else {
          fresh++;
        }
      }

      int unread = 0;
      try {
        unread = await _api.getUnreadNotificationCount();
      } catch (_) {
        unread = 0;
      }

      if (!mounted) return;

      setState(() {
        _totalBatches = baskets.length;
        _freshBatches = fresh;
        _spoiledBatches = spoiled;
        _emptyBatches = empty;
        _unreadNotifications = unread;
        _isMetricsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _metricsError = e.toString();
        _isMetricsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBackground(
        gradientColors: AppColors.backgroundGradient,
        particleCount: 20,
        particleColor: AppColors.particleColor,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.headerGreen,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        GlassNavBar(
                          title: 'Dashboard',
                          titleSize: 26,
                          showNotification: false,
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                    width: 1.2,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const NotificationsPage(),
                                          ),
                                        );

                                        if (!mounted) return;
                                        _loadDashboardData();
                                      },
                                      icon: const Icon(
                                        Icons.notifications_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          _unreadNotifications.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Main glass content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: ListView(
                        children: [
                          // Welcome section
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 70),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.06),
                                    Colors.white.withOpacity(0.02),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, $_displayName',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Monitor your produce inventory in real-time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          if (_isMetricsLoading)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Loading dashboard data...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          if (_metricsError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Dashboard load failed: $_metricsError',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          // Key metrics section
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 140),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _metricCard(
                                    title: 'Total Batches',
                                    value: _totalBatches.toString(),
                                    subtitle: '$_unreadNotifications Alerts',
                                    color: AppColors.accentGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _metricCard(
                                    title: 'Healthy',
                                    value: _freshBatches.toString(),
                                    subtitle: _totalBatches == 0
                                        ? '0%'
                                        : '${((_freshBatches / _totalBatches) * 100).round()}%',
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _metricCard(
                                    title: 'At Risk',
                                    value: (_spoiledBatches + _emptyBatches)
                                        .toString(),
                                    subtitle: _totalBatches == 0
                                        ? '0%'
                                        : '${(((_spoiledBatches + _emptyBatches) / _totalBatches) * 100).round()}%',
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Batch status section
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 210),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Batch Status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Column(
                                  children: [
                                    _statusCard(
                                      context,
                                      'Fresh Batches',
                                      _freshBatches,
                                      AppColors.success,
                                      Icons.eco_rounded,
                                      'Fresh and within safe storage range',
                                    ),
                                    const SizedBox(height: 12),
                                    _statusCard(
                                      context,
                                      'Spoiled Batches',
                                      _spoiledBatches,
                                      const Color(0xFFDC2626),
                                      Icons.warning_amber_rounded,
                                      'Classifier flagged these as spoiled',
                                    ),
                                    const SizedBox(height: 12),
                                    _statusCard(
                                      context,
                                      'Empty Baskets',
                                      _emptyBatches,
                                      const Color(0xFFD97706),
                                      Icons.block,
                                      'Spoiled classifier with high remaining life',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quick actions section
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 350),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GridView.count(
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  children: [
                                    _actionCard(
                                      context,
                                      'Batches',
                                      Icons.inventory_2_rounded,
                                    ),
                                    _actionCard(
                                      context,
                                      'Alerts',
                                      Icons.notifications_active_rounded,
                                    ),
                                    _actionCard(
                                      context,
                                      'Reports',
                                      Icons.assessment_rounded,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 18,
              left: 12,
              right: 12,
              child: GlassBottomNavBar(
                activeIndex: 0,
                onTap: (index) {
                  if (index == 1) {
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
                    _openProfilePage(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
    String description,
  ) {
    return MotionTap(
      onTap: () {
        final targetView = switch (label) {
          'Fresh Batches' => 'fresh',
          'Spoiled Batches' => 'spoiled',
          'Empty Baskets' => 'not_available',
          _ => 'overview',
        };
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BatchesPage(initialView: targetView),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.32), color.withOpacity(0.14)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.32)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  Text(
                    'Batches',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext context, String label, IconData icon) {
    final accentColor = switch (label) {
      'Batches' => AppColors.accentGreen,
      'Alerts' => const Color(0xFFDC2626),
      'Reports' => const Color(0xFF2F80ED),
      _ => AppColors.accentGreen,
    };

    return MotionTap(
      onTap: () {
        if (label == 'Batches') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BatchesPage()));
          return;
        }
        if (label == 'Alerts') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AlertsPage()));
          return;
        }
        if (label == 'Reports') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ReportsPage()));
          return;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.06),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
