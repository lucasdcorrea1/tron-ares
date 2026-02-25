import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_entity.dart';
import 'transaction_event.dart';

/// Base class for all transaction states
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

/// Loading state
class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

/// State when transactions are loaded successfully
class TransactionLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final TransactionType? filterType;
  final DateFilterType dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const TransactionLoaded({
    required this.transactions,
    this.filterType,
    this.dateFilter = DateFilterType.all,
    this.customStartDate,
    this.customEndDate,
  });

  /// Get filtered transactions based on type filter
  List<TransactionEntity> get filteredTransactions {
    if (filterType == null) {
      return transactions;
    }
    return transactions.where((t) => t.type == filterType).toList();
  }

  /// Total income from current transactions
  double get totalIncome {
    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total expenses from current transactions
  double get totalExpenses {
    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Net balance from current transactions
  double get balance => totalIncome - totalExpenses;

  TransactionLoaded copyWith({
    List<TransactionEntity>? transactions,
    TransactionType? filterType,
    bool clearFilterType = false,
    DateFilterType? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool clearCustomDates = false,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate:
          clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate:
          clearCustomDates ? null : (customEndDate ?? this.customEndDate),
    );
  }

  @override
  List<Object?> get props => [
        transactions,
        filterType,
        dateFilter,
        customStartDate,
        customEndDate,
      ];
}

/// State when a transaction operation is successful
class TransactionOperationSuccess extends TransactionState {
  final String message;

  const TransactionOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state
class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
