import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/transaction_repository.dart';

/// Use case for getting the total balance
class GetBalanceUseCase implements UseCase<double, NoParams> {
  final TransactionRepository repository;

  GetBalanceUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) {
    return repository.getBalance();
  }
}

/// Use case for getting total income
class GetTotalIncomeUseCase implements UseCase<double, NoParams> {
  final TransactionRepository repository;

  GetTotalIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) {
    return repository.getTotalIncome();
  }
}

/// Use case for getting total expenses
class GetTotalExpensesUseCase implements UseCase<double, NoParams> {
  final TransactionRepository repository;

  GetTotalExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) {
    return repository.getTotalExpenses();
  }
}

/// Parameters for monthly balance
class MonthlyParams extends Equatable {
  final int year;
  final int month;

  const MonthlyParams({
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [year, month];
}

/// Use case for getting monthly income
class GetMonthlyIncomeUseCase implements UseCase<double, MonthlyParams> {
  final TransactionRepository repository;

  GetMonthlyIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(MonthlyParams params) {
    return repository.getMonthlyIncome(params.year, params.month);
  }
}

/// Use case for getting monthly expenses
class GetMonthlyExpensesUseCase implements UseCase<double, MonthlyParams> {
  final TransactionRepository repository;

  GetMonthlyExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(MonthlyParams params) {
    return repository.getMonthlyExpenses(params.year, params.month);
  }
}
