import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/stats_entity.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/monthly_trend_chart.dart';
import '../widgets/stats_card.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (state is AnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.expense,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.message,
                    style: AppTypography.bodyMedium(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () {
                      context.read<AnalyticsBloc>().add(const LoadAnalyticsEvent());
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is AnalyticsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AnalyticsBloc>().add(const RefreshAnalyticsEvent());
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(context, state.stats),
                    const SizedBox(height: AppSpacing.lg),

                    // Comparison with last month
                    _buildComparisonSection(context, state.stats.comparisonLastMonth),
                    const SizedBox(height: AppSpacing.lg),

                    // Monthly Trend Chart
                    _buildSectionTitle(context, 'Tendencia Mensal'),
                    const SizedBox(height: AppSpacing.md),
                    MonthlyTrendChart(data: state.stats.monthlyTrend),
                    const SizedBox(height: AppSpacing.lg),

                    // Expenses by Category
                    _buildSectionTitle(context, 'Despesas por Categoria'),
                    const SizedBox(height: AppSpacing.md),
                    CategoryPieChart(categories: state.stats.expensesByCategory),
                    const SizedBox(height: AppSpacing.lg),

                    // Top Categories List
                    _buildTopCategoriesList(context, state.stats.topCategories),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ProfileStats stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Saldo Total',
                value: CurrencyFormatter.formatBRL(stats.totalBalance),
                icon: Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatsCard(
                title: 'Transacoes',
                value: stats.transactionCount.toString(),
                icon: Icons.receipt_long,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Receitas (Mes)',
                value: CurrencyFormatter.formatBRL(stats.monthlyIncome),
                icon: Icons.trending_up,
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatsCard(
                title: 'Despesas (Mes)',
                value: CurrencyFormatter.formatBRL(stats.monthlyExpenses),
                icon: Icons.trending_down,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Economia (Mes)',
                value: CurrencyFormatter.formatBRL(stats.monthlySavings),
                icon: Icons.savings,
                color: stats.monthlySavings >= 0 ? AppColors.income : AppColors.expense,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: StatsCard(
                title: 'Contas',
                value: stats.connectedAccounts.toString(),
                icon: Icons.account_balance,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonSection(BuildContext context, ComparisonStats comparison) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparado ao mes anterior',
            style: AppTypography.titleSmall(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildComparisonItem(
                  'Receitas',
                  comparison.incomeChange,
                  AppColors.income,
                ),
              ),
              Expanded(
                child: _buildComparisonItem(
                  'Despesas',
                  comparison.expenseChange,
                  AppColors.expense,
                ),
              ),
              Expanded(
                child: _buildComparisonItem(
                  'Economia',
                  comparison.savingsChange,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, double change, Color color) {
    final isPositive = change >= 0;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final changeColor = label == 'Despesas'
        ? (isPositive ? AppColors.expense : AppColors.income)
        : (isPositive ? AppColors.income : AppColors.expense);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: changeColor),
            const SizedBox(width: 4),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: AppTypography.titleMedium(color: changeColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.titleMedium(color: AppColors.textPrimary),
    );
  }

  Widget _buildTopCategoriesList(BuildContext context, List<CategoryStat> categories) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Nenhuma transacao encontrada',
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categorias',
            style: AppTypography.titleSmall(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...categories.map((cat) => _buildCategoryItem(cat)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryStat category) {
    final color = _parseColor(category.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _formatCategoryName(category.category),
              style: AppTypography.bodyMedium(color: AppColors.textPrimary),
            ),
          ),
          Text(
            CurrencyFormatter.formatBRL(category.amount),
            style: AppTypography.bodyMedium(color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 50,
            child: Text(
              '${category.percentage.toStringAsFixed(1)}%',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.textMuted;
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
