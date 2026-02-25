import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/datasources/schedule_local_datasource.dart';
import '../../domain/entities/schedule_entity.dart';

// Events
abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object?> get props => [];
}

class LoadSchedulesEvent extends ScheduleEvent {
  final DateTime? date;

  const LoadSchedulesEvent({this.date});

  @override
  List<Object?> get props => [date];
}

class AddScheduleEvent extends ScheduleEvent {
  final String title;
  final String? description;
  final DateTime dateTime;
  final String? category;
  final bool hasReminder;

  const AddScheduleEvent({
    required this.title,
    this.description,
    required this.dateTime,
    this.category,
    this.hasReminder = false,
  });

  @override
  List<Object?> get props => [title, description, dateTime, category, hasReminder];
}

class UpdateScheduleEvent extends ScheduleEvent {
  final ScheduleEntity schedule;

  const UpdateScheduleEvent(this.schedule);

  @override
  List<Object?> get props => [schedule];
}

class DeleteScheduleEvent extends ScheduleEvent {
  final String id;

  const DeleteScheduleEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleScheduleCompletionEvent extends ScheduleEvent {
  final String id;
  final bool isCompleted;

  const ToggleScheduleCompletionEvent({
    required this.id,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [id, isCompleted];
}

// States
abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object?> get props => [];
}

class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

class SchedulesLoaded extends ScheduleState {
  final List<ScheduleEntity> schedules;
  final DateTime? selectedDate;

  const SchedulesLoaded({
    required this.schedules,
    this.selectedDate,
  });

  @override
  List<Object?> get props => [schedules, selectedDate];
}

class ScheduleError extends ScheduleState {
  final String message;

  const ScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}

class ScheduleOperationSuccess extends ScheduleState {
  final String message;

  const ScheduleOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleLocalDataSource _dataSource;
  DateTime? _selectedDate;

  ScheduleBloc(this._dataSource) : super(const ScheduleInitial()) {
    on<LoadSchedulesEvent>(_onLoadSchedules);
    on<AddScheduleEvent>(_onAddSchedule);
    on<UpdateScheduleEvent>(_onUpdateSchedule);
    on<DeleteScheduleEvent>(_onDeleteSchedule);
    on<ToggleScheduleCompletionEvent>(_onToggleCompletion);
  }

  Future<void> _onLoadSchedules(
    LoadSchedulesEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    try {
      _selectedDate = event.date;
      final schedules = event.date != null
          ? await _dataSource.getSchedulesForDate(event.date!)
          : await _dataSource.getAllSchedules();

      emit(SchedulesLoaded(schedules: schedules, selectedDate: _selectedDate));
    } catch (e) {
      emit(ScheduleError('Erro ao carregar agendamentos: $e'));
    }
  }

  Future<void> _onAddSchedule(
    AddScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final schedule = ScheduleEntity(
        id: '',
        title: event.title,
        description: event.description,
        date: event.dateTime,
        isCompleted: false,
        hasReminder: event.hasReminder,
        category: event.category,
        createdAt: now,
        updatedAt: now,
      );

      await _dataSource.createSchedule(schedule);

      emit(const ScheduleOperationSuccess('Agendamento criado com sucesso'));
      add(LoadSchedulesEvent(date: _selectedDate));
    } catch (e) {
      emit(ScheduleError('Erro ao criar agendamento: $e'));
    }
  }

  Future<void> _onUpdateSchedule(
    UpdateScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      await _dataSource.updateSchedule(event.schedule);

      emit(const ScheduleOperationSuccess('Agendamento atualizado com sucesso'));
      add(LoadSchedulesEvent(date: _selectedDate));
    } catch (e) {
      emit(ScheduleError('Erro ao atualizar agendamento: $e'));
    }
  }

  Future<void> _onDeleteSchedule(
    DeleteScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      await _dataSource.deleteSchedule(event.id);

      emit(const ScheduleOperationSuccess('Agendamento excluído com sucesso'));
      add(LoadSchedulesEvent(date: _selectedDate));
    } catch (e) {
      emit(ScheduleError('Erro ao excluir agendamento: $e'));
    }
  }

  Future<void> _onToggleCompletion(
    ToggleScheduleCompletionEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    try {
      await _dataSource.toggleCompletion(event.id, event.isCompleted);

      emit(ScheduleOperationSuccess(
        event.isCompleted ? 'Marcado como concluído' : 'Marcado como pendente',
      ));
      add(LoadSchedulesEvent(date: _selectedDate));
    } catch (e) {
      emit(ScheduleError('Erro ao atualizar status: $e'));
    }
  }
}
