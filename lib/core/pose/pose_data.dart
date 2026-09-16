import 'pose_landmark_point.dart';

/// Full body pose estimation container with landmark points.
class PoseData {
  final PoseLandmarkPoint? nose;
  final PoseLandmarkPoint? shoulderLeft;
  final PoseLandmarkPoint? shoulderRight;
  final PoseLandmarkPoint? elbowLeft;
  final PoseLandmarkPoint? elbowRight;
  final PoseLandmarkPoint? wristLeft;
  final PoseLandmarkPoint? wristRight;
  final PoseLandmarkPoint? hipLeft;
  final PoseLandmarkPoint? hipRight;
  final PoseLandmarkPoint? kneeLeft;
  final PoseLandmarkPoint? kneeRight;
  final PoseLandmarkPoint? ankleLeft;
  final PoseLandmarkPoint? ankleRight;
  final double overallConfidence;
  final DateTime timestamp;

  const PoseData({
    this.nose,
    this.shoulderLeft,
    this.shoulderRight,
    this.elbowLeft,
    this.elbowRight,
    this.wristLeft,
    this.wristRight,
    this.hipLeft,
    this.hipRight,
    this.kneeLeft,
    this.kneeRight,
    this.ankleLeft,
    this.ankleRight,
    this.overallConfidence = 1.0,
    required this.timestamp,
  });

  bool hasUpperBody([double minConfidence = 0.5]) {
    return (shoulderLeft?.isReliable(minConfidence) ?? false) &&
        (shoulderRight?.isReliable(minConfidence) ?? false) &&
        (elbowLeft?.isReliable(minConfidence) ?? false) &&
        (elbowRight?.isReliable(minConfidence) ?? false);
  }

  bool hasLowerBody([double minConfidence = 0.5]) {
    return (hipLeft?.isReliable(minConfidence) ?? false) &&
        (kneeLeft?.isReliable(minConfidence) ?? false) &&
        (ankleLeft?.isReliable(minConfidence) ?? false);
  }

  bool hasFullBody([double minConfidence = 0.5]) {
    return hasUpperBody(minConfidence) && hasLowerBody(minConfidence);
  }
}
