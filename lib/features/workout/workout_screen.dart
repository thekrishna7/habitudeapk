import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/habit_task_model.dart';
import '../tasks/tasks_provider.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksNotifierProvider).valueOrNull ?? [];

    return AppScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            AppSpacing.gapH24,
            const SectionHeader(
              title: 'AI Computer Vision Workouts',
              subtitle: 'Select an exercise for real-time form tracking & rep count',
            ),
            AppSpacing.gapH16,
            _buildExerciseCard(
              context: context,
              type: TaskType.pushUps,
              title: 'Push-ups',
              difficulty: 'Intermediate',
              target: '10 reps',
              xp: '+75 XP',
              color: AppColors.secondary,
              matchingTask: tasks.where((t) => t.type == TaskType.pushUps).firstOrNull,
            ),
            AppSpacing.gapH12,
            _buildExerciseCard(
              context: context,
              type: TaskType.squats,
              title: 'Squats',
              difficulty: 'Beginner',
              target: '15 reps',
              xp: '+75 XP',
              color: const Color(0xFF38BDF8),
              matchingTask: tasks.where((t) => t.type == TaskType.squats).firstOrNull,
            ),
            AppSpacing.gapH12,
            _buildExerciseCard(
              context: context,
              type: TaskType.plank,
              title: 'Plank Hold',
              difficulty: 'Core Endurance',
              target: '30 sec',
              xp: '+60 XP',
              color: AppColors.tertiary,
              matchingTask: tasks.where((t) => t.type == TaskType.plank).firstOrNull,
            ),
            AppSpacing.gapH12,
            _buildExerciseCard(
              context: context,
              type: TaskType.jumpingJacks,
              title: 'Jumping Jacks',
              difficulty: 'Cardio Burn',
              target: '25 reps',
              xp: '+50 XP',
              color: AppColors.warning,
              matchingTask: tasks.where((t) => t.type == TaskType.jumpingJacks).firstOrNull,
            ),
            AppSpacing.gapH32,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Workout Hub', style: AppTypography.displaySmall),
        AppSpacing.gapH4,
        Text(
          'Let Habitude watch your form and count every repetition.',
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildExerciseCard({
    required BuildContext context,
    required TaskType type,
    required String title,
    required String difficulty,
    required String target,
    required String xp,
    required Color color,
    required HabitTask? matchingTask,
  }) {
    final taskId = matchingTask?.id ?? 'custom_${type.name}';
    final targetCount = matchingTask?.target ?? 10;
    final isCompleted = matchingTask?.isCompleted ?? false;

    return AppCard(
      onTap: () {
        context.push(
          '/ai-workout?taskId=$taskId&type=${type.name}&target=$targetCount',
        );
      },
      borderColor: isCompleted ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
      backgroundColor: isCompleted ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.15),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: isCompleted ? AppColors.primary : color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : type.icon,
              color: isCompleted ? AppColors.primary : color,
              size: 26,
            ),
          ),
          AppSpacing.gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: AppTypography.titleLarge),
                    if (isCompleted) ...[
                      AppSpacing.gapW8,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text(
                          'COMPLETED',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapH4,
                Text(
                  '$difficulty • $target',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  xp,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppSpacing.gapH8,
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
