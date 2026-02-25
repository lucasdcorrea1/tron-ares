import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Transactions table definition
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get description => text().withLength(min: 1, max: 255)();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Debts table definition
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get initialAmount => real()();
  RealColumn get currentAmount => real()();
  RealColumn get interestRate => real()(); // Monthly rate (0.01 = 1%)
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Debt entries table (payments and interest charges)
class DebtEntries extends Table {
  TextColumn get id => text()();
  TextColumn get debtId => text().references(Debts, #id)();
  TextColumn get type => text()(); // 'interest' or 'payment'
  RealColumn get amount => real()();
  RealColumn get balanceBefore => real()();
  RealColumn get balanceAfter => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Schedules table definition
class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get hasReminder => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Main database class for the Imperium app
@DriftDatabase(tables: [Transactions, Debts, DebtEntries, Schedules])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(debts);
          await m.createTable(debtEntries);
        }
        if (from < 3) {
          await m.createTable(schedules);
        }
      },
    );
  }

  // ==================== Transaction operations ====================

  /// Get all transactions ordered by date (most recent first)
  Future<List<Transaction>> getAllTransactions() async {
    return (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transactions by type
  Future<List<Transaction>> getTransactionsByType(String type) async {
    return (select(transactions)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get transactions within a date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(startDate) &
              t.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Get recent transactions (limited)
  Future<List<Transaction>> getRecentTransactions({int limit = 5}) async {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  /// Get a single transaction by ID
  Future<Transaction?> getTransactionById(String id) async {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new transaction
  Future<void> insertTransaction(TransactionsCompanion transaction) async {
    await into(transactions).insert(transaction);
  }

  /// Update an existing transaction
  Future<void> updateTransaction(TransactionsCompanion transaction) async {
    await (update(transactions)..where((t) => t.id.equals(transaction.id.value)))
        .write(transaction);
  }

  /// Delete a transaction by ID
  Future<void> deleteTransaction(String id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Get total income
  Future<double> getTotalIncome() async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      variables: [Variable.withString('income')],
    ).getSingleOrNull();

    return (result?.data['total'] as double?) ?? 0.0;
  }

  /// Get total expenses
  Future<double> getTotalExpenses() async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ?',
      variables: [Variable.withString('expense')],
    ).getSingleOrNull();

    return (result?.data['total'] as double?) ?? 0.0;
  }

  /// Get balance (income - expenses)
  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expenses = await getTotalExpenses();
    return income - expenses;
  }

  /// Get income for a specific month
  Future<double> getMonthlyIncome(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final result = await customSelect(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      variables: [
        Variable.withString('income'),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
    ).getSingleOrNull();

    return (result?.data['total'] as double?) ?? 0.0;
  }

  /// Get expenses for a specific month
  Future<double> getMonthlyExpenses(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final result = await customSelect(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      variables: [
        Variable.withString('expense'),
        Variable.withDateTime(startDate),
        Variable.withDateTime(endDate),
      ],
    ).getSingleOrNull();

    return (result?.data['total'] as double?) ?? 0.0;
  }

  /// Watch all transactions as a stream
  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Watch recent transactions as a stream
  Stream<List<Transaction>> watchRecentTransactions({int limit = 5}) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  // ==================== Debt operations ====================

  /// Get all active debts
  Future<List<Debt>> getAllDebts() async {
    return (select(debts)
          ..where((d) => d.isActive.equals(true))
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .get();
  }

  /// Get a single debt by ID
  Future<Debt?> getDebtById(String id) async {
    return (select(debts)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new debt
  Future<void> insertDebt(DebtsCompanion debt) async {
    await into(debts).insert(debt);
  }

  /// Update a debt
  Future<void> updateDebt(DebtsCompanion debt) async {
    await (update(debts)..where((d) => d.id.equals(debt.id.value))).write(debt);
  }

  /// Delete a debt and its entries
  Future<void> deleteDebt(String id) async {
    await (delete(debtEntries)..where((e) => e.debtId.equals(id))).go();
    await (delete(debts)..where((d) => d.id.equals(id))).go();
  }

  /// Get total debt amount
  Future<double> getTotalDebt() async {
    final result = await customSelect(
      'SELECT SUM(current_amount) as total FROM debts WHERE is_active = 1',
    ).getSingleOrNull();

    return (result?.data['total'] as double?) ?? 0.0;
  }

  /// Watch all debts as a stream
  Stream<List<Debt>> watchAllDebts() {
    return (select(debts)
          ..where((d) => d.isActive.equals(true))
          ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
        .watch();
  }

  // ==================== Debt Entry operations ====================

  /// Get all entries for a debt
  Future<List<DebtEntry>> getEntriesForDebt(String debtId) async {
    return (select(debtEntries)
          ..where((e) => e.debtId.equals(debtId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  /// Get entries for a debt within date range
  Future<List<DebtEntry>> getEntriesForDebtInRange(
    String debtId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return (select(debtEntries)
          ..where((e) =>
              e.debtId.equals(debtId) &
              e.date.isBiggerOrEqualValue(startDate) &
              e.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  /// Insert a debt entry
  Future<void> insertDebtEntry(DebtEntriesCompanion entry) async {
    await into(debtEntries).insert(entry);
  }

  /// Get the last entry date for a debt
  Future<DateTime?> getLastEntryDate(String debtId) async {
    final result = await (select(debtEntries)
          ..where((e) => e.debtId.equals(debtId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)])
          ..limit(1))
        .getSingleOrNull();

    return result?.date;
  }

  /// Check if interest was applied for a specific month
  Future<bool> wasInterestAppliedForMonth(
    String debtId,
    int year,
    int month,
  ) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final result = await (select(debtEntries)
          ..where((e) =>
              e.debtId.equals(debtId) &
              e.type.equals('interest') &
              e.date.isBiggerOrEqualValue(startDate) &
              e.date.isSmallerOrEqualValue(endDate)))
        .getSingleOrNull();

    return result != null;
  }

  /// Watch entries for a debt
  Stream<List<DebtEntry>> watchEntriesForDebt(String debtId) {
    return (select(debtEntries)
          ..where((e) => e.debtId.equals(debtId))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .watch();
  }

  // ==================== Schedule operations ====================

  /// Get all schedules ordered by date
  Future<List<Schedule>> getAllSchedules() async {
    return (select(schedules)..orderBy([(s) => OrderingTerm.asc(s.scheduledAt)]))
        .get();
  }

  /// Get schedules for a specific date
  Future<List<Schedule>> getSchedulesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (select(schedules)
          ..where((s) =>
              s.scheduledAt.isBiggerOrEqualValue(startOfDay) &
              s.scheduledAt.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(s) => OrderingTerm.asc(s.scheduledAt)]))
        .get();
  }

  /// Get upcoming schedules (not completed, future or today)
  Future<List<Schedule>> getUpcomingSchedules({int limit = 10}) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return (select(schedules)
          ..where((s) =>
              s.isCompleted.equals(false) &
              s.scheduledAt.isBiggerOrEqualValue(startOfToday))
          ..orderBy([(s) => OrderingTerm.asc(s.scheduledAt)])
          ..limit(limit))
        .get();
  }

  /// Get a single schedule by ID
  Future<Schedule?> getScheduleById(String id) async {
    return (select(schedules)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new schedule
  Future<void> insertSchedule(SchedulesCompanion schedule) async {
    await into(schedules).insert(schedule);
  }

  /// Update a schedule
  Future<void> updateSchedule(SchedulesCompanion schedule) async {
    await (update(schedules)..where((s) => s.id.equals(schedule.id.value)))
        .write(schedule);
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String id) async {
    await (delete(schedules)..where((s) => s.id.equals(id))).go();
  }

  /// Toggle schedule completion
  Future<void> toggleScheduleCompletion(String id, bool isCompleted) async {
    await (update(schedules)..where((s) => s.id.equals(id))).write(
      SchedulesCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Watch all schedules
  Stream<List<Schedule>> watchAllSchedules() {
    return (select(schedules)..orderBy([(s) => OrderingTerm.asc(s.scheduledAt)]))
        .watch();
  }

  /// Watch schedules for a specific date
  Stream<List<Schedule>> watchSchedulesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (select(schedules)
          ..where((s) =>
              s.scheduledAt.isBiggerOrEqualValue(startOfDay) &
              s.scheduledAt.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(s) => OrderingTerm.asc(s.scheduledAt)]))
        .watch();
  }
}

/// Opens the database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'imperium.db'));
    return NativeDatabase.createInBackground(file);
  });
}
