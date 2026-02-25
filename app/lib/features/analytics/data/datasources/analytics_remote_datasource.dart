import 'package:dio/dio.dart';

import '../models/stats_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<ProfileStatsModel> getProfileStats();
  Future<Map<String, dynamic>> getExpenseBreakdown({String period = 'month'});
  Future<Map<String, dynamic>> getIncomeBreakdown({String period = 'month'});
  Future<List<Map<String, dynamic>>> getDailyStats({int days = 30});
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final Dio dio;

  AnalyticsRemoteDataSourceImpl({required this.dio});

  @override
  Future<ProfileStatsModel> getProfileStats() async {
    final response = await dio.get('/profile/stats');
    return ProfileStatsModel.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> getExpenseBreakdown({String period = 'month'}) async {
    final response = await dio.get(
      '/profile/stats/breakdown',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getIncomeBreakdown({String period = 'month'}) async {
    final response = await dio.get(
      '/profile/stats/income',
      queryParameters: {'period': period},
    );
    return response.data;
  }

  @override
  Future<List<Map<String, dynamic>>> getDailyStats({int days = 30}) async {
    final response = await dio.get(
      '/profile/stats/daily',
      queryParameters: {'days': days},
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}
