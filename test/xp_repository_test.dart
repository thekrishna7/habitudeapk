import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/data/repositories/xp_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('XPRepository Tests', () {
    late XPRepository xpRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      xpRepo = XPRepositoryImpl(prefs);
    });

    test('Initial XP is 0 with Level 1 Novice title', () async {
      final total = await xpRepo.getTotalXP();
      final level = xpRepo.calculateLevel(total);
      final title = xpRepo.getLevelTitle(level);
      final progress = xpRepo.calculateLevelProgress(total);

      expect(total, equals(0));
      expect(level, equals(1));
      expect(title, equals('Novice'));
      expect(progress, equals(0.0));
    });

    test('Awards XP correctly and updates daily and total stats', () async {
      const dateStr = '2026-09-17';
      final awarded = await xpRepo.awardTaskXP('task_1', 75, dateStr);
      expect(awarded, isTrue);

      expect(await xpRepo.getTotalXP(), equals(75));
      expect(await xpRepo.getDailyXP(dateStr), equals(75));
      expect(await xpRepo.isTaskXPAwarded('task_1'), isTrue);

      // Subsequent attempt for same task ID is rejected
      final duplicate = await xpRepo.awardTaskXP('task_1', 75, dateStr);
      expect(duplicate, isFalse);
      expect(await xpRepo.getTotalXP(), equals(75));
    });

    test('Level calculation scales properly every 500 XP', () async {
      expect(xpRepo.calculateLevel(0), equals(1));
      expect(xpRepo.calculateLevel(499), equals(1));
      expect(xpRepo.calculateLevel(500), equals(2));
      expect(xpRepo.calculateLevel(1200), equals(3));
      expect(xpRepo.calculateLevelProgress(750), equals(0.5)); // 250 / 500
    });
  });
}
