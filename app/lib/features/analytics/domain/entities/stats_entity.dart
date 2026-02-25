import 'package:equatable/equatable.dart';

/// Profile statistics entity
class ProfileStats extends Equatable {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlySavings;
  final int transactionCount;
  final List<CategoryStat> topCategories;
  final List<MonthlyTrendPoint> monthlyTrend;
  final List<CategoryStat> expensesByCategory;
  final ComparisonStats comparisonLastMonth;
  final int connectedAccounts;

  const ProfileStats({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlySavings,
    required this.transactionCount,
    required this.topCategories,
    required this.monthlyTrend,
    required this.expensesByCategory,
    required this.comparisonLastMonth,
    required this.connectedAccounts,
  });

  @override
  List<Object?> get props => [
        totalBalance,
        monthlyIncome,
        monthlyExpenses,
        monthlySavings,
        transactionCount,
        topCategories,
        monthlyTrend,
        expensesByCategory,
        comparisonLastMonth,
        connectedAccounts,
      ];
}

/// Category statistics for pie chart
class CategoryStat extends Equatable {
  final String category;
  final double amount;
  final double percentage;
  final String color;

  const CategoryStat({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  List<Object?> get props => [category, amount, percentage, color];
}

/// Monthly trend point for line chart
class MonthlyTrendPoint extends Equatable {
  final String month;
  final double income;
  final double expenses;
  final double balance;

  const MonthlyTrendPoint({
    required this.month,
    required this.income,
    required this.expenses,
    required this.balance,
  });

  @override
  List<Object?> get props => [month, income, expenses, balance];
}

/// Comparison with last month
class ComparisonStats extends Equatable {
  final double incomeChange;
  final double expenseChange;
  final double savingsChange;

  const ComparisonStats({
    required this.incomeChange,
    required this.expenseChange,
    required this.savingsChange,
  });

  @override
  List<Object?> get props => [incomeChange, expenseChange, savingsChange];
}
