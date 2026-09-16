import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/pose/exercise_detector.dart';
import '../../core/pose/exercise_detector_factory.dart';
import '../../core/pose/pose_data.dart';
import '../../core/pose/pose_landmark_point.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/habit_task_model.dart';
import '../profile/xp_provider.dart';
import '../tasks/tasks_provider.dart';

class AIWorkoutScreen extends ConsumerStatefulWidget {
  final String taskId;
  final TaskType exerciseType;
  final int target;

  const AIWorkoutScreen({
    super.key,
    required this.taskId,
    required this.exerciseType,
    required this.target,
  });

  @override
  ConsumerState<AIWorkoutScreen> createState() => _AIWorkoutScreenState();
}

class _AIWorkoutScreenState extends ConsumerState<AIWorkoutScreen> {
  late ExerciseDetector _detector;
  late ExerciseDetectionResult _latestResult;
  Timer? _simulationTimer;
  bool _isSimulating = false;
  int _simFrame = 0;

  @override
  void initState() {
    super.initState();
    _detector = ExerciseDetectorFactory.createDetector(
      type: widget.exerciseType,
      target: widget.target,
    );
    _latestResult = _detector.processPose(
      PoseData(timestamp: DateTime.now()),
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _onPoseReceived(PoseData pose) {
    if (!mounted) return;
    setState(() {
      _latestResult = _detector.processPose(pose);
    });

    if (_detector.isComplete) {
      _simulationTimer?.cancel();
      _handleCompletion();
    }
  }

  Future<void> _handleCompletion() async {
    // Complete task in repository and award XP
    await ref.read(todayTasksNotifierProvider.notifier).completeTask(widget.taskId);
    ref.read(xpNotifierProvider.notifier).refresh();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapH20,
            Text('Workout Complete!', style: AppTypography.displaySmall),
            AppSpacing.gapH8,
            Text(
              '${_detector.exerciseName} target reached (${_detector.target} ${_detector.unit}).',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH24,
            PrimaryButton(
              text: 'Done',
              onPressed: () {
                Navigator.of(ctx).pop();
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive Simulation for developer testing / emulator validation.
  void _toggleSimulation() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() => _isSimulating = false);
    } else {
      setState(() => _isSimulating = true);
      _simulationTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        _simFrame++;
        final pose = _generateSyntheticPose(widget.exerciseType, _simFrame);
        _onPoseReceived(pose);
      });
    }
  }

  PoseData _generateSyntheticPose(TaskType type, int frame) {
    final now = DateTime.now();
    final isDownPhase = (frame % 8) >= 4;

    switch (type) {
      case TaskType.pushUps:
        final elbowY = isDownPhase ? 0.65 : 0.45;
        return PoseData(
          shoulderLeft: const PoseLandmarkPoint(x: 0.4, y: 0.3),
          elbowLeft: PoseLandmarkPoint(x: 0.3, y: elbowY),
          wristLeft: const PoseLandmarkPoint(x: 0.25, y: 0.7),
          shoulderRight: const PoseLandmarkPoint(x: 0.6, y: 0.3),
          elbowRight: PoseLandmarkPoint(x: 0.7, y: elbowY),
          wristRight: const PoseLandmarkPoint(x: 0.75, y: 0.7),
          overallConfidence: 0.95,
          timestamp: now,
        );

      case TaskType.squats:
        final hipY = isDownPhase ? 0.65 : 0.45;
        final kneeY = isDownPhase ? 0.70 : 0.65;
        return PoseData(
          hipLeft: PoseLandmarkPoint(x: 0.45, y: hipY),
          kneeLeft: PoseLandmarkPoint(x: 0.45, y: kneeY),
          ankleLeft: const PoseLandmarkPoint(x: 0.45, y: 0.9),
          hipRight: PoseLandmarkPoint(x: 0.55, y: hipY),
          kneeRight: PoseLandmarkPoint(x: 0.55, y: kneeY),
          ankleRight: const PoseLandmarkPoint(x: 0.55, y: 0.9),
          overallConfidence: 0.95,
          timestamp: now,
        );

      case TaskType.plank:
        return PoseData(
          shoulderLeft: const PoseLandmarkPoint(x: 0.25, y: 0.6),
          hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.6),
          ankleLeft: const PoseLandmarkPoint(x: 0.8, y: 0.6),
          overallConfidence: 0.95,
          timestamp: now,
        );

      case TaskType.jumpingJacks:
        final ankleDist = isDownPhase ? 0.35 : 0.15;
        final wristY = isDownPhase ? 0.25 : 0.65;
        return PoseData(
          shoulderLeft: const PoseLandmarkPoint(x: 0.45, y: 0.35),
          shoulderRight: const PoseLandmarkPoint(x: 0.55, y: 0.35),
          wristLeft: PoseLandmarkPoint(x: 0.2, y: wristY),
          wristRight: PoseLandmarkPoint(x: 0.8, y: wristY),
          ankleLeft: PoseLandmarkPoint(x: 0.5 - ankleDist, y: 0.85),
          ankleRight: PoseLandmarkPoint(x: 0.5 + ankleDist, y: 0.85),
          overallConfidence: 0.95,
          timestamp: now,
        );

      case TaskType.steps:
      case TaskType.stretching:
      case TaskType.custom:
        return PoseData(timestamp: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formColor = _latestResult.formQuality == ExerciseFormQuality.good
        ? AppColors.primary
        : AppColors.warning;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Viewport / Body Outline Frame
            _buildCameraViewport(),

            // Top Header: Back button, Exercise title, Target
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _detector.exerciseName.toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      'Target: ${_detector.target} ${_detector.unit}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live HUD Overlay (Center & Bottom)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Form Quality & State Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: formColor.withValues(alpha: 0.2),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(color: formColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _latestResult.formQuality ==
                                      ExerciseFormQuality.good
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                              size: 14,
                              color: formColor,
                            ),
                            AppSpacing.gapW4,
                            Text(
                              _latestResult.formQuality.displayName,
                              style: AppTypography.labelSmall.copyWith(
                                color: formColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapW12,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _latestResult.currentState,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH12,
                  // Feedback Toast Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _latestResult.feedback,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppSpacing.gapH16,
                  // Main Counter Dashboard Card
                  AppCard(
                    backgroundColor: Colors.black.withValues(alpha: 0.85),
                    borderColor: AppColors.primary.withValues(alpha: 0.4),
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'COUNT',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              '${_latestResult.currentCount} / ${_latestResult.target} ${_latestResult.unit}',
                              style: AppTypography.statNumberLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH8,
                        ClipRRect(
                          borderRadius: AppRadius.radiusPill,
                          child: LinearProgressIndicator(
                            value: _latestResult.progressPercentage,
                            backgroundColor: AppColors.surfaceHighlight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        AppSpacing.gapH16,
                        // Dev Simulation Button
                        GestureDetector(
                          onTap: _toggleSimulation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isSimulating
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.surfaceElevated,
                              borderRadius: AppRadius.radiusPill,
                              border: Border.all(
                                color: _isSimulating
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isSimulating
                                      ? Icons.stop_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  size: 16,
                                  color: _isSimulating
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                AppSpacing.gapW8,
                                Text(
                                  _isSimulating
                                      ? 'Testing Active (Simulating Motion)'
                                      : 'Test Simulator (Tap to Test AI Detector)',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: _isSimulating
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraViewport() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D111A),
          borderRadius: AppRadius.radiusXl,
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Grid Lines & Corner Targeting
            CustomPaint(
              size: Size.infinite,
              painter: _TargetingFramePainter(),
            ),
            // Human Pose Positioning Silhouette
            Opacity(
              opacity: 0.25,
              child: Icon(
                Icons.accessibility_new_rounded,
                size: 240,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetingFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 24.0;
    const padding = 16.0;

    // Top-Left Corner
    canvas.drawLine(
      const Offset(padding, padding + cornerLength),
      const Offset(padding, padding),
      paint,
    );
    canvas.drawLine(
      const Offset(padding, padding),
      const Offset(padding + cornerLength, padding),
      paint,
    );

    // Top-Right Corner
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, padding),
      Offset(size.width - padding, padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding, padding + cornerLength),
      paint,
    );

    // Bottom-Left Corner
    canvas.drawLine(
      Offset(padding, size.height - padding - cornerLength),
      Offset(padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding + cornerLength, size.height - padding),
      paint,
    );

    // Bottom-Right Corner
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding - cornerLength),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
