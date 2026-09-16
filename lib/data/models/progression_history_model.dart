import 'habit_task_model.dart';

class ProgressionPoint {
  final TaskType exerciseType;
  final String date; // 'yyyy-MM-dd'
  final int target;
  final String unit;
  final String reason;

  const ProgressionPoint({
    required this.exerciseType,
    required this.date,
    required this.target,
    required this.unit,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'exerciseType': exerciseType.name,
        'date': date,
        'target': target,
        'unit': unit,
        'reason': reason,
      };

  factory ProgressionPoint.fromJson(Map<String, dynamic> json) =>
      ProgressionPoint(
        exerciseType: TaskType.values.firstWhere(
          (e) => e.name == json['exerciseType'],
          orElse: () => TaskType.pushUps,
        ),
        date: json['date'] as String,
        target: json['target'] as int,
        unit: json['unit'] as String,
        reason: json['reason'] as String? ?? 'Consistency milestone reached',
      );
}
