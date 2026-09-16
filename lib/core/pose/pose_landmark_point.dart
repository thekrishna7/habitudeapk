/// Normalized landmark point in 2D/3D space with confidence score.
class PoseLandmarkPoint {
  final double x; // Normalized 0.0 to 1.0 (or pixel space)
  final double y; // Normalized 0.0 to 1.0 (or pixel space)
  final double z; // Depth approximation
  final double confidence; // 0.0 to 1.0

  const PoseLandmarkPoint({
    required this.x,
    required this.y,
    this.z = 0.0,
    this.confidence = 1.0,
  });

  bool isReliable([double minConfidence = 0.5]) => confidence >= minConfidence;

  PoseLandmarkPoint lerp(PoseLandmarkPoint other, double t) {
    return PoseLandmarkPoint(
      x: x + (other.x - x) * t,
      y: y + (other.y - y) * t,
      z: z + (other.z - z) * t,
      confidence: confidence + (other.confidence - confidence) * t,
    );
  }

  @override
  String toString() => 'Point(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, conf: ${confidence.toStringAsFixed(2)})';
}
