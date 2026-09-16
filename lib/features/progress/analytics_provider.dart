import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/analytics_data_model.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/analytics_repository.dart';

final selectedPeriodProvider = StateProvider<AnalyticsPeriod>((ref) {
  return AnalyticsPeriod.days7;
});

final analyticsFutureProvider =
    FutureProvider.family<PerformanceAnalytics, AnalyticsPeriod>((ref, period) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getAnalytics(period);
});

final achievementsListProvider =
    FutureProvider<List<AchievementProgress>>((ref) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getAchievementsProgress();
});
