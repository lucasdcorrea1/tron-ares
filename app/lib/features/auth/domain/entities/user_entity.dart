import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, createdAt];
}

class ProfileEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? avatar;
  final String? bio;
  final ProfileSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.bio,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, name, avatar, bio, settings, createdAt, updatedAt];
}

class ProfileSettings extends Equatable {
  final String currency;
  final String language;

  const ProfileSettings({
    required this.currency,
    required this.language,
  });

  @override
  List<Object?> get props => [currency, language];
}

class AuthResult extends Equatable {
  final UserEntity user;
  final ProfileEntity profile;
  final String token;

  const AuthResult({
    required this.user,
    required this.profile,
    required this.token,
  });

  @override
  List<Object?> get props => [user, profile, token];
}
