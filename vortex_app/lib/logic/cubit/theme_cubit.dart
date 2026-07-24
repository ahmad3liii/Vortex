import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppTheme { light, dark }

class ThemeState {
  final AppTheme themeMode;
  ThemeState(this.themeMode);
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(AppTheme.dark)); // الوضع الليلي افتراضي

  void toggleTheme() {
    emit(
      ThemeState(
        state.themeMode == AppTheme.dark ? AppTheme.light : AppTheme.dark,
      ),
    );
  }

  bool get isDark => state.themeMode == AppTheme.dark;
}
