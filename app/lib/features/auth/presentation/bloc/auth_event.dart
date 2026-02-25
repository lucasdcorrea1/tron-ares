import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatusEvent extends AuthEvent {
  const AuthCheckStatusEvent();
}

class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

class AuthUploadAvatarEvent extends AuthEvent {
  final File imageFile;

  const AuthUploadAvatarEvent({required this.imageFile});

  @override
  List<Object?> get props => [imageFile];
}

class AuthUpdateProfileEvent extends AuthEvent {
  final String? name;
  final String? bio;

  const AuthUpdateProfileEvent({this.name, this.bio});

  @override
  List<Object?> get props => [name, bio];
}
