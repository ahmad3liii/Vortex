import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('ar')) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');
    if (savedLanguage != null) {
      emit(Locale(savedLanguage));
    }
  }

  Future<void> toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (state.languageCode == 'ar') {
      emit(const Locale('en'));
      await prefs.setString('language_code', 'en');
    } else {
      emit(const Locale('ar'));
      await prefs.setString('language_code', 'ar');
    }
  }
}
