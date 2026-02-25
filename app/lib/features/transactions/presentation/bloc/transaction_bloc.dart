import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/update_transaction.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// BLoC for managing transaction operations
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsUseCase getTransactions;
  final GetTransactionsByTypeUseCase getTransactionsByType;
  final GetTransactionsByDateRangeUseCase getTransactionsByDateRange;
  final AddTransactionUseCase addTransaction;
  final UpdateTransactionUseCase updateTransaction;
  final DeleteTransactionUseCase deleteTransaction;

  TransactionBloc({
    required this.getTransactions,
    required this.getTransactionsByType,
    required this.getTransactionsByDateRange,
    required this.addTransaction,
    required this.updateTransaction,
    required this.deleteTransaction,
  }) : super(const TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<LoadTransactionsByTypeEvent>(_onLoadTransactionsByType);
    on<LoadTransactionsByDateRangeEvent>(_onLoadTransactionsByDateRange);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<SetFilterTypeEvent>(_onSetFilterType);
    on<SetDateFilterEvent>(_onSetDateFilter);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    final result = await getTransactions(const NoParams());

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionLoaded(transactions: transactions)),
    );
  }

  Future<void> _onLoadTransactionsByType(
    LoadTransactionsByTypeEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    final result = await getTransactionsByType(event.type);

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionLoaded(
        transactions: transactions,
        filterType: event.type,
      )),
    );
  }

  Future<void> _onLoadTransactionsByDateRange(
    LoadTransactionsByDateRangeEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());

    final result = await getTransactionsByDateRange(
      DateRangeParams(
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionLoaded(
        transactions: transactions,
        dateFilter: DateFilterType.custom,
        customStartDate: event.startDate,
        customEndDate: event.endDate,
      )),
    );
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await addTransaction(event.transaction);

    await result.fold(
      (failure) async => emit(TransactionError(failure.message)),
      (_) async {
        emit(const TransactionOperationSuccess('transactionAdded'));
        // Reload transactions
        add(const LoadTransactionsEvent());
      },
    );
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await updateTransaction(event.transaction);

    await result.fold(
      (failure) async => emit(TransactionError(failure.message)),
      (_) async {
        emit(const TransactionOperationSuccess('transactionUpdated'));
        // Reload transactions
        add(const LoadTransactionsEvent());
      },
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final result = await deleteTransaction(event.id);

    await result.fold(
      (failure) async => emit(TransactionError(failure.message)),
      (_) async {
        emit(const TransactionOperationSuccess('transactionDeleted'));
        // Reload transactions
        add(const LoadTransactionsEvent());
      },
    );
  }

  void _onSetFilterType(
    SetFilterTypeEvent event,
    Emitter<TransactionState> emit,
  ) {
    final currentState = state;
    if (currentState is TransactionLoaded) {
      if (event.type == null) {
        emit(currentState.copyWith(clearFilterType: true));
      } else {
        emit(currentState.copyWith(filterType: event.type));
      }
    }
  }

  Future<void> _onSetDateFilter(
    SetDateFilterEvent event,
    Emitter<TransactionState> emit,
  ) async {
    switch (event.filterType) {
      case DateFilterType.all:
        add(const LoadTransactionsEvent());
        break;

      case DateFilterType.currentMonth:
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, 1);
        final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        add(LoadTransactionsByDateRangeEvent(
          startDate: startDate,
          endDate: endDate,
        ));
        break;

      case DateFilterType.last7Days:
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));
        add(LoadTransactionsByDateRangeEvent(
          startDate: startDate,
          endDate: now,
        ));
        break;

      case DateFilterType.custom:
        if (event.customStartDate != null && event.customEndDate != null) {
          add(LoadTransactionsByDateRangeEvent(
            startDate: event.customStartDate!,
            endDate: event.customEndDate!,
          ));
        }
        break;
    }
  }
}
