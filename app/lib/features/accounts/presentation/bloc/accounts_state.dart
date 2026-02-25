import 'package:equatable/equatable.dart';

import '../../domain/entities/account_entity.dart';

abstract class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => [];
}

class AccountsInitial extends AccountsState {}

class AccountsLoading extends AccountsState {}

class AccountsLoaded extends AccountsState {
  final List<ConnectedAccount> accounts;
  final double totalBalance;

  const AccountsLoaded({
    required this.accounts,
    this.totalBalance = 0.0,
  });

  @override
  List<Object?> get props => [accounts, totalBalance];

  AccountsLoaded copyWith({
    List<ConnectedAccount>? accounts,
    double? totalBalance,
  }) {
    return AccountsLoaded(
      accounts: accounts ?? this.accounts,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }
}

class AccountsError extends AccountsState {
  final String message;

  const AccountsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AccountCreating extends AccountsState {}

class AccountCreated extends AccountsState {
  final ConnectedAccount account;

  const AccountCreated(this.account);

  @override
  List<Object?> get props => [account];
}
