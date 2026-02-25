import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/datasources/debt_local_datasource.dart';
import '../../domain/entities/debt_entity.dart';

// Events
abstract class DebtEvent extends Equatable {
  const DebtEvent();

  @override
  List<Object?> get props => [];
}

class LoadDebtsEvent extends DebtEvent {
  const LoadDebtsEvent();
}

class LoadDebtDetailEvent extends DebtEvent {
  final String debtId;

  const LoadDebtDetailEvent(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

class AddDebtEvent extends DebtEvent {
  final String name;
  final String description;
  final double initialAmount;
  final double interestRate;
  final DateTime startDate;

  const AddDebtEvent({
    required this.name,
    required this.description,
    required this.initialAmount,
    required this.interestRate,
    required this.startDate,
  });

  @override
  List<Object?> get props => [name, description, initialAmount, interestRate, startDate];
}

class AddPaymentEvent extends DebtEvent {
  final String debtId;
  final double amount;
  final DateTime date;
  final String? note;

  const AddPaymentEvent({
    required this.debtId,
    required this.amount,
    required this.date,
    this.note,
  });

  @override
  List<Object?> get props => [debtId, amount, date, note];
}

class DeleteDebtEvent extends DebtEvent {
  final String debtId;

  const DeleteDebtEvent(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

class ApplyMissingInterestsEvent extends DebtEvent {
  final String debtId;

  const ApplyMissingInterestsEvent(this.debtId);

  @override
  List<Object?> get props => [debtId];
}

// States
abstract class DebtState extends Equatable {
  const DebtState();

  @override
  List<Object?> get props => [];
}

class DebtInitial extends DebtState {
  const DebtInitial();
}

class DebtLoading extends DebtState {
  const DebtLoading();
}

class DebtsLoaded extends DebtState {
  final List<DebtEntity> debts;
  final double totalDebt;

  const DebtsLoaded({
    required this.debts,
    required this.totalDebt,
  });

  @override
  List<Object?> get props => [debts, totalDebt];
}

class DebtDetailLoaded extends DebtState {
  final DebtEntity debt;
  final List<DebtEntryEntity> entries;

  const DebtDetailLoaded({
    required this.debt,
    required this.entries,
  });

  @override
  List<Object?> get props => [debt, entries];
}

class DebtError extends DebtState {
  final String message;

  const DebtError(this.message);

  @override
  List<Object?> get props => [message];
}

class DebtOperationSuccess extends DebtState {
  final String message;

  const DebtOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final DebtLocalDataSource _dataSource;

  DebtBloc(this._dataSource) : super(const DebtInitial()) {
    on<LoadDebtsEvent>(_onLoadDebts);
    on<LoadDebtDetailEvent>(_onLoadDebtDetail);
    on<AddDebtEvent>(_onAddDebt);
    on<AddPaymentEvent>(_onAddPayment);
    on<DeleteDebtEvent>(_onDeleteDebt);
    on<ApplyMissingInterestsEvent>(_onApplyMissingInterests);
  }

  Future<void> _onLoadDebts(
    LoadDebtsEvent event,
    Emitter<DebtState> emit,
  ) async {
    emit(const DebtLoading());
    try {
      final debts = await _dataSource.getAllDebts();
      final totalDebt = await _dataSource.getTotalDebt();

      // Apply missing interests for all debts
      for (final debt in debts) {
        await _dataSource.applyMissingInterests(debt.id);
      }

      // Reload after applying interests
      final updatedDebts = await _dataSource.getAllDebts();
      final updatedTotal = await _dataSource.getTotalDebt();

      emit(DebtsLoaded(debts: updatedDebts, totalDebt: updatedTotal));
    } catch (e) {
      emit(DebtError('Erro ao carregar dívidas: $e'));
    }
  }

  Future<void> _onLoadDebtDetail(
    LoadDebtDetailEvent event,
    Emitter<DebtState> emit,
  ) async {
    emit(const DebtLoading());
    try {
      // First apply missing interests
      await _dataSource.applyMissingInterests(event.debtId);

      final debt = await _dataSource.getDebtById(event.debtId);
      if (debt == null) {
        emit(const DebtError('Dívida não encontrada'));
        return;
      }

      final entries = await _dataSource.getEntriesForDebt(event.debtId);

      emit(DebtDetailLoaded(debt: debt, entries: entries));
    } catch (e) {
      emit(DebtError('Erro ao carregar detalhes: $e'));
    }
  }

  Future<void> _onAddDebt(
    AddDebtEvent event,
    Emitter<DebtState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final debt = DebtEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.name,
        description: event.description,
        initialAmount: event.initialAmount,
        currentAmount: event.initialAmount,
        interestRate: event.interestRate,
        startDate: event.startDate,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await _dataSource.createDebt(debt);

      // Apply any missing interests based on start date
      await _dataSource.applyMissingInterests(debt.id);

      emit(const DebtOperationSuccess('Dívida adicionada com sucesso'));
      add(const LoadDebtsEvent());
    } catch (e) {
      emit(DebtError('Erro ao adicionar dívida: $e'));
    }
  }

  Future<void> _onAddPayment(
    AddPaymentEvent event,
    Emitter<DebtState> emit,
  ) async {
    try {
      // Get current debt to check if it will be paid off
      final debtBefore = await _dataSource.getDebtById(event.debtId);

      await _dataSource.addPayment(
        event.debtId,
        event.amount,
        event.date,
        event.note,
      );

      // Check if debt is now paid off
      final debtAfter = await _dataSource.getDebtById(event.debtId);

      if (debtAfter != null && debtAfter.currentAmount <= 0) {
        emit(const DebtOperationSuccess('🎉 Parabéns! Dívida quitada com sucesso!'));
      } else if (debtBefore != null && event.amount > debtBefore.currentAmount) {
        emit(const DebtOperationSuccess('Pagamento ajustado ao saldo restante'));
      } else {
        emit(const DebtOperationSuccess('Pagamento registrado com sucesso'));
      }

      add(LoadDebtDetailEvent(event.debtId));
    } catch (e) {
      emit(DebtError('Erro ao registrar pagamento: $e'));
    }
  }

  Future<void> _onDeleteDebt(
    DeleteDebtEvent event,
    Emitter<DebtState> emit,
  ) async {
    try {
      await _dataSource.deleteDebt(event.debtId);
      emit(const DebtOperationSuccess('Dívida excluída com sucesso'));
      add(const LoadDebtsEvent());
    } catch (e) {
      emit(DebtError('Erro ao excluir dívida: $e'));
    }
  }

  Future<void> _onApplyMissingInterests(
    ApplyMissingInterestsEvent event,
    Emitter<DebtState> emit,
  ) async {
    try {
      await _dataSource.applyMissingInterests(event.debtId);
      add(LoadDebtDetailEvent(event.debtId));
    } catch (e) {
      emit(DebtError('Erro ao aplicar juros: $e'));
    }
  }
}
