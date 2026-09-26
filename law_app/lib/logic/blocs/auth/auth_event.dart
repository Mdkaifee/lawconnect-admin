import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStartedEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmittedEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmittedEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterSubmittedEvent({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class UpdateProfileEvent extends AuthEvent {
  final String? name;
  final String? headline;
  final String? college;

  const UpdateProfileEvent({this.name, this.headline, this.college});

  @override
  List<Object?> get props => [name, headline, college];
}

class LogoutEvent extends AuthEvent {}
