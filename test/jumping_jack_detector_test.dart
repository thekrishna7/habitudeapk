import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/pose/detectors/jumping_jack_detector.dart';
import 'package:habitude/core/pose/pose_data.dart';
import 'package:habitude/core/pose/pose_landmark_point.dart';

void main() {
  group('JumpingJackDetector Tests', () {
    late JumpingJackDetector detector;

    setUp(() {
      detector = JumpingJackDetector(target: 3);
    });

    test('Valid jumping jack open-close cycle increments rep count', () {
      final now = DateTime.now();

      // Closed stance: feet close (0.10 dist), arms down (wrists below shoulders)
      final closedPose = PoseData(
        shoulderLeft: const PoseLandmarkPoint(x: 0.45, y: 0.35),
        shoulderRight: const PoseLandmarkPoint(x: 0.55, y: 0.35),
        wristLeft: const PoseLandmarkPoint(x: 0.45, y: 0.65),
        wristRight: const PoseLandmarkPoint(x: 0.55, y: 0.65),
        ankleLeft: const PoseLandmarkPoint(x: 0.47, y: 0.85),
        ankleRight: const PoseLandmarkPoint(x: 0.53, y: 0.85),
        overallConfidence: 0.95,
        timestamp: now,
      );

      // Open stance: feet wide (0.30 dist >= 1.3x shoulder dist), wrists above shoulders
      final openPose = PoseData(
        shoulderLeft: const PoseLandmarkPoint(x: 0.45, y: 0.35),
        shoulderRight: const PoseLandmarkPoint(x: 0.55, y: 0.35),
        wristLeft: const PoseLandmarkPoint(x: 0.20, y: 0.20),
        wristRight: const PoseLandmarkPoint(x: 0.80, y: 0.20),
        ankleLeft: const PoseLandmarkPoint(x: 0.35, y: 0.85),
        ankleRight: const PoseLandmarkPoint(x: 0.65, y: 0.85),
        overallConfidence: 0.95,
        timestamp: now,
      );

      // Establish CLOSED
      for (int i = 0; i < 5; i++) {
        detector.processPose(closedPose);
      }
      expect(detector.currentCount, equals(0));

      // Transition to OPEN
      for (int i = 0; i < 5; i++) {
        detector.processPose(openPose);
      }
      expect(detector.currentCount, equals(0));

      // Return to CLOSED
      for (int i = 0; i < 5; i++) {
        detector.processPose(closedPose);
      }
      expect(detector.currentCount, equals(1));
    });
  });
}
