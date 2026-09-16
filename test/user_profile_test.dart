import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/data/models/user_profile_model.dart';

void main() {
  group('UserProfile Model Tests', () {
    final testDate = DateTime(2026, 9, 17, 12, 0);
    final profile = UserProfile(
      id: 'user_test_123',
      name: 'Krishna',
      email: 'krishna@example.com',
      age: 26,
      gender: Gender.male,
      height: 180.0,
      weight: 75.0,
      fitnessLevel: FitnessLevel.intermediate,
      primaryGoal: PrimaryGoal.buildStrength,
      dailyStepGoal: 8000,
      preferredWorkoutDuration: 20,
      createdAt: testDate,
      updatedAt: testDate,
    );

    test('toJson and fromJson correctly serialize and deserialize profile', () {
      final jsonMap = profile.toJson();
      final restored = UserProfile.fromJson(jsonMap);

      expect(restored.id, equals(profile.id));
      expect(restored.name, equals('Krishna'));
      expect(restored.email, equals('krishna@example.com'));
      expect(restored.age, equals(26));
      expect(restored.gender, equals(Gender.male));
      expect(restored.height, equals(180.0));
      expect(restored.weight, equals(75.0));
      expect(restored.fitnessLevel, equals(FitnessLevel.intermediate));
      expect(restored.primaryGoal, equals(PrimaryGoal.buildStrength));
      expect(restored.dailyStepGoal, equals(8000));
      expect(restored.preferredWorkoutDuration, equals(20));
      expect(restored.createdAt, equals(testDate));
    });

    test('copyWith properly updates selective fields', () {
      final updated = profile.copyWith(
        name: 'Krishna Updated',
        fitnessLevel: FitnessLevel.advanced,
        dailyStepGoal: 10000,
      );

      expect(updated.name, equals('Krishna Updated'));
      expect(updated.fitnessLevel, equals(FitnessLevel.advanced));
      expect(updated.dailyStepGoal, equals(10000));
      expect(updated.age, equals(26)); // Unchanged
      expect(updated.height, equals(180.0)); // Unchanged
    });

    test('FitnessLevel and PrimaryGoal parsing with safe fallbacks', () {
      expect(FitnessLevel.fromString('beginner'), equals(FitnessLevel.beginner));
      expect(
          FitnessLevel.fromString('intermediate'), equals(FitnessLevel.intermediate));
      expect(FitnessLevel.fromString('advanced'), equals(FitnessLevel.advanced));
      expect(FitnessLevel.fromString('unknown'), equals(FitnessLevel.beginner));

      expect(PrimaryGoal.fromString('buildStrength'), equals(PrimaryGoal.buildStrength));
      expect(PrimaryGoal.fromString('loseWeight'), equals(PrimaryGoal.loseWeight));
      expect(PrimaryGoal.fromString('unknown'), equals(PrimaryGoal.getFit));
    });
  });
}
