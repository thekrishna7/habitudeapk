import '../../data/models/habit_task_model.dart';
import 'detectors/jumping_jack_detector.dart';
import 'detectors/plank_detector.dart';
import 'detectors/push_up_detector.dart';
import 'detectors/squat_detector.dart';
import 'exercise_detector.dart';

/// Central Factory and Registry for creating exercise-specific AI detectors.
class ExerciseDetectorFactory {
  ExerciseDetectorFactory._();

  /// Returns true if the task type is supported by the computer vision pipeline.
  static bool isSupported(TaskType type) {
    switch (type) {
      case TaskType.pushUps:
      case TaskType.squats:
      case TaskType.plank:
      case TaskType.jumpingJacks:
        return true;
      case TaskType.steps:
      case TaskType.stretching:
      case TaskType.custom:
        return false;
    }
  }

  /// Instantiates the appropriate ExerciseDetector with the requested target.
  static ExerciseDetector createDetector({
    required TaskType type,
    required int target,
  }) {
    switch (type) {
      case TaskType.pushUps:
        return PushUpDetector(target: target);
      case TaskType.squats:
        return SquatDetector(target: target);
      case TaskType.plank:
        return PlankDetector(target: target);
      case TaskType.jumpingJacks:
        return JumpingJackDetector(target: target);
      case TaskType.steps:
      case TaskType.stretching:
      case TaskType.custom:
        throw UnsupportedError('AI Pose detector not supported for $type');
    }
  }
}
