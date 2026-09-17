import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/habit_task_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../tasks/tasks_provider.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksNotifierProvider).valueOrNull ?? [];
    final workoutRepo = ref.watch(workoutRepositoryProvider);
    final workouts = workoutRepo.getPredefinedWorkouts();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 120, // clearance for liquid floating dock
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          AppSpacing.gapH24,

          // Structured Workout Programs
          const SectionHeader(
            title: 'Full Workout Programs',
            subtitle: 'Multi-exercise guided routines with live AI pose tracking',
          ),
          AppSpacing.gapH16,
          ...workouts.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: _buildProgramCard(context, w),
              )),

          AppSpacing.gapH28,
          // Individual AI Exercises
          const SectionHeader(
            title: 'Quick AI Exercise Launch',
            subtitle: 'Targeted single-exercise computer vision sessions',
          ),
          AppSpacing.gapH16,
          _buildExerciseCard(
            context: context,
            type: TaskType.pushUps,
            title: 'Push-ups',
            difficulty: 'Upper Body',
            target: '10 reps',
            xp: '+75 XP',
            color: AppColors.primary,
            matchingTask:
                tasks.where((t) => t.type == TaskType.pushUps).firstOrNull,
          ),
          AppSpacing.gapH12,
          _buildExerciseCard(
            context: context,
            type: TaskType.squats,
            title: 'Squats',
            difficulty: 'Lower Power',
            target: '15 reps',
            xp: '+75 XP',
            color: AppColors.secondary,
            matchingTask:
                tasks.where((t) => t.type == TaskType.squats).firstOrNull,
          ),
          AppSpacing.gapH12,
          _buildExerciseCard(
            context: context,
            type: TaskType.plank,
            title: 'Plank Hold',
            difficulty: 'Core Stability',
            target: '30 sec',
            xp: '+60 XP',
            color: AppColors.tertiary,
            matchingTask:
                tasks.where((t) => t.type == TaskType.plank).firstOrNull,
          ),
          AppSpacing.gapH12,
          _buildExerciseCard(
            context: context,
            type: TaskType.jumpingJacks,
            title: 'Jumping Jacks',
            difficulty: 'Cardio Engine',
            target: '25 reps',
            xp: '+50 XP',
            color: AppColors.accentPurple,
            matchingTask:
                tasks.where((t) => t.type == TaskType.jumpingJacks).firstOrNull,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.radiusPill,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'AI CAMERA STUDIO',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapH8,
        Text(
          'Workout Arena',
          style: AppTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        AppSpacing.gapH4,
        Text(
          'AI-verified form correction, automated reps, and instant XP rewards.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramCard(BuildContext context, dynamic workout) {
    return AppCard(
      enableGlow: true,
      glowColor: AppColors.secondary,
      padding: const EdgeInsets.all(20),
      onTap: () {
        // Start first exercise in routine
        final firstEx = workout.exercises.first;
        context.push(
          '/ai-workout?taskId=${workout.id}&type=${firstEx.exerciseType.name}&target=${firstEx.target}',
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  workout.difficulty.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.radiusPill,
                ),
                child: Text(
                  '+${workout.totalXP} XP',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,
          Text(
            workout.name,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            workout.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapH16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${workout.estimatedDurationMinutes} mins',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.fitness_center_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.exercises.length} movements',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'START',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.background,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: AppColors.background,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
      borderColor: isCompleted
          ? AppColors.primary.withValues(alpha: 0.6)
          : AppColors.borderGlass,
      enableGlow: isCompleted,
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.15),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: isCompleted
                    ? AppColors.primary
                    : color.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCompleted
                      ? AppColors.primaryGlow
                      : color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : type.icon,
              color: isCompleted ? AppColors.primary : color,
              size: 24,
            ),
          ),
          AppSpacing.gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isCompleted) ...[
                      AppSpacing.gapW8,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: AppRadius.radiusPill,
                        ),
                        child: Text(
                          'DONE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapH4,
                Text(
                  '$difficulty • $target',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  xp,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
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
