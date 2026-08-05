class AuthState {
  final bool isPasswordVisible;
  final bool isLoading;
  final bool isSuccess;
  final bool isRegisterSuccess;
  final bool isLoggedIn;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  AuthState({
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.isSuccess = false,
    this.isRegisterSuccess = false,
    this.isLoggedIn = false,
    this.errorMessage,
    this.userData,
  });

  AuthState copyWith({
    bool? isPasswordVisible,
    bool? isLoading,
    bool? isSuccess,
    bool? isRegisterSuccess,
    bool? isLoggedIn,
    String? errorMessage,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isRegisterSuccess: isRegisterSuccess ?? this.isRegisterSuccess,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: errorMessage,
      userData: userData ?? this.userData,
    );
  }
}
