import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/analytics_data_model.dart';
import 'analytics_provider.dart';
import 'widgets/activity_chart_widget.dart';
import 'widgets/exercise_progression_card.dart';
import 'widgets/insights_card.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final analyticsAsync = ref.watch(analyticsFutureProvider(selectedPeriod));
    final achievementsAsync = ref.watch(achievementsListProvider);

    return AppScaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async {
          ref.invalidate(analyticsFutureProvider(selectedPeriod));
          ref.invalidate(achievementsListProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              AppSpacing.gapH20,
              _buildPeriodSelector(context, ref, selectedPeriod),
              AppSpacing.gapH24,
              analyticsAsync.when(
                data: (analytics) => _buildAnalyticsContent(
                  context,
                  ref,
                  analytics,
                  achievementsAsync.valueOrNull ?? [],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, stack) => AppCard(
                  padding: AppSpacing.cardPadding,
                  child: Center(
                    child: Text(
                      'Failed to load progress data.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH32,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: AppTypography.headlineLarge,
        ),
        AppSpacing.gapH4,
        Text(
          'Track your consistency, physical growth, and milestones.',
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    AnalyticsPeriod currentPeriod,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.radiusPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = period == currentPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(selectedPeriodProvider.notifier).state = period;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Center(
                  child: Text(
                    period.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    WidgetRef ref,
    PerformanceAnalytics analytics,
    List<dynamic> achievements,
  ) {
    if (!analytics.hasEnoughData) {
      return const EmptyState(
        icon: Icons.insights_rounded,
        title: 'Your progress story starts today',
        description:
            'As you complete daily habits, steps, and AI camera workouts, your detailed trends and metrics will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Key Statistics Grid
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Task Completion',
                value: '${analytics.taskCompletionRate.toStringAsFixed(0)}%',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.primary,
                subtitle:
                    '${analytics.totalTasksCompleted}/${analytics.totalTasksPlanned} habits',
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: StatCard(
                label: 'Total Movement',
                value: '${analytics.totalSteps}',
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.secondary,
                subtitle: 'Avg ${analytics.averageDailySteps} steps/day',
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'AI Workouts',
                value: '${analytics.totalWorkouts}',
                icon: Icons.fitness_center_rounded,
                iconColor: AppColors.tertiary,
                subtitle: analytics.formattedWorkoutDuration,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: StatCard(
                label: 'Streak / XP',
                value: '🔥 ${analytics.currentStreak}d',
                icon: Icons.bolt_rounded,
                iconColor: AppColors.warning,
                subtitle: '${analytics.totalXP} Total XP',
              ),
            ),
          ],
        ),
        AppSpacing.gapH24,

        // 2. Activity Chart
        ActivityChartWidget(dailyPoints: analytics.dailyPoints),
        AppSpacing.gapH24,

        // 3. Step Analysis Card
        _buildStepAnalyticsCard(analytics),
        AppSpacing.gapH24,

        // 4. Workout Analytics Card
        _buildWorkoutAnalyticsCard(analytics),
        AppSpacing.gapH24,

        // 5. Adaptive Exercise Progression Stepper
        ExerciseProgressionCard(progressions: analytics.exerciseProgressions),
        AppSpacing.gapH24,

        // 6. AI Insights
        InsightsCard(insights: analytics.insights),
        AppSpacing.gapH24,

        // 7. Achievements Preview
        _buildAchievementsPreview(context, achievements),
      ],
    );
  }

  Widget _buildStepAnalyticsCard(PerformanceAnalytics analytics) {
    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: AppColors.secondary,
                size: 20,
              ),
              AppSpacing.gapW8,
              Text(
                'Step Goal Performance',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          AppSpacing.gapH16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal Met Rate',
                    style: AppTypography.caption,
                  ),
                  AppSpacing.gapH4,
                  Text(
                    '${analytics.stepGoalCompletionRate.toStringAsFixed(0)}%',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${analytics.stepGoalDaysReached} of ${analytics.period.days} days',
                    style: AppTypography.caption,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Peak Step Day',
                    style: AppTypography.caption,
                  ),
                  AppSpacing.gapH4,
                  Text(
                    '${analytics.peakSteps}',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    analytics.peakStepDate.isNotEmpty
                        ? analytics.peakStepDate
                        : 'Today',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutAnalyticsCard(PerformanceAnalytics analytics) {
    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_gymnastics_rounded,
                color: AppColors.tertiary,
                size: 20,
              ),
              AppSpacing.gapW8,
              Text(
                'Workout Breakdown',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          AppSpacing.gapH16,
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Completed', style: AppTypography.caption),
                      AppSpacing.gapH4,
                      Text(
                        '${analytics.totalWorkouts} sessions',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Exercise', style: AppTypography.caption),
                      AppSpacing.gapH4,
                      Text(
                        analytics.mostPerformedExercise,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsPreview(
    BuildContext context,
    List<dynamic> achievements,
  ) {
    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  AppSpacing.gapW8,
                  Text(
                    'Milestone Achievements',
                    style: AppTypography.titleMedium,
                  ),
                ],
              ),
              Text(
                '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: achievements.take(4).map((ach) {
              final isUnlocked = ach.isUnlocked as bool;
              final icon = ach.achievement.icon as String;
              final title = ach.achievement.title as String;

              return Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnlocked
                            ? AppColors.warning
                            : AppColors.border,
                        width: isUnlocked ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(
                          fontSize: 22,
                          color: isUnlocked ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH4,
                  SizedBox(
                    width: 70,
                    child: Text(
                      title,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
