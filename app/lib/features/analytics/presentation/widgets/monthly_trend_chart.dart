import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/stats_entity.dart';

class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyTrendPoint> data;

  const MonthlyTrendChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
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
                Icons.show_chart,
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
      height: 280,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Receitas', AppColors.income),
              const SizedBox(width: AppSpacing.lg),
              _buildLegendItem('Despesas', AppColors.expense),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: _bottomTitleWidgets,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _calculateInterval(),
                      reservedSize: 50,
                      getTitlesWidget: _leftTitleWidgets,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: _calculateMaxY(),
                lineBarsData: [
                  // Income line
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.income);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.income,
                        AppColors.incomeLight,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.income,
                          strokeWidth: 2,
                          strokeColor: AppColors.cardDark,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.income.withValues(alpha: 0.3),
                          AppColors.income.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Expense line
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.expenses);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.expense,
                        AppColors.expenseLight,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.expense,
                          strokeWidth: 2,
                          strokeColor: AppColors.cardDark,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.expense.withValues(alpha: 0.3),
                          AppColors.expense.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (LineBarSpot touchedSpot) => AppColors.surfaceDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final isIncome = barSpot.barIndex == 0;
                        return LineTooltipItem(
                          'R\$ ${barSpot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: isIncome ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= data.length) {
      return const SizedBox();
    }

    final month = data[index].month;
    // Extract month name from "2024-01" format
    final monthNames = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                        'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final monthNum = int.tryParse(month.split('-').last) ?? 1;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        monthNames[monthNum - 1],
        style: AppTypography.bodySmall(color: AppColors.textMuted),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    String text;
    if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}k';
    } else {
      text = value.toStringAsFixed(0);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: AppTypography.bodySmall(color: AppColors.textMuted),
      ),
    );
  }

  double _calculateMaxY() {
    if (data.isEmpty) return 100;

    double maxValue = 0;
    for (final point in data) {
      if (point.income > maxValue) maxValue = point.income;
      if (point.expenses > maxValue) maxValue = point.expenses;
    }

    // Add 20% padding
    return maxValue * 1.2;
  }

  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 0) return 100;

    // Aim for ~4 horizontal lines
    final rawInterval = maxY / 4;

    // Round to nice numbers
    if (rawInterval >= 10000) return (rawInterval / 10000).ceil() * 10000;
    if (rawInterval >= 1000) return (rawInterval / 1000).ceil() * 1000;
    if (rawInterval >= 100) return (rawInterval / 100).ceil() * 100;
    return (rawInterval / 10).ceil() * 10;
  }
}
