class AuthState {
  final bool isPasswordVisible, isLoading, isSuccess, isRegisterSuccess;
  final String? errorMessage;

  AuthState({
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.isSuccess = false,
    this.isRegisterSuccess = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isPasswordVisible,
    isLoading,
    isSuccess,
    isRegisterSuccess,
    String? errorMessage,
  }) {
    return AuthState(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isRegisterSuccess: isRegisterSuccess ?? this.isRegisterSuccess,
      errorMessage: errorMessage,
    );
  }
}
