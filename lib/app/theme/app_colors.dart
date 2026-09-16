import 'package:flutter/material.dart';

/// Centralized color palette for Habitude.
/// Dark-first, futuristic, premium fitness-tech identity.
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const Color background = Color(0xFF090B10); // Deep rich void
  static const Color surface = Color(0xFF11141D); // Primary surface layer
  static const Color surfaceElevated = Color(0xFF181D2A); // Elevated card layer
  static const Color surfaceHighlight = Color(0xFF22293A); // Active / border highlight
  static const Color surfaceGlass = Color(0x9911141D); // Frosted overlay

  // Core Brand Accents
  static const Color primary = Color(0xFF00F59B); // High-voltage Neon Mint/Green
  static const Color primaryLight = Color(0xFF4DFFBA);
  static const Color primaryDark = Color(0xFF00B873);
  static const Color primaryGlow = Color(0x3300F59B); // Glowing shadow

  // Secondary Accents (Tech & Energy)
  static const Color secondary = Color(0xFF00E5FF); // Electric Cyan
  static const Color secondaryGlow = Color(0x3300E5FF);
  static const Color tertiary = Color(0xFFFF6D3B); // Flame Orange / Calorie burn
  static const Color tertiaryGlow = Color(0x33FF6D3B);
  static const Color accentPurple = Color(0xFF9D4EDD); // XP / Level milestone

  // Typography & Content Colors
  static const Color textPrimary = Color(0xFFF6F8FC); // Pure crisp text
  static const Color textSecondary = Color(0xFF94A3B8); // Muted slate text
  static const Color textTertiary = Color(0xFF64748B); // Subtle / hint text
  static const Color textDisabled = Color(0xFF475569);

  // Border & Divider Colors
  static const Color border = Color(0xFF1E2536);
  static const Color borderLight = Color(0xFF2E384D);
  static const Color borderFocus = Color(0xFF00F59B);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F59B), Color(0xFF00D287)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00F59B), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF141924), Color(0xFF0E121B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161C28), Color(0xFF11141E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
