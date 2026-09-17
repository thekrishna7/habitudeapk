import 'package:flutter/material.dart';

/// Centralized Spacing Tokens for Habitude.
/// Standardized scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64
class AppSpacing {
  AppSpacing._();

  static const double xs4 = 4.0;
  static const double sm8 = 8.0;
  static const double md12 = 12.0;
  static const double lg16 = 16.0;
  static const double xl20 = 20.0;
  static const double xxl24 = 24.0;
  static const double xxxl32 = 32.0;
  static const double huge40 = 40.0;
  static const double jumbo48 = 48.0;
  static const double massive64 = 64.0;

  // Convenient SizedBox gaps
  static const SizedBox gapH4 = SizedBox(height: xs4);
  static const SizedBox gapH8 = SizedBox(height: sm8);
  static const SizedBox gapH12 = SizedBox(height: md12);
  static const SizedBox gapH16 = SizedBox(height: lg16);
  static const SizedBox gapH20 = SizedBox(height: xl20);
  static const SizedBox gapH24 = SizedBox(height: xxl24);
  static const SizedBox gapH28 = SizedBox(height: 28.0);
  static const SizedBox gapH32 = SizedBox(height: xxxl32);
  static const SizedBox gapH40 = SizedBox(height: huge40);

  static const SizedBox gapW4 = SizedBox(width: xs4);
  static const SizedBox gapW8 = SizedBox(width: sm8);
  static const SizedBox gapW10 = SizedBox(width: 10.0);
  static const SizedBox gapW12 = SizedBox(width: md12);
  static const SizedBox gapW16 = SizedBox(width: lg16);
  static const SizedBox gapW20 = SizedBox(width: xl20);
  static const SizedBox gapW24 = SizedBox(width: xxl24);
  static const SizedBox gapW32 = SizedBox(width: xxxl32);

  // Standard EdgeInsets
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: xl20, vertical: lg16);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md12);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xxl24, vertical: lg16);
}
