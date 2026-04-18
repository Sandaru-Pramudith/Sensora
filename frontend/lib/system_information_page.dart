import 'package:flutter/material.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';

class SystemInformationPage extends StatelessWidget {
  const SystemInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AnimatedBackground(
        gradientColors: const [
          Color.fromARGB(255, 15, 47, 30),
          Color.fromARGB(255, 16, 44, 18),
          Color.fromARGB(255, 27, 94, 58),
        ],
        particleCount: 36,
        particleColor: Colors.greenAccent,
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
                        _buildInformationCard(),
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
        title: 'System Information',
        titleSize: 26,
        padding: EdgeInsets.zero,
        onBack: () => Navigator.maybePop(context),
      ),
    );
  }

  Widget _buildInformationCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      color: Colors.white.withValues(alpha: 0.12),
      child: Column(
        children: [
          _buildInfoField(
            label: 'Application Version',
            value: 'V1.0',
            showInfoIcon: true,
          ),
          const SizedBox(height: 20),
          _buildInfoField(label: 'Last Sensor Calibration', value: 'Jan 2026'),
          const SizedBox(height: 20),
          _buildInfoField(label: 'System Status', value: 'Active'),
          const SizedBox(height: 20),
          _buildInfoField(label: 'Environment Mode', value: 'Prototype'),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    bool showInfoIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showInfoIcon)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderRadius: 16,
          color: Colors.white.withValues(alpha: 0.10),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
