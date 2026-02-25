import 'package:flutter/material.dart';

import '../../domain/entities/custom_theme.dart';

/// Theme state for the application
class ThemeState {
  final ThemeMode themeMode;
  final CustomTheme currentPalette;
  final CustomTheme? customTheme;
  final bool isLoading;

  const ThemeState({
    required this.themeMode,
    required this.currentPalette,
    this.customTheme,
    this.isLoading = false,
  });

  factory ThemeState.initial() {
    return ThemeState(
      themeMode: ThemeMode.dark,
      currentPalette: ThemePalettes.defaultPalette,
    );
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    CustomTheme? currentPalette,
    CustomTheme? customTheme,
    bool? isLoading,
    bool clearCustomTheme = false,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      currentPalette: currentPalette ?? this.currentPalette,
      customTheme: clearCustomTheme ? null : (customTheme ?? this.customTheme),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get the active theme (custom if set, otherwise current palette)
  CustomTheme get activeTheme => customTheme ?? currentPalette;

  /// Helper getters for colors
  Color get primary => activeTheme.primary;
  Color get secondary => activeTheme.secondary;
  Color get accent => activeTheme.accent;
  Color get income => activeTheme.income;
  Color get expense => activeTheme.expense;
  Color get background => activeTheme.background;
  Color get surface => activeTheme.surface;
  Color get card => activeTheme.card;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          currentPalette == other.currentPalette &&
          customTheme == other.customTheme &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      currentPalette.hashCode ^
      customTheme.hashCode ^
      isLoading.hashCode;
}
