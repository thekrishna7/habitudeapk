import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/storage_service.dart';
import '../models/achievement_model.dart';
import 'xp_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final xpRepo = ref.watch(xpRepositoryProvider);
  return AchievementRepositoryImpl(prefs, xpRepo);
});

abstract class AchievementRepository {
  Future<List<AchievementProgress>> getAchievementsProgress();
  Future<List<Achievement>> checkAndUnlockAchievements({
    int? completedTasks,
    int? completedWorkouts,
    int? streakDays,
    int? dailySteps,
    int? pushUpReps,
    int? totalXP,
  });
  Future<void> resetAchievements();
}

class AchievementRepositoryImpl implements AchievementRepository {
  static const String _keyUnlockedAchievements = 'habitude_unlocked_achievements';
  static const String _keyValues = 'habitude_achievement_values';

  final SharedPreferences _prefs;
  final XPRepository _xpRepo;

  AchievementRepositoryImpl(this._prefs, this._xpRepo);

  @override
  Future<List<AchievementProgress>> getAchievementsProgress() async {
    final unlockedMap = _getUnlockedMap();
    final valuesMap = _getValuesMap();

    return StandardAchievements.all.map((ach) {
      final isUnlocked = unlockedMap.containsKey(ach.id);
      final unlockedAt = isUnlocked ? DateTime.tryParse(unlockedMap[ach.id]!) : null;
      final val = valuesMap[ach.id] ?? (isUnlocked ? ach.targetValue : 0);

      return AchievementProgress(
        achievement: ach,
        currentValue: val,
        isUnlocked: isUnlocked,
        unlockedAt: unlockedAt,
      );
    }).toList();
  }

  @override
  Future<List<Achievement>> checkAndUnlockAchievements({
    int? completedTasks,
    int? completedWorkouts,
    int? streakDays,
    int? dailySteps,
    int? pushUpReps,
    int? totalXP,
  }) async {
    final unlockedMap = _getUnlockedMap();
    final valuesMap = _getValuesMap();
    final newlyUnlocked = <Achievement>[];

    for (final ach in StandardAchievements.all) {
      if (unlockedMap.containsKey(ach.id)) continue;

      int curVal = valuesMap[ach.id] ?? 0;

      switch (ach.id) {
        case 'first_step':
          if (completedTasks != null && completedTasks > curVal) {
            curVal = completedTasks;
          }
          break;
        case 'first_workout':
          if (completedWorkouts != null && completedWorkouts > curVal) {
            curVal = completedWorkouts;
          }
          break;
        case 'streak_7':
          if (streakDays != null && streakDays > curVal) {
            curVal = streakDays;
          }
          break;
        case 'steps_1000':
          if (dailySteps != null && dailySteps > curVal) {
            curVal = dailySteps;
          }
          break;
        case 'pushups_10':
        case 'pushups_50':
          if (pushUpReps != null && pushUpReps > curVal) {
            curVal = pushUpReps;
          }
          break;
        case 'tasks_100':
          if (completedTasks != null && completedTasks > curVal) {
            curVal = completedTasks;
          }
          break;
        case 'level_5':
          if (totalXP != null) {
            final level = _xpRepo.calculateLevel(totalXP);
            curVal = level;
          }
          break;
      }

      valuesMap[ach.id] = curVal;

      if (curVal >= ach.targetValue) {
        unlockedMap[ach.id] = DateTime.now().toIso8601String();
        newlyUnlocked.add(ach);
      }
    }

    await _prefs.setString(_keyUnlockedAchievements, jsonEncode(unlockedMap));
    await _prefs.setString(_keyValues, jsonEncode(valuesMap));

    return newlyUnlocked;
  }

  Map<String, String> _getUnlockedMap() {
    final raw = _prefs.getString(_keyUnlockedAchievements);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Map<String, int> _getValuesMap() {
    final raw = _prefs.getString(_keyValues);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> resetAchievements() async {
    await _prefs.remove(_keyUnlockedAchievements);
    await _prefs.remove(_keyValues);
  }
}
