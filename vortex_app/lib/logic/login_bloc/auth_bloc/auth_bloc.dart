import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthState()) {
    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
    });

    on<LoginSubmitted>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      await Future.delayed(const Duration(seconds: 2));
      if (event.email == "test@test.com") {
        emit(state.copyWith(isLoading: false, isSuccess: true));
      } else {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: "خطأ في بيانات الدخول",
          ),
        );
      }
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      await Future.delayed(const Duration(seconds: 2));

      emit(state.copyWith(isLoading: false, isRegisterSuccess: true));
    });
  }
}
