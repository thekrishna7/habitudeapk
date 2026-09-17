import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepTrackingState {
  final int todaySteps;
  final int targetSteps;
  final String pedestrianStatus;
  final bool isTracking;
  final bool hasPermission;
  final String? errorMessage;

  const StepTrackingState({
    required this.todaySteps,
    required this.targetSteps,
    this.pedestrianStatus = 'Unknown',
    this.isTracking = false,
    this.hasPermission = false,
    this.errorMessage,
  });

  double get progressPercentage =>
      targetSteps > 0 ? (todaySteps / targetSteps).clamp(0.0, 1.0) : 0.0;

  StepTrackingState copyWith({
    int? todaySteps,
    int? targetSteps,
    String? pedestrianStatus,
    bool? isTracking,
    bool? hasPermission,
    String? errorMessage,
  }) {
    return StepTrackingState(
      todaySteps: todaySteps ?? this.todaySteps,
      targetSteps: targetSteps ?? this.targetSteps,
      pedestrianStatus: pedestrianStatus ?? this.pedestrianStatus,
      isTracking: isTracking ?? this.isTracking,
      hasPermission: hasPermission ?? this.hasPermission,
      errorMessage: errorMessage,
    );
  }
}

class StepTrackingNotifier extends StateNotifier<StepTrackingState> {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  int? _initialStepOffset;

  StepTrackingNotifier()
      : super(const StepTrackingState(todaySteps: 0, targetSteps: 6000)) {
    _init();
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return 'step_count_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _getBaseOffsetKey() {
    final now = DateTime.now();
    return 'step_offset_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSteps = prefs.getInt(_getTodayKey()) ?? 0;
    final savedOffset = prefs.getInt(_getBaseOffsetKey());
    _initialStepOffset = savedOffset;

    state = state.copyWith(todaySteps: savedSteps);
    await requestPermissionAndStart();
  }

  Future<bool> requestPermissionAndStart() async {
    try {
      if (kIsWeb) {
        state = state.copyWith(
          isTracking: true,
          hasPermission: true,
        );
        return true;
      }

      var status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        status = await Permission.activityRecognition.request();
      }

      if (status.isGranted) {
        state = state.copyWith(hasPermission: true, errorMessage: null);
        _startListening();
        return true;
      } else {
        state = state.copyWith(
          hasPermission: false,
          errorMessage: 'Activity Recognition permission is required for automatic step tracking.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Step sensor error: $e',
        hasPermission: false,
      );
      return false;
    }
  }

  void _startListening() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();

    try {
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: (err) => debugPrint('Pedestrian status error: $err'),
        cancelOnError: false,
      );

      state = state.copyWith(isTracking: true);
    } catch (e) {
      debugPrint('Error starting pedometer: $e');
      state = state.copyWith(
        errorMessage: 'Hardware step sensor not supported or unavailable on this device.',
        isTracking: false,
      );
    }
  }

  Future<void> _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final offsetKey = _getBaseOffsetKey();

    if (_initialStepOffset == null) {
      final storedOffset = prefs.getInt(offsetKey);
      if (storedOffset == null) {
        _initialStepOffset = event.steps - state.todaySteps;
        await prefs.setInt(offsetKey, _initialStepOffset!);
      } else {
        _initialStepOffset = storedOffset;
      }
    }

    final calculatedSteps = (event.steps - _initialStepOffset!).clamp(0, 100000);
    final finalSteps = calculatedSteps > state.todaySteps ? calculatedSteps : state.todaySteps;

    await prefs.setInt(_getTodayKey(), finalSteps);

    state = state.copyWith(
      todaySteps: finalSteps,
      isTracking: true,
      errorMessage: null,
    );
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    state = state.copyWith(pedestrianStatus: event.status);
  }

  void _onStepCountError(dynamic error) {
    debugPrint('Pedometer error: $error');
    state = state.copyWith(
      errorMessage: 'Pedometer sensor reading error: $error',
    );
  }

  Future<void> addManualSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    final newTotal = state.todaySteps + steps;
    await prefs.setInt(_getTodayKey(), newTotal);
    state = state.copyWith(todaySteps: newTotal);
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    super.dispose();
  }
}

final stepTrackingProvider =
    StateNotifierProvider<StepTrackingNotifier, StepTrackingState>((ref) {
  return StepTrackingNotifier();
});
