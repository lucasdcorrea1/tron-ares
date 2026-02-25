import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/custom_theme.dart';
import 'theme_state.dart';

/// Cubit for managing theme state with customizable colors
class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeModeKey = 'themeMode';
  static const String _paletteIdKey = 'paletteId';
  static const String _customThemeKey = 'customTheme';

  ThemeCubit() : super(ThemeState.initial()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.dark.index;
      final themeMode = ThemeMode.values[themeModeIndex];

      // Load palette
      final paletteId = prefs.getString(_paletteIdKey);
      CustomTheme palette = ThemePalettes.defaultPalette;
      if (paletteId != null) {
        palette = ThemePalettes.getPaletteById(paletteId) ?? ThemePalettes.defaultPalette;
      }

      // Load custom theme if any
      CustomTheme? customTheme;
      final customThemeJson = prefs.getString(_customThemeKey);
      if (customThemeJson != null) {
        try {
          customTheme = CustomTheme.fromJson(jsonDecode(customThemeJson));
        } catch (_) {
          // Invalid custom theme, ignore
        }
      }

      emit(ThemeState(
        themeMode: themeMode,
        currentPalette: palette,
        customTheme: customTheme,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setPalette(CustomTheme palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_paletteIdKey, palette.id);
    // Clear custom theme when selecting a preset
    await prefs.remove(_customThemeKey);
    emit(state.copyWith(
      currentPalette: palette,
      clearCustomTheme: true,
    ));
  }

  Future<void> setCustomColor({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? income,
    Color? expense,
    Color? background,
    Color? surface,
    Color? card,
  }) async {
    // Create custom theme based on current active theme
    final baseTheme = state.activeTheme;
    final customTheme = CustomTheme(
      id: 'custom',
      name: 'Custom',
      primary: primary ?? baseTheme.primary,
      secondary: secondary ?? baseTheme.secondary,
      accent: accent ?? baseTheme.accent,
      income: income ?? baseTheme.income,
      expense: expense ?? baseTheme.expense,
      background: background ?? baseTheme.background,
      surface: surface ?? baseTheme.surface,
      card: card ?? baseTheme.card,
      isCustom: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customThemeKey, jsonEncode(customTheme.toJson()));
    emit(state.copyWith(customTheme: customTheme));
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_paletteIdKey);
    await prefs.remove(_customThemeKey);
    emit(state.copyWith(
      currentPalette: ThemePalettes.defaultPalette,
      clearCustomTheme: true,
    ));
  }

  bool get isDarkMode => state.themeMode == ThemeMode.dark;

  /// Get all available palettes
  List<CustomTheme> get availablePalettes => ThemePalettes.palettes;
}
