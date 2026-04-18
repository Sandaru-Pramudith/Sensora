import 'dart:async';

import 'package:flutter/material.dart';

import 'login_page.dart';
import 'seed_database.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String _loadingMessage = 'Loading...';
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Try to seed database with a timeout to prevent hanging
      await _trySeedDatabaseWithTimeout();

      _navigationTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) {
          return;
        }
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      });
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Still navigate after error
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    }
  }

  Future<void> _trySeedDatabaseWithTimeout() async {
    try {
      // Add 10-second timeout to prevent hanging if Firestore isn't set up
      final isSeeded = await DatabaseSeeder.isDatabaseSeeded().timeout(
        const Duration(seconds: 10),
        onTimeout: () => true,
      );

      if (!mounted) {
        return;
      }

      if (!isSeeded) {
        setState(() => _loadingMessage = 'Setting up database...');
        await DatabaseSeeder.seedDatabase().timeout(
          const Duration(seconds: 30),
        );
        if (!mounted) {
          return;
        }
        setState(() => _loadingMessage = 'Database ready!');
      }
    } on TimeoutException {
      debugPrint(
        'Database seeding timed out - Firestore may not be configured',
      );
      if (!mounted) {
        return;
      }
      setState(() => _loadingMessage = 'Skipping database setup...');
    } catch (e) {
      debugPrint('Database seeding error: $e');
      if (!mounted) {
        return;
      }
      setState(() => _loadingMessage = 'Continuing without database...');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        gradientColors: const [
          Color.fromARGB(255, 15, 47, 30),
          Color.fromARGB(255, 16, 44, 18),
          Color.fromARGB(255, 27, 94, 58),
        ],
        particleCount: 30,
        particleColor: Colors.greenAccent,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'lib/assets/Sensora logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2B7A2B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _loadingMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
