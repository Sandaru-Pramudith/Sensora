import 'dart:ui';
import 'package:flutter/material.dart';
import '../core (Shared logic, themes, constants)/app_colors.dart';

class GlassContainer extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;
  final Widget child;

  const GlassContainer({
    super.key,
    required this.padding,
    required this.borderRadius,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlur,
          sigmaY: AppColors.glassBlur,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.textWhite.withValues(alpha: 0.06),
                AppColors.textWhite.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 
                AppColors.glassBorderOpacity,
              ),
              width: AppColors.glassBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
