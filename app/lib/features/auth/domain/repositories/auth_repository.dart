import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResult>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, AuthResult>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResult>> getCurrentUser();

  Future<Either<Failure, void>> logout();

  Future<bool> isLoggedIn();

  Future<Either<Failure, ProfileEntity>> uploadAvatar(File imageFile);

  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? name,
    String? bio,
  });
}
