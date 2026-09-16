import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/task_generator_service.dart';
import '../datasources/local_task_data_source.dart';
import '../models/daily_progress_model.dart';
import '../models/habit_task_model.dart';
import '../models/user_profile_model.dart';
import 'xp_repository.dart';

final localTaskDataSourceProvider = Provider<LocalTaskDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalTaskDataSourceImpl(prefs);
});

final taskGeneratorServiceProvider = Provider<TaskGeneratorService>((ref) {
  return const TaskGeneratorService();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dataSource = ref.watch(localTaskDataSourceProvider);
  final generator = ref.watch(taskGeneratorServiceProvider);
  final xpRepo = ref.watch(xpRepositoryProvider);
  return TaskRepositoryImpl(dataSource, generator, xpRepo);
});

abstract class TaskRepository {
  Future<List<HabitTask>> getOrGenerateTodayTasks(UserProfile profile);
  Future<List<HabitTask>> getTasksForDate(String dateStr);
  Future<HabitTask?> getTaskById(String dateStr, String taskId);
  Future<void> saveTasksForDate(String dateStr, List<HabitTask> tasks);
  Future<bool> updateTaskProgress(String dateStr, String taskId, int progress);
  Future<bool> completeTask(String dateStr, String taskId);
  Future<void> resetTaskProgress(String dateStr, String taskId);
  Future<void> toggleTaskStatus(String dateStr, String taskId);
  Future<DailyProgress> getDailyProgress(String dateStr, int stepGoal);
}

class TaskRepositoryImpl implements TaskRepository {
  final LocalTaskDataSource _dataSource;
  final TaskGeneratorService _generator;
  final XPRepository _xpRepository;

  TaskRepositoryImpl(this._dataSource, this._generator, this._xpRepository);

  String _getTodayDateStr() {
    final dt = DateTime.now();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<List<HabitTask>> getOrGenerateTodayTasks(UserProfile profile) async {
    final todayStr = _getTodayDateStr();
    final existing = await _dataSource.getTasksForDate(todayStr);
    if (existing.isNotEmpty) {
      return existing;
    }

    // Generate fresh daily tasks for today
    final generated = _generator.generateDailyTasks(profile: profile);
    await _dataSource.saveTasksForDate(todayStr, generated);
    return generated;
  }

  @override
  Future<List<HabitTask>> getTasksForDate(String dateStr) {
    return _dataSource.getTasksForDate(dateStr);
  }

  @override
  Future<HabitTask?> getTaskById(String dateStr, String taskId) async {
    final tasks = await _dataSource.getTasksForDate(dateStr);
    try {
      return tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTasksForDate(String dateStr, List<HabitTask> tasks) {
    return _dataSource.saveTasksForDate(dateStr, tasks);
  }

  @override
  Future<bool> updateTaskProgress(
    String dateStr,
    String taskId,
    int progress,
  ) async {
    final tasks = await _dataSource.getTasksForDate(dateStr);
    bool justCompleted = false;

    final updated = tasks.map((t) {
      if (t.id == taskId) {
        final clamped = progress.clamp(0, t.target);
        final isCompletedNow = clamped >= t.target;
        final status = isCompletedNow
            ? TaskStatus.completed
            : (clamped > 0 ? TaskStatus.inProgress : TaskStatus.notStarted);

        if (isCompletedNow && !t.isCompleted) {
          justCompleted = true;
        }

        return t.copyWith(
          currentProgress: clamped,
          status: status,
          completedAt: isCompletedNow ? (t.completedAt ?? DateTime.now()) : null,
        );
      }
      return t;
    }).toList();

    await _dataSource.saveTasksForDate(dateStr, updated);

    if (justCompleted) {
      final task = updated.firstWhere((t) => t.id == taskId);
      await _xpRepository.awardTaskXP(task.id, task.xpReward, dateStr);
    }

    return justCompleted;
  }

  @override
  Future<bool> completeTask(String dateStr, String taskId) async {
    final tasks = await _dataSource.getTasksForDate(dateStr);
    final targetTask = tasks.firstWhere((t) => t.id == taskId);
    return updateTaskProgress(dateStr, taskId, targetTask.target);
  }

  @override
  Future<void> resetTaskProgress(String dateStr, String taskId) async {
    await updateTaskProgress(dateStr, taskId, 0);
  }

  @override
  Future<void> toggleTaskStatus(String dateStr, String taskId) async {
    final task = await getTaskById(dateStr, taskId);
    if (task == null) return;

    if (task.isCompleted) {
      await resetTaskProgress(dateStr, taskId);
    } else {
      await completeTask(dateStr, taskId);
    }
  }

  @override
  Future<DailyProgress> getDailyProgress(String dateStr, int stepGoal) async {
    final tasks = await _dataSource.getTasksForDate(dateStr);
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final dailyXP = await _xpRepository.getDailyXP(dateStr);

    return DailyProgress(
      date: dateStr,
      totalTasks: total,
      completedTasks: completed,
      totalSteps: 0,
      stepGoal: stepGoal,
      totalXpEarned: dailyXP,
    );
  }
}
