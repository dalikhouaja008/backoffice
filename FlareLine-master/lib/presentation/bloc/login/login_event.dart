part of 'login_bloc.dart';



abstract class LoginEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginRequested extends LoginEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class LogoutRequested extends LoginEvent {}

class CheckSession extends LoginEvent {}


class InitializeAuth extends LoginEvent {
  @override
  List<Object> get props => [];

  @override
  String toString() => 'InitializeAuth';
}


