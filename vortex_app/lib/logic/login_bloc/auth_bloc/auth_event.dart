abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email, password;
  LoginSubmitted(this.email, this.password);
}

class RegisterSubmitted extends AuthEvent {
  final String name, email, password;
  RegisterSubmitted({
    required this.name,
    required this.email,
    required this.password,
  });
}

class TogglePasswordVisibility extends AuthEvent {}
