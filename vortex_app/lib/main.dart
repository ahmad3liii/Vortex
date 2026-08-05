import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:vortex_market/logic/cubit/balance_cubit.dart';
import 'package:vortex_market/logic/cubit/language_cubit.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_bloc.dart';
import 'package:vortex_market/logic/cubit/nav_cubit.dart';
import 'package:vortex_market/logic/cubit/notification_cubit.dart';
import 'package:vortex_market/logic/cubit/product_cubit.dart';
import 'package:vortex_market/logic/cubit/chat_cubit.dart';
import 'package:vortex_market/logic/cubit/order_cubit.dart';
import 'package:vortex_market/logic/cubit/payment_cubit.dart';
import 'package:vortex_market/data/repositories/payment_repo.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_event.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_state.dart';
import 'package:vortex_market/logic/services/api_service.dart';
import 'package:vortex_market/presentation/screens/auth/login_screen.dart';
import 'package:vortex_market/presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => ThemeCubit()), // ✅ إضافة
            BlocProvider(
              create: (context) => AuthBloc()..add(CheckAuthStatusEvent()),
            ),
            BlocProvider(create: (context) => BalanceCubit()),
            BlocProvider(create: (context) => NavCubit()),
            BlocProvider(create: (context) => NotificationCubit()),
            BlocProvider(create: (context) => LanguageCubit()),
            BlocProvider(create: (context) => ProductCubit()..initialize()),
            BlocProvider(create: (context) => ChatCubit()),
            BlocProvider(create: (context) => OrderCubit()),
            BlocProvider(
              create: (context) =>
                  PaymentCubit(PaymentRepository(ApiService())),
            ),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              final isDark = themeState.themeMode == AppTheme.dark;
              return BlocBuilder<LanguageCubit, Locale>(
                builder: (context, locale) {
                  return MaterialApp(
                    title: 'Vortex Market',
                    debugShowCheckedModeBanner: false,
                    locale: locale,
                    supportedLocales: const [Locale('en'), Locale('ar')],
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    theme: isDark ? _darkTheme : _lightTheme,
                    home: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        if (authState.isLoading) {
                          return const SplashScreen();
                        }
                        if (authState.isLoggedIn) {
                          return MainNavigationScreen();
                        } else {
                          return const LoginScreen();
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.purple,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.purple,
      unselectedItemColor: Colors.grey,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.purple,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0F0F1F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0F0F1F),
      selectedItemColor: Colors.purpleAccent,
      unselectedItemColor: Colors.white38,
    ),
    cardColor: const Color(0xFF1A1A2E),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/splash_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: const CircularProgressIndicator(
                  color: Color(0xFFA855F7),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
