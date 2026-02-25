import 'package:flutter/material.dart';

/// Custom theme configuration entity
class CustomTheme {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color income;
  final Color expense;
  final Color background;
  final Color surface;
  final Color card;
  final bool isDefault;
  final bool isCustom;

  const CustomTheme({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.income,
    required this.expense,
    required this.background,
    required this.surface,
    required this.card,
    this.isDefault = false,
    this.isCustom = false,
  });

  CustomTheme copyWith({
    String? id,
    String? name,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? income,
    Color? expense,
    Color? background,
    Color? surface,
    Color? card,
    bool? isDefault,
    bool? isCustom,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      isDefault: isDefault ?? this.isDefault,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primary': primary.toARGB32(),
      'secondary': secondary.toARGB32(),
      'accent': accent.toARGB32(),
      'income': income.toARGB32(),
      'expense': expense.toARGB32(),
      'background': background.toARGB32(),
      'surface': surface.toARGB32(),
      'card': card.toARGB32(),
      'isDefault': isDefault,
      'isCustom': isCustom,
    };
  }

  factory CustomTheme.fromJson(Map<String, dynamic> json) {
    return CustomTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      primary: Color(json['primary'] as int),
      secondary: Color(json['secondary'] as int),
      accent: Color(json['accent'] as int),
      income: Color(json['income'] as int),
      expense: Color(json['expense'] as int),
      background: Color(json['background'] as int),
      surface: Color(json['surface'] as int),
      card: Color(json['card'] as int),
      isDefault: json['isDefault'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomTheme &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Pre-defined color palettes
class ThemePalettes {
  static const List<CustomTheme> palettes = [
    // Imperial Violet - Default
    CustomTheme(
      id: 'imperial_violet',
      name: 'Imperial Violet',
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF3B82F6),
      accent: Color(0xFF8B5CF6),
      income: Color(0xFF10B981),
      expense: Color(0xFFEF4444),
      background: Color(0xFF0F0F1A),
      surface: Color(0xFF1A1A2E),
      card: Color(0xFF252542),
      isDefault: true,
    ),

    // Ocean Blue
    CustomTheme(
      id: 'ocean_blue',
      name: 'Ocean Blue',
      primary: Color(0xFF0EA5E9),
      secondary: Color(0xFF06B6D4),
      accent: Color(0xFF38BDF8),
      income: Color(0xFF22C55E),
      expense: Color(0xFFF43F5E),
      background: Color(0xFF0C1222),
      surface: Color(0xFF111827),
      card: Color(0xFF1E293B),
    ),

    // Emerald Green
    CustomTheme(
      id: 'emerald_green',
      name: 'Emerald',
      primary: Color(0xFF10B981),
      secondary: Color(0xFF14B8A6),
      accent: Color(0xFF34D399),
      income: Color(0xFF22D3EE),
      expense: Color(0xFFEF4444),
      background: Color(0xFF0A1612),
      surface: Color(0xFF0F1D18),
      card: Color(0xFF172A23),
    ),

    // Royal Gold
    CustomTheme(
      id: 'royal_gold',
      name: 'Royal Gold',
      primary: Color(0xFFF59E0B),
      secondary: Color(0xFFEAB308),
      accent: Color(0xFFFBBF24),
      income: Color(0xFF84CC16),
      expense: Color(0xFFDC2626),
      background: Color(0xFF18120A),
      surface: Color(0xFF1C1610),
      card: Color(0xFF2A2218),
    ),

    // Rose Pink
    CustomTheme(
      id: 'rose_pink',
      name: 'Rose Pink',
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFF472B6),
      accent: Color(0xFFF9A8D4),
      income: Color(0xFF4ADE80),
      expense: Color(0xFFEF4444),
      background: Color(0xFF1A0F14),
      surface: Color(0xFF221419),
      card: Color(0xFF2D1C22),
    ),

    // Sunset Orange
    CustomTheme(
      id: 'sunset_orange',
      name: 'Sunset',
      primary: Color(0xFFF97316),
      secondary: Color(0xFFEA580C),
      accent: Color(0xFFFB923C),
      income: Color(0xFF22C55E),
      expense: Color(0xFFE11D48),
      background: Color(0xFF18100C),
      surface: Color(0xFF1F1612),
      card: Color(0xFF2C1F18),
    ),

    // Midnight Purple
    CustomTheme(
      id: 'midnight_purple',
      name: 'Midnight',
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFA78BFA),
      accent: Color(0xFFC4B5FD),
      income: Color(0xFF4ADE80),
      expense: Color(0xFFFB7185),
      background: Color(0xFF0D0B14),
      surface: Color(0xFF13111C),
      card: Color(0xFF1E1B2E),
    ),

    // Arctic Blue
    CustomTheme(
      id: 'arctic_blue',
      name: 'Arctic',
      primary: Color(0xFF60A5FA),
      secondary: Color(0xFF93C5FD),
      accent: Color(0xFFBFDBFE),
      income: Color(0xFF34D399),
      expense: Color(0xFFFB7185),
      background: Color(0xFF0B1120),
      surface: Color(0xFF0F172A),
      card: Color(0xFF1E293B),
    ),
  ];

  static CustomTheme get defaultPalette => palettes.firstWhere(
        (p) => p.isDefault,
        orElse: () => palettes.first,
      );

  static CustomTheme? getPaletteById(String id) {
    try {
      return palettes.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
