import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'settings_page.dart';
import 'alert_page.dart';
import 'dashboard_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';
import 'help_faqs_page.dart';
import 'batches_page.dart';
import 'admin_menu_page.dart';
import 'notifications_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = _isCurrentUserAdmin();
  }

  Future<bool> _isCurrentUserAdmin() async {
    final userId = (UserSession.userId ?? '').trim();
    if (userId.isEmpty) return false;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(userId)
          .get();
      return adminDoc.exists;
    } catch (_) {
      return false;
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
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: GlassNavBar(
                      title: 'Menu',
                      titleSize: 26,
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      onBack: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Menu Items
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(20),
                        borderRadius: 24,
                        color: Colors.black.withValues(alpha: 0.15),
                        child: Column(
                          children: [
                            FutureBuilder<bool>(
                              future: _isAdminFuture,
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return Column(
                                    children: [
                                      _buildMenuItem(
                                        context,
                                        icon: Icons.person_search_outlined,
                                        label: 'Admin',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AdminMenuPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            _buildMenuItem(
                              context,
                              icon: Icons.notifications_outlined,
                              label: 'Alerts',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AlertsPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildMenuItem(
                              context,
                              icon: Icons.notifications_active_outlined,
                              label: 'Notifications',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildMenuItem(
                              context,
                              icon: Icons.inventory_2_outlined,
                              label: 'Batches',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BatchesPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildMenuItem(
                              context,
                              icon: Icons.dashboard_outlined,
                              label: 'Dashboard',
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DashboardPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildMenuItem(
                              context,
                              icon: Icons.assessment_outlined,
                              label: 'Reports',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReportsPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildMenuItem(
                              context,
                              icon: Icons.help_outline,
                              label: 'Help & FAQS',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HelpFaqsPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildMenuItem(
                              context,
                              icon: Icons.person_outline,
                              label: 'Profile',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfilePage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildMenuItem(
                              context,
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
                activeIndex: 2,
                onTap: (index) {
                  if (index == 0) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                      (route) => false,
                    );
                  } else if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    );
                  } else if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 14,
        color: Colors.white.withValues(alpha: 0.08),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
