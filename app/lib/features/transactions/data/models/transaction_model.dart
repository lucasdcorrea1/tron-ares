import '../../domain/entities/transaction_entity.dart';

/// Transaction Model - Data layer
/// This class is responsible for converting between the database representation
/// and the domain entity
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.type,
    required super.category,
    required super.date,
    required super.createdAt,
  });

  /// Create from database map (Drift)
  factory TransactionModel.fromDatabase(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
      type: TransactionTypeExtension.fromString(map['type'] as String),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Create from domain entity
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      description: entity.description,
      amount: entity.amount,
      type: entity.type,
      category: entity.category,
      date: entity.date,
      createdAt: entity.createdAt,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.value,
      'category': category,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.value,
      'category': category,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON (API format with snake_case)
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionTypeExtension.fromString(json['type'] as String),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON for API (snake_case)
  Map<String, dynamic> toApiJson() {
    return {
      'description': description,
      'amount': amount,
      'type': type.value,
      'category': category,
      'date': date.toUtc().toIso8601String(),
    };
  }

  /// Convert to domain entity
  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      description: description,
      amount: amount,
      type: type,
      category: category,
      date: date,
      createdAt: createdAt,
    );
  }
}
