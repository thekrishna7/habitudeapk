import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/data/datasources/local_user_data_source.dart';
import 'package:habitude/data/models/user_profile_model.dart';
import 'package:habitude/data/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserRepository Tests', () {
    late UserRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dataSource = LocalUserDataSourceImpl(prefs);
      repository = UserRepositoryImpl(dataSource);
    });

    test('Returns null when no user profile exists', () async {
      final profile = await repository.getUserProfile();
      expect(profile, isNull);
    });

    test('Saves, retrieves, and deletes user profile correctly', () async {
      final now = DateTime(2026, 9, 17);
      final profile = UserProfile(
        id: 'user_local_1',
        name: 'Alex Hunter',
        age: 27,
        height: 178,
        weight: 73,
        fitnessLevel: FitnessLevel.intermediate,
        primaryGoal: PrimaryGoal.buildStrength,
        dailyStepGoal: 8000,
        preferredWorkoutDuration: 20,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveUserProfile(profile);

      final retrieved = await repository.getUserProfile();
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Alex Hunter'));
      expect(retrieved.dailyStepGoal, equals(8000));

      await repository.deleteUserProfile();
      final afterDelete = await repository.getUserProfile();
      expect(afterDelete, isNull);
    });
  });
}
