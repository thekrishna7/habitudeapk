import '../../../data/models/habit_task_model.dart';
import '../exercise_detector.dart';
import '../pose_data.dart';
import '../pose_math.dart';

class SquatConfig {
  final double downAngleThreshold; // <= 95° for full squat depth
  final double upAngleThreshold; // >= 155° for standing extension
  final double minConfidence;
  final double smoothingFactor;

  const SquatConfig({
    this.downAngleThreshold = 95.0,
    this.upAngleThreshold = 155.0,
    this.minConfidence = 0.45,
    this.smoothingFactor = 0.35,
  });
}

enum SquatState { ready, standing, down }

class SquatDetector implements ExerciseDetector {
  @override
  final int target;
  final SquatConfig config;

  int _reps = 0;
  SquatState _state = SquatState.ready;
  double _smoothedKneeAngle = 175.0;
  String _feedback = 'Stand upright in front of the camera';
  ExerciseFormQuality _formQuality = ExerciseFormQuality.undetermined;
  double _lastConfidence = 0.0;

  SquatDetector({
    required this.target,
    this.config = const SquatConfig(),
  });

  @override
  TaskType get exerciseType => TaskType.squats;

  @override
  String get exerciseName => 'Squats';

  @override
  String get unit => 'reps';

  @override
  int get currentCount => _reps;

  @override
  bool get isComplete => _reps >= target;

  @override
  void reset() {
    _reps = 0;
    _state = SquatState.ready;
    _smoothedKneeAngle = 175.0;
    _feedback = 'Stand upright in front of the camera';
    _formQuality = ExerciseFormQuality.undetermined;
  }

  @override
  ExerciseDetectionResult processPose(PoseData pose) {
    _lastConfidence = pose.overallConfidence;

    // Check visibility of hips, knees, ankles
    final leftLegReliable = (pose.hipLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.kneeLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.ankleLeft?.isReliable(config.minConfidence) ?? false);

    final rightLegReliable = (pose.hipRight?.isReliable(config.minConfidence) ?? false) &&
        (pose.kneeRight?.isReliable(config.minConfidence) ?? false) &&
        (pose.ankleRight?.isReliable(config.minConfidence) ?? false);

    if (!leftLegReliable && !rightLegReliable) {
      _feedback = 'Ensure full body from hips to ankles is visible';
      _formQuality = ExerciseFormQuality.needsAttention;
      return _buildResult();
    }

    // Calculate knee angle (Hip - Knee - Ankle)
    double rawKneeAngle;
    if (leftLegReliable && rightLegReliable) {
      final leftAngle = PoseMath.calculateAngle(
        pose.hipLeft!,
        pose.kneeLeft!,
        pose.ankleLeft!,
      );
      final rightAngle = PoseMath.calculateAngle(
        pose.hipRight!,
        pose.kneeRight!,
        pose.ankleRight!,
      );
      rawKneeAngle = (leftAngle + rightAngle) / 2.0;
    } else if (leftLegReliable) {
      rawKneeAngle = PoseMath.calculateAngle(
        pose.hipLeft!,
        pose.kneeLeft!,
        pose.ankleLeft!,
      );
    } else {
      rawKneeAngle = PoseMath.calculateAngle(
        pose.hipRight!,
        pose.kneeRight!,
        pose.ankleRight!,
      );
    }

    _smoothedKneeAngle = PoseMath.smoothValue(
      rawKneeAngle,
      _smoothedKneeAngle,
      config.smoothingFactor,
    );

    // State Machine
    switch (_state) {
      case SquatState.ready:
        if (_smoothedKneeAngle >= config.upAngleThreshold) {
          _state = SquatState.standing;
          _feedback = 'Ready! Lower into a squat';
          _formQuality = ExerciseFormQuality.good;
        } else {
          _feedback = 'Stand tall with knees extended';
          _formQuality = ExerciseFormQuality.undetermined;
        }
        break;

      case SquatState.standing:
        if (_smoothedKneeAngle <= config.downAngleThreshold) {
          _state = SquatState.down;
          _feedback = 'Good depth! Now push back up through your heels';
          _formQuality = ExerciseFormQuality.good;
        } else if (_smoothedKneeAngle < config.upAngleThreshold - 15) {
          _feedback = 'Lower hips until thighs are parallel';
          _formQuality = ExerciseFormQuality.good;
        } else {
          _feedback = 'Lower into squat';
        }
        break;

      case SquatState.down:
        if (_smoothedKneeAngle >= config.upAngleThreshold) {
          _state = SquatState.standing;
          if (_reps < target) {
            _reps++;
          }
          _feedback = _reps >= target ? 'Target reached! Outstanding!' : 'Squat counted! Keep going!';
          _formQuality = ExerciseFormQuality.good;
        } else if (_smoothedKneeAngle > config.downAngleThreshold + 25) {
          _feedback = 'Drive all the way up to standing';
        }
        break;
    }

    return _buildResult();
  }

  ExerciseDetectionResult _buildResult() {
    final progress = target > 0 ? (_reps / target).clamp(0.0, 1.0) : 0.0;
    final stateString = switch (_state) {
      SquatState.ready => 'READY',
      SquatState.standing => 'STANDING',
      SquatState.down => 'DOWN',
    };

    return ExerciseDetectionResult(
      exerciseName: exerciseName,
      currentState: stateString,
      currentCount: _reps,
      target: target,
      unit: unit,
      progressPercentage: progress,
      formQuality: _formQuality,
      feedback: _feedback,
      isComplete: isComplete,
      confidence: _lastConfidence,
      debugMetrics: {
        'kneeAngle': _smoothedKneeAngle.toStringAsFixed(1),
        'state': stateString,
      },
    );
  }
}
