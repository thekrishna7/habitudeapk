import 'package:flutter/material.dart';

/// Supported Exercise and Habit Task types.
enum TaskType {
  steps,
  pushUps,
  squats,
  plank,
  jumpingJacks,
  stretching,
  custom;

  String get displayName {
    switch (this) {
      case TaskType.steps:
        return 'Daily Walk';
      case TaskType.pushUps:
        return 'Push-ups';
      case TaskType.squats:
        return 'Squats';
      case TaskType.plank:
        return 'Plank';
      case TaskType.jumpingJacks:
        return 'Jumping Jacks';
      case TaskType.stretching:
        return 'Stretching';
      case TaskType.custom:
        return 'Custom Habit';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.steps:
        return Icons.directions_walk_rounded;
      case TaskType.pushUps:
        return Icons.fitness_center_rounded;
      case TaskType.squats:
        return Icons.accessibility_new_rounded;
      case TaskType.plank:
        return Icons.timer_rounded;
      case TaskType.jumpingJacks:
        return Icons.sports_gymnastics_rounded;
      case TaskType.stretching:
        return Icons.self_improvement_rounded;
      case TaskType.custom:
        return Icons.star_rounded;
    }
  }

  Color get defaultColor {
    switch (this) {
      case TaskType.steps:
        return const Color(0xFF00F59B); // Primary Neon
      case TaskType.pushUps:
        return const Color(0xFF00E5FF); // Cyan
      case TaskType.squats:
        return const Color(0xFF38BDF8); // Sky blue
      case TaskType.plank:
        return const Color(0xFFFF6D3B); // Flame orange
      case TaskType.jumpingJacks:
        return const Color(0xFFF59E0B); // Amber
      case TaskType.stretching:
        return const Color(0xFF9D4EDD); // Purple
      case TaskType.custom:
        return const Color(0xFF06B6D4);
    }
  }

  String get instructions {
    switch (this) {
      case TaskType.steps:
        return 'Stay active and hit your daily walking milestone. Track your steps throughout the day.';
      case TaskType.pushUps:
        return 'Keep your hands shoulder-width apart, core tight, and lower until elbows hit 90 degrees.';
      case TaskType.squats:
        return 'Keep feet shoulder-width apart, chest upright, and lower your hips until thighs are parallel to ground.';
      case TaskType.plank:
        return 'Rest on forearms, engage abdominal muscles, and maintain a straight neutral spine.';
      case TaskType.jumpingJacks:
        return 'Jump feet outward while raising arms above head, then return to starting stance with high energy.';
      case TaskType.stretching:
        return 'Breathe deeply and gently hold key muscle groups to improve flexibility and recovery.';
      case TaskType.custom:
        return 'Complete your custom personal habit according to your daily target.';
    }
  }

  bool get isCameraDetection {
    switch (this) {
      case TaskType.pushUps:
      case TaskType.squats:
      case TaskType.plank:
        return true;
      default:
        return false;
    }
  }

  static TaskType fromString(String? value) {
    switch (value) {
      case 'pushUps':
        return TaskType.pushUps;
      case 'squats':
        return TaskType.squats;
      case 'plank':
        return TaskType.plank;
      case 'jumpingJacks':
        return TaskType.jumpingJacks;
      case 'stretching':
        return TaskType.stretching;
      case 'custom':
        return TaskType.custom;
      case 'steps':
      default:
        return TaskType.steps;
    }
  }
}

/// Task completion status.
enum TaskStatus {
  notStarted,
  inProgress,
  completed,
  locked;

  bool get isCompleted => this == TaskStatus.completed;
  bool get isLocked => this == TaskStatus.locked;
  bool get isInProgress => this == TaskStatus.inProgress;
  bool get isNotStarted => this == TaskStatus.notStarted;

  static TaskStatus fromString(String? value) {
    switch (value) {
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'locked':
        return TaskStatus.locked;
      case 'notStarted':
      default:
        return TaskStatus.notStarted;
    }
  }
}

/// Expanded Habit Task model for the Real Daily Task Engine.
class HabitTask {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final int target;
  final int currentProgress;
  final String unit; // 'reps', 'seconds', 'steps', 'mins'
  final int xpReward;
  final TaskStatus status;
  final String date; // 'YYYY-MM-DD'
  final bool isLocked;
  final String? requiresTaskId; // Prerequisite task ID
  final DateTime createdAt;
  final DateTime? completedAt;

  const HabitTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.currentProgress = 0,
    required this.unit,
    required this.xpReward,
    this.status = TaskStatus.notStarted,
    required this.date,
    this.isLocked = false,
    this.requiresTaskId,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isNotStarted => status == TaskStatus.notStarted;

  double get progressPercentage =>
      target > 0 ? (currentProgress / target).clamp(0.0, 1.0) : 0.0;

  HabitTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    int? target,
    int? currentProgress,
    String? unit,
    int? xpReward,
    TaskStatus? status,
    String? date,
    bool? isLocked,
    String? requiresTaskId,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return HabitTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      currentProgress: currentProgress ?? this.currentProgress,
      unit: unit ?? this.unit,
      xpReward: xpReward ?? this.xpReward,
      status: status ?? this.status,
      date: date ?? this.date,
      isLocked: isLocked ?? this.isLocked,
      requiresTaskId: requiresTaskId ?? this.requiresTaskId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'target': target,
      'currentProgress': currentProgress,
      'unit': unit,
      'xpReward': xpReward,
      'status': status.name,
      'date': date,
      'isLocked': isLocked,
      'requiresTaskId': requiresTaskId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory HabitTask.fromJson(Map<String, dynamic> json) {
    return HabitTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: TaskType.fromString(json['type'] as String?),
      target: (json['target'] as num?)?.toInt() ?? 1,
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'reps',
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 50,
      status: TaskStatus.fromString(json['status'] as String?),
      date: json['date'] as String? ?? '',
      isLocked: json['isLocked'] as bool? ?? false,
      requiresTaskId: json['requiresTaskId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          type == other.type &&
          target == other.target &&
          currentProgress == other.currentProgress &&
          status == other.status &&
          date == other.date &&
          isLocked == other.isLocked;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      type.hashCode ^
      target.hashCode ^
      currentProgress.hashCode ^
      status.hashCode ^
      date.hashCode;

  @override
  String toString() {
    return 'HabitTask(id: $id, title: $title, progress: $currentProgress/$target $unit, xp: $xpReward, status: ${status.name})';
  }
}
