import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

/// Implementation of the Transaction Repository using API
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions() async {
    try {
      final transactions = await remoteDataSource.getAllTransactions();
      return Right(transactions.map((t) => t.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByType(
    TransactionType type,
  ) async {
    try {
      // API doesn't have filter by type, so we filter locally
      final transactions = await remoteDataSource.getAllTransactions();
      final filtered = transactions.where((t) => t.type == type).toList();
      return Right(filtered.map((t) => t.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // API doesn't have date filter, so we filter locally
      final transactions = await remoteDataSource.getAllTransactions();
      final filtered = transactions.where((t) =>
        t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      return Right(filtered.map((t) => t.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getRecentTransactions({
    int limit = 5,
  }) async {
    try {
      final transactions = await remoteDataSource.getAllTransactions();
      // Sort by date descending and take limit
      transactions.sort((a, b) => b.date.compareTo(a.date));
      final recent = transactions.take(limit).toList();
      return Right(recent.map((t) => t.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity?>> getTransactionById(String id) async {
    try {
      final transaction = await remoteDataSource.getTransactionById(id);
      return Right(transaction?.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addTransaction(TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await remoteDataSource.createTransaction(model);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(TransactionEntity transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      await remoteDataSource.updateTransaction(model);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await remoteDataSource.deleteTransaction(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getBalance() async {
    try {
      final balanceResponse = await remoteDataSource.getBalance();
      return Right(balanceResponse.balance);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalIncome() async {
    try {
      final balanceResponse = await remoteDataSource.getBalance();
      return Right(balanceResponse.totalIncome);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpenses() async {
    try {
      final balanceResponse = await remoteDataSource.getBalance();
      return Right(balanceResponse.totalExpenses);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getMonthlyIncome(int year, int month) async {
    try {
      // Filter transactions for the month
      final transactions = await remoteDataSource.getAllTransactions();
      final monthlyIncome = transactions
          .where((t) =>
              t.type == TransactionType.income &&
              t.date.year == year &&
              t.date.month == month)
          .fold<double>(0, (sum, t) => sum + t.amount);
      return Right(monthlyIncome);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getMonthlyExpenses(int year, int month) async {
    try {
      // Filter transactions for the month
      final transactions = await remoteDataSource.getAllTransactions();
      final monthlyExpenses = transactions
          .where((t) =>
              t.type == TransactionType.expense &&
              t.date.year == year &&
              t.date.month == month)
          .fold<double>(0, (sum, t) => sum + t.amount);
      return Right(monthlyExpenses);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchAllTransactions() {
    // API doesn't support real-time updates, so we just return a single value
    return Stream.fromFuture(getAllTransactions());
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchRecentTransactions({
    int limit = 5,
  }) {
    // API doesn't support real-time updates, so we just return a single value
    return Stream.fromFuture(getRecentTransactions(limit: limit));
  }
}
