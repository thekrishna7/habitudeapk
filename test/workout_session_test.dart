import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/data/models/habit_task_model.dart';
import 'package:habitude/data/models/workout_session_model.dart';
import 'package:habitude/data/repositories/workout_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Workout Repository & Session Tests', () {
    late SharedPreferences prefs;
    late WorkoutRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = WorkoutRepositoryImpl(prefs);
    });

    test('Provides structured predefined workouts', () {
      final workouts = repo.getPredefinedWorkouts();
      expect(workouts.length, greaterThanOrEqualTo(3));
      expect(workouts.first.exercises.length, equals(4));
    });

    test('Saves, retrieves and filters workout sessions by date range', () async {
      final now = DateTime(2026, 9, 17, 10, 0, 0);

      final session1 = WorkoutSession(
        id: 'sess_1',
        workoutId: 'quick_morning',
        workoutName: 'Morning Energy',
        startedAt: DateTime(2026, 9, 15, 8, 0, 0),
        totalDurationSeconds: 480,
        earnedXP: 150,
        status: SessionStatus.completed,
        exerciseResults: const [
          ExerciseResult(
            exerciseId: 'we_pushups_1',
            exerciseType: TaskType.pushUps,
            exerciseName: 'Push-ups',
            target: 10,
            completed: 10,
            unit: 'reps',
            durationSeconds: 60,
            earnedXP: 35,
            isCompleted: true,
          ),
        ],
      );

      final session2 = WorkoutSession(
        id: 'sess_2',
        workoutId: 'strength_starter',
        workoutName: 'Strength Starter',
        startedAt: DateTime(2026, 9, 17, 9, 0, 0),
        totalDurationSeconds: 600,
        earnedXP: 180,
        status: SessionStatus.completed,
      );

      await repo.saveSession(session1);
      await repo.saveSession(session2);

      final all = await repo.getAllSessions();
      expect(all.length, equals(2));

      final range = await repo.getSessionsForDateRange(
        DateTime(2026, 9, 16, 0, 0, 0),
        now,
      );
      expect(range.length, equals(1));
      expect(range.first.id, equals('sess_2'));
    });
  });
}
