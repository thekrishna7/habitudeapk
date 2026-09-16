import 'dart:math' as math;
import 'pose_landmark_point.dart';

/// Geometric angle, distance, and smoothing utilities for exercise pose estimation.
class PoseMath {
  PoseMath._();

  /// Calculates the interior angle (in degrees 0° to 180°) at vertex [b]
  /// formed by rays [ba] and [bc].
  static double calculateAngle(
    PoseLandmarkPoint a,
    PoseLandmarkPoint b,
    PoseLandmarkPoint c,
  ) {
    final double radians = math.atan2(c.y - b.y, c.x - b.x) -
        math.atan2(a.y - b.y, a.x - b.x);

    double angle = radians.abs() * (180.0 / math.pi);
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  /// Calculates Euclidean distance between two points in 2D space.
  static double calculateDistance(PoseLandmarkPoint a, PoseLandmarkPoint b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates the slope angle in degrees relative to the horizontal axis.
  static double calculateSlopeAngle(PoseLandmarkPoint a, PoseLandmarkPoint b) {
    final dx = (b.x - a.x).abs();
    final dy = (b.y - a.y).abs();
    if (dx == 0) return 90.0;
    return math.atan(dy / dx) * (180.0 / math.pi);
  }

  /// Exponential Moving Average (EMA) smoothing for angle / coordinate streams.
  static double smoothValue(
    double current,
    double previous,
    double smoothingFactor, // e.g. 0.35 (lower = smoother)
  ) {
    return (current * smoothingFactor) + (previous * (1.0 - smoothingFactor));
  }
}
