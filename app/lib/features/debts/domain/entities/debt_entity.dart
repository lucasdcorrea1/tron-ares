import 'package:equatable/equatable.dart';

/// Types of debt entries
enum DebtEntryType {
  /// Monthly interest charge
  interest,
  /// Payment made to reduce debt
  payment,
}

/// Entity representing a debt (like car loan, credit card, etc.)
class DebtEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double initialAmount;
  final double currentAmount;
  final double interestRate; // Monthly interest rate (e.g., 0.01 for 1%)
  final DateTime startDate;
  final DateTime? endDate; // When debt is fully paid
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.initialAmount,
    required this.currentAmount,
    required this.interestRate,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate the interest amount for the current balance
  double get monthlyInterestAmount => currentAmount * interestRate;

  /// Check if debt is fully paid
  bool get isPaid => currentAmount <= 0;

  /// Create a copy with updated values
  DebtEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? initialAmount,
    double? currentAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      initialAmount: initialAmount ?? this.initialAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        initialAmount,
        currentAmount,
        interestRate,
        startDate,
        endDate,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Entity representing a debt entry (payment or interest charge)
class DebtEntryEntity extends Equatable {
  final String id;
  final String debtId;
  final DebtEntryType type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const DebtEntryEntity({
    required this.id,
    required this.debtId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.date,
    this.note,
    required this.createdAt,
  });

  /// Check if this is a payment entry
  bool get isPayment => type == DebtEntryType.payment;

  /// Check if this is an interest entry
  bool get isInterest => type == DebtEntryType.interest;

  @override
  List<Object?> get props => [
        id,
        debtId,
        type,
        amount,
        balanceBefore,
        balanceAfter,
        date,
        note,
        createdAt,
      ];
}
