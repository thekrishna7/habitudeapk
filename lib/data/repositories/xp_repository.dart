import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/storage_service.dart';

final xpRepositoryProvider = Provider<XPRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return XPRepositoryImpl(prefs);
});

abstract class XPRepository {
  Future<int> getTotalXP();
  Future<int> getDailyXP(String dateStr);
  Future<bool> awardTaskXP(String taskId, int xp, String dateStr);
  Future<bool> isTaskXPAwarded(String taskId);
  Future<void> resetXP();
  int calculateLevel(int totalXP);
  double calculateLevelProgress(int totalXP);
  String getLevelTitle(int level);
}

class XPRepositoryImpl implements XPRepository {
  static const String _keyTotalXP = 'habitude_total_xp';
  static const String _keyDailyXPPrefix = 'habitude_daily_xp_';

  final SharedPreferences _prefs;

  XPRepositoryImpl(this._prefs);

  @override
  Future<int> getTotalXP() async {
    return _prefs.getInt(_keyTotalXP) ?? 0;
  }

  @override
  Future<int> getDailyXP(String dateStr) async {
    return _prefs.getInt('$_keyDailyXPPrefix$dateStr') ?? 0;
  }

  @override
  Future<bool> isTaskXPAwarded(String taskId) async {
    final awardedSet =
        _prefs.getStringList('habitude_awarded_task_ids') ?? [];
    return awardedSet.contains(taskId);
  }

  @override
  Future<bool> awardTaskXP(String taskId, int xp, String dateStr) async {
    final awardedList =
        _prefs.getStringList('habitude_awarded_task_ids') ?? [];
    if (awardedList.contains(taskId)) {
      // Already awarded XP for this task, prevent duplicates
      return false;
    }

    awardedList.add(taskId);
    await _prefs.setStringList('habitude_awarded_task_ids', awardedList);

    // Increment total XP
    final currentTotal = await getTotalXP();
    await _prefs.setInt(_keyTotalXP, currentTotal + xp);

    // Increment daily XP
    final currentDaily = await getDailyXP(dateStr);
    await _prefs.setInt('$_keyDailyXPPrefix$dateStr', currentDaily + xp);

    return true;
  }

  @override
  Future<void> resetXP() async {
    await _prefs.remove(_keyTotalXP);
    await _prefs.remove('habitude_awarded_task_ids');
    final keys = _prefs.getKeys().where((k) => k.startsWith(_keyDailyXPPrefix));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  @override
  int calculateLevel(int totalXP) {
    if (totalXP <= 0) return 1;
    return 1 + (totalXP ~/ 500);
  }

  @override
  double calculateLevelProgress(int totalXP) {
    final currentLevelXP = totalXP % 500;
    return (currentLevelXP / 500.0).clamp(0.0, 1.0);
  }

  @override
  String getLevelTitle(int level) {
    if (level <= 1) return 'Novice';
    if (level <= 3) return 'Dedicated Athlete';
    if (level <= 5) return 'Habit Master';
    if (level <= 9) return 'Fitness Warrior';
    return 'Habitude Legend';
  }
}
