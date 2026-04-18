import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core (Shared logic, themes, constants)/app_colors.dart';
import '../notifications_page.dart';

class GlassNavBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final bool showNotification;
  final VoidCallback? onNotificationTap;
  final int notificationCount;
  final EdgeInsetsGeometry padding;
  final double titleSize;
  final Color titleColor;

  const GlassNavBar({
    super.key,
    required this.title,
    this.onBack,
    this.showNotification = true,
    this.onNotificationTap,
    this.notificationCount = 4,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 10),
    this.titleSize = AppColors.text3xl,
    this.titleColor = AppColors.textWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                _glassCircleButton(Icons.arrow_back_ios_new, onBack!)
              else
                const SizedBox(
                  width: AppColors.headerActionSize,
                  height: AppColors.headerActionSize,
                ),
              const Spacer(),
              if (showNotification)
                _notificationButton(context)
              else
                const SizedBox(
                  width: AppColors.headerActionSize,
                  height: AppColors.headerActionSize,
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCircleButton(IconData icon, VoidCallback onTap) => ClipRRect(
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
            color: AppColors.textWhite.withValues(alpha: 
              AppColors.glassBorderOpacity,
            ),
            width: AppColors.glassBorderWidth,
          ),
        ),
        child: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            icon,
            color: AppColors.textWhite,
            size: AppColors.navBackIconSize,
          ),
        ),
      ),
    ),
  );

  Widget _notificationButton(BuildContext context) {
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
              color: AppColors.textWhite.withValues(alpha: 
                AppColors.glassBorderOpacity,
              ),
              width: AppColors.glassBorderWidth,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (onNotificationTap != null) {
                      onNotificationTap!.call();
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.textWhite,
                    size: AppColors.navBackIconSize,
                  ),
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onTap;

  const GlassBottomNavBar({super.key, this.activeIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_outlined,
      Icons.bar_chart_outlined,
      Icons.menu,
      Icons.person,
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = math.min(308.0, screenWidth * 0.72);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Align(
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: pillWidth,
              height: AppColors.navBarHeight,
              decoration: BoxDecoration(
                color: AppColors.gradientLight.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                border: Border.all(
                  color: AppColors.textWhite.withValues(alpha: 
                    AppColors.glassBorderOpacity,
                  ),
                  width: AppColors.glassBorderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientLight.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  icons.length,
                  (i) => _buildItem(context, icons[i], i == activeIndex, i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    bool active,
    int index,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: AppColors.textWhite.withValues(alpha: 0.10),
        highlightColor: AppColors.textWhite.withValues(alpha: 0.06),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(6),
          child: CircleAvatar(
            radius: active ? 18 : 17,
            backgroundColor: active
                ? AppColors.accentGreen.withValues(alpha: 0.95)
                : Colors.transparent,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: active ? 1.06 : 1,
              child: Icon(
                icon,
                size: AppColors.navIconSize,
                color: active ? AppColors.textWhite : AppColors.textWhite70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
