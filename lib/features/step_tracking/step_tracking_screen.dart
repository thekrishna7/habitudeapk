import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';

class StepTrackingScreen extends StatelessWidget {
  const StepTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: EmptyState(
        icon: Icons.directions_walk_rounded,
        title: 'Step Tracking Engine',
        description: 'Automatic sensor-based pedometer step tracking will be implemented in Phase 05.',
      ),
    );
  }
}
