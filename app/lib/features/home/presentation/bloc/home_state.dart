import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction_entity.dart';

/// Base class for all home states
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading state
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// State when home data is loaded successfully
class HomeLoaded extends HomeState {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final List<TransactionEntity> recentTransactions;

  const HomeLoaded({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.recentTransactions,
  });

  /// Monthly balance (income - expenses)
  double get monthlyBalance => monthlyIncome - monthlyExpenses;

  @override
  List<Object?> get props => [
        totalBalance,
        monthlyIncome,
        monthlyExpenses,
        recentTransactions,
      ];
}

/// Error state
class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
