/// Summary model for a day's habits, steps, and XP progress.
class DailyProgress {
  final String date; // 'YYYY-MM-DD'
  final int totalTasks;
  final int completedTasks;
  final int totalSteps;
  final int stepGoal;
  final int totalXpEarned;

  const DailyProgress({
    required this.date,
    required this.totalTasks,
    required this.completedTasks,
    this.totalSteps = 0,
    required this.stepGoal,
    required this.totalXpEarned,
  });

  double get taskProgress =>
      totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;

  double get stepProgress =>
      stepGoal > 0 ? (totalSteps / stepGoal).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'totalSteps': totalSteps,
      'stepGoal': stepGoal,
      'totalXpEarned': totalXpEarned,
    };
  }

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: json['date'] as String,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      totalSteps: (json['totalSteps'] as num?)?.toInt() ?? 0,
      stepGoal: (json['stepGoal'] as num?)?.toInt() ?? 6000,
      totalXpEarned: (json['totalXpEarned'] as num?)?.toInt() ?? 0,
    );
  }
}
