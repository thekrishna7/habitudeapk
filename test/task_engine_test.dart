import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/services/task_generator_service.dart';
import 'package:habitude/data/datasources/local_task_data_source.dart';
import 'package:habitude/data/models/habit_task_model.dart';
import 'package:habitude/data/models/user_profile_model.dart';
import 'package:habitude/data/repositories/task_repository.dart';
import 'package:habitude/data/repositories/xp_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Daily Task Engine & Progress Tests', () {
    late TaskRepository taskRepo;
    late XPRepository xpRepo;
    late SharedPreferences prefs;

    final now = DateTime(2026, 9, 17);
    final userProfile = UserProfile(
      id: 'athlete_1',
      name: 'Rohan',
      age: 26,
      height: 178,
      weight: 72,
      fitnessLevel: FitnessLevel.intermediate,
      primaryGoal: PrimaryGoal.buildStrength,
      dailyStepGoal: 8000,
      preferredWorkoutDuration: 20,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      final taskDataSource = LocalTaskDataSourceImpl(prefs);
      xpRepo = XPRepositoryImpl(prefs);
      const generator = TaskGeneratorService();
      taskRepo = TaskRepositoryImpl(taskDataSource, generator, xpRepo);
    });

    test('Same-day stability: does not regenerate or overwrite existing tasks',
        () async {
      final tasks1 = await taskRepo.getOrGenerateTodayTasks(userProfile);
      expect(tasks1, isNotEmpty);

      // Update progress on first task
      final firstTask = tasks1.first;
      await taskRepo.updateTaskProgress(firstTask.date, firstTask.id, 5);

      // Call getOrGenerateTodayTasks again
      final tasks2 = await taskRepo.getOrGenerateTodayTasks(userProfile);
      final updatedFirst = tasks2.firstWhere((t) => t.id == firstTask.id);

      expect(updatedFirst.currentProgress, equals(5));
      expect(tasks2.length, equals(tasks1.length));
    });

    test('Progress updates cap at target and mark completed when target reached',
        () async {
      final tasks = await taskRepo.getOrGenerateTodayTasks(userProfile);
      final pushUps = tasks.firstWhere((t) => t.type == TaskType.pushUps);
      final target = pushUps.target; // 10 for intermediate

      // Partial progress
      await taskRepo.updateTaskProgress(pushUps.date, pushUps.id, 4);
      var fetched = await taskRepo.getTaskById(pushUps.date, pushUps.id);
      expect(fetched!.currentProgress, equals(4));
      expect(fetched.status, equals(TaskStatus.inProgress));
      expect(fetched.isCompleted, isFalse);

      // Over-target progress (should cap at target)
      final completed =
          await taskRepo.updateTaskProgress(pushUps.date, pushUps.id, target + 10);
      expect(completed, isTrue);

      fetched = await taskRepo.getTaskById(pushUps.date, pushUps.id);
      expect(fetched!.currentProgress, equals(target)); // Capped at target
      expect(fetched.status, equals(TaskStatus.completed));
      expect(fetched.isCompleted, isTrue);
      expect(fetched.completedAt, isNotNull);
    });

    test('Single XP award: awards XP on completion and never duplicates',
        () async {
      final tasks = await taskRepo.getOrGenerateTodayTasks(userProfile);
      final squats = tasks.firstWhere((t) => t.type == TaskType.squats);

      final initialTotalXP = await xpRepo.getTotalXP();
      expect(initialTotalXP, equals(0));

      // Complete squats
      await taskRepo.completeTask(squats.date, squats.id);

      final totalXpAfterComplete = await xpRepo.getTotalXP();
      expect(totalXpAfterComplete, equals(squats.xpReward));

      // Re-updating / saving the same completed task does not duplicate XP
      await taskRepo.updateTaskProgress(
          squats.date, squats.id, squats.target);

      final totalXpAfterResave = await xpRepo.getTotalXP();
      expect(totalXpAfterResave, equals(squats.xpReward)); // Still original XP
    });

    test('DailyProgress calculation reflects actual task completion',
        () async {
      final tasks = await taskRepo.getOrGenerateTodayTasks(userProfile);
      final dateStr = tasks.first.date;

      // Initially 0 completed
      var progress = await taskRepo.getDailyProgress(dateStr, 8000);
      expect(progress.completedTasks, equals(0));
      expect(progress.taskProgress, equals(0.0));

      // Complete 2 tasks
      await taskRepo.completeTask(dateStr, tasks[0].id);
      await taskRepo.completeTask(dateStr, tasks[1].id);

      progress = await taskRepo.getDailyProgress(dateStr, 8000);
      expect(progress.completedTasks, equals(2));
      expect(progress.taskProgress, equals(2 / tasks.length));
    });

    test('Multi-day historical preservation', () async {
      const day1 = '2026-09-16';
      const day2 = '2026-09-17';

      const generator = TaskGeneratorService();
      final day1Tasks = generator.generateDailyTasks(
        profile: userProfile,
        forDate: DateTime(2026, 9, 16),
      );
      await taskRepo.saveTasksForDate(day1, day1Tasks);
      await taskRepo.completeTask(day1, day1Tasks.first.id);

      final day2Tasks = generator.generateDailyTasks(
        profile: userProfile,
        forDate: DateTime(2026, 9, 17),
      );
      await taskRepo.saveTasksForDate(day2, day2Tasks);

      // Verify Day 1 remains completed
      final fetchedDay1 = await taskRepo.getTasksForDate(day1);
      expect(fetchedDay1.first.isCompleted, isTrue);

      // Verify Day 2 starts uncompleted
      final fetchedDay2 = await taskRepo.getTasksForDate(day2);
      expect(fetchedDay2.first.isCompleted, isFalse);
    });
  });
}
