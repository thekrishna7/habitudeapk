import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/services/storage_service.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileNotifierProvider);

    return AppScaffold(
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text('Error loading profile: $error'),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    AppSpacing.gapH16,
                    Text('No Profile Found', style: AppTypography.headlineMedium),
                    AppSpacing.gapH8,
                    Text(
                      'Complete personalization to set up your fitness journey.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapH24,
                    PrimaryButton(
                      text: 'Set Up Profile',
                      onPressed: () => context.go('/personalization'),
                    ),
                  ],
                ),
              ),
            );
          }

          final initials = profile.name.isNotEmpty
              ? profile.name.substring(0, 1).toUpperCase()
              : 'H';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapH12,
                // Profile Header Card
                _buildHeaderCard(context, profile, initials),
                AppSpacing.gapH24,
                // Key Metrics
                Text('Personal Metrics', style: AppTypography.headlineMedium),
                AppSpacing.gapH12,
                _buildMetricsGrid(profile),
                AppSpacing.gapH24,
                // Stats Summary (Mock/Accumulated Stats)
                Text('Activity Overview', style: AppTypography.headlineMedium),
                AppSpacing.gapH12,
                _buildActivityStatsRow(profile),
                AppSpacing.gapH32,
                // Edit Profile Button
                PrimaryButton(
                  text: 'Edit Profile',
                  icon: Icons.edit_rounded,
                  onPressed: () => context.push('/edit-profile'),
                ),
                AppSpacing.gapH16,
                // Reset / Clear Data Button
                SecondaryButton(
                  text: 'Reset Profile & Data',
                  icon: Icons.refresh_rounded,
                  onPressed: () => _confirmReset(context, ref),
                ),
                AppSpacing.gapH32,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    dynamic profile,
    String initials,
  ) {
    return AppCard(
      gradient: AppColors.cardGradient,
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          AppSpacing.gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: AppTypography.headlineLarge,
                ),
                AppSpacing.gapH4,
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.radiusPill,
                      ),
                      child: Text(
                        profile.fitnessLevel.displayName.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppSpacing.gapW8,
                    Flexible(
                      child: Text(
                        profile.primaryGoal.displayName,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(dynamic profile) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: AppSpacing.cardPaddingCompact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HEIGHT', style: AppTypography.labelSmall),
                AppSpacing.gapH4,
                Text(
                  '${profile.height.toInt()} cm',
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: AppCard(
            padding: AppSpacing.cardPaddingCompact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WEIGHT', style: AppTypography.labelSmall),
                AppSpacing.gapH4,
                Text(
                  '${profile.weight.toInt()} kg',
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: AppCard(
            padding: AppSpacing.cardPaddingCompact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AGE', style: AppTypography.labelSmall),
                AppSpacing.gapH4,
                Text(
                  '${profile.age} yrs',
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStatsRow(dynamic profile) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Streak',
                value: '🔥 0 Days',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.tertiary,
                subtitle: 'Habitude Active',
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: StatCard(
                label: 'Total XP',
                value: '0 XP',
                icon: Icons.flash_on_rounded,
                iconColor: AppColors.secondary,
                subtitle: 'Level 1 Athlete',
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Step Target',
                value: '${profile.dailyStepGoal}',
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.primary,
                subtitle: 'Steps / Day',
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: StatCard(
                label: 'Daily Session',
                value: '${profile.preferredWorkoutDuration} min',
                icon: Icons.timer_outlined,
                iconColor: AppColors.accentPurple,
                subtitle: 'Preferred Target',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Reset All Data?', style: AppTypography.titleLarge),
        content: Text(
          'This will clear your local user profile and restart the setup flow.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      await ref.read(userProfileNotifierProvider.notifier).clearProfile();
      final storage = ref.read(storageServiceProvider);
      await storage.setHasSeenOnboarding(false);
      if (context.mounted) {
        context.go('/onboarding');
      }
    }
  }
}
