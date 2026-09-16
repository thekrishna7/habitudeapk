import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import '../models/habit_task_model.dart';

abstract class LocalTaskDataSource {
  Future<List<HabitTask>> getTasksForDate(String dateStr);
  Future<void> saveTasksForDate(String dateStr, List<HabitTask> tasks);
  Future<void> updateTaskStatus(String dateStr, String taskId, TaskStatus status);
  Future<void> clearAllTasks();
}

class LocalTaskDataSourceImpl implements LocalTaskDataSource {
  static const String _keyPrefix = 'habitude_tasks_';
  final SharedPreferences _prefs;

  LocalTaskDataSourceImpl(this._prefs);

  String _getKey(String dateStr) => '$_keyPrefix$dateStr';

  @override
  Future<List<HabitTask>> getTasksForDate(String dateStr) async {
    try {
      final jsonString = _prefs.getString(_getKey(dateStr));
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => HabitTask.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      AppLogger.error('Failed to parse local tasks for $dateStr', e, st);
      return [];
    }
  }

  @override
  Future<void> saveTasksForDate(String dateStr, List<HabitTask> tasks) async {
    try {
      final jsonString = jsonEncode(tasks.map((t) => t.toJson()).toList());
      await _prefs.setString(_getKey(dateStr), jsonString);
    } catch (e, st) {
      AppLogger.error('Failed to save tasks for $dateStr', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateTaskStatus(
    String dateStr,
    String taskId,
    TaskStatus status,
  ) async {
    final tasks = await getTasksForDate(dateStr);
    final updated = tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(status: status);
      }
      return t;
    }).toList();
    await saveTasksForDate(dateStr, updated);
  }

  @override
  Future<void> clearAllTasks() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
