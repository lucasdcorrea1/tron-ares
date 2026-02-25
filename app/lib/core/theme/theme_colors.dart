import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/settings/domain/entities/custom_theme.dart';
import '../../features/settings/presentation/bloc/theme_cubit.dart';
import '../../features/settings/presentation/bloc/theme_state.dart';

/// Extension to easily access theme colors from BuildContext
extension ThemeColorsExtension on BuildContext {
  /// Get the current active theme
  CustomTheme get colors {
    try {
      return read<ThemeCubit>().state.activeTheme;
    } catch (_) {
      return ThemePalettes.defaultPalette;
    }
  }

  /// Watch theme changes (for reactive widgets)
  CustomTheme watchColors() {
    try {
      return watch<ThemeCubit>().state.activeTheme;
    } catch (_) {
      return ThemePalettes.defaultPalette;
    }
  }

  /// Get theme state
  ThemeState get themeState {
    try {
      return read<ThemeCubit>().state;
    } catch (_) {
      return ThemeState.initial();
    }
  }

  /// Check if dark mode
  bool get isDarkMode {
    try {
      return read<ThemeCubit>().state.themeMode == ThemeMode.dark;
    } catch (_) {
      return true;
    }
  }
}

/// Static class for accessing colors outside of widget tree
/// Use only when context is not available
class AppColors {
  static CustomTheme _current = ThemePalettes.defaultPalette;

  static void update(CustomTheme theme) {
    _current = theme;
  }

  // Primary colors
  static Color get primary => _current.primary;
  static Color get primaryLight => _current.primary.withValues(alpha: 0.7);
  static Color get primaryDark => _current.primary.withValues(alpha: 1.0);

  static Color get secondary => _current.secondary;
  static Color get secondaryLight => _current.secondary.withValues(alpha: 0.7);
  static Color get secondaryDark => _current.secondary.withValues(alpha: 1.0);

  // Accent
  static Color get accent => _current.accent;

  // Gradient colors
  static List<Color> get primaryGradient => [_current.primary, _current.secondary];
  static List<Color> get accentGradient => [_current.accent, _current.secondary];

  // Background colors
  static Color get backgroundDark => _current.background;
  static Color get surfaceDark => _current.surface;
  static Color get cardDark => _current.card;

  // Text colors (fixed for readability)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic colors
  static Color get income => _current.income;
  static Color get incomeLight => _current.income.withValues(alpha: 0.7);
  static Color get expense => _current.expense;
  static Color get expenseLight => _current.expense.withValues(alpha: 0.7);

  // Borders
  static const Color divider = Color(0xFF334155);
  static const Color border = Color(0xFF475569);

  // Status colors
  static Color get success => _current.income;
  static const Color warning = Color(0xFFF59E0B);
  static Color get error => _current.expense;
  static Color get info => _current.secondary;

  // Light theme colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Legacy aliases
  static Color get imperiumGold => primary;
  static Color get imperiumDarkGold => primaryDark;
  static Color get imperiumLightGold => primaryLight;
}
