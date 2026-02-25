import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.userId,
    required super.name,
    super.avatar,
    super.bio,
    required super.settings,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      settings: ProfileSettingsModel.fromJson(json['settings'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'settings': (settings as ProfileSettingsModel).toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ProfileSettingsModel extends ProfileSettings {
  const ProfileSettingsModel({
    required super.currency,
    required super.language,
  });

  factory ProfileSettingsModel.fromJson(Map<String, dynamic> json) {
    return ProfileSettingsModel(
      currency: json['currency'] as String? ?? 'BRL',
      language: json['language'] as String? ?? 'pt-BR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'language': language,
    };
  }
}

class AuthResultModel extends AuthResult {
  const AuthResultModel({
    required UserModel user,
    required ProfileModel profile,
    required super.token,
  }) : super(user: user, profile: profile);

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    return AuthResultModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      profile: ProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class UpdateProfileRequest {
  final String? name;
  final String? bio;
  final String? currency;
  final String? language;

  const UpdateProfileRequest({
    this.name,
    this.bio,
    this.currency,
    this.language,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (bio != null) data['bio'] = bio;
    if (currency != null || language != null) {
      data['settings'] = {
        if (currency != null) 'currency': currency,
        if (language != null) 'language': language,
      };
    }
    return data;
  }
}
