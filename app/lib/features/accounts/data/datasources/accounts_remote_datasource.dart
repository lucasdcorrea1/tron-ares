import 'package:dio/dio.dart';

import '../models/account_model.dart';

abstract class AccountsRemoteDataSource {
  Future<List<ConnectedAccountModel>> getAccounts();
  Future<ConnectedAccountModel> getAccount(String id);
  Future<ConnectedAccountModel> createAccount(CreateAccountRequest request);
  Future<ConnectedAccountModel> updateAccount(String id, Map<String, dynamic> data);
  Future<void> deleteAccount(String id);
  Future<ConnectedAccountModel> syncBalance(String id, double balance);
  Future<Map<String, dynamic>> getAccountsSummary();
}

class AccountsRemoteDataSourceImpl implements AccountsRemoteDataSource {
  final Dio dio;

  AccountsRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ConnectedAccountModel>> getAccounts() async {
    final response = await dio.get('/accounts');
    final List<dynamic> data = response.data;
    return data.map((json) => ConnectedAccountModel.fromJson(json)).toList();
  }

  @override
  Future<ConnectedAccountModel> getAccount(String id) async {
    final response = await dio.get('/accounts/$id');
    return ConnectedAccountModel.fromJson(response.data);
  }

  @override
  Future<ConnectedAccountModel> createAccount(CreateAccountRequest request) async {
    final response = await dio.post('/accounts', data: request.toJson());
    return ConnectedAccountModel.fromJson(response.data);
  }

  @override
  Future<ConnectedAccountModel> updateAccount(String id, Map<String, dynamic> data) async {
    final response = await dio.put('/accounts/$id', data: data);
    return ConnectedAccountModel.fromJson(response.data);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await dio.delete('/accounts/$id');
  }

  @override
  Future<ConnectedAccountModel> syncBalance(String id, double balance) async {
    final response = await dio.post(
      '/accounts/$id/sync',
      data: {'balance': balance},
    );
    return ConnectedAccountModel.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> getAccountsSummary() async {
    final response = await dio.get('/accounts/summary');
    return response.data;
  }
}
