import 'habit_task_model.dart';

enum AnalyticsPeriod {
  days7(7, '7 Days'),
  days30(30, '30 Days'),
  days90(90, '90 Days');

  final int days;
  final String label;
  const AnalyticsPeriod(this.days, this.label);
}

class DailyActivityPoint {
  final String date; // 'yyyy-MM-dd'
  final String dayName; // 'Mon', 'Tue'
  final int tasksCompleted;
  final int totalTasks;
  final int steps;
  final int stepGoal;
  final int workoutDurationSeconds;
  final int xpEarned;

  const DailyActivityPoint({
    required this.date,
    required this.dayName,
    required this.tasksCompleted,
    required this.totalTasks,
    required this.steps,
    required this.stepGoal,
    required this.workoutDurationSeconds,
    required this.xpEarned,
  });

  double get taskCompletionRatio =>
      totalTasks > 0 ? (tasksCompleted / totalTasks).clamp(0.0, 1.0) : 0.0;

  double get stepGoalRatio =>
      stepGoal > 0 ? (steps / stepGoal).clamp(0.0, 1.0) : 0.0;
}

class ExerciseProgressionSummary {
  final TaskType exerciseType;
  final String exerciseName;
  final String unit;
  final List<int> targetHistory;
  final int currentTarget;
  final int startTarget;

  const ExerciseProgressionSummary({
    required this.exerciseType,
    required this.exerciseName,
    required this.unit,
    required this.targetHistory,
    required this.currentTarget,
    required this.startTarget,
  });

  int get growth => currentTarget - startTarget;
}

class AnalyticsInsight {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String category; // 'consistency', 'steps', 'workouts', 'progression'

  const AnalyticsInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
  });
}

class PerformanceAnalytics {
  final AnalyticsPeriod period;
  final List<DailyActivityPoint> dailyPoints;
  final int totalTasksPlanned;
  final int totalTasksCompleted;
  final double taskCompletionRate; // e.g. 85.5%
  final int totalSteps;
  final int averageDailySteps;
  final int peakSteps;
  final String peakStepDate;
  final int stepGoalDaysReached;
  final double stepGoalCompletionRate; // e.g. 71.4%
  final int totalWorkouts;
  final int totalWorkoutDurationSeconds;
  final int totalExercisesCompleted;
  final String mostPerformedExercise;
  final int totalXP;
  final int currentStreak;
  final int bestStreak;
  final List<ExerciseProgressionSummary> exerciseProgressions;
  final List<AnalyticsInsight> insights;
  final bool hasEnoughData;

  const PerformanceAnalytics({
    required this.period,
    required this.dailyPoints,
    required this.totalTasksPlanned,
    required this.totalTasksCompleted,
    required this.taskCompletionRate,
    required this.totalSteps,
    required this.averageDailySteps,
    required this.peakSteps,
    required this.peakStepDate,
    required this.stepGoalDaysReached,
    required this.stepGoalCompletionRate,
    required this.totalWorkouts,
    required this.totalWorkoutDurationSeconds,
    required this.totalExercisesCompleted,
    required this.mostPerformedExercise,
    required this.totalXP,
    required this.currentStreak,
    required this.bestStreak,
    required this.exerciseProgressions,
    required this.insights,
    required this.hasEnoughData,
  });

  String get formattedWorkoutDuration {
    final hours = totalWorkoutDurationSeconds ~/ 3600;
    final minutes = (totalWorkoutDurationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
