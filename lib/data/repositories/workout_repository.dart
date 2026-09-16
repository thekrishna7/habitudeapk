import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/storage_service.dart';
import '../models/habit_task_model.dart';
import '../models/workout_session_model.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WorkoutRepositoryImpl(prefs);
});

abstract class WorkoutRepository {
  List<Workout> getPredefinedWorkouts();
  Future<List<WorkoutSession>> getAllSessions();
  Future<List<WorkoutSession>> getSessionsForDateRange(DateTime start, DateTime end);
  Future<void> saveSession(WorkoutSession session);
  Future<WorkoutSession?> getActiveSession();
  Future<void> saveActiveSession(WorkoutSession? session);
  Future<void> clearAllSessions();
}

class WorkoutRepositoryImpl implements WorkoutRepository {
  static const String _keySessions = 'habitude_workout_sessions';
  static const String _keyActiveSession = 'habitude_active_workout_session';

  final SharedPreferences _prefs;

  WorkoutRepositoryImpl(this._prefs);

  @override
  List<Workout> getPredefinedWorkouts() {
    return const [
      Workout(
        id: 'quick_morning',
        name: 'Morning Energy',
        description: 'Wake up your body with an invigorating 4-exercise full body blast.',
        difficulty: 'Beginner',
        estimatedDurationMinutes: 8,
        totalXP: 150,
        exercises: [
          WorkoutExercise(
            id: 'we_pushups_1',
            exerciseType: TaskType.pushUps,
            name: 'Push-ups',
            target: 10,
            unit: 'reps',
            restDurationSeconds: 15,
            xpReward: 35,
            order: 1,
          ),
          WorkoutExercise(
            id: 'we_squats_1',
            exerciseType: TaskType.squats,
            name: 'Squats',
            target: 15,
            unit: 'reps',
            restDurationSeconds: 15,
            xpReward: 35,
            order: 2,
          ),
          WorkoutExercise(
            id: 'we_plank_1',
            exerciseType: TaskType.plank,
            name: 'Plank',
            target: 30,
            unit: 'sec',
            restDurationSeconds: 15,
            xpReward: 40,
            order: 3,
          ),
          WorkoutExercise(
            id: 'we_jacks_1',
            exerciseType: TaskType.jumpingJacks,
            name: 'Jumping Jacks',
            target: 20,
            unit: 'reps',
            restDurationSeconds: 0,
            xpReward: 40,
            order: 4,
          ),
        ],
      ),
      Workout(
        id: 'strength_starter',
        name: 'Strength Starter',
        description: 'Build foundational pushing and lower body power.',
        difficulty: 'Intermediate',
        estimatedDurationMinutes: 10,
        totalXP: 180,
        exercises: [
          WorkoutExercise(
            id: 'we_pushups_2',
            exerciseType: TaskType.pushUps,
            name: 'Push-ups',
            target: 15,
            unit: 'reps',
            restDurationSeconds: 20,
            xpReward: 50,
            order: 1,
          ),
          WorkoutExercise(
            id: 'we_squats_2',
            exerciseType: TaskType.squats,
            name: 'Squats',
            target: 20,
            unit: 'reps',
            restDurationSeconds: 20,
            xpReward: 50,
            order: 2,
          ),
          WorkoutExercise(
            id: 'we_plank_2',
            exerciseType: TaskType.plank,
            name: 'Core Plank',
            target: 45,
            unit: 'sec',
            restDurationSeconds: 0,
            xpReward: 80,
            order: 3,
          ),
        ],
      ),
      Workout(
        id: 'core_focus',
        name: 'Core & Stability',
        description: 'Target abdominal endurance and posture stability.',
        difficulty: 'All Levels',
        estimatedDurationMinutes: 6,
        totalXP: 120,
        exercises: [
          WorkoutExercise(
            id: 'we_plank_3',
            exerciseType: TaskType.plank,
            name: 'Forearm Plank',
            target: 40,
            unit: 'sec',
            restDurationSeconds: 20,
            xpReward: 60,
            order: 1,
          ),
          WorkoutExercise(
            id: 'we_jacks_3',
            exerciseType: TaskType.jumpingJacks,
            name: 'Cardio Bursts',
            target: 25,
            unit: 'reps',
            restDurationSeconds: 0,
            xpReward: 60,
            order: 2,
          ),
        ],
      ),
    ];
  }

  @override
  Future<List<WorkoutSession>> getAllSessions() async {
    final rawList = _prefs.getStringList(_keySessions) ?? [];
    return rawList
        .map((e) => WorkoutSession.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WorkoutSession>> getSessionsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllSessions();
    return all.where((s) {
      return s.startedAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          s.startedAt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  @override
  Future<void> saveSession(WorkoutSession session) async {
    final all = await getAllSessions();
    final index = all.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      all[index] = session;
    } else {
      all.add(session);
    }
    final rawList = all.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_keySessions, rawList);
  }

  @override
  Future<WorkoutSession?> getActiveSession() async {
    final raw = _prefs.getString(_keyActiveSession);
    if (raw == null) return null;
    return WorkoutSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveActiveSession(WorkoutSession? session) async {
    if (session == null) {
      await _prefs.remove(_keyActiveSession);
    } else {
      await _prefs.setString(_keyActiveSession, jsonEncode(session.toJson()));
    }
  }

  @override
  Future<void> clearAllSessions() async {
    await _prefs.remove(_keySessions);
    await _prefs.remove(_keyActiveSession);
  }
}
