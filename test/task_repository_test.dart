import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/services/task_generator_service.dart';
import 'package:habitude/data/datasources/local_task_data_source.dart';
import 'package:habitude/data/models/habit_task_model.dart';
import 'package:habitude/data/models/user_profile_model.dart';
import 'package:habitude/data/repositories/task_repository.dart';
import 'package:habitude/data/repositories/xp_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TaskRepository Tests', () {
    late TaskRepository repository;
    final now = DateTime(2026, 9, 17);
    final profile = UserProfile(
      id: 'test_u',
      name: 'Test Athlete',
      age: 24,
      height: 175,
      weight: 70,
      fitnessLevel: FitnessLevel.beginner,
      primaryGoal: PrimaryGoal.getFit,
      dailyStepGoal: 6000,
      preferredWorkoutDuration: 10,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = LocalTaskDataSourceImpl(prefs);
      final xpRepo = XPRepositoryImpl(prefs);
      const generator = TaskGeneratorService();
      repository = TaskRepositoryImpl(dataSource, generator, xpRepo);
    });

    test('Generates tasks if none exist, persists them and allows toggling',
        () async {
      final tasks = await repository.getOrGenerateTodayTasks(profile);
      expect(tasks, isNotEmpty);

      final firstTask = tasks.first;
      expect(firstTask.status, equals(TaskStatus.notStarted));

      final todayStr = tasks.first.date;

      // Toggle first task to completed
      await repository.toggleTaskStatus(todayStr, firstTask.id);

      final updatedTasks = await repository.getTasksForDate(todayStr);
      final updatedFirst = updatedTasks.firstWhere((t) => t.id == firstTask.id);
      expect(updatedFirst.status, equals(TaskStatus.completed));
      expect(updatedFirst.isCompleted, isTrue);

      // Check daily progress calculation
      final progress = await repository.getDailyProgress(todayStr, 6000);
      expect(progress.totalTasks, equals(tasks.length));
      expect(progress.completedTasks, equals(1));
      expect(progress.totalXpEarned, equals(firstTask.xpReward));
    });
  });
}
