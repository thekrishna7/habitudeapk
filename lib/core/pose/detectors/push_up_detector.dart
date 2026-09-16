import '../../../data/models/habit_task_model.dart';
import '../exercise_detector.dart';
import '../pose_data.dart';
import '../pose_math.dart';

class PushUpConfig {
  final double downAngleThreshold; // <= 90° for valid bottom
  final double upAngleThreshold; // >= 155° for top extension
  final double minConfidence;
  final double smoothingFactor;

  const PushUpConfig({
    this.downAngleThreshold = 90.0,
    this.upAngleThreshold = 155.0,
    this.minConfidence = 0.45,
    this.smoothingFactor = 0.35,
  });
}

enum PushUpState { ready, up, down }

class PushUpDetector implements ExerciseDetector {
  @override
  final int target;
  final PushUpConfig config;

  int _reps = 0;
  PushUpState _state = PushUpState.ready;
  double _smoothedAngle = 170.0;
  String _feedback = 'Position yourself in push-up stance';
  ExerciseFormQuality _formQuality = ExerciseFormQuality.undetermined;
  double _lastConfidence = 0.0;

  PushUpDetector({
    required this.target,
    this.config = const PushUpConfig(),
  });

  @override
  TaskType get exerciseType => TaskType.pushUps;

  @override
  String get exerciseName => 'Push-ups';

  @override
  String get unit => 'reps';

  @override
  int get currentCount => _reps;

  @override
  bool get isComplete => _reps >= target;

  @override
  void reset() {
    _reps = 0;
    _state = PushUpState.ready;
    _smoothedAngle = 170.0;
    _feedback = 'Position yourself in push-up stance';
    _formQuality = ExerciseFormQuality.undetermined;
  }

  @override
  ExerciseDetectionResult processPose(PoseData pose) {
    _lastConfidence = pose.overallConfidence;

    // Check visibility of shoulders, elbows, wrists
    final leftArmReliable = (pose.shoulderLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.elbowLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.wristLeft?.isReliable(config.minConfidence) ?? false);

    final rightArmReliable = (pose.shoulderRight?.isReliable(config.minConfidence) ?? false) &&
        (pose.elbowRight?.isReliable(config.minConfidence) ?? false) &&
        (pose.wristRight?.isReliable(config.minConfidence) ?? false);

    if (!leftArmReliable && !rightArmReliable) {
      _feedback = 'Move arms and torso into camera view';
      _formQuality = ExerciseFormQuality.needsAttention;
      return _buildResult();
    }

    // Calculate active elbow angle (prefer best confidence arm)
    double rawAngle;
    if (leftArmReliable && rightArmReliable) {
      final leftAngle = PoseMath.calculateAngle(
        pose.shoulderLeft!,
        pose.elbowLeft!,
        pose.wristLeft!,
      );
      final rightAngle = PoseMath.calculateAngle(
        pose.shoulderRight!,
        pose.elbowRight!,
        pose.wristRight!,
      );
      rawAngle = (leftAngle + rightAngle) / 2.0;
    } else if (leftArmReliable) {
      rawAngle = PoseMath.calculateAngle(
        pose.shoulderLeft!,
        pose.elbowLeft!,
        pose.wristLeft!,
      );
    } else {
      rawAngle = PoseMath.calculateAngle(
        pose.shoulderRight!,
        pose.elbowRight!,
        pose.wristRight!,
      );
    }

    _smoothedAngle = PoseMath.smoothValue(
      rawAngle,
      _smoothedAngle,
      config.smoothingFactor,
    );

    // State Machine Transitions
    switch (_state) {
      case PushUpState.ready:
        if (_smoothedAngle >= config.upAngleThreshold) {
          _state = PushUpState.up;
          _feedback = 'Ready! Lower your chest';
          _formQuality = ExerciseFormQuality.good;
        } else {
          _feedback = 'Lock arms at the top to begin';
          _formQuality = ExerciseFormQuality.undetermined;
        }
        break;

      case PushUpState.up:
        if (_smoothedAngle <= config.downAngleThreshold) {
          _state = PushUpState.down;
          _feedback = 'Great depth! Now push back up';
          _formQuality = ExerciseFormQuality.good;
        } else {
          _feedback = 'Lower your chest smoothly';
          _formQuality = ExerciseFormQuality.good;
        }
        break;

      case PushUpState.down:
        if (_smoothedAngle >= config.upAngleThreshold) {
          _state = PushUpState.up;
          if (_reps < target) {
            _reps++;
          }
          _feedback = _reps >= target ? 'Target reached! Great job!' : 'Rep counted! Keep going!';
          _formQuality = ExerciseFormQuality.good;
        } else if (_smoothedAngle > config.downAngleThreshold + 30) {
          _feedback = 'Push all the way up';
        }
        break;
    }

    return _buildResult();
  }

  ExerciseDetectionResult _buildResult() {
    final progress = target > 0 ? (_reps / target).clamp(0.0, 1.0) : 0.0;
    final stateString = switch (_state) {
      PushUpState.ready => 'READY',
      PushUpState.up => 'UP',
      PushUpState.down => 'DOWN',
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
        'elbowAngle': _smoothedAngle.toStringAsFixed(1),
        'state': stateString,
      },
    );
  }
}
