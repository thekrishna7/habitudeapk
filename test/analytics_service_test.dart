import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/data/models/analytics_data_model.dart';
import 'package:habitude/data/models/habit_task_model.dart';
import 'package:habitude/data/models/user_profile_model.dart';
import 'package:habitude/data/repositories/analytics_repository.dart';
import 'package:habitude/data/repositories/streak_repository.dart';
import 'package:habitude/data/repositories/task_repository.dart';
import 'package:habitude/data/repositories/workout_repository.dart';
import 'package:habitude/data/repositories/xp_repository.dart';
import 'package:habitude/features/progress/insight_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:habitude/core/services/task_generator_service.dart';
import 'package:habitude/data/datasources/local_task_data_source.dart';

void main() {
  group('Analytics Repository & Insights Tests', () {
    late SharedPreferences prefs;
    late TaskRepository taskRepo;
    late WorkoutRepository workoutRepo;
    late StreakRepository streakRepo;
    late XPRepository xpRepo;
    late AnalyticsRepository analyticsRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final dataSource = LocalTaskDataSourceImpl(prefs);
      const generator = TaskGeneratorService();
      xpRepo = XPRepositoryImpl(prefs);
      taskRepo = TaskRepositoryImpl(dataSource, generator, xpRepo);
      workoutRepo = WorkoutRepositoryImpl(prefs);
      streakRepo = StreakRepositoryImpl(prefs);

      analyticsRepo = AnalyticsRepositoryImpl(
        prefs: prefs,
        taskRepo: taskRepo,
        workoutRepo: workoutRepo,
        streakRepo: streakRepo,
        xpRepo: xpRepo,
      );
    });

    test('Empty analytics calculates safe zero-rates without division by zero', () async {
      final analytics = await analyticsRepo.getAnalytics(AnalyticsPeriod.days7);

      expect(analytics.period, equals(AnalyticsPeriod.days7));
      expect(analytics.totalTasksPlanned, equals(0));
      expect(analytics.totalTasksCompleted, equals(0));
      expect(analytics.taskCompletionRate, equals(0.0));
      expect(analytics.totalSteps, equals(0));
      expect(analytics.totalWorkouts, equals(0));
      expect(analytics.insights, isNotEmpty);
    });

    test('Aggregates task completion and step totals correctly', () async {
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Generate today's tasks
      await taskRepo.getOrGenerateTodayTasks(
        UserProfile(
          id: 'test_user',
          name: 'Test',
          age: 25,
          height: 175.0,
          weight: 70.0,
          fitnessLevel: FitnessLevel.beginner,
          primaryGoal: PrimaryGoal.buildHealthyHabits,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Complete the first task
      final tasks = await taskRepo.getTasksForDate(todayStr);
      expect(tasks.isNotEmpty, isTrue);
      await taskRepo.updateTaskProgress(todayStr, tasks.first.id, tasks.first.target);

      // Set steps in prefs
      await prefs.setInt('step_count_$todayStr', 7500);
      await prefs.setInt('step_goal_$todayStr', 6000);

      final analytics = await analyticsRepo.getAnalytics(AnalyticsPeriod.days7);

      expect(analytics.totalTasksPlanned, greaterThan(0));
      expect(analytics.totalTasksCompleted, equals(1));
      expect(analytics.totalSteps, equals(7500));
      expect(analytics.stepGoalDaysReached, equals(1));
      expect(analytics.hasEnoughData, isTrue);
    });

    test('InsightGenerator produces factual, rule-based insights', () {
      final analytics = PerformanceAnalytics(
        period: AnalyticsPeriod.days7,
        dailyPoints: const [],
        totalTasksPlanned: 10,
        totalTasksCompleted: 9,
        taskCompletionRate: 90.0,
        totalSteps: 45000,
        averageDailySteps: 6428,
        peakSteps: 9000,
        peakStepDate: '2026-09-16',
        stepGoalDaysReached: 5,
        stepGoalCompletionRate: 71.4,
        totalWorkouts: 3,
        totalWorkoutDurationSeconds: 1800,
        totalExercisesCompleted: 12,
        mostPerformedExercise: 'Push-ups',
        totalXP: 450,
        currentStreak: 5,
        bestStreak: 8,
        exerciseProgressions: const [
          ExerciseProgressionSummary(
            exerciseType: TaskType.pushUps,
            exerciseName: 'Push-ups',
            unit: 'reps',
            targetHistory: [8, 10, 12],
            currentTarget: 12,
            startTarget: 8,
          ),
        ],
        insights: const [],
        hasEnoughData: true,
      );

      final insights = InsightGenerator.generateInsights(analytics);

      expect(insights.length, inInclusiveRange(2, 4));
      expect(insights.any((i) => i.category == 'consistency'), isTrue);
      expect(insights.any((i) => i.category == 'steps'), isTrue);
      expect(insights.any((i) => i.title.contains('Push-ups')), isTrue);
    });
  });
}
