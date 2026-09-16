import 'habit_task_model.dart';

enum SessionStatus {
  ready,
  countdown,
  active,
  rest,
  paused,
  completed,
  cancelled,
  partiallyCompleted,
}

class WorkoutExercise {
  final String id;
  final TaskType exerciseType;
  final String name;
  final int target;
  final String unit;
  final int restDurationSeconds;
  final int xpReward;
  final int order;

  const WorkoutExercise({
    required this.id,
    required this.exerciseType,
    required this.name,
    required this.target,
    required this.unit,
    this.restDurationSeconds = 15,
    required this.xpReward,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseType': exerciseType.name,
        'name': name,
        'target': target,
        'unit': unit,
        'restDurationSeconds': restDurationSeconds,
        'xpReward': xpReward,
        'order': order,
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
        id: json['id'] as String,
        exerciseType: TaskType.values.firstWhere(
          (e) => e.name == json['exerciseType'],
          orElse: () => TaskType.pushUps,
        ),
        name: json['name'] as String,
        target: json['target'] as int,
        unit: json['unit'] as String,
        restDurationSeconds: json['restDurationSeconds'] as int? ?? 15,
        xpReward: json['xpReward'] as int,
        order: json['order'] as int,
      );
}

class ExerciseResult {
  final String exerciseId;
  final TaskType exerciseType;
  final String exerciseName;
  final int target;
  final int completed;
  final String unit;
  final int durationSeconds;
  final String formQuality;
  final int earnedXP;
  final bool isCompleted;

  const ExerciseResult({
    required this.exerciseId,
    required this.exerciseType,
    required this.exerciseName,
    required this.target,
    required this.completed,
    required this.unit,
    required this.durationSeconds,
    this.formQuality = 'GOOD',
    required this.earnedXP,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseType': exerciseType.name,
        'exerciseName': exerciseName,
        'target': target,
        'completed': completed,
        'unit': unit,
        'durationSeconds': durationSeconds,
        'formQuality': formQuality,
        'earnedXP': earnedXP,
        'isCompleted': isCompleted,
      };

  factory ExerciseResult.fromJson(Map<String, dynamic> json) => ExerciseResult(
        exerciseId: json['exerciseId'] as String,
        exerciseType: TaskType.values.firstWhere(
          (e) => e.name == json['exerciseType'],
          orElse: () => TaskType.pushUps,
        ),
        exerciseName: json['exerciseName'] as String,
        target: json['target'] as int,
        completed: json['completed'] as int,
        unit: json['unit'] as String,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        formQuality: json['formQuality'] as String? ?? 'GOOD',
        earnedXP: json['earnedXP'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class Workout {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final int estimatedDurationMinutes;
  final List<WorkoutExercise> exercises;
  final int totalXP;

  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.estimatedDurationMinutes,
    required this.exercises,
    required this.totalXP,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'difficulty': difficulty,
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'totalXP': totalXP,
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        difficulty: json['difficulty'] as String,
        estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalXP: json['totalXP'] as int,
      );
}

class WorkoutSession {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int currentExerciseIndex;
  final List<ExerciseResult> exerciseResults;
  final int totalDurationSeconds;
  final int earnedXP;
  final SessionStatus status;

  const WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    this.completedAt,
    this.currentExerciseIndex = 0,
    this.exerciseResults = const [],
    this.totalDurationSeconds = 0,
    this.earnedXP = 0,
    this.status = SessionStatus.ready,
  });

  bool get isFinished =>
      status == SessionStatus.completed ||
      status == SessionStatus.partiallyCompleted ||
      status == SessionStatus.cancelled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'workoutId': workoutId,
        'workoutName': workoutName,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'currentExerciseIndex': currentExerciseIndex,
        'exerciseResults': exerciseResults.map((e) => e.toJson()).toList(),
        'totalDurationSeconds': totalDurationSeconds,
        'earnedXP': earnedXP,
        'status': status.name,
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String,
        workoutId: json['workoutId'] as String,
        workoutName: json['workoutName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        currentExerciseIndex: json['currentExerciseIndex'] as int? ?? 0,
        exerciseResults: (json['exerciseResults'] as List<dynamic>? ?? [])
            .map((e) => ExerciseResult.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
        earnedXP: json['earnedXP'] as int? ?? 0,
        status: SessionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SessionStatus.ready,
        ),
      );

  WorkoutSession copyWith({
    String? id,
    String? workoutId,
    String? workoutName,
    DateTime? startedAt,
    DateTime? completedAt,
    int? currentExerciseIndex,
    List<ExerciseResult>? exerciseResults,
    int? totalDurationSeconds,
    int? earnedXP,
    SessionStatus? status,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      exerciseResults: exerciseResults ?? this.exerciseResults,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      earnedXP: earnedXP ?? this.earnedXP,
      status: status ?? this.status,
    );
  }
}
