import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography hierarchy for Echoes Warm Editorial Resonance design system.
/// Uses Newsreader for literary editorial headlines and Hanken Grotesk for functional UI labels.
abstract class AppTypography {
  // Display - Literary Titles (Newsreader)
  static TextStyle displayLg = GoogleFonts.newsreader(
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 48 / 40,
    letterSpacing: -0.8,
    color: AppColors.onSurface,
  );

  static TextStyle displayLgMobile = GoogleFonts.newsreader(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 40 / 32,
    letterSpacing: -0.32,
    color: AppColors.onSurface,
  );

  // Headlines (Newsreader)
  static TextStyle headlineLg = GoogleFonts.newsreader(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 36 / 28,
    letterSpacing: -0.28,
    color: AppColors.primary,
  );

  static TextStyle headlineMd = GoogleFonts.newsreader(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.newsreader(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AppColors.onSurface,
  );

  // Body Copy (Newsreader & Hanken Grotesk)
  static TextStyle bodyLg = GoogleFonts.newsreader(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMd = GoogleFonts.newsreader(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodySm = GoogleFonts.hankenGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurfaceVariant,
  );

  // Functional Labels & Metrics (Hanken Grotesk with tabular numerals)
  static TextStyle labelLg = GoogleFonts.hankenGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.28,
    color: AppColors.onSurface,
  );

  static TextStyle labelMd = GoogleFonts.hankenGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.48,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSm = GoogleFonts.hankenGrotesk(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 14 / 10,
    letterSpacing: 0.6,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.onSurfaceVariant,
  );
}
