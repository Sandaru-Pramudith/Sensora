// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'core (Shared logic, themes, constants)/api_config.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'profile_page.dart';
import 'view_reports_page.dart';

// Ensure this matches the class name and file name of your Result Page

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => ReportsPageState();
}

class ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  // Controller to read the Batch ID input
  final TextEditingController _batchIdController = TextEditingController();

  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutCubic,
          ),
        );

    _headerController.forward();
  }

  @override
  void dispose() {
    _batchIdController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  // --- MEMBER 5: VALIDATION & FILTERING LOGIC ---
  Future<void> _handleSearchValidation() async {
    final input = _batchIdController.text.trim();

    if (input.isEmpty) {
      _showError("Please enter a Basket ID.");
      return;
    }

    final basketId = int.tryParse(input);
    if (basketId == null) {
      _showError("Basket ID must be a number.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/reports/basket/$basketId"),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewReportDetails(basketId: basketId),
          ),
        );
      } else if (response.statusCode == 404) {
        _showError("Basket not found.");
      } else {
        _showError("Failed to load report.");
      }
    } catch (e) {
      _showError("Could not connect to backend: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gradientDark,
      extendBody: true,
      body: AnimatedBackground(
        gradientColors: AppColors.backgroundGradient,
        particleColor: AppColors.particleColor,
        particleCount: 20,
        child: SizedBox.expand(
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      Text(
                        "Enter a Basket ID to retrieve specific analysis data.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textWhite60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildGlassSearchBar(),
                      const SizedBox(height: 30),
                      _buildLeaderActionButton(
                        "ACCEPT",
                        Icons.check_circle_outline,
                        _handleSearchValidation,
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 12,
                right: 12,
                child: GlassBottomNavBar(
                  activeIndex: 1,
                  onTap: (index) {
                    if (index == 0) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MenuPage()),
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
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildGlassSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _batchIdController,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: "Enter Basket ID (e.g. 1)",
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textWhite40,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF00FFA3),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderActionButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00FFA3).withOpacity(0.15),
                const Color(0xFF4DFFDF).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFF00FFA3).withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFA3).withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FFA3).withOpacity(0.4),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF00FFA3),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white38,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _glassCircleButton(
                    Icons.arrow_back_ios_new,
                    () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Search Reports',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassCircleButton(IconData icon, VoidCallback onTap) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    ),
  );
}
