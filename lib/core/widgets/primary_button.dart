import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Premium high-energy action button with optional icon, glow & loading state.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final LinearGradient? gradient;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 54.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = onPressed != null && !isLoading
        ? (gradient ?? AppColors.primaryGradient)
        : null;

    final childWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      width: isFullWidth ? double.infinity : width,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        color: onPressed == null || isLoading ? AppColors.surfaceElevated : null,
        borderRadius: AppRadius.radiusLg,
        boxShadow: onPressed != null && !isLoading
            ? [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppRadius.radiusLg,
          splashColor: Colors.black.withValues(alpha: 0.15),
          highlightColor: Colors.black.withValues(alpha: 0.08),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.background),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 20,
                          color: onPressed != null
                              ? AppColors.background
                              : AppColors.textDisabled,
                        ),
                        AppSpacing.gapW8,
                      ],
                      Text(
                        text,
                        style: AppTypography.labelLarge.copyWith(
                          color: onPressed != null
                              ? AppColors.background
                              : AppColors.textDisabled,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return childWidget;
  }
}
