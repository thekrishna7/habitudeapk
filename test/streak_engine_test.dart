import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/data/repositories/streak_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Streak Engine Tests', () {
    late SharedPreferences prefs;
    late StreakRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = StreakRepositoryImpl(prefs);
    });

    test('Initial streak is 0', () async {
      final info = await repo.getStreakInfo();
      expect(info.currentStreak, equals(0));
      expect(info.bestStreak, equals(0));
    });

    test('Single completion sets streak to 1', () async {
      final d1 = DateTime(2026, 9, 15);
      final info = await repo.recordActivityCompletion(d1);

      expect(info.currentStreak, equals(1));
      expect(info.bestStreak, equals(1));
    });

    test('Multiple completions on same day do not duplicate streak increment', () async {
      final d1 = DateTime(2026, 9, 15);
      await repo.recordActivityCompletion(d1);
      final info2 = await repo.recordActivityCompletion(d1);

      expect(info2.currentStreak, equals(1));
      expect(info2.bestStreak, equals(1));
    });

    test('Consecutive day completion increases streak', () async {
      final d1 = DateTime(2026, 9, 15);
      final d2 = DateTime(2026, 9, 16);
      final d3 = DateTime(2026, 9, 17);

      await repo.recordActivityCompletion(d1);
      await repo.recordActivityCompletion(d2);
      final info = await repo.recordActivityCompletion(d3);

      expect(info.currentStreak, equals(3));
      expect(info.bestStreak, equals(3));
    });

    test('Missed day resets current streak but preserves best streak', () async {
      final d1 = DateTime(2026, 9, 10);
      final d2 = DateTime(2026, 9, 11);
      final dGap = DateTime(2026, 9, 15); // 4 days later

      await repo.recordActivityCompletion(d1);
      await repo.recordActivityCompletion(d2);
      final info = await repo.recordActivityCompletion(dGap);

      expect(info.currentStreak, equals(1));
      expect(info.bestStreak, equals(2));
    });
  });
}
