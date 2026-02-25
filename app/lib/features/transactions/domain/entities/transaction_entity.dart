import 'package:equatable/equatable.dart';

/// Transaction type enum
enum TransactionType { income, expense }

/// Extension to convert TransactionType to/from string
extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        throw ArgumentError('Invalid transaction type: $value');
    }
  }
}

/// Transaction categories
enum TransactionCategory {
  food,
  transport,
  housing,
  leisure,
  health,
  education,
  salary,
  freelance,
  other,
}

/// Extension for TransactionCategory
extension TransactionCategoryExtension on TransactionCategory {
  String get value {
    switch (this) {
      case TransactionCategory.food:
        return 'food';
      case TransactionCategory.transport:
        return 'transport';
      case TransactionCategory.housing:
        return 'housing';
      case TransactionCategory.leisure:
        return 'leisure';
      case TransactionCategory.health:
        return 'health';
      case TransactionCategory.education:
        return 'education';
      case TransactionCategory.salary:
        return 'salary';
      case TransactionCategory.freelance:
        return 'freelance';
      case TransactionCategory.other:
        return 'other';
    }
  }

  static TransactionCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'food':
        return TransactionCategory.food;
      case 'transport':
        return TransactionCategory.transport;
      case 'housing':
        return TransactionCategory.housing;
      case 'leisure':
        return TransactionCategory.leisure;
      case 'health':
        return TransactionCategory.health;
      case 'education':
        return TransactionCategory.education;
      case 'salary':
        return TransactionCategory.salary;
      case 'freelance':
        return TransactionCategory.freelance;
      case 'other':
      default:
        return TransactionCategory.other;
    }
  }

  /// Get icon for the category (legacy - use iconData instead)
  String get icon {
    switch (this) {
      case TransactionCategory.food:
        return '🍔';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.housing:
        return '🏠';
      case TransactionCategory.leisure:
        return '🎮';
      case TransactionCategory.health:
        return '🏥';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.salary:
        return '💰';
      case TransactionCategory.freelance:
        return '💻';
      case TransactionCategory.other:
        return '📦';
    }
  }

  /// Get icon code point for the category (Material Icons)
  int get iconCodePoint {
    switch (this) {
      case TransactionCategory.food:
        return 0xe56c; // restaurant
      case TransactionCategory.transport:
        return 0xe1d7; // directions_car
      case TransactionCategory.housing:
        return 0xe88a; // home
      case TransactionCategory.leisure:
        return 0xea28; // sports_esports
      case TransactionCategory.health:
        return 0xe548; // favorite
      case TransactionCategory.education:
        return 0xe80c; // school
      case TransactionCategory.salary:
        return 0xe8a1; // account_balance_wallet
      case TransactionCategory.freelance:
        return 0xe30a; // computer
      case TransactionCategory.other:
        return 0xe8b8; // more_horiz
    }
  }

  /// Get color hex value for the category
  int get colorValue {
    switch (this) {
      case TransactionCategory.food:
        return 0xFFF97316; // Orange
      case TransactionCategory.transport:
        return 0xFF3B82F6; // Blue
      case TransactionCategory.housing:
        return 0xFF8B5CF6; // Violet
      case TransactionCategory.leisure:
        return 0xFFEC4899; // Pink
      case TransactionCategory.health:
        return 0xFFEF4444; // Red
      case TransactionCategory.education:
        return 0xFF06B6D4; // Cyan
      case TransactionCategory.salary:
        return 0xFF10B981; // Emerald
      case TransactionCategory.freelance:
        return 0xFF6366F1; // Indigo
      case TransactionCategory.other:
        return 0xFF64748B; // Slate
    }
  }
}

/// Transaction entity - Domain layer
/// This is a pure Dart class with no dependencies on Flutter or external packages
/// (except Equatable for value comparison)
class TransactionEntity extends Equatable {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  /// Create a copy with modified fields
  TransactionEntity copyWith({
    String? id,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if this is an income transaction
  bool get isIncome => type == TransactionType.income;

  /// Check if this is an expense transaction
  bool get isExpense => type == TransactionType.expense;

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        type,
        category,
        date,
        createdAt,
      ];
}
