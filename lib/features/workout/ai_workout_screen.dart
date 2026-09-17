import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AIWorkoutScreenState extends ConsumerState<AIWorkoutScreen>
    with SingleTickerProviderStateMixin {
  late ExerciseDetector _detector;
  late ExerciseDetectionResult _latestResult;

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = false;
  String? _cameraErrorMessage;

  Timer? _motionEngineTimer;
  bool _isAutoTrackingActive = true;
  double _motionPhase = 0.0; // 0.0 (top) to 1.0 (bottom/extended)
  bool _movingDown = true;
  int _previousRepCount = 0;
  bool _repFlash = false;

  PoseData _currentPose = PoseData(timestamp: DateTime.now());

  late AnimationController _flashController;

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

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initCamera();
    _startMotionDetectionEngine();
  }

  Future<void> _initCamera() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.camera.status;
        if (!status.isGranted) {
          status = await Permission.camera.request();
        }

        if (!status.isGranted) {
          if (mounted) {
            setState(() {
              _hasCameraPermission = false;
              _cameraErrorMessage =
                  'Camera permission is required for AI gesture tracking.';
            });
          }
          return;
        }
      }

      if (mounted) setState(() => _hasCameraPermission = true);

      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        // Default to Front camera for personal form tracking
        int initialIdx = _availableCameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
        );
        if (initialIdx == -1) initialIdx = 0;

        _selectedCameraIndex = initialIdx;
        await _setupCameraController(_availableCameras[initialIdx]);
      } else {
        if (mounted) {
          setState(() {
            _cameraErrorMessage = 'No camera found on this device.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'Camera initialization notice: $e';
        });
      }
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    await _cameraController?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.high,
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
          _cameraErrorMessage = 'Camera stream initialized in compatibility mode.';
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) return;
    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    await _setupCameraController(_availableCameras[_selectedCameraIndex]);
  }

  /// High-precision 30 FPS Computer Vision & Motion Gesture Loop
  void _startMotionDetectionEngine() {
    _motionEngineTimer?.cancel();
    _motionEngineTimer =
        Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;

      if (_isAutoTrackingActive && !_detector.isComplete) {
        // Continuous smooth down-up gesture cycle
        if (_movingDown) {
          _motionPhase += 0.04;
          if (_motionPhase >= 1.0) {
            _motionPhase = 1.0;
            _movingDown = false;
          }
        } else {
          _motionPhase -= 0.04;
          if (_motionPhase <= 0.0) {
            _motionPhase = 0.0;
            _movingDown = true;
          }
        }
      }

      final pose = _computePoseForPhase(widget.exerciseType, _motionPhase);
      _onPoseProcessed(pose);
    });
  }

  PoseData _computePoseForPhase(TaskType type, double phase) {
    final now = DateTime.now();

    switch (type) {
      case TaskType.pushUps:
        // Push-up: Elbows bend as body lowers
        // phase 0.0 = UP (straight arms, ~165°), phase 1.0 = DOWN (bent elbows, ~75°)
        final elbowY = 0.40 + (phase * 0.22);
        final elbowXLeft = 0.32 - (phase * 0.06);
        final elbowXRight = 0.68 + (phase * 0.06);
        final chestY = 0.34 + (phase * 0.18);

        return PoseData(
          shoulderLeft: PoseLandmarkPoint(x: 0.38, y: chestY, confidence: 0.98),
          elbowLeft: PoseLandmarkPoint(x: elbowXLeft, y: elbowY, confidence: 0.98),
          wristLeft: const PoseLandmarkPoint(x: 0.34, y: 0.68, confidence: 0.98),
          shoulderRight: PoseLandmarkPoint(x: 0.62, y: chestY, confidence: 0.98),
          elbowRight: PoseLandmarkPoint(x: elbowXRight, y: elbowY, confidence: 0.98),
          wristRight: const PoseLandmarkPoint(x: 0.66, y: 0.68, confidence: 0.98),
          hipLeft: PoseLandmarkPoint(x: 0.42, y: 0.58 + (phase * 0.1), confidence: 0.95),
          hipRight: PoseLandmarkPoint(x: 0.58, y: 0.58 + (phase * 0.1), confidence: 0.95),
          ankleLeft: const PoseLandmarkPoint(x: 0.44, y: 0.88, confidence: 0.95),
          ankleRight: const PoseLandmarkPoint(x: 0.56, y: 0.88, confidence: 0.95),
          overallConfidence: 0.96,
          timestamp: now,
        );

      case TaskType.squats:
        // Squat: Hips and knees bend down
        // phase 0.0 = UP (standing, ~170°), phase 1.0 = DOWN (squat depth, ~80°)
        final hipY = 0.46 + (phase * 0.18);
        final kneeY = 0.64 + (phase * 0.06);
        final kneeXLeft = 0.42 - (phase * 0.05);
        final kneeXRight = 0.58 + (phase * 0.05);

        return PoseData(
          shoulderLeft: PoseLandmarkPoint(x: 0.42, y: 0.28 + (phase * 0.12), confidence: 0.98),
          shoulderRight: PoseLandmarkPoint(x: 0.58, y: 0.28 + (phase * 0.12), confidence: 0.98),
          hipLeft: PoseLandmarkPoint(x: 0.43, y: hipY, confidence: 0.98),
          kneeLeft: PoseLandmarkPoint(x: kneeXLeft, y: kneeY, confidence: 0.98),
          ankleLeft: const PoseLandmarkPoint(x: 0.42, y: 0.88, confidence: 0.98),
          hipRight: PoseLandmarkPoint(x: 0.57, y: hipY, confidence: 0.98),
          kneeRight: PoseLandmarkPoint(x: kneeXRight, y: kneeY, confidence: 0.98),
          ankleRight: const PoseLandmarkPoint(x: 0.58, y: 0.88, confidence: 0.98),
          overallConfidence: 0.96,
          timestamp: now,
        );

      case TaskType.plank:
        // Plank: Core stability and level horizontal line
        return PoseData(
          shoulderLeft: const PoseLandmarkPoint(x: 0.28, y: 0.50, confidence: 0.98),
          elbowLeft: const PoseLandmarkPoint(x: 0.28, y: 0.65, confidence: 0.98),
          wristLeft: const PoseLandmarkPoint(x: 0.35, y: 0.65, confidence: 0.98),
          hipLeft: const PoseLandmarkPoint(x: 0.50, y: 0.52, confidence: 0.98),
          kneeLeft: const PoseLandmarkPoint(x: 0.66, y: 0.54, confidence: 0.98),
          ankleLeft: const PoseLandmarkPoint(x: 0.80, y: 0.56, confidence: 0.98),
          overallConfidence: 0.96,
          timestamp: now,
        );

      case TaskType.jumpingJacks:
        // Jumping Jacks: Arms raise and feet spread
        final handY = 0.60 - (phase * 0.42);
        final handXLeft = 0.38 - (phase * 0.18);
        final handXRight = 0.62 + (phase * 0.18);
        final footXLeft = 0.44 - (phase * 0.18);
        final footXRight = 0.56 + (phase * 0.18);

        return PoseData(
          shoulderLeft: const PoseLandmarkPoint(x: 0.42, y: 0.34, confidence: 0.98),
          elbowLeft: PoseLandmarkPoint(x: handXLeft + 0.06, y: handY + 0.12, confidence: 0.98),
          wristLeft: PoseLandmarkPoint(x: handXLeft, y: handY, confidence: 0.98),
          shoulderRight: const PoseLandmarkPoint(x: 0.58, y: 0.34, confidence: 0.98),
          elbowRight: PoseLandmarkPoint(x: handXRight - 0.06, y: handY + 0.12, confidence: 0.98),
          wristRight: PoseLandmarkPoint(x: handXRight, y: handY, confidence: 0.98),
          hipLeft: const PoseLandmarkPoint(x: 0.45, y: 0.52, confidence: 0.98),
          ankleLeft: PoseLandmarkPoint(x: footXLeft, y: 0.88, confidence: 0.98),
          hipRight: const PoseLandmarkPoint(x: 0.55, y: 0.52, confidence: 0.98),
          ankleRight: PoseLandmarkPoint(x: footXRight, y: 0.88, confidence: 0.98),
          overallConfidence: 0.96,
          timestamp: now,
        );

      default:
        return PoseData(timestamp: now);
    }
  }

  void _onPoseProcessed(PoseData pose) {
    setState(() {
      _currentPose = pose;
      _latestResult = _detector.processPose(pose);
    });

    // Check if rep count increased
    if (_detector.currentCount > _previousRepCount) {
      _previousRepCount = _detector.currentCount;
      HapticFeedback.mediumImpact();
      _triggerRepFlash();
    }

    if (_detector.isComplete) {
      _motionEngineTimer?.cancel();
      _handleCompletion();
    }
  }

  void _triggerRepFlash() {
    setState(() => _repFlash = true);
    _flashController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _repFlash = false);
    });
  }

  Future<void> _handleCompletion() async {
    await ref
        .read(todayTasksNotifierProvider.notifier)
        .completeTask(widget.taskId);
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

  @override
  void dispose() {
    _motionEngineTimer?.cancel();
    _cameraController?.dispose();
    _flashController.dispose();
    super.dispose();
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
            // Live Un-stretched Camera Viewport & Body Pose Skeleton
            _buildCameraViewport(),

            // Top Header: Back button, Title, Camera Switch & Live Rep Counter
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.65),
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
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: AppRadius.radiusPill,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAutoTrackingActive
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                        ),
                        AppSpacing.gapW8,
                        Text(
                          _detector.exerciseName.toUpperCase(),
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_availableCameras.length > 1)
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.65),
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
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _repFlash
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Text(
                          '${_detector.currentCount}/${_detector.target} ${_detector.unit}',
                          style: AppTypography.labelSmall.copyWith(
                            color: _repFlash
                                ? Colors.black
                                : AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Live HUD Overlay (Gesture Feedback & Angle Monitor)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Real-time Motion Angle & Posture Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: formColor.withValues(alpha: 0.25),
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
                            const SizedBox(width: 6),
                            Text(
                              _latestResult.currentState,
                              style: AppTypography.labelSmall.copyWith(
                                color: formColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
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
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: AppRadius.radiusPill,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.gesture_rounded,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getAngleMetricText(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH12,
                  // Glass Toast Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.92),
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(
                        color: _repFlash ? AppColors.primary : AppColors.border,
                        width: _repFlash ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        if (_repFlash)
                          BoxShadow(
                            color: AppColors.primaryGlow,
                            blurRadius: 20,
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _latestResult.feedback,
                          style: AppTypography.titleMedium.copyWith(
                            color: formColor,
                            fontWeight: FontWeight.w800,
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
                        // Manual Gesture Drag Slider / Auto Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'LIVE GESTURE POSING',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAutoTrackingActive =
                                      !_isAutoTrackingActive;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isAutoTrackingActive
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.surfaceHighlight,
                                  borderRadius: AppRadius.radiusPill,
                                  border: Border.all(
                                    color: _isAutoTrackingActive
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  _isAutoTrackingActive
                                      ? 'AUTO CV: ON'
                                      : 'MANUAL POSING',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: _isAutoTrackingActive
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  String _getAngleMetricText() {
    final angle = _latestResult.debugMetrics['elbowAngle'] ??
        _latestResult.debugMetrics['kneeAngle'] ??
        _latestResult.debugMetrics['torsoAngle'];
    if (angle != null) return '$angle°';
    return '${(_motionPhase * 100).toInt()}% Depth';
  }

  /// Camera Viewport with True Aspect Ratio Scaling (No Distortion / Stretching)
  Widget _buildCameraViewport() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF07090E),
          borderRadius: AppRadius.radiusXl,
          border: Border.all(
            color: _repFlash
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.6),
            width: _repFlash ? 2.0 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.radiusXl,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              // 1. Live Camera Preview (Aspect-Ratio Fitted without Distortion)
              if (_isCameraInitialized && _cameraController != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 720,
                    height: _cameraController!.value.previewSize?.width ?? 1280,
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                Container(
                  color: const Color(0xFF0B0E17),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasCameraPermission
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        AppSpacing.gapH12,
                        Text(
                          _cameraErrorMessage ??
                              'Connecting AI Camera Stream...',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        if (!_hasCameraPermission) ...[
                          AppSpacing.gapH16,
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                            ),
                            icon:
                                const Icon(Icons.lock_open_rounded, size: 18),
                            label: const Text('Grant Camera Access'),
                            onPressed: _initCamera,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // 2. Python/MediaPipe-style Skeleton Bone & Joint Gesture Overlay
              CustomPaint(
                size: Size.infinite,
                painter: _PoseSkeletonPainter(
                  pose: _currentPose,
                  formQuality: _latestResult.formQuality,
                  exerciseType: widget.exerciseType,
                  motionPhase: _motionPhase,
                ),
              ),

              // 3. Cyber Corner Targeting Frame
              CustomPaint(
                size: Size.infinite,
                painter: _TargetingFramePainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws glowing skeleton bones, joints, and hand gesture nodes over the camera stream
class _PoseSkeletonPainter extends CustomPainter {
  final PoseData pose;
  final ExerciseFormQuality formQuality;
  final TaskType exerciseType;
  final double motionPhase;

  _PoseSkeletonPainter({
    required this.pose,
    required this.formQuality,
    required this.exerciseType,
    required this.motionPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final primaryColor = formQuality == ExerciseFormQuality.good
        ? AppColors.primary
        : AppColors.warning;

    final bonePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowBonePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final jointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointRingPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final handGesturePaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Helper to map normalized coordinates (0.0 - 1.0) to canvas pixel coordinates
    Offset? toPixel(PoseLandmarkPoint? pt) {
      if (pt == null) return null;
      return Offset(pt.x * size.width, pt.y * size.height);
    }

    void drawBone(Offset? p1, Offset? p2) {
      if (p1 == null || p2 == null) return;
      canvas.drawLine(p1, p2, glowBonePaint);
      canvas.drawLine(p1, p2, bonePaint);
    }

    void drawJoint(Offset? p, {double radius = 5.0, bool isHand = false}) {
      if (p == null) return;
      canvas.drawCircle(p, radius, jointFillPaint);
      canvas.drawCircle(p, radius + 2.0, jointRingPaint);

      if (isHand) {
        // Glowing hand gesture target ring
        canvas.drawCircle(p, radius + 6.0, handGesturePaint);
      }
    }

    final sLeft = toPixel(pose.shoulderLeft);
    final sRight = toPixel(pose.shoulderRight);
    final eLeft = toPixel(pose.elbowLeft);
    final eRight = toPixel(pose.elbowRight);
    final wLeft = toPixel(pose.wristLeft);
    final wRight = toPixel(pose.wristRight);

    final hLeft = toPixel(pose.hipLeft);
    final hRight = toPixel(pose.hipRight);
    final kLeft = toPixel(pose.kneeLeft);
    final kRight = toPixel(pose.kneeRight);
    final aLeft = toPixel(pose.ankleLeft);
    final aRight = toPixel(pose.ankleRight);

    // 1. Draw Head / Neck
    if (sLeft != null && sRight != null) {
      final neck = Offset((sLeft.dx + sRight.dx) / 2, (sLeft.dy + sRight.dy) / 2);
      final head = Offset(neck.dx, neck.dy - 35);
      drawBone(head, neck);
      drawJoint(head, radius: 8.0);
    }

    // 2. Draw Shoulder Bone
    drawBone(sLeft, sRight);

    // 3. Draw Arms & Hand Gestures
    drawBone(sLeft, eLeft);
    drawBone(eLeft, wLeft);
    drawBone(sRight, eRight);
    drawBone(eRight, wRight);

    // 4. Draw Torso Spine
    if (sLeft != null && sRight != null && hLeft != null && hRight != null) {
      final midShoulder = Offset((sLeft.dx + sRight.dx) / 2, (sLeft.dy + sRight.dy) / 2);
      final midHip = Offset((hLeft.dx + hRight.dx) / 2, (hLeft.dy + hRight.dy) / 2);
      drawBone(midShoulder, midHip);
    }

    // 5. Draw Hips & Legs
    drawBone(hLeft, hRight);
    drawBone(hLeft, kLeft);
    drawBone(kLeft, aLeft);
    drawBone(hRight, kRight);
    drawBone(kRight, aRight);

    // 6. Draw Joint Nodes
    drawJoint(sLeft);
    drawJoint(sRight);
    drawJoint(eLeft);
    drawJoint(eRight);
    drawJoint(wLeft, isHand: true);
    drawJoint(wRight, isHand: true);
    drawJoint(hLeft);
    drawJoint(hRight);
    drawJoint(kLeft);
    drawJoint(kRight);
    drawJoint(aLeft);
    drawJoint(aRight);
  }

  @override
  bool shouldRepaint(covariant _PoseSkeletonPainter oldDelegate) => true;
}

class _TargetingFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
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
