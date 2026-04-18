import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';

import 'loading_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SensoraApp());
}

class SensoraApp extends StatelessWidget {
  const SensoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);

    return MaterialApp(
      title: 'Sensora',
      theme: base.copyWith(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        splashFactory: InkSparkle.splashFactory,
        scaffoldBackgroundColor: AppColors.gradientDark,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppColors.accentGreen,
              brightness: Brightness.dark,
            ).copyWith(
              primary: AppColors.accentGreen,
              secondary: AppColors.highlightGreen,
              surface: AppColors.modalBackground,
              onSurface: AppColors.textWhite,
            ),
        iconTheme: const IconThemeData(
          size: AppColors.iconMd,
          color: AppColors.textWhite70,
        ),
        textTheme: base.textTheme.apply(
          bodyColor: AppColors.textWhite,
          displayColor: AppColors.textWhite,
          fontSizeFactor: 1.0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.modalBackground.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            side: BorderSide(color: AppColors.textWhite.withOpacity(0.10)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.modalBackground.withOpacity(0.94),
          contentTextStyle: const TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: AppColors.textWhite.withOpacity(0.12),
          thickness: 1,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, AppColors.buttonHeight),
            ),
            foregroundColor: const WidgetStatePropertyAll(
              AppColors.textWhite,
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.textWhite.withOpacity(0.25);
              }
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF58B84A);
              }
              return AppColors.accentGreen;
            }),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) return 0;
              return 2;
            }),
            shadowColor: WidgetStatePropertyAll(
              AppColors.accentGreen.withOpacity(0.35),
            ),
            overlayColor: WidgetStatePropertyAll(
              AppColors.textWhite.withOpacity(0.08),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontSize: AppColors.textMd,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, AppColors.buttonHeight),
            ),
            foregroundColor: const WidgetStatePropertyAll(
              AppColors.textWhite,
            ),
            backgroundColor: WidgetStatePropertyAll(AppColors.accentGreen),
            overlayColor: WidgetStatePropertyAll(
              AppColors.textWhite.withOpacity(0.08),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontSize: AppColors.textMd,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(0, AppColors.buttonHeight),
            ),
            foregroundColor: const WidgetStatePropertyAll(
              AppColors.textWhite70,
            ),
            side: WidgetStatePropertyAll(
              BorderSide(color: AppColors.textWhite.withOpacity(0.16)),
            ),
            overlayColor: WidgetStatePropertyAll(
              AppColors.textWhite.withOpacity(0.05),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
              ),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontSize: AppColors.textMd,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.textWhite.withOpacity(0.06),
          labelStyle: const TextStyle(color: AppColors.textWhite70),
          hintStyle: const TextStyle(color: AppColors.textWhite50),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            borderSide: BorderSide(color: AppColors.textWhite.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            borderSide: BorderSide(color: AppColors.textWhite.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            borderSide: BorderSide(
              color: AppColors.highlightGreen.withOpacity(0.8),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Start the app with the LoadingPage as the initial route.
      home: const LoadingPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensora')),
      body: const Center(child: Text('Welcome to Sensora!')),
    );
  }
}
