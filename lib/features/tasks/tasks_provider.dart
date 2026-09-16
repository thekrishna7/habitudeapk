import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit_task_model.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/task_repository.dart';
import '../profile/profile_provider.dart';
import '../profile/xp_provider.dart';

final todayTasksNotifierProvider =
    StateNotifierProvider<TodayTasksNotifier, AsyncValue<List<HabitTask>>>((ref) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final profileState = ref.watch(userProfileNotifierProvider);
  final userProfile = profileState.valueOrNull;

  return TodayTasksNotifier(ref, taskRepo, userProfile);
});

class TodayTasksNotifier extends StateNotifier<AsyncValue<List<HabitTask>>> {
  final Ref _ref;
  final TaskRepository _repository;
  final UserProfile? _profile;

  TodayTasksNotifier(this._ref, this._repository, this._profile)
      : super(const AsyncValue.loading()) {
    if (_profile != null) {
      loadTodayTasks();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  String _getTodayDateStr() {
    final dt = DateTime.now();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> loadTodayTasks() async {
    if (_profile == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getOrGenerateTodayTasks(_profile);
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateTaskProgress(String taskId, int progress) async {
    final currentTasks = state.valueOrNull;
    if (currentTasks == null) return false;

    final todayStr = _getTodayDateStr();
    final targetTask = currentTasks.firstWhere((t) => t.id == taskId);
    final clamped = progress.clamp(0, targetTask.target);
    final isDone = clamped >= targetTask.target;

    // Optimistic UI update
    final updated = currentTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(
          currentProgress: clamped,
          status: isDone
              ? TaskStatus.completed
              : (clamped > 0 ? TaskStatus.inProgress : TaskStatus.notStarted),
          completedAt: isDone ? (t.completedAt ?? DateTime.now()) : null,
        );
      }
      return t;
    }).toList();

    state = AsyncValue.data(updated);

    try {
      final justCompleted =
          await _repository.updateTaskProgress(todayStr, taskId, clamped);
      if (justCompleted) {
        // Refresh XP state
        _ref.read(xpNotifierProvider.notifier).refresh();
      }
      return justCompleted;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await loadTodayTasks();
      return false;
    }
  }

  Future<bool> incrementTaskProgress(String taskId, [int amount = 1]) async {
    final currentTasks = state.valueOrNull;
    if (currentTasks == null) return false;

    final targetTask = currentTasks.firstWhere((t) => t.id == taskId);
    final nextProgress = targetTask.currentProgress + amount;
    return updateTaskProgress(taskId, nextProgress);
  }

  Future<bool> completeTask(String taskId) async {
    final currentTasks = state.valueOrNull;
    if (currentTasks == null) return false;

    final targetTask = currentTasks.firstWhere((t) => t.id == taskId);
    return updateTaskProgress(taskId, targetTask.target);
  }

  Future<void> resetTask(String taskId) async {
    await updateTaskProgress(taskId, 0);
  }

  Future<void> toggleTask(String taskId) async {
    final currentTasks = state.valueOrNull;
    if (currentTasks == null) return;

    final targetTask = currentTasks.firstWhere((t) => t.id == taskId);
    if (targetTask.isCompleted) {
      await resetTask(taskId);
    } else {
      await completeTask(taskId);
    }
  }
}
