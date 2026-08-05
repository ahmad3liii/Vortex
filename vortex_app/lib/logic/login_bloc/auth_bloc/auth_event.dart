abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted(this.email, this.password);
}

class RegisterSubmitted extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String location;
  RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.location,
  });
}

class TogglePasswordVisibility extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}
