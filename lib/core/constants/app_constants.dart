/// Global application constants for Habitude.
class AppConstants {
  AppConstants._();

  static const String appName = 'HABITUDE';
  static const String appTagline = 'Build Better. Move Better. Become Better.';
  static const String appSubtagline = 'Your habits. Your movement. Your progress.';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyUserAuthToken = 'user_auth_token';
  static const String keyUserTheme = 'user_theme_mode';

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration splashDuration = Duration(milliseconds: 2200);
}
