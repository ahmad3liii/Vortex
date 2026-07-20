import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_bloc.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return BlocProvider(
          create: (context) => AuthBloc(),
          child: MaterialApp(
            title: 'Vortex Market',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.purple,
              useMaterial3: true,
              brightness: Brightness.dark,
            ),
            home: LoginScreen(),
          ),
        );
      },
    );
  }
}
