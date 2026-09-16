import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/data/repositories/achievement_repository.dart';
import 'package:habitude/data/repositories/xp_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Achievement Repository Tests', () {
    late SharedPreferences prefs;
    late XPRepository xpRepo;
    late AchievementRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      xpRepo = XPRepositoryImpl(prefs);
      repo = AchievementRepositoryImpl(prefs, xpRepo);
    });

    test('Initial achievements are all locked', () async {
      final list = await repo.getAchievementsProgress();
      expect(list.isNotEmpty, isTrue);
      expect(list.every((a) => !a.isUnlocked), isTrue);
    });

    test('Reaching target unlocks achievement and awards reward', () async {
      final unlocked = await repo.checkAndUnlockAchievements(completedTasks: 1);
      expect(unlocked.any((a) => a.id == 'first_step'), isTrue);

      final list = await repo.getAchievementsProgress();
      final firstStep = list.firstWhere((a) => a.achievement.id == 'first_step');
      expect(firstStep.isUnlocked, isTrue);
      expect(firstStep.unlockedAt, isNotNull);
    });

    test('Already unlocked achievements do not re-unlock', () async {
      await repo.checkAndUnlockAchievements(completedTasks: 1);
      final unlockedAgain =
          await repo.checkAndUnlockAchievements(completedTasks: 1);
      expect(unlockedAgain.isEmpty, isTrue);
    });
  });
}
