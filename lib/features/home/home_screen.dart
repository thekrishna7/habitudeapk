import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/models/habit_task_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../core/services/step_tracking_service.dart';
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
    final stepState = ref.watch(stepTrackingProvider);

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final progress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;

    final userName =
        profile?.name.isNotEmpty == true ? profile!.name : 'Athlete';

    return RefreshIndicator(
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
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 120, // generous clearance for floating liquid nav dock
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, userName, profile, xpState),
            AppSpacing.gapH24,
            _buildTodayProgressHeroCard(progress, completedTasks, totalTasks),
            AppSpacing.gapH20,
            _buildQuickStatsRow(context, xpState, stepState),
            AppSpacing.gapH28,
            SectionHeader(
              title: "Today's Routine",
              subtitle:
                  '${profile?.fitnessLevel.displayName ?? "Custom"} • ${profile?.primaryGoal.displayName ?? "Fitness"}',
              actionLabel: 'View All ($completedTasks/$totalTasks)',
              onActionTap: () => context.push('/tasks'),
            ),
            AppSpacing.gapH16,
            _buildTaskList(context, ref, tasks, tasksAsync.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName,
    UserProfile? profile,
    XPState xpState,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LEVEL ${xpState.level} ATHLETE',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH8,
              Text(
                '${_getGreeting()}, $userName',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Glass Avatar
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayProgressHeroCard(
    double progress,
    int completedTasks,
    int totalTasks,
  ) {
    final percent = (progress * 100).toInt();

    return AppCard(
      enableGlow: true,
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Glowing Radial Ring
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
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    "TODAY'S TARGET",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                AppSpacing.gapH8,
                Text(
                  '$completedTasks of $totalTasks Habits',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                AppSpacing.gapH4,
                Text(
                  completedTasks == totalTasks && totalTasks > 0
                      ? 'All habits crushed today! 🔥'
                      : 'Tap habits below to start AI workout.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(
    BuildContext context,
    XPState xpState,
    StepTrackingState stepState,
  ) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Live Steps',
            value: '${stepState.todaySteps}',
            icon: Icons.directions_walk_rounded,
            iconColor: AppColors.secondary,
            subtitle: stepState.pedestrianStatus,
            onTap: () => context.push('/step_tracking'),
          ),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: StatCard(
            label: 'Total Power',
            value: '${xpState.totalXP} XP',
            icon: Icons.bolt_rounded,
            iconColor: AppColors.primary,
            subtitle: '+${xpState.dailyXP} XP Today',
            onTap: () => context.push('/progress'),
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
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (tasks.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(24),
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
          ? AppColors.primary.withValues(alpha: 0.6)
          : AppColors.borderGlass,
      enableGlow: isDone,
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon pod with glow
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.14),
                  borderRadius: AppRadius.radiusMd,
                  border: Border.all(
                    color: isDone
                        ? AppColors.primary
                        : color.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDone
                          ? AppColors.primaryGlow
                          : color.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : task.type.icon,
                  color: isDone ? AppColors.primary : color,
                  size: 24,
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
                        fontWeight: FontWeight.w800,
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                        Text(
                          '${task.currentProgress} / ${task.target} ${task.unit}',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // XP Badge / Action
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(
                    color: isDone ? AppColors.primary : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDone) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '+${task.xpReward} XP',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDone
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,
          // Glowing Linear Progress Bar
          ClipRRect(
            borderRadius: AppRadius.radiusFull,
            child: LinearProgressIndicator(
              value: task.progressPercentage,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.primary : color,
              ),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
