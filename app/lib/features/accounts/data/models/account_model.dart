import '../../domain/entities/account_entity.dart';

class ConnectedAccountModel extends ConnectedAccount {
  const ConnectedAccountModel({
    required super.id,
    required super.userId,
    required super.provider,
    required super.accountType,
    required super.accountName,
    required super.lastFour,
    required super.balance,
    required super.color,
    required super.icon,
    required super.isActive,
    required super.lastSync,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ConnectedAccountModel.fromJson(Map<String, dynamic> json) {
    return ConnectedAccountModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      accountType: json['account_type'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      lastFour: json['last_four'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? '#808080',
      icon: json['icon'] as String? ?? 'bank',
      isActive: json['is_active'] as bool? ?? true,
      lastSync: DateTime.tryParse(json['last_sync'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider,
      'account_type': accountType,
      'account_name': accountName,
      'last_four': lastFour,
      'balance': balance,
      'color': color,
      'icon': icon,
      'is_active': isActive,
      'last_sync': lastSync.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CreateAccountRequest {
  final String provider;
  final String accountType;
  final String accountName;
  final String lastFour;
  final double balance;
  final String? color;
  final String? icon;

  CreateAccountRequest({
    required this.provider,
    required this.accountType,
    required this.accountName,
    required this.lastFour,
    required this.balance,
    this.color,
    this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'account_type': accountType,
      'account_name': accountName,
      'last_four': lastFour,
      'balance': balance,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
    };
  }
}
