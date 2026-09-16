import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/pose/detectors/squat_detector.dart';
import 'package:habitude/core/pose/pose_data.dart';
import 'package:habitude/core/pose/pose_landmark_point.dart';

void main() {
  group('SquatDetector Tests', () {
    late SquatDetector detector;

    setUp(() {
      detector = SquatDetector(target: 3);
    });

    test('Initial detector state is 0 reps and not completed', () {
      expect(detector.currentCount, equals(0));
      expect(detector.isComplete, isFalse);
    });

    test('Valid squat cycle increments rep count', () {
      // 1. Standing pose (knee ~ 170°)
      final standingPose = PoseData(
        hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.3),
        kneeLeft: const PoseLandmarkPoint(x: 0.5, y: 0.6),
        ankleLeft: const PoseLandmarkPoint(x: 0.5, y: 0.9),
        overallConfidence: 0.95,
        timestamp: DateTime.now(),
      );

      // 2. Squat down pose (knee ~ 90°)
      final downPose = PoseData(
        hipLeft: const PoseLandmarkPoint(x: 0.3, y: 0.6),
        kneeLeft: const PoseLandmarkPoint(x: 0.6, y: 0.6),
        ankleLeft: const PoseLandmarkPoint(x: 0.6, y: 0.9),
        overallConfidence: 0.95,
        timestamp: DateTime.now(),
      );

      // Frame sequence to establish STANDING
      for (int i = 0; i < 10; i++) {
        detector.processPose(standingPose);
      }
      expect(detector.currentCount, equals(0));

      // Frame sequence to reach DOWN
      for (int i = 0; i < 10; i++) {
        detector.processPose(downPose);
      }
      expect(detector.currentCount, equals(0)); // not yet returned

      // Frame sequence to return UP to STANDING
      for (int i = 0; i < 10; i++) {
        detector.processPose(standingPose);
      }
      expect(detector.currentCount, equals(1));
    });

    test('Partial depth does not increment rep count', () {
      final standingPose = PoseData(
        hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.3),
        kneeLeft: const PoseLandmarkPoint(x: 0.5, y: 0.6),
        ankleLeft: const PoseLandmarkPoint(x: 0.5, y: 0.9),
        overallConfidence: 0.95,
        timestamp: DateTime.now(),
      );

      // Half-squat pose (knee ~ 130°, not reaching down threshold of <= 95°)
      final halfDownPose = PoseData(
        hipLeft: const PoseLandmarkPoint(x: 0.4, y: 0.45),
        kneeLeft: const PoseLandmarkPoint(x: 0.55, y: 0.65),
        ankleLeft: const PoseLandmarkPoint(x: 0.55, y: 0.9),
        overallConfidence: 0.95,
        timestamp: DateTime.now(),
      );

      for (int i = 0; i < 5; i++) {
        detector.processPose(standingPose);
      }
      for (int i = 0; i < 5; i++) {
        detector.processPose(halfDownPose);
      }
      for (int i = 0; i < 5; i++) {
        detector.processPose(standingPose);
      }

      expect(detector.currentCount, equals(0));
    });
  });
}
