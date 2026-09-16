import '../../data/models/habit_task_model.dart';
import '../../data/models/user_profile_model.dart';

/// Real Daily Task Engine responsible for generating balanced daily fitness and habit tasks.
class TaskGeneratorService {
  const TaskGeneratorService();

  /// Generates initial habit tasks for a specific date with stable IDs.
  List<HabitTask> generateDailyTasks({
    required UserProfile profile,
    DateTime? forDate,
  }) {
    final effectiveDate = forDate ?? DateTime.now();
    final dateStr = _formatDate(effectiveDate);
    final level = profile.fitnessLevel;
    final goal = profile.primaryGoal;
    final stepGoal = profile.dailyStepGoal;
    final now = DateTime.now();

    final tasks = <HabitTask>[];

    // Task 1: Daily Walk (Step Habit)
    final walkId = 'task_${dateStr}_walk';
    tasks.add(
      HabitTask(
        id: walkId,
        title: 'Daily Walk',
        description: 'Hit your daily step goal to keep your metabolism active.',
        type: TaskType.steps,
        target: stepGoal,
        currentProgress: 0,
        unit: 'steps',
        xpReward: 100,
        status: TaskStatus.notStarted,
        date: dateStr,
        isLocked: false,
        createdAt: now,
      ),
    );

    // Task 2: Push-ups based on level
    final pushUpTarget = switch (level) {
      FitnessLevel.beginner => 5,
      FitnessLevel.intermediate => 10,
      FitnessLevel.advanced => 15,
    };
    final pushUpXp = switch (level) {
      FitnessLevel.beginner => 50,
      FitnessLevel.intermediate => 75,
      FitnessLevel.advanced => 100,
    };
    final pushUpId = 'task_${dateStr}_pushups';
    tasks.add(
      HabitTask(
        id: pushUpId,
        title: '$pushUpTarget Push-ups',
        description: 'Upper body push strength and chest activation.',
        type: TaskType.pushUps,
        target: pushUpTarget,
        currentProgress: 0,
        unit: 'reps',
        xpReward: pushUpXp,
        status: TaskStatus.notStarted,
        date: dateStr,
        isLocked: false,
        createdAt: now,
      ),
    );

    // Task 3: Squats based on level
    final squatTarget = switch (level) {
      FitnessLevel.beginner => 10,
      FitnessLevel.intermediate => 15,
      FitnessLevel.advanced => 20,
    };
    final squatXp = switch (level) {
      FitnessLevel.beginner => 50,
      FitnessLevel.intermediate => 75,
      FitnessLevel.advanced => 100,
    };
    final squatId = 'task_${dateStr}_squats';
    tasks.add(
      HabitTask(
        id: squatId,
        title: '$squatTarget Squats',
        description: 'Lower body power, knee stability, and quad development.',
        type: TaskType.squats,
        target: squatTarget,
        currentProgress: 0,
        unit: 'reps',
        xpReward: squatXp,
        status: TaskStatus.notStarted,
        date: dateStr,
        isLocked: false,
        createdAt: now,
      ),
    );

    // Task 4: Plank (Core stability) - requires push-ups or squats to be completed first
    final plankTarget = switch (level) {
      FitnessLevel.beginner => 30,
      FitnessLevel.intermediate => 45,
      FitnessLevel.advanced => 60,
    };
    final plankXp = switch (level) {
      FitnessLevel.beginner => 40,
      FitnessLevel.intermediate => 60,
      FitnessLevel.advanced => 80,
    };
    final plankId = 'task_${dateStr}_plank';
    tasks.add(
      HabitTask(
        id: plankId,
        title: '$plankTarget sec Plank',
        description: 'Isometric core strength and anti-rotational spinal stability.',
        type: TaskType.plank,
        target: plankTarget,
        currentProgress: 0,
        unit: 'seconds',
        xpReward: plankXp,
        status: TaskStatus.notStarted,
        date: dateStr,
        isLocked: false,
        requiresTaskId: pushUpId,
        createdAt: now,
      ),
    );

    // Task 5: Goal-Specific Habit
    final goalTask = _buildGoalSpecificTask(goal, level, dateStr, plankId, now);
    if (goalTask != null) {
      tasks.add(goalTask);
    }

    return tasks;
  }

  HabitTask? _buildGoalSpecificTask(
    PrimaryGoal goal,
    FitnessLevel level,
    String dateStr,
    String prerequisiteId,
    DateTime now,
  ) {
    switch (goal) {
      case PrimaryGoal.loseWeight:
      case PrimaryGoal.improveEndurance:
        final count = switch (level) {
          FitnessLevel.beginner => 20,
          FitnessLevel.intermediate => 35,
          FitnessLevel.advanced => 50,
        };
        return HabitTask(
          id: 'task_${dateStr}_jacks',
          title: '$count Jumping Jacks',
          description: 'Elevate heart rate and boost metabolic burn.',
          type: TaskType.jumpingJacks,
          target: count,
          currentProgress: 0,
          unit: 'reps',
          xpReward: 50,
          status: TaskStatus.notStarted,
          date: dateStr,
          isLocked: false,
          requiresTaskId: prerequisiteId,
          createdAt: now,
        );
      case PrimaryGoal.buildHealthyHabits:
      case PrimaryGoal.getFit:
      case PrimaryGoal.stayActive:
      case PrimaryGoal.buildStrength:
        return HabitTask(
          id: 'task_${dateStr}_stretch',
          title: '5 min Stretch & Recovery',
          description: 'Post-movement mobility, flexibility, and muscle release.',
          type: TaskType.stretching,
          target: 5,
          currentProgress: 0,
          unit: 'mins',
          xpReward: 40,
          status: TaskStatus.notStarted,
          date: dateStr,
          isLocked: false,
          requiresTaskId: prerequisiteId,
          createdAt: now,
        );
    }
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
