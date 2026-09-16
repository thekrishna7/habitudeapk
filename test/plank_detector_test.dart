import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/pose/detectors/plank_detector.dart';
import 'package:habitude/core/pose/pose_data.dart';
import 'package:habitude/core/pose/pose_landmark_point.dart';

void main() {
  group('PlankDetector Tests', () {
    late PlankDetector detector;

    setUp(() {
      detector = PlankDetector(target: 10);
    });

    test('Initial plank detector is at 0 seconds and not completed', () {
      expect(detector.currentCount, equals(0));
      expect(detector.isComplete, isFalse);
    });

    test('Valid horizontal alignment accumulates duration', () {
      final t0 = DateTime(2026, 9, 17, 10, 0, 0);

      // Horizontal straight alignment (Shoulder - Hip - Ankle in line ~ 180°)
      final validPose1 = PoseData(
        shoulderLeft: const PoseLandmarkPoint(x: 0.2, y: 0.6),
        hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.6),
        ankleLeft: const PoseLandmarkPoint(x: 0.8, y: 0.6),
        overallConfidence: 0.95,
        timestamp: t0,
      );

      final validPose2 = PoseData(
        shoulderLeft: const PoseLandmarkPoint(x: 0.2, y: 0.6),
        hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.6),
        ankleLeft: const PoseLandmarkPoint(x: 0.8, y: 0.6),
        overallConfidence: 0.95,
        timestamp: t0.add(const Duration(seconds: 3)),
      );

      detector.processPose(validPose1);
      final res = detector.processPose(validPose2);

      expect(res.currentState, equals('HOLDING'));
      expect(detector.currentCount, greaterThanOrEqualTo(2));
    });

    test('Sagging hips pauses duration accumulation and enters lost position', () {
      final t0 = DateTime(2026, 9, 17, 10, 0, 0);

      final validPose = PoseData(
        shoulderLeft: const PoseLandmarkPoint(x: 0.2, y: 0.6),
        hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.6),
        ankleLeft: const PoseLandmarkPoint(x: 0.8, y: 0.6),
        overallConfidence: 0.95,
        timestamp: t0,
      );

      // Severely sagging hip (~120° angle)
      final saggingPose = PoseData(
        shoulderLeft: const PoseLandmarkPoint(x: 0.2, y: 0.4),
        hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.8),
        ankleLeft: const PoseLandmarkPoint(x: 0.8, y: 0.4),
        overallConfidence: 0.95,
        timestamp: t0.add(const Duration(seconds: 2)),
      );

      detector.processPose(validPose);
      final res = detector.processPose(saggingPose);

      expect(res.currentState, equals('LOST POSITION'));
    });
  });
}
