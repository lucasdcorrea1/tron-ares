import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(const AuthState.initial()) {
    on<AuthCheckStatusEvent>(_onCheckStatus);
    on<AuthLoginEvent>(_onLogin);
    on<AuthRegisterEvent>(_onRegister);
    on<AuthLogoutEvent>(_onLogout);
    on<AuthUploadAvatarEvent>(_onUploadAvatar);
    on<AuthUpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final isLoggedIn = await repository.isLoggedIn();
    if (!isLoggedIn) {
      emit(const AuthState.unauthenticated());
      return;
    }

    final result = await repository.getCurrentUser();
    result.fold(
      (failure) => emit(const AuthState.unauthenticated()),
      (authResult) => emit(AuthState.authenticated(
        user: authResult.user,
        profile: authResult.profile,
      )),
    );
  }

  Future<void> _onLogin(
    AuthLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await repository.login(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (authResult) => emit(AuthState.authenticated(
        user: authResult.user,
        profile: authResult.profile,
      )),
    );
  }

  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await repository.register(
      email: event.email,
      password: event.password,
      name: event.name,
    );

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (authResult) => emit(AuthState.authenticated(
        user: authResult.user,
        profile: authResult.profile,
      )),
    );
  }

  Future<void> _onLogout(
    AuthLogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await repository.logout();
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> _onUploadAvatar(
    AuthUploadAvatarEvent event,
    Emitter<AuthState> emit,
  ) async {
    // Keep current user/profile while loading
    final currentState = state;
    emit(currentState.copyWith(status: AuthStatus.loading));

    final result = await repository.uploadAvatar(event.imageFile);

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (profile) {
        if (currentState.user != null) {
          emit(AuthState.authenticated(
            user: currentState.user!,
            profile: profile,
          ));
        }
      },
    );
  }

  Future<void> _onUpdateProfile(
    AuthUpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(currentState.copyWith(status: AuthStatus.loading));

    final result = await repository.updateProfile(
      name: event.name,
      bio: event.bio,
    );

    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (profile) {
        if (currentState.user != null) {
          emit(AuthState.authenticated(
            user: currentState.user!,
            profile: profile,
          ));
        }
      },
    );
  }
}
