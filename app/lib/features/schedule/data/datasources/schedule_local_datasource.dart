import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/schedule_entity.dart';

/// Local data source for schedule operations
abstract class ScheduleLocalDataSource {
  Future<List<ScheduleEntity>> getAllSchedules();
  Future<List<ScheduleEntity>> getSchedulesForDate(DateTime date);
  Future<List<ScheduleEntity>> getUpcomingSchedules({int limit = 10});
  Future<ScheduleEntity?> getScheduleById(String id);
  Future<void> createSchedule(ScheduleEntity schedule);
  Future<void> updateSchedule(ScheduleEntity schedule);
  Future<void> deleteSchedule(String id);
  Future<void> toggleCompletion(String id, bool isCompleted);
  Stream<List<ScheduleEntity>> watchAllSchedules();
  Stream<List<ScheduleEntity>> watchSchedulesForDate(DateTime date);
}

/// Implementation of ScheduleLocalDataSource using Drift
class ScheduleLocalDataSourceImpl implements ScheduleLocalDataSource {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ScheduleLocalDataSourceImpl(this._db);

  @override
  Future<List<ScheduleEntity>> getAllSchedules() async {
    final schedules = await _db.getAllSchedules();
    return schedules.map(_scheduleToEntity).toList();
  }

  @override
  Future<List<ScheduleEntity>> getSchedulesForDate(DateTime date) async {
    final schedules = await _db.getSchedulesForDate(date);
    return schedules.map(_scheduleToEntity).toList();
  }

  @override
  Future<List<ScheduleEntity>> getUpcomingSchedules({int limit = 10}) async {
    final schedules = await _db.getUpcomingSchedules(limit: limit);
    return schedules.map(_scheduleToEntity).toList();
  }

  @override
  Future<ScheduleEntity?> getScheduleById(String id) async {
    final schedule = await _db.getScheduleById(id);
    return schedule != null ? _scheduleToEntity(schedule) : null;
  }

  @override
  Future<void> createSchedule(ScheduleEntity schedule) async {
    await _db.insertSchedule(SchedulesCompanion(
      id: Value(schedule.id.isEmpty ? _uuid.v4() : schedule.id),
      title: Value(schedule.title),
      description: Value(schedule.description),
      scheduledAt: Value(schedule.dateTime),
      isCompleted: Value(schedule.isCompleted),
      hasReminder: Value(schedule.hasReminder),
      category: Value(schedule.category),
      createdAt: Value(schedule.createdAt),
      updatedAt: Value(schedule.updatedAt),
    ));
  }

  @override
  Future<void> updateSchedule(ScheduleEntity schedule) async {
    await _db.updateSchedule(SchedulesCompanion(
      id: Value(schedule.id),
      title: Value(schedule.title),
      description: Value(schedule.description),
      scheduledAt: Value(schedule.dateTime),
      isCompleted: Value(schedule.isCompleted),
      hasReminder: Value(schedule.hasReminder),
      category: Value(schedule.category),
      updatedAt: Value(DateTime.now()),
    ));
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _db.deleteSchedule(id);
  }

  @override
  Future<void> toggleCompletion(String id, bool isCompleted) async {
    await _db.toggleScheduleCompletion(id, isCompleted);
  }

  @override
  Stream<List<ScheduleEntity>> watchAllSchedules() {
    return _db.watchAllSchedules().map(
          (schedules) => schedules.map(_scheduleToEntity).toList(),
        );
  }

  @override
  Stream<List<ScheduleEntity>> watchSchedulesForDate(DateTime date) {
    return _db.watchSchedulesForDate(date).map(
          (schedules) => schedules.map(_scheduleToEntity).toList(),
        );
  }

  // Helper method
  ScheduleEntity _scheduleToEntity(Schedule schedule) {
    return ScheduleEntity(
      id: schedule.id,
      title: schedule.title,
      description: schedule.description,
      date: schedule.scheduledAt,
      isCompleted: schedule.isCompleted,
      hasReminder: schedule.hasReminder,
      category: schedule.category,
      createdAt: schedule.createdAt,
      updatedAt: schedule.updatedAt,
    );
  }
}
