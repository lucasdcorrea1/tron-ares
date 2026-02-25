import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/transaction_entity.dart';
import '../models/transaction_model.dart';

/// Local data source for transactions
/// This class handles all database operations for transactions
abstract class TransactionLocalDataSource {
  /// Get all transactions
  Future<List<TransactionModel>> getAllTransactions();

  /// Get transactions by type
  Future<List<TransactionModel>> getTransactionsByType(TransactionType type);

  /// Get transactions by date range
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get recent transactions
  Future<List<TransactionModel>> getRecentTransactions({int limit = 5});

  /// Get transaction by ID
  Future<TransactionModel?> getTransactionById(String id);

  /// Add transaction
  Future<void> addTransaction(TransactionModel transaction);

  /// Update transaction
  Future<void> updateTransaction(TransactionModel transaction);

  /// Delete transaction
  Future<void> deleteTransaction(String id);

  /// Get total balance
  Future<double> getBalance();

  /// Get total income
  Future<double> getTotalIncome();

  /// Get total expenses
  Future<double> getTotalExpenses();

  /// Get monthly income
  Future<double> getMonthlyIncome(int year, int month);

  /// Get monthly expenses
  Future<double> getMonthlyExpenses(int year, int month);

  /// Watch all transactions
  Stream<List<TransactionModel>> watchAllTransactions();

  /// Watch recent transactions
  Stream<List<TransactionModel>> watchRecentTransactions({int limit = 5});
}

/// Implementation of the local data source using Drift
class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final AppDatabase database;

  TransactionLocalDataSourceImpl(this.database);

  TransactionModel _transactionToModel(Transaction t) {
    return TransactionModel(
      id: t.id,
      description: t.description,
      amount: t.amount,
      type: TransactionTypeExtension.fromString(t.type),
      category: t.category,
      date: t.date,
      createdAt: t.createdAt,
    );
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final transactions = await database.getAllTransactions();
      return transactions.map(_transactionToModel).toList();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get transactions: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByType(
      TransactionType type) async {
    try {
      final transactions =
          await database.getTransactionsByType(type.value);
      return transactions.map(_transactionToModel).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get transactions by type: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final transactions = await database.getTransactionsByDateRange(
        startDate,
        endDate,
      );
      return transactions.map(_transactionToModel).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get transactions by date range: $e');
    }
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
    try {
      final transactions = await database.getRecentTransactions(limit: limit);
      return transactions.map(_transactionToModel).toList();
    } catch (e) {
      throw DatabaseException(
          message: 'Failed to get recent transactions: $e');
    }
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final transaction = await database.getTransactionById(id);
      if (transaction == null) return null;
      return _transactionToModel(transaction);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get transaction: $e');
    }
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await database.insertTransaction(
        TransactionsCompanion(
          id: Value(transaction.id),
          description: Value(transaction.description),
          amount: Value(transaction.amount),
          type: Value(transaction.type.value),
          category: Value(transaction.category),
          date: Value(transaction.date),
          createdAt: Value(transaction.createdAt),
        ),
      );
    } catch (e) {
      throw DatabaseException(message: 'Failed to add transaction: $e');
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await database.updateTransaction(
        TransactionsCompanion(
          id: Value(transaction.id),
          description: Value(transaction.description),
          amount: Value(transaction.amount),
          type: Value(transaction.type.value),
          category: Value(transaction.category),
          date: Value(transaction.date),
          createdAt: Value(transaction.createdAt),
        ),
      );
    } catch (e) {
      throw DatabaseException(message: 'Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await database.deleteTransaction(id);
    } catch (e) {
      throw DatabaseException(message: 'Failed to delete transaction: $e');
    }
  }

  @override
  Future<double> getBalance() async {
    try {
      return await database.getBalance();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get balance: $e');
    }
  }

  @override
  Future<double> getTotalIncome() async {
    try {
      return await database.getTotalIncome();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get total income: $e');
    }
  }

  @override
  Future<double> getTotalExpenses() async {
    try {
      return await database.getTotalExpenses();
    } catch (e) {
      throw DatabaseException(message: 'Failed to get total expenses: $e');
    }
  }

  @override
  Future<double> getMonthlyIncome(int year, int month) async {
    try {
      return await database.getMonthlyIncome(year, month);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get monthly income: $e');
    }
  }

  @override
  Future<double> getMonthlyExpenses(int year, int month) async {
    try {
      return await database.getMonthlyExpenses(year, month);
    } catch (e) {
      throw DatabaseException(message: 'Failed to get monthly expenses: $e');
    }
  }

  @override
  Stream<List<TransactionModel>> watchAllTransactions() {
    return database.watchAllTransactions().map(
          (transactions) => transactions.map(_transactionToModel).toList(),
        );
  }

  @override
  Stream<List<TransactionModel>> watchRecentTransactions({int limit = 5}) {
    return database.watchRecentTransactions(limit: limit).map(
          (transactions) => transactions.map(_transactionToModel).toList(),
        );
  }
}
