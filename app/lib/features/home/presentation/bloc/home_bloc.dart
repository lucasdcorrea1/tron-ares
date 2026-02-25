import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/usecases/get_balance.dart';
import '../../../transactions/domain/usecases/get_transactions.dart';
import 'home_event.dart';
import 'home_state.dart';

/// BLoC for managing home/dashboard data
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetBalanceUseCase getBalance;
  final GetMonthlyIncomeUseCase getMonthlyIncome;
  final GetMonthlyExpensesUseCase getMonthlyExpenses;
  final GetRecentTransactionsUseCase getRecentTransactions;

  HomeBloc({
    required this.getBalance,
    required this.getMonthlyIncome,
    required this.getMonthlyExpenses,
    required this.getRecentTransactions,
  }) : super(const HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    await _loadData(emit);
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<HomeState> emit) async {
    final now = DateTime.now();
    final monthParams = MonthlyParams(year: now.year, month: now.month);

    // Fetch all data in parallel
    final results = await Future.wait([
      getBalance(const NoParams()),
      getMonthlyIncome(monthParams),
      getMonthlyExpenses(monthParams),
      getRecentTransactions(const RecentTransactionsParams(limit: 5)),
    ]);

    final balanceResult = results[0];
    final monthlyIncomeResult = results[1];
    final monthlyExpensesResult = results[2];
    final recentTransactionsResult = results[3];

    // Check for errors
    String? errorMessage;

    balanceResult.fold(
      (failure) => errorMessage = failure.message,
      (_) {},
    );

    if (errorMessage != null) {
      emit(HomeError(errorMessage!));
      return;
    }

    monthlyIncomeResult.fold(
      (failure) => errorMessage = failure.message,
      (_) {},
    );

    if (errorMessage != null) {
      emit(HomeError(errorMessage!));
      return;
    }

    monthlyExpensesResult.fold(
      (failure) => errorMessage = failure.message,
      (_) {},
    );

    if (errorMessage != null) {
      emit(HomeError(errorMessage!));
      return;
    }

    recentTransactionsResult.fold(
      (failure) => errorMessage = failure.message,
      (_) {},
    );

    if (errorMessage != null) {
      emit(HomeError(errorMessage!));
      return;
    }

    // Extract values
    final balance = balanceResult.fold((_) => 0.0, (value) => value as double);
    final monthlyIncome =
        monthlyIncomeResult.fold((_) => 0.0, (value) => value as double);
    final monthlyExpenses =
        monthlyExpensesResult.fold((_) => 0.0, (value) => value as double);
    final recentTransactions = recentTransactionsResult.fold(
      (_) => <TransactionEntity>[],
      (value) => value as List<TransactionEntity>,
    );

    emit(HomeLoaded(
      totalBalance: balance,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      recentTransactions: recentTransactions,
    ));
  }
}
