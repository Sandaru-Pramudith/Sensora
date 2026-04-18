// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';

class AlertDetailsPage extends StatelessWidget {
  final Map<String, String> alertData;

  const AlertDetailsPage({super.key, required this.alertData});

  @override
  Widget build(BuildContext context) {
    // Extract alert info from data or use defaults
    final batchId = alertData['title']?.split(' ').first ?? 'B-745';
    final fruitType = alertData['title']?.split(' ').last ?? 'Banana';
    final detectedTime = alertData['time'] ?? '2 Hours';

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
                  // Top Navigation Bar
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
                      title: 'Alert Details',
                      titleSize: 26,
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                      onBack: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Alert Details Card
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 120,
                      ),
                      child: _buildAlertCard(batchId, fruitType, detectedTime),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Bar
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
                          userId: alertData['userId'] ?? '',
                          role: alertData['role'] ?? '',
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

  Widget _buildAlertCard(
    String batchId,
    String fruitType,
    String detectedTime,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      color: Colors.black.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Alert Title
          const Center(
            child: Text(
              'SPOILING ALERT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Status
          _buildInfoRow('Status:', 'New'),

          const SizedBox(height: 16),

          // Fruit Type
          _buildInfoRow('Fruit Type:', fruitType),

          // Batch ID
          _buildInfoRow('Batch ID:', batchId),

          // Location
          _buildInfoRow('Location:', 'Aisle 4'),

          // Detected
          _buildInfoRow('Detected:', '$detectedTime Ago'),

          const SizedBox(height: 20),

          // Message
          Text(
            '"Gas Levels Indicate Possible Spoilage."',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.normal,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          // Action Buttons
          Row(
            children: [
              _buildActionButton('Acknowledge Alert', onTap: () {}),
              const SizedBox(width: 12),
              _buildActionButton('View Batch Details', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.highlightGreen.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.highlightGreen,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}





