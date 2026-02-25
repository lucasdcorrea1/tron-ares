import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import '../../features/schedule/domain/entities/schedule_entity.dart';

/// Service for Google Calendar integration
class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarScope,
      calendar.CalendarApi.calendarEventsScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Get current user email
  String? get userEmail => _currentUser?.email;

  /// Get current user name
  String? get userName => _currentUser?.displayName;

  /// Get current user photo
  String? get userPhoto => _currentUser?.photoUrl;

  /// Initialize and check for existing sign in
  Future<bool> init() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initCalendarApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('GoogleCalendarService init error: $e');
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initCalendarApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('GoogleCalendarService signIn error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _calendarApi = null;
  }

  /// Initialize Calendar API
  Future<void> _initCalendarApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient != null) {
      _calendarApi = calendar.CalendarApi(httpClient);
    }
  }

  /// Get events from Google Calendar
  Future<List<ScheduleEntity>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    try {
      final now = DateTime.now();
      final timeMin = startDate ?? DateTime(now.year, now.month, 1);
      final timeMax = endDate ?? DateTime(now.year, now.month + 2, 0);

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: timeMin.toUtc(),
        timeMax: timeMax.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items?.map((event) => _eventToSchedule(event)).toList() ?? [];
    } catch (e) {
      debugPrint('GoogleCalendarService getEvents error: $e');
      rethrow;
    }
  }

  /// Create event in Google Calendar
  Future<ScheduleEntity> createEvent(ScheduleEntity schedule) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    try {
      final event = _scheduleToEvent(schedule);
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      return _eventToSchedule(createdEvent);
    } catch (e) {
      debugPrint('GoogleCalendarService createEvent error: $e');
      rethrow;
    }
  }

  /// Update event in Google Calendar
  Future<ScheduleEntity> updateEvent(ScheduleEntity schedule) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    if (schedule.googleEventId == null) {
      throw Exception('Event does not have Google Calendar ID');
    }

    try {
      final event = _scheduleToEvent(schedule);
      final updatedEvent = await _calendarApi!.events.update(
        event,
        'primary',
        schedule.googleEventId!,
      );
      return _eventToSchedule(updatedEvent);
    } catch (e) {
      debugPrint('GoogleCalendarService updateEvent error: $e');
      rethrow;
    }
  }

  /// Delete event from Google Calendar
  Future<void> deleteEvent(String googleEventId) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    try {
      await _calendarApi!.events.delete('primary', googleEventId);
    } catch (e) {
      debugPrint('GoogleCalendarService deleteEvent error: $e');
      rethrow;
    }
  }

  /// Sync local events with Google Calendar
  Future<SyncResult> syncEvents(List<ScheduleEntity> localEvents) async {
    if (_calendarApi == null) {
      throw Exception('Not signed in to Google Calendar');
    }

    final result = SyncResult();

    try {
      // Get Google events
      final googleEvents = await getEvents();
      final googleEventIds = googleEvents
          .where((e) => e.googleEventId != null)
          .map((e) => e.googleEventId!)
          .toSet();

      // Upload local events that don't exist in Google
      for (final local in localEvents) {
        if (local.googleEventId == null) {
          // New local event - create in Google
          final created = await createEvent(local);
          result.uploaded.add(created);
        } else if (!googleEventIds.contains(local.googleEventId)) {
          // Local event was deleted from Google - mark for deletion
          result.deletedFromGoogle.add(local);
        }
      }

      // Download Google events that don't exist locally
      final localEventIds = localEvents
          .where((e) => e.googleEventId != null)
          .map((e) => e.googleEventId!)
          .toSet();

      for (final google in googleEvents) {
        if (google.googleEventId != null &&
            !localEventIds.contains(google.googleEventId)) {
          result.downloaded.add(google);
        }
      }

      return result;
    } catch (e) {
      debugPrint('GoogleCalendarService syncEvents error: $e');
      rethrow;
    }
  }

  /// Convert Google Calendar Event to ScheduleEntity
  ScheduleEntity _eventToSchedule(calendar.Event event) {
    DateTime startDate;
    DateTime? endDate;
    bool isAllDay = false;

    if (event.start?.dateTime != null) {
      startDate = event.start!.dateTime!.toLocal();
      endDate = event.end?.dateTime?.toLocal();
    } else if (event.start?.date != null) {
      // All-day event - date is DateTime type
      startDate = event.start!.date!;
      isAllDay = true;
    } else {
      startDate = DateTime.now();
    }

    final now = DateTime.now();

    return ScheduleEntity(
      id: event.id ?? '',
      title: event.summary ?? 'Sem título',
      description: event.description,
      date: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      type: _parseEventType(event),
      amount: _parseAmount(event.description),
      isRecurring: event.recurrence != null && event.recurrence!.isNotEmpty,
      recurrenceRule: event.recurrence?.firstOrNull,
      googleEventId: event.id,
      isSynced: true,
      createdAt: event.created?.toLocal() ?? now,
      updatedAt: event.updated?.toLocal() ?? now,
    );
  }

  /// Convert ScheduleEntity to Google Calendar Event
  calendar.Event _scheduleToEvent(ScheduleEntity schedule) {
    final event = calendar.Event();
    event.summary = schedule.title;

    // Add amount to description if present
    String description = schedule.description ?? '';
    if (schedule.amount != null && schedule.amount! > 0) {
      description += '\n[Imperium: ${schedule.type.name} R\$ ${schedule.amount!.toStringAsFixed(2)}]';
    }
    event.description = description;

    if (schedule.isAllDay) {
      // For all-day events, use date (DateTime without time component)
      final startDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      final endDateValue = schedule.endDate ?? schedule.date.add(const Duration(days: 1));
      final endDate = DateTime(endDateValue.year, endDateValue.month, endDateValue.day);

      event.start = calendar.EventDateTime(date: startDate);
      event.end = calendar.EventDateTime(date: endDate);
    } else {
      event.start = calendar.EventDateTime(
        dateTime: schedule.date.toUtc(),
        timeZone: 'America/Sao_Paulo',
      );
      event.end = calendar.EventDateTime(
        dateTime: (schedule.endDate ?? schedule.date.add(const Duration(hours: 1))).toUtc(),
        timeZone: 'America/Sao_Paulo',
      );
    }

    // Add color based on type
    event.colorId = _getColorIdForType(schedule.type);

    if (schedule.recurrenceRule != null) {
      event.recurrence = [schedule.recurrenceRule!];
    }

    return event;
  }

  ScheduleType _parseEventType(calendar.Event event) {
    final description = event.description?.toLowerCase() ?? '';
    final summary = event.summary?.toLowerCase() ?? '';

    if (description.contains('[imperium: income') ||
        summary.contains('receita') ||
        summary.contains('salário') ||
        summary.contains('pagamento recebido')) {
      return ScheduleType.income;
    } else if (description.contains('[imperium: expense') ||
        summary.contains('conta') ||
        summary.contains('pagamento') ||
        summary.contains('fatura')) {
      return ScheduleType.expense;
    } else if (description.contains('[imperium: bill') ||
        summary.contains('vencimento')) {
      return ScheduleType.bill;
    }
    return ScheduleType.reminder;
  }

  double? _parseAmount(String? description) {
    if (description == null) return null;

    final regex = RegExp(r'R\$\s*([\d.,]+)');
    final match = regex.firstMatch(description);
    if (match != null) {
      final amountStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(amountStr);
    }
    return null;
  }

  String _getColorIdForType(ScheduleType type) {
    switch (type) {
      case ScheduleType.income:
        return '10'; // Green
      case ScheduleType.expense:
        return '11'; // Red
      case ScheduleType.bill:
        return '6'; // Orange
      case ScheduleType.reminder:
        return '7'; // Cyan
    }
  }
}

/// Result of sync operation
class SyncResult {
  final List<ScheduleEntity> uploaded = [];
  final List<ScheduleEntity> downloaded = [];
  final List<ScheduleEntity> deletedFromGoogle = [];

  int get totalChanges => uploaded.length + downloaded.length + deletedFromGoogle.length;
  bool get hasChanges => totalChanges > 0;
}
