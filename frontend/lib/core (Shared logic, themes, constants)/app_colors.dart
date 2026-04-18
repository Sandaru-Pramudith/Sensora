import 'package:flutter/material.dart';

/// Centralized color definitions for the Sensora app
/// Use these constants throughout the project for consistent styling
class AppColors {
  // Primary Background Gradient Colors
  static const Color gradientDark = Color(0xFF143C28);
  static const Color gradientMid = Color(0xFF1A532F);
  static const Color gradientLight = Color(0xFF2B7A48);

  static const List<Color> backgroundGradient = [
    gradientDark,
    gradientMid,
    gradientLight,
  ];

  // Header Colors
  static const Color headerGreen = Color(0xB31B3F2B);

  // Accent Colors
  static const Color accentGreen = Color(0xFF6BCB5B);
  static const Color highlightGreen = Color(0xFF00FFA3);

  // Particle/Animation Colors
  static const Color particleColor = Color(0xFF6BCB5B);

  // Dropdown/Menu Colors
  static const Color dropdownColor = Color(0xFF2E7D52);
  static const Color modalBackground = Color(0xFF1A3D2E);

  // Glass Effect Colors
  static const Color glassWhite = Color(0x14FFFFFF); // 8% opacity
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% opacity
  static const Color glassBackground = Color(0x26000000); // 15% opacity

  // Text Colors
  static const Color textWhite = Colors.white;
  static const Color textWhite90 = Color(0xE6FFFFFF); // 90% opacity
  static const Color textWhite80 = Color(0xCCFFFFFF); // 80% opacity
  static const Color textWhite70 = Color(0xB3FFFFFF); // 70% opacity
  static const Color textWhite60 = Color(0x99FFFFFF); // 60% opacity
  static const Color textWhite50 = Color(0x80FFFFFF); // 50% opacity
  static const Color textWhite40 = Color(0x66FFFFFF); // 40% opacity

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE91E63);
  static const Color info = Color(0xFF2196F3);
  static const Color danger = Color(0xFFCB5B5B);

  // Notification Type Colors
  static const Color appUpdateColor = Color(0xFF6BCB5B);
  static const Color loginLogoutColor = Color(0xFF5B9ECB);
  static const Color alertColor = Color(0xFFCB5B5B);

  // Button Colors
  static const Color buttonGreen = Color(0xFF6BCB5B);
  static const Color buttonRed = Colors.red;

  // Chart Colors
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartPink = Color(0xFFE91E63);
  static const Color chartGray = Color(0xFFE0E0E0);

  // Divider/Border Colors
  static const Color dividerLight = Color(0x1AFFFFFF); // 10% opacity
  static const Color dividerDark = Color(0x14FFFFFF); // 8% opacity

  // ====================
  // UI Standardization Tokens
  // ====================

  // Spacing
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space18 = 18;
  static const double space20 = 20;
  static const double space24 = 24;

  // Radius
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radiusPill = 30;

  // Icon sizes
  static const double iconSm = 14;
  static const double iconMd = 18;
  static const double iconLg = 22;
  static const double iconXl = 24;

  // Common component sizes
  static const double buttonHeight = 46;
  static const double buttonHeightLg = 52;
  static const double navBarHeight = 54;
  static const double headerActionSize = 42;
  static const double navIconSize = 21;
  static const double navBackIconSize = 20;

  // Typography scale
  static const double textXs = 11;
  static const double textSm = 12;
  static const double textMd = 14;
  static const double textLg = 16;
  static const double textXl = 18;
  static const double text2xl = 22;
  static const double text3xl = 26;

  // Glass/opacity standards
  static const double glassBlur = 14;
  static const double glassBorderWidth = 1.2;
  static const double glassBackgroundOpacity = 0.10;
  static const double glassBorderOpacity = 0.12;
  static const double appShadowOpacity = 0.22;
  static const double appShadowBlur = 16;
}
