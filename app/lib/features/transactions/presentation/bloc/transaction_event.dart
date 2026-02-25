import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction_entity.dart';

/// Base class for all transaction events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all transactions
class LoadTransactionsEvent extends TransactionEvent {
  const LoadTransactionsEvent();
}

/// Event to load transactions by type
class LoadTransactionsByTypeEvent extends TransactionEvent {
  final TransactionType type;

  const LoadTransactionsByTypeEvent(this.type);

  @override
  List<Object?> get props => [type];
}

/// Event to load transactions by date range
class LoadTransactionsByDateRangeEvent extends TransactionEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadTransactionsByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to add a new transaction
class AddTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to update an existing transaction
class UpdateTransactionEvent extends TransactionEvent {
  final TransactionEntity transaction;

  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to delete a transaction
class DeleteTransactionEvent extends TransactionEvent {
  final String id;

  const DeleteTransactionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to set filter type
class SetFilterTypeEvent extends TransactionEvent {
  final TransactionType? type;

  const SetFilterTypeEvent(this.type);

  @override
  List<Object?> get props => [type];
}

/// Event to set date filter
class SetDateFilterEvent extends TransactionEvent {
  final DateFilterType filterType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const SetDateFilterEvent({
    required this.filterType,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  List<Object?> get props => [filterType, customStartDate, customEndDate];
}

/// Date filter options
enum DateFilterType {
  all,
  currentMonth,
  last7Days,
  custom,
}
