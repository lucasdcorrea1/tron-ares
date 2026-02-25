import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/stats_entity.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategoryStat> categories;

  const CategoryPieChart({
    super.key,
    required this.categories,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sem dados para exibir',
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildSections(),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      final color = _parseColor(category.color);

      return PieChartSectionData(
        color: color,
        value: category.amount,
        title: '${category.percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 2,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.categories.take(6).map((category) {
          final color = _parseColor(category.color);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatCategoryName(category.category),
                    style: AppTypography.bodySmall(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  String _formatCategoryName(String category) {
    final names = {
      'food': 'Alimentacao',
      'transport': 'Transporte',
      'housing': 'Moradia',
      'leisure': 'Lazer',
      'health': 'Saude',
      'education': 'Educacao',
      'salary': 'Salario',
      'freelance': 'Freelance',
      'other': 'Outros',
    };
    return names[category] ?? category;
  }
}
