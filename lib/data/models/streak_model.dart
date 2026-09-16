class StreakInfo {
  final int currentStreak;
  final int bestStreak;
  final String? lastCompletedDate; // 'yyyy-MM-dd'
  final List<String> activeDates;

  const StreakInfo({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedDate,
    this.activeDates = const [],
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastCompletedDate': lastCompletedDate,
        'activeDates': activeDates,
      };

  factory StreakInfo.fromJson(Map<String, dynamic> json) => StreakInfo(
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
        lastCompletedDate: json['lastCompletedDate'] as String?,
        activeDates: (json['activeDates'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  StreakInfo copyWith({
    int? currentStreak,
    int? bestStreak,
    String? lastCompletedDate,
    List<String>? activeDates,
  }) {
    return StreakInfo(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      activeDates: activeDates ?? this.activeDates,
    );
  }
}
