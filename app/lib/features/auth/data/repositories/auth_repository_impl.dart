import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ApiClient apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.apiClient,
  });

  @override
  Future<Either<Failure, AuthResult>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        name: name,
      );
      final result = await remoteDataSource.register(request);
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao criar conta: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final result = await remoteDataSource.login(request);
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao fazer login: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> getCurrentUser() async {
    try {
      final result = await remoteDataSource.getCurrentUser();
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao buscar usuário: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await apiClient.clearToken();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Erro ao fazer logout: $e'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return await apiClient.hasToken();
  }

  @override
  Future<Either<Failure, ProfileEntity>> uploadAvatar(File imageFile) async {
    try {
      final result = await remoteDataSource.uploadAvatar(imageFile);
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao fazer upload: $e'));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? name,
    String? bio,
  }) async {
    try {
      final request = UpdateProfileRequest(name: name, bio: bio);
      final result = await remoteDataSource.updateProfile(request);
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erro ao atualizar perfil: $e'));
    }
  }
}
