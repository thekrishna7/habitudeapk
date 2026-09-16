import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/storage_service.dart';
import '../models/streak_model.dart';

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StreakRepositoryImpl(prefs);
});

abstract class StreakRepository {
  Future<StreakInfo> getStreakInfo([DateTime? relativeTo]);
  Future<StreakInfo> recordActivityCompletion(DateTime date);
  Future<void> resetStreak();
}

class StreakRepositoryImpl implements StreakRepository {
  static const String _keyStreak = 'habitude_streak_data';
  final SharedPreferences _prefs;

  StreakRepositoryImpl(this._prefs);

  @override
  Future<StreakInfo> getStreakInfo([DateTime? relativeTo]) async {
    final raw = _prefs.getString(_keyStreak);
    if (raw == null) {
      return const StreakInfo(currentStreak: 0, bestStreak: 0);
    }
    try {
      final info = StreakInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return _evaluateStreakFreshness(info, relativeTo ?? DateTime.now());
    } catch (_) {
      return const StreakInfo(currentStreak: 0, bestStreak: 0);
    }
  }

  StreakInfo _evaluateStreakFreshness(StreakInfo info, DateTime now) {
    if (info.lastCompletedDate == null) return info;
    final lastDate = DateTime.tryParse(info.lastCompletedDate!);
    if (lastDate == null) return info;

    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final daysDifference = today.difference(lastDay).inDays;

    if (daysDifference > 1) {
      // User missed more than 1 day, streak resets to 0 but best streak preserved
      return info.copyWith(currentStreak: 0);
    }
    return info;
  }

  @override
  Future<StreakInfo> recordActivityCompletion(DateTime date) async {
    final current = await getStreakInfo(date);
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // If already recorded today, do not increment streak count again
    if (current.lastCompletedDate == dateStr) {
      return current;
    }

    int newStreak = 1;
    if (current.lastCompletedDate != null) {
      final last = DateTime.parse(current.lastCompletedDate!);
      final today = DateTime(date.year, date.month, date.day);
      final prevDay = DateTime(last.year, last.month, last.day);
      final diff = today.difference(prevDay).inDays;

      if (diff == 1) {
        newStreak = current.currentStreak + 1;
      } else if (diff == 0) {
        newStreak = current.currentStreak;
      } else {
        newStreak = 1;
      }
    }

    final newBest =
        newStreak > current.bestStreak ? newStreak : current.bestStreak;
    final activeDates = List<String>.from(current.activeDates);
    if (!activeDates.contains(dateStr)) {
      activeDates.add(dateStr);
    }

    final updated = StreakInfo(
      currentStreak: newStreak,
      bestStreak: newBest,
      lastCompletedDate: dateStr,
      activeDates: activeDates,
    );

    await _prefs.setString(_keyStreak, jsonEncode(updated.toJson()));
    return updated;
  }

  @override
  Future<void> resetStreak() async {
    await _prefs.remove(_keyStreak);
  }
}
