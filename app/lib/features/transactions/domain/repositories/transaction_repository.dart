import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/transaction_entity.dart';

/// Transaction Repository contract (abstract class)
/// This defines the interface that the data layer must implement
/// Following Clean Architecture, the domain layer doesn't know about the data layer
abstract class TransactionRepository {
  /// Get all transactions
  Future<Either<Failure, List<TransactionEntity>>> getAllTransactions();

  /// Get transactions by type (income/expense)
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByType(
    TransactionType type,
  );

  /// Get transactions within a date range
  Future<Either<Failure, List<TransactionEntity>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get recent transactions (limited)
  Future<Either<Failure, List<TransactionEntity>>> getRecentTransactions({
    int limit = 5,
  });

  /// Get a single transaction by ID
  Future<Either<Failure, TransactionEntity?>> getTransactionById(String id);

  /// Add a new transaction
  Future<Either<Failure, void>> addTransaction(TransactionEntity transaction);

  /// Update an existing transaction
  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction);

  /// Delete a transaction
  Future<Either<Failure, void>> deleteTransaction(String id);

  /// Get total balance (income - expenses)
  Future<Either<Failure, double>> getBalance();

  /// Get total income
  Future<Either<Failure, double>> getTotalIncome();

  /// Get total expenses
  Future<Either<Failure, double>> getTotalExpenses();

  /// Get monthly income
  Future<Either<Failure, double>> getMonthlyIncome(int year, int month);

  /// Get monthly expenses
  Future<Either<Failure, double>> getMonthlyExpenses(int year, int month);

  /// Watch all transactions as a stream
  Stream<Either<Failure, List<TransactionEntity>>> watchAllTransactions();

  /// Watch recent transactions as a stream
  Stream<Either<Failure, List<TransactionEntity>>> watchRecentTransactions({
    int limit = 5,
  });
}
