import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/habit_task_model.dart';
import '../../data/models/user_profile_model.dart';
import '../profile/profile_provider.dart';
import '../profile/xp_provider.dart';
import '../tasks/tasks_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final tasksAsync = ref.watch(todayTasksNotifierProvider);
    final xpAsync = ref.watch(xpNotifierProvider);

    final profile = profileAsync.valueOrNull;
    final tasks = tasksAsync.valueOrNull ?? [];
    final xpState = xpAsync.valueOrNull ?? const XPState.initial();

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final progress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    final userName =
        profile?.name.isNotEmpty == true ? profile!.name : 'Athlete';
    final stepGoal = profile?.dailyStepGoal ?? 6000;

    return AppScaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async {
          await ref.read(todayTasksNotifierProvider.notifier).loadTodayTasks();
          await ref.read(xpNotifierProvider.notifier).loadXP();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, userName, profile),
              AppSpacing.gapH24,
              _buildTodayProgressCard(progress, completedTasks, totalTasks),
              AppSpacing.gapH20,
              _buildQuickStatsRow(xpState, stepGoal),
              AppSpacing.gapH28,
              SectionHeader(
                title: "Today's Tasks",
                subtitle:
                    'Tailored for ${profile?.fitnessLevel.displayName ?? "your"} journey',
                actionLabel: 'See All ($completedTasks/$totalTasks)',
                onActionTap: () => context.push('/tasks'),
              ),
              AppSpacing.gapH16,
              _buildTaskList(context, ref, tasks, tasksAsync.isLoading),
              AppSpacing.gapH32,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName,
    UserProfile? profile,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, $userName',
                style: AppTypography.headlineLarge,
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.gapH4,
              Text(
                "Let's make today count.",
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
        // Profile Avatar -> tapping opens profile
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.substring(0, 1).toUpperCase(),
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayProgressCard(
    double progress,
    int completedTasks,
    int totalTasks,
  ) {
    final percent = (progress * 100).toInt();

    return AppCard(
      gradient: AppColors.cardGradient,
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          // Radial Progress Ring
          ProgressRing(
            progress: progress,
            size: 100,
            strokeWidth: 9,
            percentageText: '$percent%',
          ),
          AppSpacing.gapW20,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    "TODAY'S PROGRESS",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppSpacing.gapH8,
                Text(
                  '$completedTasks of $totalTasks habits completed',
                  style: AppTypography.titleMedium,
                ),
                AppSpacing.gapH4,
                Text(
                  completedTasks == totalTasks && totalTasks > 0
                      ? 'All habits crushed today! 🔥'
                      : 'Tap habits below to log progress.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(XPState xpState, int stepGoal) {
    return Row(
      children: [
        const Expanded(
          child: StatCard(
            label: 'Streak',
            value: '🔥 1 Day',
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.tertiary,
            subtitle: 'Day 1 of Consistency',
          ),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: StatCard(
            label: 'Level ${xpState.level}',
            value: '${xpState.totalXP} XP',
            icon: Icons.flash_on_rounded,
            iconColor: AppColors.secondary,
            subtitle: '+${xpState.dailyXP} XP Today',
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<HabitTask> tasks,
    bool isLoading,
  ) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (tasks.isEmpty) {
      return AppCard(
        padding: AppSpacing.cardPadding,
        child: Center(
          child: Text(
            'No tasks generated yet. Pull to reload.',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => AppSpacing.gapH12,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(context, ref, task);
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, HabitTask task) {
    final color = task.type.defaultColor;
    final isDone = task.isCompleted;

    return AppCard(
      onTap: () {
        context.push('/task-detail/${task.id}');
      },
      borderColor: isDone
          ? AppColors.primary.withValues(alpha: 0.5)
          : AppColors.border,
      backgroundColor: isDone
          ? AppColors.primary.withValues(alpha: 0.05)
          : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: isDone
                        ? AppColors.primary
                        : color.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : task.type.icon,
                  color: isDone ? AppColors.primary : color,
                  size: 22,
                ),
              ),
              AppSpacing.gapW16,
              // Task Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.titleMedium.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Row(
                      children: [
                        Text(
                          task.type.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDone ? AppColors.primary : color,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                        Text(
                          '${task.currentProgress} / ${task.target} ${task.unit}',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // XP Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(
                    color: isDone ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDone) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      AppSpacing.gapW4,
                    ],
                    Text(
                      '+${task.xpReward} XP',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDone
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,
          // Progress Bar
          ClipRRect(
            borderRadius: AppRadius.radiusPill,
            child: LinearProgressIndicator(
              value: task.progressPercentage,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.primary : color,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
