import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      badge: 'AUTOMATED TRACKING',
      title: 'Track Automatically',
      subtitle:
          'Habitude seamlessly logs your daily movement and steps in real time without manual check-ins.',
      icon: Icons.directions_run_rounded,
      accentColor: AppColors.primary,
    ),
    _OnboardingItem(
      badge: 'COMPUTER VISION AI',
      title: 'Move With AI',
      subtitle:
          'Next-gen camera vision evaluates your posture, guides exercise form, and counts every rep accurately.',
      icon: Icons.camera_enhance_rounded,
      accentColor: AppColors.secondary,
    ),
    _OnboardingItem(
      badge: 'PROGRESSIVE HABITS',
      title: 'Build Your Streak',
      subtitle:
          'Earn XP, unlock progressive fitness targets, and transform daily consistency into personal growth.',
      icon: Icons.local_fire_department_rounded,
      accentColor: AppColors.tertiary,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setHasSeenOnboarding(true);
    if (mounted) {
      context.go('/personalization');
    }
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.animNormal,
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Tagline & Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl20,
                vertical: AppSpacing.md12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textTertiary,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'Skip',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 36, width: 48),
                ],
              ),
            ),

            // Main PageView Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return _buildPageSlide(item);
                },
              ),
            ),

            // Bottom Navigation Section (Indicator & Action Buttons)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl20,
                vertical: AppSpacing.lg16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Indicator Pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index == _currentIndex),
                    ),
                  ),
                  AppSpacing.gapH24,
                  // Action Button
                  PrimaryButton(
                    text: isLastPage ? 'Get Started' : 'Next',
                    icon: isLastPage ? Icons.arrow_forward_rounded : null,
                    onPressed: _nextPage,
                  ),
                  AppSpacing.gapH12,
                  // Sub-text
                  Text(
                    AppConstants.appSubtagline,
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSlide(_OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Futuristic Icon Container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(
                color: item.accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.accentColor.withValues(alpha: 0.15),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                item.icon,
                size: 64,
                color: item.accentColor,
              ),
            ),
          ),
          AppSpacing.gapH40,
          // Feature Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: item.accentColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusPill,
              border: Border.all(
                color: item.accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              item.badge,
              style: AppTypography.labelSmall.copyWith(
                color: item.accentColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          AppSpacing.gapH16,
          // Slide Title
          Text(
            item.title,
            style: AppTypography.displaySmall,
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH12,
          // Slide Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              item.subtitle,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: AppConstants.animFast,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surfaceHighlight,
        borderRadius: AppRadius.radiusPill,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}

class _OnboardingItem {
  final String badge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _OnboardingItem({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}
