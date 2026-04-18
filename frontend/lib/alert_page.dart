// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'alert_details_page.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';
import 'models/alert_model.dart';
import 'services/sensora_api.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  final _api = SensoraApi();
  List<AlertModel> _alerts = [];
  int _unreadNotifications = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutCubic,
          ),
        );
    _headerController.forward();
    _loadAlerts();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.getAlerts(limit: 100);
      int unread = 0;
      try {
        unread = await _api.getUnreadNotificationCount();
      } catch (_) {
        unread = 0;
      }
      setState(() {
        _alerts = raw.map(AlertModel.fromJson).toList();
        _unreadNotifications = unread;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
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
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.headerGreen,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        child: GlassNavBar(
                          title: 'Alerts',
                          titleSize: 26,
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                          onBack: () => Navigator.pop(context),
                          notificationCount: _unreadNotifications,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildBody()),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            Positioned(
              bottom: 18,
              left: 12,
              right: 12,
              child: GlassBottomNavBar(
                activeIndex: -1,
                onTap: (i) {
                  switch (i) {
                    case 0:
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                        (r) => false,
                      );
                      break;
                    case 1:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      );
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MenuPage()),
                      );
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: '', role: ''),
                        ),
                      );
                      break;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGreen),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_outlined,
              size: 56,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Could not reach backend',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            TextButton.icon(
              onPressed: _loadAlerts,
              icon: const Icon(Icons.refresh, color: AppColors.accentGreen),
              label: const Text(
                'Retry',
                style: TextStyle(color: AppColors.accentGreen),
              ),
            ),
          ],
        ),
      );
    }
    if (_alerts.isEmpty) {
      return Center(
        child: Text(
          'No alerts',
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentGreen,
      onRefresh: _loadAlerts,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 28,
          color: Colors.black.withOpacity(0.15),
          child: ListView.separated(
            itemCount: _alerts.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withOpacity(0.08), height: 32),
            itemBuilder: (_, i) => _buildAlertRow(_alerts[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertRow(AlertModel a) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertDetailsPage(
            alertData: {
              'title': '${a.batchId} ${a.fruitType}',
              'time': a.timeAgo,
            },
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: a.severityColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: a.severityColor.withOpacity(0.3)),
            ),
            child: Icon(a.icon, color: a.severityColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.batchId} ${a.fruitType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  a.alertType.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                if (a.acknowledged)
                  const Text(
                    '✓ Acknowledged',
                    style: TextStyle(color: Color(0xFF6BCB5B), fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                a.timeAgo,
                style: TextStyle(
                  color: a.severityColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: a.severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.severity.toUpperCase(),
                  style: TextStyle(
                    color: a.severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
