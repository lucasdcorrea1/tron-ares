import 'package:equatable/equatable.dart';

/// Types of scheduled events
enum ScheduleType {
  income,   // Receita agendada
  expense,  // Despesa agendada
  bill,     // Conta a pagar
  reminder, // Lembrete geral
}

/// Entity representing a scheduled item/event
class ScheduleEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final DateTime? endDate;
  final bool isAllDay;
  final bool isCompleted;
  final bool hasReminder;
  final String? category;
  final ScheduleType type;
  final double? amount;
  final bool isRecurring;
  final String? recurrenceRule;
  final String? googleEventId;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleEntity({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.endDate,
    this.isAllDay = false,
    this.isCompleted = false,
    this.hasReminder = true,
    this.category,
    this.type = ScheduleType.reminder,
    this.amount,
    this.isRecurring = false,
    this.recurrenceRule,
    this.googleEventId,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this schedule is in the past
  bool get isPast => date.isBefore(DateTime.now());

  /// Check if this schedule is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if this is a financial event
  bool get isFinancial => type == ScheduleType.income ||
                          type == ScheduleType.expense ||
                          type == ScheduleType.bill;

  /// Legacy getter for compatibility
  DateTime get dateTime => date;

  /// Create a copy with updated values
  ScheduleEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    bool? isAllDay,
    bool? isCompleted,
    bool? hasReminder,
    String? category,
    ScheduleType? type,
    double? amount,
    bool? isRecurring,
    String? recurrenceRule,
    String? googleEventId,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      isCompleted: isCompleted ?? this.isCompleted,
      hasReminder: hasReminder ?? this.hasReminder,
      category: category ?? this.category,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      googleEventId: googleEventId ?? this.googleEventId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        date,
        endDate,
        isAllDay,
        isCompleted,
        hasReminder,
        category,
        type,
        amount,
        isRecurring,
        recurrenceRule,
        googleEventId,
        isSynced,
        createdAt,
        updatedAt,
      ];
}
