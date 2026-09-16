class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int targetValue;
  final String category; // 'tasks', 'workouts', 'steps', 'streak', 'xp', 'exercises'
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    required this.category,
    this.xpReward = 50,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'targetValue': targetValue,
        'category': category,
        'xpReward': xpReward,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        targetValue: json['targetValue'] as int,
        category: json['category'] as String,
        xpReward: json['xpReward'] as int? ?? 50,
      );
}

class AchievementProgress {
  final Achievement achievement;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.achievement,
    required this.currentValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  double get progressPercentage =>
      achievement.targetValue > 0
          ? (currentValue / achievement.targetValue).clamp(0.0, 1.0)
          : 0.0;

  Map<String, dynamic> toJson() => {
        'achievement': achievement.toJson(),
        'currentValue': currentValue,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        achievement:
            Achievement.fromJson(json['achievement'] as Map<String, dynamic>),
        currentValue: json['currentValue'] as int? ?? 0,
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'] as String)
            : null,
      );
}

class StandardAchievements {
  static const List<Achievement> all = [
    Achievement(
      id: 'first_step',
      title: 'First Step',
      description: 'Complete your first habit task.',
      icon: '🎯',
      targetValue: 1,
      category: 'tasks',
      xpReward: 50,
    ),
    Achievement(
      id: 'first_workout',
      title: 'First Workout',
      description: 'Complete your first structured AI workout session.',
      icon: '⚡',
      targetValue: 1,
      category: 'workouts',
      xpReward: 75,
    ),
    Achievement(
      id: 'streak_7',
      title: '7 Day Streak',
      description: 'Maintain a 7-day active daily streak.',
      icon: '🔥',
      targetValue: 7,
      category: 'streak',
      xpReward: 150,
    ),
    Achievement(
      id: 'steps_1000',
      title: '1,000 Steps',
      description: 'Reach 1,000 steps in a single day.',
      icon: '🚶',
      targetValue: 1000,
      category: 'steps',
      xpReward: 50,
    ),
    Achievement(
      id: 'pushups_10',
      title: '10 Push-ups',
      description: 'Complete 10 valid camera-verified push-ups.',
      icon: '💪',
      targetValue: 10,
      category: 'exercises',
      xpReward: 50,
    ),
    Achievement(
      id: 'pushups_50',
      title: '50 Push-ups',
      description: 'Complete 50 valid push-ups across all sessions.',
      icon: '🏆',
      targetValue: 50,
      category: 'exercises',
      xpReward: 150,
    ),
    Achievement(
      id: 'tasks_100',
      title: 'Centurion',
      description: 'Complete 100 daily tasks.',
      icon: '🌟',
      targetValue: 100,
      category: 'tasks',
      xpReward: 300,
    ),
    Achievement(
      id: 'level_5',
      title: 'Level 5 Athlete',
      description: 'Reach Level 5 progression tier.',
      icon: '👑',
      targetValue: 5,
      category: 'xp',
      xpReward: 200,
    ),
  ];
}
