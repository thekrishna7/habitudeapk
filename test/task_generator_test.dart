import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/services/task_generator_service.dart';
import 'package:habitude/data/models/habit_task_model.dart';
import 'package:habitude/data/models/user_profile_model.dart';

void main() {
  group('TaskGeneratorService Tests', () {
    const generator = TaskGeneratorService();
    final now = DateTime(2026, 9, 17);

    test('Generates appropriate beginner tasks', () {
      final beginnerProfile = UserProfile(
        id: 'u1',
        name: 'Beginner Athlete',
        age: 25,
        height: 170,
        weight: 65,
        fitnessLevel: FitnessLevel.beginner,
        primaryGoal: PrimaryGoal.getFit,
        dailyStepGoal: 6000,
        preferredWorkoutDuration: 10,
        createdAt: now,
        updatedAt: now,
      );

      final tasks = generator.generateDailyTasks(
        profile: beginnerProfile,
        forDate: now,
      );

      expect(tasks.length, greaterThanOrEqualTo(4));

      final pushUps = tasks.firstWhere((t) => t.type == TaskType.pushUps);
      expect(pushUps.target, equals(5));
      expect(pushUps.unit, equals('reps'));

      final squats = tasks.firstWhere((t) => t.type == TaskType.squats);
      expect(squats.target, equals(10));

      final plank = tasks.firstWhere((t) => t.type == TaskType.plank);
      expect(plank.target, equals(30));
      expect(plank.unit, equals('seconds'));

      final walk = tasks.firstWhere((t) => t.type == TaskType.steps);
      expect(walk.target, equals(6000));
    });

    test('Generates intermediate and advanced task progression', () {
      final intermediateProfile = UserProfile(
        id: 'u2',
        name: 'Intermediate Athlete',
        age: 28,
        height: 175,
        weight: 72,
        fitnessLevel: FitnessLevel.intermediate,
        primaryGoal: PrimaryGoal.buildStrength,
        dailyStepGoal: 8000,
        preferredWorkoutDuration: 20,
        createdAt: now,
        updatedAt: now,
      );

      final intTasks = generator.generateDailyTasks(
        profile: intermediateProfile,
        forDate: now,
      );

      final intPushUps = intTasks.firstWhere((t) => t.type == TaskType.pushUps);
      expect(intPushUps.target, equals(10));
      expect(intPushUps.xpReward, equals(75));

      final advancedProfile = intermediateProfile.copyWith(
        fitnessLevel: FitnessLevel.advanced,
      );
      final advTasks = generator.generateDailyTasks(
        profile: advancedProfile,
        forDate: now,
      );

      final advPushUps = advTasks.firstWhere((t) => t.type == TaskType.pushUps);
      expect(advPushUps.target, equals(15));
      expect(advPushUps.xpReward, equals(100));

      final advSquats = advTasks.firstWhere((t) => t.type == TaskType.squats);
      expect(advSquats.target, equals(20));

      final advPlank = advTasks.firstWhere((t) => t.type == TaskType.plank);
      expect(advPlank.target, equals(60));
    });

    test('Generates cardio task for weight loss or endurance goal', () {
      final cardioProfile = UserProfile(
        id: 'u3',
        name: 'Cardio Focus',
        age: 30,
        height: 180,
        weight: 85,
        fitnessLevel: FitnessLevel.intermediate,
        primaryGoal: PrimaryGoal.loseWeight,
        dailyStepGoal: 10000,
        preferredWorkoutDuration: 30,
        createdAt: now,
        updatedAt: now,
      );

      final tasks = generator.generateDailyTasks(
        profile: cardioProfile,
        forDate: now,
      );

      final hasJumpingJacks = tasks.any((t) => t.type == TaskType.jumpingJacks);
      expect(hasJumpingJacks, isTrue);
    });
  });
}
