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
import '../../data/models/habit_task_model.dart';
import 'tasks_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  int _localProgress = 0;
  bool _initialized = false;

  void _showCompletionCelebration(HabitTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapH20,
            Text('Habit Completed!', style: AppTypography.displaySmall),
            AppSpacing.gapH8,
            Text(
              '${task.title} crushed for today.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH16,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.radiusPill,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '+${task.xpReward} XP Earned',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppSpacing.gapH24,
            PrimaryButton(
              text: 'Awesome!',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(todayTasksNotifierProvider).valueOrNull ?? [];
    final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;

    if (task == null) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Task Detail'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text('Task not found', style: AppTypography.bodyMedium),
        ),
      );
    }

    if (!_initialized) {
      _localProgress = task.currentProgress;
      _initialized = true;
    }

    final isDone = task.isCompleted;
    final color = task.type.defaultColor;

    return AppScaffold(
      appBar: AppBar(
        title: Text(task.type.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            AppCard(
              gradient: AppColors.cardGradient,
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : color.withValues(alpha: 0.15),
                          borderRadius: AppRadius.radiusMd,
                          border: Border.all(
                            color: isDone
                                ? AppColors.primary
                                : color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : task.type.icon,
                          color: isDone ? AppColors.primary : color,
                          size: 28,
                        ),
                      ),
                      AppSpacing.gapW16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title, style: AppTypography.headlineLarge),
                            AppSpacing.gapH4,
                            Text(
                              task.description,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH20,
                  // Progress Bar & Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROGRESS: $localProgressDisplay / ${task.target} ${task.unit}',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDone
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '+${task.xpReward} XP',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH8,
                  ClipRRect(
                    borderRadius: AppRadius.radiusPill,
                    child: LinearProgressIndicator(
                      value: task.target > 0
                          ? (_localProgress / task.target).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: AppColors.surfaceHighlight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDone ? AppColors.primary : color,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH24,
            // Mode Banner
            if (task.type.isCameraDetection) ...[
              AppCard(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                borderColor: AppColors.secondary.withValues(alpha: 0.3),
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.camera_enhance_rounded, color: AppColors.secondary, size: 24),
                        AppSpacing.gapW12,
                        Text('AI Vision Workout Available', style: AppTypography.titleMedium.copyWith(color: AppColors.secondary)),
                      ],
                    ),
                    AppSpacing.gapH8,
                    Text('Open your camera to let Habitude automatically track your form and count every repetition in real time.', style: AppTypography.bodySmall),
                    AppSpacing.gapH16,
                    PrimaryButton(
                      text: 'Start AI Camera Session',
                      icon: Icons.play_arrow_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)],
                      ),
                      onPressed: () {
                        context.push(
                          '/ai-workout?taskId=${task.id}&type=${task.type.name}&target=${task.target}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else if (task.type == TaskType.steps) ...[
              AppCard(
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                borderColor: AppColors.primary.withValues(alpha: 0.3),
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_walk_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        AppSpacing.gapW12,
                        Text(
                          'Hardware Step Sensor Active',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH8,
                    Text(
                      'Habitude automatically tracks your steps in the background using your phone\'s cadence sensor.',
                      style: AppTypography.bodySmall,
                    ),
                    AppSpacing.gapH16,
                    PrimaryButton(
                      text: 'Open Live Step Tracker',
                      icon: Icons.speed_rounded,
                      onPressed: () {
                        context.push('/step_tracking');
                      },
                    ),
                  ],
                ),
              ),
            ],
            AppSpacing.gapH24,
            // Instructions Section
            Text('Movement Guidance', style: AppTypography.headlineMedium),
            AppSpacing.gapH12,
            AppCard(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Text(
                      task.type.instructions,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH24,
            // Interactive Progress Controls
            Text('Manual Check-in', style: AppTypography.headlineMedium),
            AppSpacing.gapH12,
            AppCard(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        icon: const Icon(Icons.remove_rounded),
                        onPressed: _localProgress > 0
                            ? () {
                                setState(() {
                                  _localProgress = (_localProgress - 1)
                                      .clamp(0, task.target);
                                });
                              }
                            : null,
                      ),
                      AppSpacing.gapW24,
                      Text(
                        '$_localProgress',
                        style: AppTypography.statNumberLarge.copyWith(
                          color: isDone
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapW24,
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _localProgress < task.target
                            ? () {
                                setState(() {
                                  _localProgress = (_localProgress + 1)
                                      .clamp(0, task.target);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  AppSpacing.gapH16,
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: color,
                      thumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surfaceHighlight,
                    ),
                    child: Slider(
                      value: _localProgress.toDouble(),
                      min: 0,
                      max: task.target.toDouble(),
                      divisions: task.target > 0 ? task.target : 1,
                      onChanged: (val) {
                        setState(() {
                          _localProgress = val.toInt();
                        });
                      },
                    ),
                  ),
                  AppSpacing.gapH8,
                  PrimaryButton(
                    text: _localProgress >= task.target
                        ? 'Complete Habit (+${task.xpReward} XP)'
                        : 'Save Progress',
                    icon: _localProgress >= task.target
                        ? Icons.check_circle_rounded
                        : Icons.save_rounded,
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final justCompleted = await ref
                          .read(todayTasksNotifierProvider.notifier)
                          .updateTaskProgress(task.id, _localProgress);
                      if (!mounted) return;
                      if (justCompleted) {
                        _showCompletionCelebration(task);
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Progress updated!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                        );
                      }
                    },
                  ),
                  if (isDone) ...[
                    AppSpacing.gapH12,
                    SecondaryButton(
                      text: 'Reset Habit',
                      icon: Icons.refresh_rounded,
                      onPressed: () async {
                        await ref
                            .read(todayTasksNotifierProvider.notifier)
                            .resetTask(task.id);
                        setState(() => _localProgress = 0);
                      },
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapH40,
          ],
        ),
      ),
    );
  }

  String get localProgressDisplay => '$_localProgress';
}
