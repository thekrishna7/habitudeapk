import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/habit_task_model.dart';
import '../features/authentication/login_screen.dart';
import '../features/exercise_detection/exercise_detection_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/personalization/personalization_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/step_tracking/step_tracking_screen.dart';
import '../features/tasks/task_detail_screen.dart';
import '../features/tasks/tasks_screen.dart';
import '../features/workout/ai_workout_screen.dart';
import '../features/workout/workout_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/personalization',
        name: 'personalization',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const PersonalizationScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const TasksScreen(),
        ),
      ),
      GoRoute(
        path: '/task-detail/:id',
        name: 'task_detail',
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['id'] ?? '';
          return _buildPageTransition(
            key: state.pageKey,
            child: TaskDetailScreen(taskId: taskId),
          );
        },
      ),
      GoRoute(
        path: '/workout',
        name: 'workout',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const WorkoutScreen(),
        ),
      ),
      GoRoute(
        path: '/ai-workout',
        name: 'ai_workout',
        pageBuilder: (context, state) {
          final taskId = state.uri.queryParameters['taskId'] ?? 'custom';
          final typeStr = state.uri.queryParameters['type'] ?? 'pushUps';
          final targetStr = state.uri.queryParameters['target'] ?? '10';
          final exerciseType = TaskType.fromString(typeStr);
          final target = int.tryParse(targetStr) ?? 10;

          return _buildPageTransition(
            key: state.pageKey,
            child: AIWorkoutScreen(
              taskId: taskId,
              exerciseType: exerciseType,
              target: target,
            ),
          );
        },
      ),
      GoRoute(
        path: '/step_tracking',
        name: 'step_tracking',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const StepTrackingScreen(),
        ),
      ),
      GoRoute(
        path: '/exercise_detection',
        name: 'exercise_detection',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ExerciseDetectionScreen(),
        ),
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ProgressScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit_profile',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _buildPageTransition(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
});

CustomTransitionPage<void> _buildPageTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}
