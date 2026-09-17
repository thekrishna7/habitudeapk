import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/pose/exercise_detector.dart';
import '../../core/pose/exercise_detector_factory.dart';
import '../../core/pose/pose_data.dart';
import '../../core/pose/pose_landmark_point.dart';
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

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = false;
  String? _cameraErrorMessage;

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

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
        }

        if (!status.isGranted) {
          setState(() {
            _hasCameraPermission = false;
            _cameraErrorMessage = 'Camera permission is required for AI workout tracking.';
          });
          return;
        }
      }

      setState(() => _hasCameraPermission = true);

      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        // Prefer front camera for workout form tracking
        int initialIdx = _availableCameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (initialIdx == -1) initialIdx = 0;

        _selectedCameraIndex = initialIdx;
        await _setupCameraController(_availableCameras[initialIdx]);
      } else {
        setState(() {
          _cameraErrorMessage = 'No camera found on this device.';
        });
      }
    } catch (e) {
      setState(() {
        _cameraErrorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    await _cameraController?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
          _cameraErrorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'Camera stream error: $e';
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    await _setupCameraController(_availableCameras[_selectedCameraIndex]);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
          shoulderLeft: const PoseLandmarkPoint(x: 0.3, y: 0.5),
          hipLeft: const PoseLandmarkPoint(x: 0.5, y: 0.52),
          ankleLeft: const PoseLandmarkPoint(x: 0.75, y: 0.54),
          overallConfidence: 0.95,
          timestamp: now,
        );

      case TaskType.jumpingJacks:
        final handY = isDownPhase ? 0.2 : 0.6;
        final footX = isDownPhase ? 0.25 : 0.45;
        return PoseData(
          wristLeft: PoseLandmarkPoint(x: 0.3, y: handY),
          wristRight: PoseLandmarkPoint(x: 0.7, y: handY),
          ankleLeft: PoseLandmarkPoint(x: footX, y: 0.9),
          ankleRight: PoseLandmarkPoint(x: 1.0 - footX, y: 0.9),
          overallConfidence: 0.95,
          timestamp: now,
        );

      default:
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
            // Live Camera Viewport
            _buildCameraViewport(),

            // Top Header: Back, Title, Switch Camera & Target
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
                  Row(
                    children: [
                      if (_availableCameras.length > 1)
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.6),
                          ),
                          icon: const Icon(
                            Icons.flip_camera_ios_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _switchCamera,
                        ),
                      AppSpacing.gapW8,
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
                          '${_detector.currentCount}/${_detector.target} ${_detector.unit}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
                    child: Column(
                      children: [
                        Text(
                          _latestResult.feedback,
                          style: AppTypography.titleMedium.copyWith(
                            color: formColor,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
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
                            minHeight: 6,
                          ),
                        ),
                        AppSpacing.gapH12,
                        // Testing / Simulator action toggle
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
                                      ? 'AI Tracking Active (Simulating Motion)'
                                      : 'Auto Rep Count Tester (Tap to Test)',
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
        child: ClipRRect(
          borderRadius: AppRadius.radiusXl,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              // Live Camera Stream
              if (_isCameraInitialized && _cameraController != null)
                CameraPreview(_cameraController!)
              else
                Container(
                  color: const Color(0xFF080B12),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasCameraPermission ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        AppSpacing.gapH12,
                        Text(
                          _cameraErrorMessage ?? 'Initializing Camera Stream...',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        if (!_hasCameraPermission) ...[
                          AppSpacing.gapH16,
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(Icons.lock_open_rounded, size: 18),
                            label: const Text('Grant Camera Access'),
                            onPressed: _initCamera,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Grid Lines & Corner Targeting Overlay
              CustomPaint(
                size: Size.infinite,
                painter: _TargetingFramePainter(),
              ),

              // Human Pose Positioning Silhouette Guide
              if (!_isCameraInitialized)
                Opacity(
                  opacity: 0.25,
                  child: const Icon(
                    Icons.accessibility_new_rounded,
                    size: 240,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
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
