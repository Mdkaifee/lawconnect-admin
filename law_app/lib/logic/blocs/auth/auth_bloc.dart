import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AppStartedEvent>(_onAppStarted);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onAppStarted(AppStartedEvent event, Emitter<AuthState> emit) async {
    try {
      if (_authRepository.isAuthenticated()) {
        final user = await _authRepository.getProfile();
        if (user != null) {
          emit(Authenticated(user));
          return;
        }
      }
      emit(Unauthenticated());
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmittedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterSubmitted(RegisterSubmittedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<AuthState> emit) async {
    try {
      final user = await _authRepository.updateProfile(
        name: event.name,
        headline: event.headline,
        college: event.college,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
