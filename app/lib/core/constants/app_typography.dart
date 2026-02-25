import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography definitions for the Imperium app
/// - Titles: Playfair Display (elegant, classic)
/// - Body: Inter (modern, readable)
/// - Currency: JetBrains Mono (monospace, precise)
abstract class AppTypography {
  // Display styles - Playfair Display for elegance
  static TextStyle displayLarge({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  // Headline styles - Playfair Display
  static TextStyle headlineLarge({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headlineMedium({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle headlineSmall({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  // Title styles - Inter for modern look
  static TextStyle titleLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle titleMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle titleSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: color ?? AppColors.textPrimary,
      );

  // Body styles - Inter for readability
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: color ?? AppColors.textSecondary,
      );

  // Label styles - Inter
  static TextStyle labelLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle labelMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color ?? AppColors.textSecondary,
      );

  static TextStyle labelSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color ?? AppColors.textMuted,
      );

  // Currency styles - JetBrains Mono for precision
  static TextStyle currencyLarge({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle currencyMedium({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle currencySmall({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  // Button text style
  static TextStyle button({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.25,
        color: color ?? AppColors.textPrimary,
      );
}
