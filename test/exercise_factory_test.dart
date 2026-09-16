import 'package:flutter_test/flutter_test.dart';
import 'package:habitude/core/pose/detectors/jumping_jack_detector.dart';
import 'package:habitude/core/pose/detectors/plank_detector.dart';
import 'package:habitude/core/pose/detectors/push_up_detector.dart';
import 'package:habitude/core/pose/detectors/squat_detector.dart';
import 'package:habitude/core/pose/exercise_detector_factory.dart';
import 'package:habitude/data/models/habit_task_model.dart';

void main() {
  group('ExerciseDetectorFactory Tests', () {
    test('Correctly identifies supported computer vision exercise types', () {
      expect(ExerciseDetectorFactory.isSupported(TaskType.pushUps), isTrue);
      expect(ExerciseDetectorFactory.isSupported(TaskType.squats), isTrue);
      expect(ExerciseDetectorFactory.isSupported(TaskType.plank), isTrue);
      expect(ExerciseDetectorFactory.isSupported(TaskType.jumpingJacks), isTrue);
      expect(ExerciseDetectorFactory.isSupported(TaskType.steps), isFalse);
      expect(ExerciseDetectorFactory.isSupported(TaskType.stretching), isFalse);
    });

    test('Instantiates appropriate detector instances', () {
      final pushUp = ExerciseDetectorFactory.createDetector(
        type: TaskType.pushUps,
        target: 10,
      );
      expect(pushUp, isA<PushUpDetector>());
      expect(pushUp.target, equals(10));
      expect(pushUp.unit, equals('reps'));

      final squat = ExerciseDetectorFactory.createDetector(
        type: TaskType.squats,
        target: 15,
      );
      expect(squat, isA<SquatDetector>());
      expect(squat.target, equals(15));

      final plank = ExerciseDetectorFactory.createDetector(
        type: TaskType.plank,
        target: 30,
      );
      expect(plank, isA<PlankDetector>());
      expect(plank.target, equals(30));
      expect(plank.unit, equals('sec'));

      final jack = ExerciseDetectorFactory.createDetector(
        type: TaskType.jumpingJacks,
        target: 25,
      );
      expect(jack, isA<JumpingJackDetector>());
      expect(jack.target, equals(25));
    });
  });
}
