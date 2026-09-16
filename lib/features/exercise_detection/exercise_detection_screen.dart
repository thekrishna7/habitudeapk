import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';

class ExerciseDetectionScreen extends StatelessWidget {
  const ExerciseDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: EmptyState(
        icon: Icons.camera_enhance_rounded,
        title: 'Exercise Computer Vision',
        description: 'Camera-based pose estimation for push-ups, squats, and planks arrives in Phase 06 & 07.',
      ),
    );
  }
}
