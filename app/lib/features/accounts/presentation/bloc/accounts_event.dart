import 'package:equatable/equatable.dart';

import '../../data/models/account_model.dart';

abstract class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccountsEvent extends AccountsEvent {
  const LoadAccountsEvent();
}

class RefreshAccountsEvent extends AccountsEvent {
  const RefreshAccountsEvent();
}

class CreateAccountEvent extends AccountsEvent {
  final CreateAccountRequest request;

  const CreateAccountEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class UpdateAccountEvent extends AccountsEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateAccountEvent(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteAccountEvent extends AccountsEvent {
  final String id;

  const DeleteAccountEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SyncBalanceEvent extends AccountsEvent {
  final String id;
  final double balance;

  const SyncBalanceEvent(this.id, this.balance);

  @override
  List<Object?> get props => [id, balance];
}
