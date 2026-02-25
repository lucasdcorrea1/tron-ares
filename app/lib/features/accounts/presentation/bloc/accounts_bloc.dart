import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/accounts_remote_datasource.dart';
import '../../domain/entities/account_entity.dart';
import 'accounts_event.dart';
import 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountsRemoteDataSource dataSource;

  AccountsBloc({required this.dataSource}) : super(AccountsInitial()) {
    on<LoadAccountsEvent>(_onLoadAccounts);
    on<RefreshAccountsEvent>(_onRefreshAccounts);
    on<CreateAccountEvent>(_onCreateAccount);
    on<UpdateAccountEvent>(_onUpdateAccount);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<SyncBalanceEvent>(_onSyncBalance);
  }

  Future<void> _onLoadAccounts(
    LoadAccountsEvent event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoading());
    try {
      final accounts = await dataSource.getAccounts();
      final totalBalance = accounts.fold<double>(
        0.0,
        (sum, acc) => sum + acc.balance,
      );
      emit(AccountsLoaded(accounts: accounts, totalBalance: totalBalance));
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> _onRefreshAccounts(
    RefreshAccountsEvent event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      final accounts = await dataSource.getAccounts();
      final totalBalance = accounts.fold<double>(
        0.0,
        (sum, acc) => sum + acc.balance,
      );
      emit(AccountsLoaded(accounts: accounts, totalBalance: totalBalance));
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> _onCreateAccount(
    CreateAccountEvent event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountCreating());
    try {
      final account = await dataSource.createAccount(event.request);
      emit(AccountCreated(account));
      // Reload accounts
      add(const LoadAccountsEvent());
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> _onUpdateAccount(
    UpdateAccountEvent event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      await dataSource.updateAccount(event.id, event.data);
      add(const RefreshAccountsEvent());
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      await dataSource.deleteAccount(event.id);
      add(const RefreshAccountsEvent());
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }

  Future<void> _onSyncBalance(
    SyncBalanceEvent event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      await dataSource.syncBalance(event.id, event.balance);
      add(const RefreshAccountsEvent());
    } catch (e) {
      emit(AccountsError(e.toString()));
    }
  }
}
