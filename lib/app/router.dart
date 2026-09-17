import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_scaffold.dart';
import '../core/widgets/liquid_bottom_nav.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Fullscreen flows (No bottom nav)
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/personalization',
        name: 'personalization',
        builder: (context, state) => const PersonalizationScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: '/task-detail/:id',
        name: 'task_detail',
        builder: (context, state) {
          final taskId = state.pathParameters['id'] ?? '';
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/ai-workout',
        name: 'ai_workout',
        builder: (context, state) {
          final taskId = state.uri.queryParameters['taskId'] ?? 'custom';
          final typeStr = state.uri.queryParameters['type'] ?? 'pushUps';
          final targetStr = state.uri.queryParameters['target'] ?? '10';
          final exerciseType = TaskType.fromString(typeStr);
          final target = int.tryParse(targetStr) ?? 10;

          return AIWorkoutScreen(
            taskId: taskId,
            exerciseType: exerciseType,
            target: target,
          );
        },
      ),
      GoRoute(
        path: '/step_tracking',
        name: 'step_tracking',
        builder: (context, state) => const StepTrackingScreen(),
      ),
      GoRoute(
        path: '/exercise_detection',
        name: 'exercise_detection',
        builder: (context, state) => const ExerciseDetectionScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit_profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Main App Shell with Floating Liquid Glass Navigation Dock
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(
            body: navigationShell,
            extendBodyBehindAppBar: true,
            bottomNavigationBar: LiquidBottomNav(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          );
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => _buildFadePage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          // Branch 1: Workouts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workout',
                name: 'workout',
                pageBuilder: (context, state) => _buildFadePage(
                  key: state.pageKey,
                  child: const WorkoutScreen(),
                ),
              ),
            ],
          ),
          // Branch 2: Progress
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                name: 'progress',
                pageBuilder: (context, state) => _buildFadePage(
                  key: state.pageKey,
                  child: const ProgressScreen(),
                ),
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => _buildFadePage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _buildFadePage({
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
