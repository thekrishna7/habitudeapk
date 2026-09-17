import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/services/step_tracking_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/stat_card.dart';

class StepTrackingScreen extends ConsumerWidget {
  const StepTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepState = ref.watch(stepTrackingProvider);
    final notifier = ref.read(stepTrackingProvider.notifier);

    final distanceKm = (stepState.todaySteps * 0.00078).toStringAsFixed(2);
    final caloriesKcal = (stepState.todaySteps * 0.045).toStringAsFixed(0);

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Movement & Steps', style: AppTypography.displaySmall),
                    AppSpacing.gapH4,
                    Text(
                      'Live hardware sensor cadence tracking',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stepState.isTracking
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.error.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusPill,
                    border: Border.all(
                      color: stepState.isTracking
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stepState.isTracking
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Text(
                        stepState.isTracking ? 'Active' : 'Offline',
                        style: AppTypography.labelSmall.copyWith(
                          color: stepState.isTracking
                              ? AppColors.primary
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapH24,

            // Permission Warning Card if not granted
            if (!stepState.hasPermission) ...[
              AppCard(
                borderColor: AppColors.warning,
                backgroundColor: AppColors.warning.withValues(alpha: 0.08),
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 24,
                        ),
                        AppSpacing.gapW10,
                        Text(
                          'Sensor Permission Required',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'To automatically count steps in background, Habitude needs Activity Recognition permission.',
                      style: AppTypography.bodySmall,
                    ),
                    AppSpacing.gapH16,
                    PrimaryButton(
                      text: 'Grant Permission & Start',
                      height: 44,
                      icon: Icons.lock_open_rounded,
                      onPressed: () => notifier.requestPermissionAndStart(),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,
            ],

            // Hero Radial Gauge Card
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Column(
                children: [
                  Center(
                    child: ProgressRing(
                      progress: stepState.progressPercentage,
                      size: 180,
                      strokeWidth: 14,
                      centerWidget: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_walk_rounded,
                            size: 32,
                            color: AppColors.secondary,
                          ),
                          AppSpacing.gapH4,
                          Text(
                            '${stepState.todaySteps}',
                            style: AppTypography.headlineLarge.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '/ ${stepState.targetSteps} target',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapH24,
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        AppSpacing.gapW8,
                        Text(
                          'Pedestrian Motion: ${stepState.pedestrianStatus.toUpperCase()}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH24,

            // Quick Stats Grid
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Distance Walked',
                    value: '$distanceKm km',
                    icon: Icons.route_rounded,
                    iconColor: AppColors.primary,
                    subtitle: 'Estimated Cadence',
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: StatCard(
                    label: 'Burned Output',
                    value: '$caloriesKcal kcal',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.tertiary,
                    subtitle: 'Metabolic Pace',
                  ),
                ),
              ],
            ),
            AppSpacing.gapH24,

            // Manual Test Controls (Useful for testing)
            AppCard(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step Sensor Testing', style: AppTypography.titleMedium),
                  AppSpacing.gapH8,
                  Text(
                    'Walk with your device in hand or pocket to see the live count increment automatically.',
                    style: AppTypography.bodySmall,
                  ),
                  AppSpacing.gapH16,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('+100 Steps'),
                          onPressed: () => notifier.addManualSteps(100),
                        ),
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusMd,
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Re-detect'),
                          onPressed: () => notifier.requestPermissionAndStart(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
