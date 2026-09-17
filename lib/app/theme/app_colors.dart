import 'package:flutter/material.dart';

/// Centralized color palette for Habitude.
/// Ultra-luxury, futuristic, cyber-athletic liquid glass identity.
class AppColors {
  AppColors._();

  // Backgrounds & Void Layers
  static const Color background = Color(0xFF07090E); // Deep obsidian void
  static const Color surface = Color(0xFF0E121C); // Primary dark surface
  static const Color surfaceElevated = Color(0xFF141926); // Elevated glass layer
  static const Color surfaceHighlight = Color(0xFF1E2638); // Highlighted layer
  static const Color surfaceGlass = Color(0xB3101524); // Frosted glass fill
  static const Color surfaceGlassLight = Color(0x33FFFFFF); // Specular reflection

  // High-Voltage Brand Accents
  static const Color primary = Color(0xFF00F59B); // Electric Cyber Mint
  static const Color primaryLight = Color(0xFF5CFFC2);
  static const Color primaryDark = Color(0xFF00BA74);
  static const Color primaryGlow = Color(0x6600F59B); // High-intensity aura

  // Secondary Neon Energy Accents
  static const Color secondary = Color(0xFF00E5FF); // Hyper Neon Cyan
  static const Color secondaryLight = Color(0xFF70F3FF);
  static const Color secondaryGlow = Color(0x6600E5FF);

  // Tertiary Flame & Calorie Accents
  static const Color tertiary = Color(0xFFFF6B35); // Laser Flame Orange
  static const Color tertiaryLight = Color(0xFFFF9266);
  static const Color tertiaryGlow = Color(0x66FF6B35);

  // Purple / XP Tier Accents
  static const Color accentPurple = Color(0xFF8B5CF6); // Ultraviolet
  static const Color accentPurpleLight = Color(0xFFA78BFA);
  static const Color accentPurpleGlow = Color(0x668B5CF6);

  // Crisp High-Contrast Typography
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFF94A3B8); // Muted slate
  static const Color textTertiary = Color(0xFF64748B); // Hint slate
  static const Color textDisabled = Color(0xFF334155);

  // Specular Hairline Borders & Glass Outlines
  static const Color border = Color(0xFF1F293D);
  static const Color borderLight = Color(0xFF2D3B55);
  static const Color borderGlass = Color(0x2EFFFFFF);
  static const Color borderFocus = Color(0xFF00F59B);

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF43F5E);
  static const Color info = Color(0xFF38BDF8);

  // Luxury Gradients
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

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient flameGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF3366)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0xCC182030), Color(0x990F1420)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141926), Color(0xFF0D111A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient specularBorderGradient = LinearGradient(
    colors: [
      Color(0x8000F59B),
      Color(0x20FFFFFF),
      Color(0x6000E5FF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
