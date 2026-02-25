import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/debt_entity.dart';

/// Local data source for debt operations
abstract class DebtLocalDataSource {
  Future<List<DebtEntity>> getAllDebts();
  Future<DebtEntity?> getDebtById(String id);
  Future<void> createDebt(DebtEntity debt);
  Future<void> updateDebt(DebtEntity debt);
  Future<void> deleteDebt(String id);
  Future<double> getTotalDebt();

  Future<List<DebtEntryEntity>> getEntriesForDebt(String debtId);
  Future<void> addPayment(String debtId, double amount, DateTime date, String? note);
  Future<void> applyInterest(String debtId, DateTime date);
  Future<void> applyMissingInterests(String debtId);
  Future<bool> wasInterestAppliedForMonth(String debtId, int year, int month);

  Stream<List<DebtEntity>> watchAllDebts();
  Stream<List<DebtEntryEntity>> watchEntriesForDebt(String debtId);
}

/// Implementation of DebtLocalDataSource using Drift
class DebtLocalDataSourceImpl implements DebtLocalDataSource {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DebtLocalDataSourceImpl(this._db);

  @override
  Future<List<DebtEntity>> getAllDebts() async {
    final debts = await _db.getAllDebts();
    return debts.map(_debtToEntity).toList();
  }

  @override
  Future<DebtEntity?> getDebtById(String id) async {
    final debt = await _db.getDebtById(id);
    return debt != null ? _debtToEntity(debt) : null;
  }

  @override
  Future<void> createDebt(DebtEntity debt) async {
    await _db.insertDebt(DebtsCompanion(
      id: Value(debt.id),
      name: Value(debt.name),
      description: Value(debt.description),
      initialAmount: Value(debt.initialAmount),
      currentAmount: Value(debt.currentAmount),
      interestRate: Value(debt.interestRate),
      startDate: Value(debt.startDate),
      endDate: Value(debt.endDate),
      isActive: Value(debt.isActive),
      createdAt: Value(debt.createdAt),
      updatedAt: Value(debt.updatedAt),
    ));
  }

  @override
  Future<void> updateDebt(DebtEntity debt) async {
    await _db.updateDebt(DebtsCompanion(
      id: Value(debt.id),
      name: Value(debt.name),
      description: Value(debt.description),
      initialAmount: Value(debt.initialAmount),
      currentAmount: Value(debt.currentAmount),
      interestRate: Value(debt.interestRate),
      startDate: Value(debt.startDate),
      endDate: Value(debt.endDate),
      isActive: Value(debt.isActive),
      createdAt: Value(debt.createdAt),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _db.deleteDebt(id);
  }

  @override
  Future<double> getTotalDebt() async {
    return await _db.getTotalDebt();
  }

  @override
  Future<List<DebtEntryEntity>> getEntriesForDebt(String debtId) async {
    final entries = await _db.getEntriesForDebt(debtId);
    return entries.map(_entryToEntity).toList();
  }

  @override
  Future<void> addPayment(
    String debtId,
    double amount,
    DateTime date,
    String? note,
  ) async {
    // First apply any missing interest up to the payment date
    await applyMissingInterests(debtId);

    final debt = await _db.getDebtById(debtId);
    if (debt == null) return;

    final balanceBefore = debt.currentAmount;

    // Cap the payment at the current balance (don't allow negative balance)
    final actualPayment = amount > balanceBefore ? balanceBefore : amount;
    final balanceAfter = balanceBefore - actualPayment;

    // Insert payment entry
    await _db.insertDebtEntry(DebtEntriesCompanion(
      id: Value(_uuid.v4()),
      debtId: Value(debtId),
      type: const Value('payment'),
      amount: Value(actualPayment),
      balanceBefore: Value(balanceBefore),
      balanceAfter: Value(balanceAfter),
      date: Value(date),
      note: Value(balanceAfter <= 0 ? (note ?? 'Quitação da dívida! 🎉') : note),
      createdAt: Value(DateTime.now()),
    ));

    // Update debt current amount
    await _db.updateDebt(DebtsCompanion(
      id: Value(debtId),
      currentAmount: Value(balanceAfter),
      updatedAt: Value(DateTime.now()),
      isActive: Value(balanceAfter > 0),
      endDate: balanceAfter <= 0 ? Value(DateTime.now()) : const Value.absent(),
    ));
  }

  @override
  Future<void> applyInterest(String debtId, DateTime date) async {
    final debt = await _db.getDebtById(debtId);
    if (debt == null || !debt.isActive) return;

    final balanceBefore = debt.currentAmount;
    final interestAmount = balanceBefore * debt.interestRate;
    final balanceAfter = balanceBefore + interestAmount;

    // Insert interest entry
    await _db.insertDebtEntry(DebtEntriesCompanion(
      id: Value(_uuid.v4()),
      debtId: Value(debtId),
      type: const Value('interest'),
      amount: Value(interestAmount),
      balanceBefore: Value(balanceBefore),
      balanceAfter: Value(balanceAfter),
      date: Value(date),
      note: Value('Juros ${(debt.interestRate * 100).toStringAsFixed(1)}% do mês'),
      createdAt: Value(DateTime.now()),
    ));

    // Update debt current amount
    await _db.updateDebt(DebtsCompanion(
      id: Value(debtId),
      currentAmount: Value(balanceAfter),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> applyMissingInterests(String debtId) async {
    final debt = await _db.getDebtById(debtId);
    if (debt == null || !debt.isActive) return;

    final now = DateTime.now();
    var checkDate = debt.startDate;

    // Iterate through each month from start date to now
    while (checkDate.isBefore(now)) {
      final lastDayOfMonth = DateTime(checkDate.year, checkDate.month + 1, 0);

      // Only apply interest if we've passed the last day of that month
      if (lastDayOfMonth.isBefore(now) ||
          (lastDayOfMonth.year == now.year &&
           lastDayOfMonth.month == now.month &&
           lastDayOfMonth.day == now.day)) {

        final wasApplied = await _db.wasInterestAppliedForMonth(
          debtId,
          checkDate.year,
          checkDate.month,
        );

        if (!wasApplied) {
          // Reload debt to get current balance
          final currentDebt = await _db.getDebtById(debtId);
          if (currentDebt == null || !currentDebt.isActive) break;

          final balanceBefore = currentDebt.currentAmount;
          final interestAmount = balanceBefore * currentDebt.interestRate;
          final balanceAfter = balanceBefore + interestAmount;

          await _db.insertDebtEntry(DebtEntriesCompanion(
            id: Value(_uuid.v4()),
            debtId: Value(debtId),
            type: const Value('interest'),
            amount: Value(interestAmount),
            balanceBefore: Value(balanceBefore),
            balanceAfter: Value(balanceAfter),
            date: Value(lastDayOfMonth),
            note: Value('Juros ${(currentDebt.interestRate * 100).toStringAsFixed(1)}% - ${_getMonthName(checkDate.month)}/${checkDate.year}'),
            createdAt: Value(DateTime.now()),
          ));

          await _db.updateDebt(DebtsCompanion(
            id: Value(debtId),
            currentAmount: Value(balanceAfter),
            updatedAt: Value(DateTime.now()),
          ));
        }
      }

      // Move to next month
      checkDate = DateTime(checkDate.year, checkDate.month + 1, 1);
    }
  }

  @override
  Future<bool> wasInterestAppliedForMonth(
    String debtId,
    int year,
    int month,
  ) async {
    return await _db.wasInterestAppliedForMonth(debtId, year, month);
  }

  @override
  Stream<List<DebtEntity>> watchAllDebts() {
    return _db.watchAllDebts().map(
          (debts) => debts.map(_debtToEntity).toList(),
        );
  }

  @override
  Stream<List<DebtEntryEntity>> watchEntriesForDebt(String debtId) {
    return _db.watchEntriesForDebt(debtId).map(
          (entries) => entries.map(_entryToEntity).toList(),
        );
  }

  // Helper methods

  DebtEntity _debtToEntity(Debt debt) {
    return DebtEntity(
      id: debt.id,
      name: debt.name,
      description: debt.description,
      initialAmount: debt.initialAmount,
      currentAmount: debt.currentAmount,
      interestRate: debt.interestRate,
      startDate: debt.startDate,
      endDate: debt.endDate,
      isActive: debt.isActive,
      createdAt: debt.createdAt,
      updatedAt: debt.updatedAt,
    );
  }

  DebtEntryEntity _entryToEntity(DebtEntry entry) {
    return DebtEntryEntity(
      id: entry.id,
      debtId: entry.debtId,
      type: entry.type == 'interest' ? DebtEntryType.interest : DebtEntryType.payment,
      amount: entry.amount,
      balanceBefore: entry.balanceBefore,
      balanceAfter: entry.balanceAfter,
      date: entry.date,
      note: entry.note,
      createdAt: entry.createdAt,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[month - 1];
  }
}
