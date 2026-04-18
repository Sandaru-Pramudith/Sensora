import 'package:flutter/material.dart';

import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _enableSettings = true;
  bool _alertSound = true;
  bool _pushNotification = true;
  bool _ripeAlerts = true;
  bool _spoilingAlerts = true;

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
                        _buildSettingsCard(),
                        const SizedBox(height: 18),
                        _buildSaveButton(context),
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
        color: Color(0xB31B3F2B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: GlassNavBar(
        title: 'Notification Settings',
        titleSize: 22,
        padding: EdgeInsets.zero,
        onBack: () => Navigator.maybePop(context),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      color: Colors.white.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toggleTile('Enable Settings', _enableSettings, (value) {
            setState(() => _enableSettings = value);
          }),
          const SizedBox(height: 12),
          _toggleTile('Alert Sound', _alertSound, (value) {
            setState(() => _alertSound = value);
          }),
          const SizedBox(height: 12),
          _toggleTile('Push Notification', _pushNotification, (value) {
            setState(() => _pushNotification = value);
          }),
          const SizedBox(height: 12),
          _toggleTile('Ripe Alerts', _ripeAlerts, (value) {
            setState(() => _ripeAlerts = value);
          }),
          const SizedBox(height: 12),
          _toggleTile('Spoiling Alerts', _spoilingAlerts, (value) {
            setState(() => _spoilingAlerts = value);
          }),
        ],
      ),
    );
  }

  Widget _toggleTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF7ED26B),
          inactiveThumbColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Save',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// GlassContainer moved to shared (Global components like buttons, cards)/sudam_glass.dart
