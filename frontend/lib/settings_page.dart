import 'package:flutter/material.dart';

import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
import 'notification_settings_page.dart';
import 'alert_threshold_settings.dart';
import 'change_password_page.dart';
import 'system_information_page.dart';
import 'logout_pages.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBackground(
        gradientColors: AppColors.backgroundGradient,
        particleCount: 40,
        particleColor: AppColors.particleColor,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      children: [
                        const SizedBox(height: 8),
                        _buildMenuCard(context),
                      ],
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
                activeIndex: -1,
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
                          userId: (UserSession.userId ?? '').trim(),
                          role: (UserSession.role ?? '').trim(),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.headerGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: GlassNavBar(
        title: 'Settings',
        titleSize: 26,
        padding: EdgeInsets.zero,
        onBack: () => Navigator.maybePop(context),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      color: Colors.white.withValues(alpha: 0.12),
      child: Column(
        children: [
          _settingTile(
            Icons.notifications_active_outlined,
            'Notification Settings',
            context,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsPage(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _settingTile(
            Icons.warning_amber_outlined,
            'Alert Threshold Settings',
            context,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AlertThresholdSettingsPage(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _settingTile(
            Icons.lock_outline,
            'Change Password',
            context,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
          const SizedBox(height: 10),
          _settingTile(
            Icons.storage_outlined,
            'System Information',
            context,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SystemInformationPage()),
            ),
          ),
          const SizedBox(height: 10),
          _settingTile(
            Icons.logout,
            'Logout',
            context,
            emphasize: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogoutConfirmationPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile(
    IconData icon,
    String title,
    BuildContext context, {
    bool emphasize = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap ?? () {},
        child: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderRadius: 30,
          color: Colors.black.withValues(alpha: 0.22),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// GlassContainer moved to shared (Global components like buttons, cards)/sudam_glass.dart
