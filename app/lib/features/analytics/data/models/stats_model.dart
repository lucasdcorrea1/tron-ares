import '../../domain/entities/stats_entity.dart';

class ProfileStatsModel extends ProfileStats {
  const ProfileStatsModel({
    required super.totalBalance,
    required super.monthlyIncome,
    required super.monthlyExpenses,
    required super.monthlySavings,
    required super.transactionCount,
    required super.topCategories,
    required super.monthlyTrend,
    required super.expensesByCategory,
    required super.comparisonLastMonth,
    required super.connectedAccounts,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatsModel(
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
      monthlyExpenses: (json['monthly_expenses'] as num?)?.toDouble() ?? 0.0,
      monthlySavings: (json['monthly_savings'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      topCategories: (json['top_categories'] as List<dynamic>?)
              ?.map((e) => CategoryStatModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlyTrend: (json['monthly_trend'] as List<dynamic>?)
              ?.map((e) => MonthlyTrendPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expensesByCategory: (json['expenses_by_category'] as List<dynamic>?)
              ?.map((e) => CategoryStatModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comparisonLastMonth: ComparisonStatsModel.fromJson(
          json['comparison_last_month'] as Map<String, dynamic>? ?? {}),
      connectedAccounts: json['connected_accounts'] as int? ?? 0,
    );
  }
}

class CategoryStatModel extends CategoryStat {
  const CategoryStatModel({
    required super.category,
    required super.amount,
    required super.percentage,
    required super.color,
  });

  factory CategoryStatModel.fromJson(Map<String, dynamic> json) {
    return CategoryStatModel(
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? '#808080',
    );
  }
}

class MonthlyTrendPointModel extends MonthlyTrendPoint {
  const MonthlyTrendPointModel({
    required super.month,
    required super.income,
    required super.expenses,
    required super.balance,
  });

  factory MonthlyTrendPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPointModel(
      month: json['month'] as String? ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ComparisonStatsModel extends ComparisonStats {
  const ComparisonStatsModel({
    required super.incomeChange,
    required super.expenseChange,
    required super.savingsChange,
  });

  factory ComparisonStatsModel.fromJson(Map<String, dynamic> json) {
    return ComparisonStatsModel(
      incomeChange: (json['income_change'] as num?)?.toDouble() ?? 0.0,
      expenseChange: (json['expense_change'] as num?)?.toDouble() ?? 0.0,
      savingsChange: (json['savings_change'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
