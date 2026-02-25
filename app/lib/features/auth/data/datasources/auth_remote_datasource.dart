import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResultModel> register(RegisterRequest request);
  Future<AuthResultModel> login(LoginRequest request);
  Future<AuthResultModel> getCurrentUser();
  Future<ProfileModel> uploadAvatar(File imageFile);
  Future<ProfileModel> updateProfile(UpdateProfileRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthResultModel> register(RegisterRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/register',
        data: request.toJson(),
      );
      final result = AuthResultModel.fromJson(response.data);
      await apiClient.saveToken(result.token);
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<AuthResultModel> login(LoginRequest request) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      final result = AuthResultModel.fromJson(response.data);
      await apiClient.saveToken(result.token);
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<AuthResultModel> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get('/auth/me');
      // /me doesn't return token, so we create a mock one
      final data = response.data as Map<String, dynamic>;
      data['token'] = ''; // Token already saved
      return AuthResultModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<ProfileModel> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
        ),
      });

      final response = await apiClient.dio.post(
        '/profile/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<ProfileModel> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await apiClient.dio.put(
        '/profile',
        data: request.toJson(),
      );

      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
