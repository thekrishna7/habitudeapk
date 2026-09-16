import '../../data/models/analytics_data_model.dart';

class InsightGenerator {
  static List<AnalyticsInsight> generateInsights(PerformanceAnalytics analytics) {
    final insights = <AnalyticsInsight>[];

    // 1. Task Completion Rate Insight
    if (analytics.totalTasksPlanned > 0) {
      if (analytics.taskCompletionRate >= 80.0) {
        insights.add(
          AnalyticsInsight(
            id: 'high_task_completion',
            title: 'High Habit Consistency',
            description:
                'You completed ${analytics.taskCompletionRate.toStringAsFixed(0)}% of your planned tasks during this period.',
            icon: '🎯',
            category: 'consistency',
          ),
        );
      } else if (analytics.taskCompletionRate >= 50.0) {
        insights.add(
          AnalyticsInsight(
            id: 'moderate_task_completion',
            title: 'Building Momentum',
            description:
                'You completed ${analytics.totalTasksCompleted} of ${analytics.totalTasksPlanned} habits. Consistency is compounding.',
            icon: '📈',
            category: 'consistency',
          ),
        );
      } else {
        insights.add(
          AnalyticsInsight(
            id: 'starting_consistency',
            title: 'Focus on One Habit',
            description:
                'Completing just one small daily habit each morning creates steady progression.',
            icon: '🌱',
            category: 'consistency',
          ),
        );
      }
    }

    // 2. Exercise Progression Insight
    for (final prog in analytics.exerciseProgressions) {
      if (prog.growth > 0) {
        insights.add(
          AnalyticsInsight(
            id: 'prog_${prog.exerciseType.name}',
            title: '${prog.exerciseName} Target Growth',
            description:
                'Your ${prog.exerciseName} target progressed from ${prog.startTarget} to ${prog.currentTarget} ${prog.unit}.',
            icon: '💪',
            category: 'progression',
          ),
        );
        break; // Only include top progression to avoid noise
      }
    }

    // 3. Step Goal Consistency Insight
    if (analytics.stepGoalDaysReached > 0) {
      insights.add(
        AnalyticsInsight(
          id: 'step_goal_insight',
          title: 'Daily Movement Target',
          description:
              'Your step goal was completed on ${analytics.stepGoalDaysReached} of ${analytics.period.days} days (avg ${analytics.averageDailySteps} steps/day).',
          icon: '🚶',
          category: 'steps',
        ),
      );
    }

    // 4. Streak Insight
    if (analytics.currentStreak >= 3) {
      insights.add(
        AnalyticsInsight(
          id: 'active_streak',
          title: '${analytics.currentStreak}-Day Active Streak',
          description:
              'You have maintained activity for ${analytics.currentStreak} consecutive days without interruption.',
          icon: '🔥',
          category: 'consistency',
        ),
      );
    }

    // 5. Workout Sessions Insight
    if (analytics.totalWorkouts > 0) {
      insights.add(
        AnalyticsInsight(
          id: 'workout_consistency',
          title: 'Workout Dedication',
          description:
              'Completed ${analytics.totalWorkouts} workout sessions (${analytics.formattedWorkoutDuration} total training time).',
          icon: '⚡',
          category: 'workouts',
        ),
      );
    }

    // Limit to 2-4 insights maximum
    if (insights.isEmpty) {
      insights.add(
        const AnalyticsInsight(
          id: 'fresh_start',
          title: 'Activity Starting',
          description:
              'Log daily tasks, workouts, and steps to unlock personalized activity insights.',
          icon: '✨',
          category: 'consistency',
        ),
      );
    }

    return insights.take(4).toList();
  }
}
