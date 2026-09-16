import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/xp_repository.dart';

class XPState {
  final int totalXP;
  final int dailyXP;
  final int level;
  final double levelProgress;
  final String levelTitle;

  const XPState({
    required this.totalXP,
    required this.dailyXP,
    required this.level,
    required this.levelProgress,
    required this.levelTitle,
  });

  const XPState.initial()
      : totalXP = 0,
        dailyXP = 0,
        level = 1,
        levelProgress = 0.0,
        levelTitle = 'Novice';
}

final xpNotifierProvider =
    StateNotifierProvider<XPNotifier, AsyncValue<XPState>>((ref) {
  final xpRepo = ref.watch(xpRepositoryProvider);
  return XPNotifier(xpRepo);
});

class XPNotifier extends StateNotifier<AsyncValue<XPState>> {
  final XPRepository _xpRepository;

  XPNotifier(this._xpRepository) : super(const AsyncValue.loading()) {
    loadXP();
  }

  String _getTodayDateStr() {
    final dt = DateTime.now();
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> loadXP() async {
    try {
      final todayStr = _getTodayDateStr();
      final total = await _xpRepository.getTotalXP();
      final daily = await _xpRepository.getDailyXP(todayStr);
      final level = _xpRepository.calculateLevel(total);
      final progress = _xpRepository.calculateLevelProgress(total);
      final title = _xpRepository.getLevelTitle(level);

      state = AsyncValue.data(
        XPState(
          totalXP: total,
          dailyXP: daily,
          level: level,
          levelProgress: progress,
          levelTitle: title,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadXP();
}
