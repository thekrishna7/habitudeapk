import '../../../data/models/habit_task_model.dart';
import '../exercise_detector.dart';
import '../pose_data.dart';
import '../pose_math.dart';

class PlankConfig {
  final double minHipAngle; // >= 155° (straight body line)
  final double maxHipAngle; // <= 200°
  final double maxSlopeAngle; // <= 45° horizontal incline
  final double minConfidence;
  final double smoothingFactor;

  const PlankConfig({
    this.minHipAngle = 155.0,
    this.maxHipAngle = 200.0,
    this.maxSlopeAngle = 45.0,
    this.minConfidence = 0.45,
    this.smoothingFactor = 0.35,
  });
}

enum PlankState { notReady, ready, holding, lostPosition }

class PlankDetector implements ExerciseDetector {
  @override
  final int target; // in seconds
  final PlankConfig config;

  double _accumulatedSeconds = 0.0;
  PlankState _state = PlankState.notReady;
  double _smoothedHipAngle = 180.0;
  DateTime? _lastTimestamp;
  String _feedback = 'Get down into a horizontal forearm plank';
  ExerciseFormQuality _formQuality = ExerciseFormQuality.undetermined;
  double _lastConfidence = 0.0;

  PlankDetector({
    required this.target,
    this.config = const PlankConfig(),
  });

  @override
  TaskType get exerciseType => TaskType.plank;

  @override
  String get exerciseName => 'Plank';

  @override
  String get unit => 'sec';

  @override
  int get currentCount => _accumulatedSeconds.toInt();

  @override
  bool get isComplete => _accumulatedSeconds >= target;

  @override
  void reset() {
    _accumulatedSeconds = 0.0;
    _state = PlankState.notReady;
    _smoothedHipAngle = 180.0;
    _lastTimestamp = null;
    _feedback = 'Get down into a horizontal forearm plank';
    _formQuality = ExerciseFormQuality.undetermined;
  }

  @override
  ExerciseDetectionResult processPose(PoseData pose) {
    _lastConfidence = pose.overallConfidence;
    final now = pose.timestamp;

    // Check visibility of shoulders, hips, ankles
    final leftReliable = (pose.shoulderLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.hipLeft?.isReliable(config.minConfidence) ?? false) &&
        (pose.ankleLeft?.isReliable(config.minConfidence) ?? false);

    final rightReliable = (pose.shoulderRight?.isReliable(config.minConfidence) ?? false) &&
        (pose.hipRight?.isReliable(config.minConfidence) ?? false) &&
        (pose.ankleRight?.isReliable(config.minConfidence) ?? false);

    if (!leftReliable && !rightReliable) {
      _feedback = 'Position your full body horizontally in frame';
      _formQuality = ExerciseFormQuality.needsAttention;
      _lastTimestamp = now;
      if (_state == PlankState.holding) {
        _state = PlankState.lostPosition;
      }
      return _buildResult();
    }

    // Calculate body alignment angle (Shoulder - Hip - Ankle)
    double rawHipAngle;
    double rawSlope;
    if (leftReliable) {
      rawHipAngle = PoseMath.calculateAngle(
        pose.shoulderLeft!,
        pose.hipLeft!,
        pose.ankleLeft!,
      );
      rawSlope = PoseMath.calculateSlopeAngle(
        pose.shoulderLeft!,
        pose.ankleLeft!,
      );
    } else {
      rawHipAngle = PoseMath.calculateAngle(
        pose.shoulderRight!,
        pose.hipRight!,
        pose.ankleRight!,
      );
      rawSlope = PoseMath.calculateSlopeAngle(
        pose.shoulderRight!,
        pose.ankleRight!,
      );
    }

    _smoothedHipAngle = PoseMath.smoothValue(
      rawHipAngle,
      _smoothedHipAngle,
      config.smoothingFactor,
    );

    final bool isAligned = _smoothedHipAngle >= config.minHipAngle &&
        _smoothedHipAngle <= config.maxHipAngle;
    final bool isHorizontal = rawSlope <= config.maxSlopeAngle;

    // Timing delta calculation
    double deltaSeconds = 0.0;
    if (_lastTimestamp != null) {
      deltaSeconds = now.difference(_lastTimestamp!).inMilliseconds / 1000.0;
      if (deltaSeconds > 5.0) deltaSeconds = 0.0; // clamp unreasonable huge gap
    }
    _lastTimestamp = now;

    // State Machine
    if (isAligned && isHorizontal) {
      _state = PlankState.holding;
      _formQuality = ExerciseFormQuality.good;

      if (_accumulatedSeconds < target) {
        _accumulatedSeconds += deltaSeconds;
      }

      if (_accumulatedSeconds >= target) {
        _feedback = 'Plank target achieved! Outstanding core endurance!';
      } else {
        _feedback = 'Great alignment! Hold steady and breathe.';
      }
    } else {
      if (_state == PlankState.holding) {
        _state = PlankState.lostPosition;
      }

      _formQuality = ExerciseFormQuality.needsAttention;
      if (!isAligned) {
        if (_smoothedHipAngle < config.minHipAngle) {
          _feedback = 'Raise your hips slightly to align with shoulders';
        } else {
          _feedback = 'Lower your hips into a straight neutral line';
        }
      } else if (!isHorizontal) {
        _feedback = 'Get into a horizontal plank position';
      }
    }

    return _buildResult();
  }

  ExerciseDetectionResult _buildResult() {
    final progress = target > 0 ? (_accumulatedSeconds / target).clamp(0.0, 1.0) : 0.0;
    final stateString = switch (_state) {
      PlankState.notReady => 'POSITIONING',
      PlankState.ready => 'READY',
      PlankState.holding => 'HOLDING',
      PlankState.lostPosition => 'LOST POSITION',
    };

    return ExerciseDetectionResult(
      exerciseName: exerciseName,
      currentState: stateString,
      currentCount: _accumulatedSeconds.toInt(),
      target: target,
      unit: unit,
      progressPercentage: progress,
      formQuality: _formQuality,
      feedback: _feedback,
      isComplete: isComplete,
      confidence: _lastConfidence,
      debugMetrics: {
        'hipAngle': _smoothedHipAngle.toStringAsFixed(1),
        'seconds': _accumulatedSeconds.toStringAsFixed(1),
        'state': stateString,
      },
    );
  }
}
