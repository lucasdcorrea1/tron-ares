import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/imperium_app_bar.dart';
import '../../domain/entities/custom_theme.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/theme_state.dart';

/// Elegant theme customization page
class ThemeCustomizationPage extends StatefulWidget {
  const ThemeCustomizationPage({super.key});

  @override
  State<ThemeCustomizationPage> createState() => _ThemeCustomizationPageState();
}

class _ThemeCustomizationPageState extends State<ThemeCustomizationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _editingColorKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final activeTheme = state.activeTheme;

        return Scaffold(
          backgroundColor: activeTheme.background,
          appBar: ImperiumAppBar(
            title: 'Personalizar Tema',
            showBackButton: true,
            actions: [
              if (state.customTheme != null)
                TextButton(
                  onPressed: () => context.read<ThemeCubit>().resetToDefault(),
                  child: Text(
                    'Resetar',
                    style: AppTypography.labelMedium(color: activeTheme.expense),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: activeTheme.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: activeTheme.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: activeTheme.primary,
                  labelStyle: AppTypography.labelMedium(),
                  tabs: const [
                    Tab(text: 'Paletas'),
                    Tab(text: 'Customizar'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PalettesTab(activeTheme: activeTheme, state: state),
                    _CustomizeTab(
                      activeTheme: activeTheme,
                      editingColorKey: _editingColorKey,
                      onEditColor: (key) => setState(() => _editingColorKey = key),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Palettes selection tab
class _PalettesTab extends StatelessWidget {
  final CustomTheme activeTheme;
  final ThemeState state;

  const _PalettesTab({
    required this.activeTheme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final palettes = ThemePalettes.palettes;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: palettes.length,
      itemBuilder: (context, index) {
        final palette = palettes[index];
        final isSelected = state.currentPalette.id == palette.id &&
            state.customTheme == null;

        return _PaletteCard(
          palette: palette,
          isSelected: isSelected,
          activeTheme: activeTheme,
          onTap: () => context.read<ThemeCubit>().setPalette(palette),
        );
      },
    );
  }
}

/// Single palette card
class _PaletteCard extends StatelessWidget {
  final CustomTheme palette;
  final bool isSelected;
  final CustomTheme activeTheme;
  final VoidCallback onTap;

  const _PaletteCard({
    required this.palette,
    required this.isSelected,
    required this.activeTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: activeTheme.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isSelected ? palette.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                palette.name,
                                style: AppTypography.titleMedium(),
                              ),
                              if (palette.isDefault) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'DEFAULT',
                                    style: AppTypography.labelSmall(
                                      color: palette.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Color preview
                Row(
                  children: [
                    _ColorCircle(color: palette.primary, size: 36),
                    const SizedBox(width: AppSpacing.xs),
                    _ColorCircle(color: palette.secondary, size: 36),
                    const SizedBox(width: AppSpacing.xs),
                    _ColorCircle(color: palette.accent, size: 36),
                    const Spacer(),
                    _ColorCircle(color: palette.income, size: 28),
                    const SizedBox(width: AppSpacing.xs),
                    _ColorCircle(color: palette.expense, size: 28),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Background preview
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.background,
                        palette.surface,
                        palette.card,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Customize colors tab
class _CustomizeTab extends StatelessWidget {
  final CustomTheme activeTheme;
  final String? editingColorKey;
  final Function(String?) onEditColor;

  const _CustomizeTab({
    required this.activeTheme,
    required this.editingColorKey,
    required this.onEditColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorItems = [
      _ColorItem(key: 'primary', label: 'Primária', description: 'Cor principal do app', color: activeTheme.primary),
      _ColorItem(key: 'secondary', label: 'Secundária', description: 'Destaques e ações', color: activeTheme.secondary),
      _ColorItem(key: 'accent', label: 'Acento', description: 'Detalhes e realces', color: activeTheme.accent),
      _ColorItem(key: 'income', label: 'Receita', description: 'Indicadores positivos', color: activeTheme.income),
      _ColorItem(key: 'expense', label: 'Despesa', description: 'Indicadores negativos', color: activeTheme.expense),
      _ColorItem(key: 'background', label: 'Fundo', description: 'Cor de fundo', color: activeTheme.background),
      _ColorItem(key: 'surface', label: 'Superfície', description: 'Áreas elevadas', color: activeTheme.surface),
      _ColorItem(key: 'card', label: 'Cartões', description: 'Fundo dos cards', color: activeTheme.card),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: activeTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: activeTheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: activeTheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Toque em uma cor para personalizar. As mudanças são aplicadas em tempo real.',
                  style: AppTypography.bodySmall(color: activeTheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Color items
        ...colorItems.map((item) => _ColorEditRow(
          item: item,
          isEditing: editingColorKey == item.key,
          activeTheme: activeTheme,
          onTap: () {
            if (editingColorKey == item.key) {
              onEditColor(null);
            } else {
              onEditColor(item.key);
              _showColorPicker(context, item);
            }
          },
        )),
      ],
    );
  }

  void _showColorPicker(BuildContext context, _ColorItem item) {
    Color selectedColor = item.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: activeTheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: activeTheme.card,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    item.label,
                    style: AppTypography.titleLarge(),
                  ),
                  const Spacer(),
                  _ColorCircle(color: selectedColor, size: 32),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Color picker
            Expanded(
              child: StatefulBuilder(
                builder: (context, setPickerState) {
                  return ColorPicker(
                    color: selectedColor,
                    onColorChanged: (color) {
                      setPickerState(() => selectedColor = color);
                    },
                    width: 44,
                    height: 44,
                    borderRadius: 22,
                    spacing: 8,
                    runSpacing: 8,
                    wheelDiameter: 200,
                    enableShadesSelection: true,
                    pickersEnabled: const {
                      ColorPickerType.both: false,
                      ColorPickerType.primary: true,
                      ColorPickerType.accent: true,
                      ColorPickerType.bw: false,
                      ColorPickerType.custom: false,
                      ColorPickerType.wheel: true,
                    },
                    pickerTypeLabels: const {
                      ColorPickerType.primary: 'Básicas',
                      ColorPickerType.accent: 'Acentuadas',
                      ColorPickerType.wheel: 'Roda',
                    },
                    selectedPickerTypeColor: activeTheme.primary,
                    heading: null,
                    subheading: Text(
                      'Selecione um tom',
                      style: AppTypography.labelMedium(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    wheelSubheading: Text(
                      'Ajuste fino',
                      style: AppTypography.labelMedium(
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _applyColor(context, item.key, selectedColor);
                    Navigator.pop(context);
                    onEditColor(null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Aplicar',
                    style: AppTypography.titleSmall(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => onEditColor(null));
  }

  void _applyColor(BuildContext context, String key, Color color) {
    final cubit = context.read<ThemeCubit>();
    switch (key) {
      case 'primary':
        cubit.setCustomColor(primary: color);
        break;
      case 'secondary':
        cubit.setCustomColor(secondary: color);
        break;
      case 'accent':
        cubit.setCustomColor(accent: color);
        break;
      case 'income':
        cubit.setCustomColor(income: color);
        break;
      case 'expense':
        cubit.setCustomColor(expense: color);
        break;
      case 'background':
        cubit.setCustomColor(background: color);
        break;
      case 'surface':
        cubit.setCustomColor(surface: color);
        break;
      case 'card':
        cubit.setCustomColor(card: color);
        break;
    }
  }
}

/// Color edit row
class _ColorEditRow extends StatelessWidget {
  final _ColorItem item;
  final bool isEditing;
  final CustomTheme activeTheme;
  final VoidCallback onTap;

  const _ColorEditRow({
    required this.item,
    required this.isEditing,
    required this.activeTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: activeTheme.card,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isEditing ? item.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                _ColorCircle(color: item.color, size: 44),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: AppTypography.titleSmall(),
                      ),
                      Text(
                        item.description,
                        style: AppTypography.bodySmall(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '#${item.color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  style: AppTypography.labelSmall(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.edit_outlined,
                  color: activeTheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Color item model
class _ColorItem {
  final String key;
  final String label;
  final String description;
  final Color color;

  const _ColorItem({
    required this.key,
    required this.label,
    required this.description,
    required this.color,
  });
}

/// Circular color preview
class _ColorCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorCircle({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
