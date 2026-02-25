import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

/// Use case for getting all transactions
class GetTransactionsUseCase
    implements UseCase<List<TransactionEntity>, NoParams> {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(NoParams params) {
    return repository.getAllTransactions();
  }
}

/// Use case for getting transactions by type
class GetTransactionsByTypeUseCase
    implements UseCase<List<TransactionEntity>, TransactionType> {
  final TransactionRepository repository;

  GetTransactionsByTypeUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(TransactionType type) {
    return repository.getTransactionsByType(type);
  }
}

/// Parameters for date range filtering
class DateRangeParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  const DateRangeParams({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Use case for getting transactions by date range
class GetTransactionsByDateRangeUseCase
    implements UseCase<List<TransactionEntity>, DateRangeParams> {
  final TransactionRepository repository;

  GetTransactionsByDateRangeUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(DateRangeParams params) {
    return repository.getTransactionsByDateRange(
      params.startDate,
      params.endDate,
    );
  }
}

/// Parameters for getting recent transactions
class RecentTransactionsParams extends Equatable {
  final int limit;

  const RecentTransactionsParams({this.limit = 5});

  @override
  List<Object?> get props => [limit];
}

/// Use case for getting recent transactions
class GetRecentTransactionsUseCase
    implements UseCase<List<TransactionEntity>, RecentTransactionsParams> {
  final TransactionRepository repository;

  GetRecentTransactionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TransactionEntity>>> call(
      RecentTransactionsParams params) {
    return repository.getRecentTransactions(limit: params.limit);
  }
}
