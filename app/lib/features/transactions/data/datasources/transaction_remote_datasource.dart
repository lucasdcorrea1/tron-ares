import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/transaction_model.dart';

/// Balance response from API
class BalanceResponse {
  final double balance;
  final double totalIncome;
  final double totalExpenses;

  BalanceResponse({
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
  });

  factory BalanceResponse.fromJson(Map<String, dynamic> json) {
    return BalanceResponse(
      balance: (json['balance'] as num).toDouble(),
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
    );
  }
}

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<TransactionModel?> getTransactionById(String id);
  Future<TransactionModel> createTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<BalanceResponse> getBalance();
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final response = await apiClient.dio.get('/transactions');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final response = await apiClient.dio.get('/transactions/$id');
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      final response = await apiClient.dio.post(
        '/transactions',
        data: transaction.toApiJson(),
      );
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TransactionModel> updateTransaction(TransactionModel transaction) async {
    try {
      final response = await apiClient.dio.put(
        '/transactions/${transaction.id}',
        data: transaction.toApiJson(),
      );
      return TransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await apiClient.dio.delete('/transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<BalanceResponse> getBalance() async {
    try {
      final response = await apiClient.dio.get('/transactions/balance');
      return BalanceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
