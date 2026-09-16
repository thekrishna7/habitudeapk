/// Core Habit / Activity Model definition.
class HabitModel {
  final String id;
  final String title;
  final String category;
  final int targetValue;
  final String unit;
  final int xpReward;
  final bool isCompleted;

  const HabitModel({
    required this.id,
    required this.title,
    required this.category,
    required this.targetValue,
    required this.unit,
    required this.xpReward,
    this.isCompleted = false,
  });

  HabitModel copyWith({
    String? id,
    String? title,
    String? category,
    int? targetValue,
    String? unit,
    int? xpReward,
    bool? isCompleted,
  }) {
    return HabitModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'targetValue': targetValue,
      'unit': unit,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
    };
  }

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      targetValue: json['targetValue'] as int,
      unit: json['unit'] as String,
      xpReward: json['xpReward'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
