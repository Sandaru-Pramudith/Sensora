import 'dart:ui';
import 'package:flutter/material.dart';

import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'core/user_session.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'login_page.dart';

class LogoutConfirmationPage extends StatefulWidget {
  const LogoutConfirmationPage({super.key});

  @override
  State<LogoutConfirmationPage> createState() => _LogoutConfirmationPageState();
}

class _LogoutConfirmationPageState extends State<LogoutConfirmationPage>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _particleController.dispose();
    super.dispose();
  }

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
        particleCount: 40,
        particleColor: Colors.greenAccent,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildConfirmationDialog(),
                  ),
                ),
              ),
            ],
          ),
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
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.centerLeft, child: _backButton(context)),
            const Center(
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlur,
          sigmaY: AppColors.glassBlur,
        ),
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
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textWhite,
              size: AppColors.iconMd,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationDialog() {
    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
      borderRadius: 28,
      color: Colors.white.withValues(alpha: 0.12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Are You Sure You Want To Log Out?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _handleLogout(),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    UserSession.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LogoutSuccessPage()),
    );
  }
}

class LogoutSuccessPage extends StatefulWidget {
  const LogoutSuccessPage({super.key});

  @override
  State<LogoutSuccessPage> createState() => _LogoutSuccessPageState();
}

class _LogoutSuccessPageState extends State<LogoutSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final AnimationController _particleController;
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _particleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: AnimatedBackground(
          gradientColors: const [
            Color.fromARGB(255, 15, 47, 30),
            Color.fromARGB(255, 16, 44, 18),
            Color.fromARGB(255, 27, 94, 58),
          ],
          particleCount: 40,
          particleColor: Colors.greenAccent,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildSuccessContent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24, width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.logout, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Logged Out Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  elevation: 4,
                  shadowColor: AppColors.accentGreen.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Go To Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
