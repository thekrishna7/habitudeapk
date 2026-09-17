import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_typography.dart';

class LiquidNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const LiquidNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class LiquidBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidNavItem> items;

  const LiquidBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = const [
      LiquidNavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Home',
      ),
      LiquidNavItem(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center_rounded,
        label: 'Workout',
      ),
      LiquidNavItem(
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights_rounded,
        label: 'Progress',
      ),
      LiquidNavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
      child: ClipRRect(
        borderRadius: AppRadius.radiusFull,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0x8A0B0E17), // iOS ultra-translucent frosted glass
              borderRadius: AppRadius.radiusFull,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.primaryGlow.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (index) {
                final isSelected = index == currentIndex;
                final item = items[index];

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    },
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon with spring scale
                            AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 22,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary.withValues(alpha: 0.7),
                                shadows: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryGlow,
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Label
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary.withValues(alpha: 0.6),
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                fontSize: 10.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // iOS Active Droplet indicator dot
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 12 : 0,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: AppRadius.radiusPill,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryGlow,
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
