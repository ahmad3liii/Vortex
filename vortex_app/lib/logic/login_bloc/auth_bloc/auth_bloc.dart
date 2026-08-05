import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService _apiService = ApiService();

  AuthBloc() : super(AuthState(isLoading: true)) {
    on<CheckAuthStatusEvent>((event, emit) async {
      await _loadAuthState(emit);
    });

    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
    });

    on<LoginSubmitted>((event, emit) async {
      emit(
        state.copyWith(isLoading: true, errorMessage: null, isSuccess: false),
      );

      try {
        final response = await _apiService.login(
          email: event.email,
          password: event.password,
        );

        print('📥 Login response status: ${response.statusCode}');
        print('📥 Login response data: ${response.data}');

        if (response.statusCode == 200 &&
            response.data['message'] == 'success') {
          final prefs = await SharedPreferences.getInstance();

          // حفظ user_id فقط (لأن الخادم لا يرسل توكنات)
          final userId = response.data['user_id'];
          if (userId != null) {
            await prefs.setInt('user_id', userId);
            await prefs.setString(
              'full_name',
              response.data['full_name'] ?? '',
            );
            await prefs.setString('email', response.data['email'] ?? '');
            await prefs.setString('phone', response.data['phone'] ?? '');
            await prefs.setString('location', response.data['location'] ?? '');
            await prefs.setString('avatar', response.data['avatar'] ?? '');
            await prefs.setString('bio', response.data['bio'] ?? '');
            await prefs.setString(
              'user_type',
              response.data['user_type'] ?? 'buyer',
            );
            print('✅ Saved user_id: $userId');
          }

          final userData = {
            'user_id': response.data['user_id'],
            'user_type': response.data['user_type'] ?? 'buyer',
            'full_name': response.data['full_name'] ?? '',
            'email': response.data['email'] ?? '',
            'phone': response.data['phone'] ?? '',
            'location': response.data['location'] ?? '',
            'avatar': response.data['avatar'] ?? '',
            'bio': response.data['bio'] ?? '',
          };

          emit(
            state.copyWith(
              isLoading: false,
              isSuccess: true,
              isLoggedIn: true,
              userData: userData,
            ),
          );
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage:
                  response.data['message'] ?? "بيانات الدخول غير صحيحة",
            ),
          );
        }
      } catch (e) {
        print('❌ Login error: $e');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: "تعذر الاتصال بالسيرفر، تأكد من الإنترنت",
          ),
        );
      }
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(
        state.copyWith(
          isLoading: true,
          errorMessage: null,
          isRegisterSuccess: false,
        ),
      );

      try {
        final response = await _apiService.register(
          full_name: event.name,
          email: event.email,
          password: event.password,
          phone: event.phone,
          location: event.location,
        );

        print('📥 Register response status: ${response.statusCode}');
        print('📥 Register response data: ${response.data}');

        if (response.statusCode == 201) {
          emit(state.copyWith(isLoading: false, isRegisterSuccess: true));
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: response.data['message'] ?? "فشل إنشاء الحساب",
            ),
          );
        }
      } catch (e) {
        print('❌ Register error: $e');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: "حدث خطأ أثناء الاتصال بالشبكة",
          ),
        );
      }
    });

    on<LogoutEvent>((event, emit) async {
      await _apiService.logout();
      emit(
        state.copyWith(
          isLoggedIn: false,
          userData: null,
          isSuccess: false,
          isLoading: false,
        ),
      );
    });

    add(CheckAuthStatusEvent());
  }

  Future<void> _loadAuthState(Emitter<AuthState> emit) async {
    print('🔄 Loading auth state...');
    await Future.delayed(const Duration(seconds: 5));
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      print('✅ Found user_id: $userId');
      final userData = {
        'user_id': userId,
        'user_type': prefs.getString('user_type') ?? 'buyer',
        'full_name': prefs.getString('full_name') ?? '',
        'email': prefs.getString('email') ?? '',
        'phone': prefs.getString('phone') ?? '',
        'location': prefs.getString('location') ?? '',
        'avatar': prefs.getString('avatar') ?? '',
        'bio': prefs.getString('bio') ?? '',
      };
      emit(
        state.copyWith(isLoggedIn: true, userData: userData, isLoading: false),
      );
    } else {
      print('❌ No user_id found, user not logged in');
      emit(state.copyWith(isLoggedIn: false, userData: null, isLoading: false));
    }
  }
}
