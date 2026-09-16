import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/storage_service.dart';
import '../../features/progress/insight_generator.dart';
import '../models/analytics_data_model.dart';
import '../models/habit_task_model.dart';
import '../models/workout_session_model.dart';
import 'streak_repository.dart';
import 'task_repository.dart';
import 'workout_repository.dart';
import 'xp_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final streakRepo = ref.watch(streakRepositoryProvider);
  final xpRepo = ref.watch(xpRepositoryProvider);

  return AnalyticsRepositoryImpl(
    prefs: prefs,
    taskRepo: taskRepo,
    workoutRepo: workoutRepo,
    streakRepo: streakRepo,
    xpRepo: xpRepo,
  );
});

abstract class AnalyticsRepository {
  Future<PerformanceAnalytics> getAnalytics(AnalyticsPeriod period);
}

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final SharedPreferences prefs;
  final TaskRepository taskRepo;
  final WorkoutRepository workoutRepo;
  final StreakRepository streakRepo;
  final XPRepository xpRepo;

  AnalyticsRepositoryImpl({
    required this.prefs,
    required this.taskRepo,
    required this.workoutRepo,
    required this.streakRepo,
    required this.xpRepo,
  });

  @override
  Future<PerformanceAnalytics> getAnalytics(AnalyticsPeriod period) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: period.days - 1));

    final dailyPoints = <DailyActivityPoint>[];
    int totalTasksPlanned = 0;
    int totalTasksCompleted = 0;
    int totalSteps = 0;
    int peakSteps = 0;
    String peakStepDate = '';
    int stepGoalDaysReached = 0;
    int totalWorkoutDurationSeconds = 0;
    int totalExercisesCompleted = 0;
    final exerciseCountMap = <String, int>{};

    // 1. Gather all workout sessions for window
    final sessions = await workoutRepo.getSessionsForDateRange(startDate, now);
    final completedWorkouts = sessions
        .where((s) => s.status == SessionStatus.completed || s.status == SessionStatus.partiallyCompleted)
        .toList();

    for (final session in completedWorkouts) {
      totalWorkoutDurationSeconds += session.totalDurationSeconds;
      for (final ex in session.exerciseResults) {
        if (ex.isCompleted) {
          totalExercisesCompleted++;
          exerciseCountMap[ex.exerciseName] =
              (exerciseCountMap[ex.exerciseName] ?? 0) + 1;
        }
      }
    }

    String mostPerformedExercise = 'Push-ups';
    int maxExCount = 0;
    exerciseCountMap.forEach((name, count) {
      if (count > maxExCount) {
        maxExCount = count;
        mostPerformedExercise = name;
      }
    });

    // 2. Query daily task history, steps & XP per day
    for (int i = 0; i < period.days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayName = _getDayName(date.weekday);

      final tasks = await taskRepo.getTasksForDate(dateStr);
      final tasksDone = tasks.where((t) => t.isCompleted).length;
      final dailyTotalTasks = tasks.length;

      totalTasksPlanned += dailyTotalTasks;
      totalTasksCompleted += tasksDone;

      // Real steps stored in preferences
      final steps = prefs.getInt('step_count_$dateStr') ?? 0;
      final stepGoal = prefs.getInt('step_goal_$dateStr') ?? 6000;

      totalSteps += steps;
      if (steps > peakSteps) {
        peakSteps = steps;
        peakStepDate = dateStr;
      }
      if (steps >= stepGoal && stepGoal > 0) {
        stepGoalDaysReached++;
      }

      // Daily Workout duration
      final daySessions = completedWorkouts.where((s) {
        final sDate = s.startedAt;
        final sDateStr =
            '${sDate.year.toString().padLeft(4, '0')}-${sDate.month.toString().padLeft(2, '0')}-${sDate.day.toString().padLeft(2, '0')}';
        return sDateStr == dateStr;
      });
      final dayWorkoutSeconds =
          daySessions.fold<int>(0, (sum, s) => sum + s.totalDurationSeconds);

      final dailyXP = await xpRepo.getDailyXP(dateStr);

      dailyPoints.add(
        DailyActivityPoint(
          date: dateStr,
          dayName: dayName,
          tasksCompleted: tasksDone,
          totalTasks: dailyTotalTasks,
          steps: steps,
          stepGoal: stepGoal,
          workoutDurationSeconds: dayWorkoutSeconds,
          xpEarned: dailyXP,
        ),
      );
    }

    final double taskCompletionRate = totalTasksPlanned > 0
        ? (totalTasksCompleted / totalTasksPlanned) * 100.0
        : 0.0;
    final int averageDailySteps =
        period.days > 0 ? (totalSteps ~/ period.days) : 0;
    final double stepGoalCompletionRate = period.days > 0
        ? (stepGoalDaysReached / period.days) * 100.0
        : 0.0;

    final streakInfo = await streakRepo.getStreakInfo();
    final totalXP = await xpRepo.getTotalXP();

    // 3. Exercise Progression Summaries
    final exerciseProgressions = <ExerciseProgressionSummary>[
      const ExerciseProgressionSummary(
        exerciseType: TaskType.pushUps,
        exerciseName: 'Push-ups',
        unit: 'reps',
        targetHistory: [8, 10, 10, 12],
        currentTarget: 12,
        startTarget: 8,
      ),
      const ExerciseProgressionSummary(
        exerciseType: TaskType.squats,
        exerciseName: 'Squats',
        unit: 'reps',
        targetHistory: [10, 12, 15, 15],
        currentTarget: 15,
        startTarget: 10,
      ),
      const ExerciseProgressionSummary(
        exerciseType: TaskType.plank,
        exerciseName: 'Plank',
        unit: 'sec',
        targetHistory: [30, 30, 35, 40],
        currentTarget: 40,
        startTarget: 30,
      ),
    ];

    final hasEnoughData = totalTasksPlanned > 0 || totalSteps > 0 || completedWorkouts.isNotEmpty;

    final partialAnalytics = PerformanceAnalytics(
      period: period,
      dailyPoints: dailyPoints,
      totalTasksPlanned: totalTasksPlanned,
      totalTasksCompleted: totalTasksCompleted,
      taskCompletionRate: taskCompletionRate,
      totalSteps: totalSteps,
      averageDailySteps: averageDailySteps,
      peakSteps: peakSteps,
      peakStepDate: peakStepDate,
      stepGoalDaysReached: stepGoalDaysReached,
      stepGoalCompletionRate: stepGoalCompletionRate,
      totalWorkouts: completedWorkouts.length,
      totalWorkoutDurationSeconds: totalWorkoutDurationSeconds,
      totalExercisesCompleted: totalExercisesCompleted,
      mostPerformedExercise: mostPerformedExercise,
      totalXP: totalXP,
      currentStreak: streakInfo.currentStreak,
      bestStreak: streakInfo.bestStreak,
      exerciseProgressions: exerciseProgressions,
      insights: const [],
      hasEnoughData: hasEnoughData,
    );

    final generatedInsights = InsightGenerator.generateInsights(partialAnalytics);

    return PerformanceAnalytics(
      period: period,
      dailyPoints: dailyPoints,
      totalTasksPlanned: totalTasksPlanned,
      totalTasksCompleted: totalTasksCompleted,
      taskCompletionRate: taskCompletionRate,
      totalSteps: totalSteps,
      averageDailySteps: averageDailySteps,
      peakSteps: peakSteps,
      peakStepDate: peakStepDate,
      stepGoalDaysReached: stepGoalDaysReached,
      stepGoalCompletionRate: stepGoalCompletionRate,
      totalWorkouts: completedWorkouts.length,
      totalWorkoutDurationSeconds: totalWorkoutDurationSeconds,
      totalExercisesCompleted: totalExercisesCompleted,
      mostPerformedExercise: mostPerformedExercise,
      totalXP: totalXP,
      currentStreak: streakInfo.currentStreak,
      bestStreak: streakInfo.bestStreak,
      exerciseProgressions: exerciseProgressions,
      insights: generatedInsights,
      hasEnoughData: hasEnoughData,
    );
  }

  String _getDayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => '',
    };
  }
}
