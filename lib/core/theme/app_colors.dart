import 'package:flutter/material.dart';

/// Design tokens for Echoes Warm Editorial Resonance design system.
/// Derived from FLUTTER_IMPLEMENTATION 2.md.
abstract class AppColors {
  // Canvas & Paper Tiers
  static const Color surface = Color(0xFFFBF9F4);
  static const Color surfaceDim = Color(0xFFDBDAD5);
  static const Color surfaceBright = Color(0xFFFBF9F4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F4EE);
  static const Color surfaceContainer = Color(0xFFEFEEE9);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E3);
  static const Color surfaceContainerHighest = Color(0xFFE4E2DD);

  // Inks & Typography
  static const Color onSurface = Color(0xFF1B1C19);
  static const Color onSurfaceVariant = Color(0xFF404946);
  static const Color inverseSurface = Color(0xFF30312D);
  static const Color inverseOnSurface = Color(0xFFF2F1EB);
  static const Color outline = Color(0xFF707975);
  static const Color outlineVariant = Color(0xFFC0C8C4);

  // Brand Accents
  static const Color primary = Color(0xFF00372D); // Deep Forest Sage
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1D4E43);
  static const Color onPrimaryContainer = Color(0xFF8DBEB0);
  static const Color primaryFixed = Color(0xFFBAEDDE);
  static const Color primaryFixedDim = Color(0xFF9FD1C2);
  static const Color onPrimaryFixed = Color(0xFF00201A);

  // Amber Focal Accents
  static const Color secondary = Color(0xFF904D00); // Amber Gold
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFE932C);
  static const Color onSecondaryContainer = Color(0xFF663500);
  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);

  // Tertiary
  static const Color tertiary = Color(0xFF00372D);
  static const Color tertiaryContainer = Color(0xFF005043);
  static const Color tertiaryFixed = Color(0xFFABF0DD);
  static const Color tertiaryFixedDim = Color(0xFF8FD4C1);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Map Elements
  static const Color mapWaterBase = Color(0xFFE4EFF1);
  static const Color mapLandMass = Color(0xFFEDE7DC);
}
