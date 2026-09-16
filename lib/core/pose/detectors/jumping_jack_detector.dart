import '../../../data/models/habit_task_model.dart';
import '../exercise_detector.dart';
import '../pose_data.dart';
import '../pose_math.dart';

class JumpingJackConfig {
  final double legSpreadMultiplier; // Ankle dist >= 1.3x shoulder dist
  final double minConfidence;
  final double smoothingFactor;

  const JumpingJackConfig({
    this.legSpreadMultiplier = 1.3,
    this.minConfidence = 0.45,
    this.smoothingFactor = 0.35,
  });
}

enum JumpingJackState { ready, closed, open }

class JumpingJackDetector implements ExerciseDetector {
  @override
  final int target;
  final JumpingJackConfig config;

  int _reps = 0;
  JumpingJackState _state = JumpingJackState.ready;
  String _feedback = 'Stand upright with feet together and arms at your sides';
  ExerciseFormQuality _formQuality = ExerciseFormQuality.undetermined;
  double _lastConfidence = 0.0;
  double _smoothedAnkleRatio = 1.0;

  JumpingJackDetector({
    required this.target,
    this.config = const JumpingJackConfig(),
  });

  @override
  TaskType get exerciseType => TaskType.jumpingJacks;

  @override
  String get exerciseName => 'Jumping Jacks';

  @override
  String get unit => 'reps';

  @override
  int get currentCount => _reps;

  @override
  bool get isComplete => _reps >= target;

  @override
  void reset() {
    _reps = 0;
    _state = JumpingJackState.ready;
    _smoothedAnkleRatio = 1.0;
    _feedback = 'Stand upright with feet together and arms at your sides';
    _formQuality = ExerciseFormQuality.undetermined;
  }

  @override
  ExerciseDetectionResult processPose(PoseData pose) {
    _lastConfidence = pose.overallConfidence;

    // Check visibility of shoulders, wrists, ankles
    final hasUpper = (pose.shoulderLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.shoulderRight?.isReliable(config.minConfidence) ?? false) &&
        (pose.wristLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.wristRight?.isReliable(config.minConfidence) ?? false);

    final hasLower = (pose.ankleLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.ankleRight?.isReliable(config.minConfidence) ?? false);

    if (!hasUpper || !hasLower) {
      _feedback = 'Ensure your entire body from head to feet is in view';
      _formQuality = ExerciseFormQuality.needsAttention;
      return _buildResult();
    }

    final shoulderDist = PoseMath.calculateDistance(
      pose.shoulderLeft!,
      pose.shoulderRight!,
    );
    final ankleDist = PoseMath.calculateDistance(
      pose.ankleLeft!,
      pose.ankleRight!,
    );

    final safeShoulderDist = shoulderDist > 0.01 ? shoulderDist : 0.2;
    final rawRatio = ankleDist / safeShoulderDist;

    _smoothedAnkleRatio = PoseMath.smoothValue(
      rawRatio,
      _smoothedAnkleRatio,
      config.smoothingFactor,
    );

    // Arms condition: wrists are at or above shoulder height in screen Y coordinates
    // (In image space, smaller Y means higher on screen)
    final leftArmUp = pose.wristLeft!.y <= (pose.shoulderLeft!.y + 0.05);
    final rightArmUp = pose.wristRight!.y <= (pose.shoulderRight!.y + 0.05);
    final bool armsRaised = leftArmUp && rightArmUp;

    final bool legsWide = _smoothedAnkleRatio >= config.legSpreadMultiplier;
    final bool legsClosed = _smoothedAnkleRatio < 1.15;
    final bool armsDown = pose.wristLeft!.y > (pose.shoulderLeft!.y + 0.15) &&
        pose.wristRight!.y > (pose.shoulderRight!.y + 0.15);

    // State Machine
    switch (_state) {
      case JumpingJackState.ready:
      case JumpingJackState.closed:
        if (armsRaised && legsWide) {
          _state = JumpingJackState.open;
          _feedback = 'Open position reached! Jump back to starting stance';
          _formQuality = ExerciseFormQuality.good;
        } else {
          _state = JumpingJackState.closed;
          _feedback = 'Jump out: spread arms and legs wide';
          _formQuality = ExerciseFormQuality.good;
        }
        break;

      case JumpingJackState.open:
        if (armsDown && legsClosed) {
          _state = JumpingJackState.closed;
          if (_reps < target) {
            _reps++;
          }
          _feedback = _reps >= target ? 'Target reached! Incredible cardio!' : 'Rep counted! Keep the rhythm!';
          _formQuality = ExerciseFormQuality.good;
        } else if (!armsRaised || !legsWide) {
          _feedback = 'Return arms and feet together';
        }
        break;
    }

    return _buildResult();
  }

  ExerciseDetectionResult _buildResult() {
    final progress = target > 0 ? (_reps / target).clamp(0.0, 1.0) : 0.0;
    final stateString = switch (_state) {
      JumpingJackState.ready => 'READY',
      JumpingJackState.closed => 'CLOSED',
      JumpingJackState.open => 'OPEN',
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
        'ankleRatio': _smoothedAnkleRatio.toStringAsFixed(2),
        'state': stateString,
      },
    );
  }
}
