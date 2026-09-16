import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../data/models/habit_task_model.dart';
import 'tasks_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _filter = 'all'; // 'all', 'inProgress', 'completed'

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(todayTasksNotifierProvider);
    final tasks = tasksAsync.valueOrNull ?? [];

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final inProgressTasks =
        tasks.where((t) => t.isInProgress && !t.isCompleted).length;

    final filteredTasks = tasks.where((t) {
      if (_filter == 'completed') return t.isCompleted;
      if (_filter == 'inProgress') return t.isInProgress && !t.isCompleted;
      return true;
    }).toList();

    return AppScaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async {
          await ref.read(todayTasksNotifierProvider.notifier).loadTodayTasks();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: AppSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(completedTasks, totalTasks),
              AppSpacing.gapH20,
              _buildFilterChips(totalTasks, inProgressTasks, completedTasks),
              AppSpacing.gapH20,
              if (tasksAsync.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filteredTasks.isEmpty)
                _buildEmptyFilterState()
              else
                _buildTaskList(filteredTasks),
              AppSpacing.gapH32,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int completed, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Tasks", style: AppTypography.displaySmall),
            AppSpacing.gapH4,
            Text(
              'Crush your daily movement goals.',
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.radiusPill,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '$completed / $total Done',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(int allCount, int inProgressCount, int doneCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('all', 'All ($allCount)'),
          AppSpacing.gapW8,
          _buildChip('inProgress', 'In Progress ($inProgressCount)'),
          AppSpacing.gapW8,
          _buildChip('completed', 'Completed ($doneCount)'),
        ],
      ),
    );
  }

  Widget _buildChip(String filterKey, String label) {
    final isSelected = _filter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.background : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _filter = filterKey);
      },
    );
  }

  Widget _buildEmptyFilterState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.task_alt_rounded,
              size: 44,
              color: AppColors.textTertiary,
            ),
            AppSpacing.gapH12,
            Text('No tasks in this category', style: AppTypography.titleMedium),
            AppSpacing.gapH4,
            Text(
              'Switch filter tabs to view other habits.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<HabitTask> taskList) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: taskList.length,
      separatorBuilder: (context, index) => AppSpacing.gapH12,
      itemBuilder: (context, index) {
        final task = taskList[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(HabitTask task) {
    final color = task.type.defaultColor;
    final isDone = task.isCompleted;

    return AppCard(
      onTap: () => context.push('/task-detail/${task.id}'),
      borderColor:
          isDone ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
      backgroundColor: isDone
          ? AppColors.primary.withValues(alpha: 0.05)
          : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
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
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : task.type.icon,
                  color: isDone ? AppColors.primary : color,
                  size: 22,
                ),
              ),
              AppSpacing.gapW16,
              // Title & Category
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
                    Text(
                      '${task.type.displayName} • ${task.currentProgress} / ${task.target} ${task.unit}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              // XP Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: AppRadius.radiusPill,
                  border: Border.all(
                    color: isDone ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  '+${task.xpReward} XP',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDone ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
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
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
