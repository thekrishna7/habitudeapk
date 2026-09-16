import '../../data/models/habit_task_model.dart';
import 'pose_data.dart';

/// Form assessment quality category.
enum ExerciseFormQuality {
  good,
  needsAttention,
  undetermined;

  String get displayName {
    switch (this) {
      case ExerciseFormQuality.good:
        return 'GOOD FORM';
      case ExerciseFormQuality.needsAttention:
        return 'NEEDS ATTENTION';
      case ExerciseFormQuality.undetermined:
        return 'ANALYZING';
    }
  }
}

/// Unified detection result emitted after processing each pose frame.
class ExerciseDetectionResult {
  final String exerciseName;
  final String currentState;
  final int currentCount;
  final int target;
  final String unit; // 'reps' or 'sec'
  final double progressPercentage;
  final ExerciseFormQuality formQuality;
  final String feedback;
  final bool isComplete;
  final double confidence;
  final Map<String, dynamic> debugMetrics;

  const ExerciseDetectionResult({
    required this.exerciseName,
    required this.currentState,
    required this.currentCount,
    required this.target,
    required this.unit,
    required this.progressPercentage,
    required this.formQuality,
    required this.feedback,
    required this.isComplete,
    required this.confidence,
    this.debugMetrics = const {},
  });
}

/// Common abstraction for all on-device exercise detectors.
abstract class ExerciseDetector {
  TaskType get exerciseType;
  String get exerciseName;
  int get target;
  String get unit;
  int get currentCount;
  bool get isComplete;

  /// Resets the detector state machine and rep/duration counters.
  void reset();

  /// Ingests a new pose frame and returns updated detection metrics.
  ExerciseDetectionResult processPose(PoseData pose);
}
