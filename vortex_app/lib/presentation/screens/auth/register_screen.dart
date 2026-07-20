import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_bloc.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_event.dart';
import 'package:vortex_market/logic/login_bloc/auth_bloc/auth_state.dart';

class RegisterScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),

          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.isRegisterSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account Created Successfully!"),
                  ),
                );
                Navigator.pop(context);
              }
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildAnimatedHeader(),

                        const SizedBox(height: 30),

                        _buildAnimatedGlassContainer(
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: nameController,
                                hint: "Full Name",
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(
                                controller: emailController,
                                hint: "Email",
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 15),
                              _buildTextField(
                                controller: passwordController,
                                hint: "Password",
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isObscure: !state.isPasswordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    state.isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => context.read<AuthBloc>().add(
                                    TogglePasswordVisibility(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),

                              _buildAnimatedMainButton(context, state),

                              const SizedBox(height: 15),
                              _buildLoginOption(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Column(
      children: [
        TweenAnimationBuilder(
          duration: const Duration(seconds: 2),
          tween: Tween<double>(begin: 1.0, end: 1.08),
          curve: Curves.easeInOut,
          builder: (context, double scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: const Icon(
            Icons.shopping_cart_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Join VORTEX',
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedGlassContainer({required Widget child}) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedMainButton(BuildContext context, AuthState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: state.isLoading ? 60 : MediaQuery.of(context).size.width,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purpleAccent.shade700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(state.isLoading ? 30 : 15),
          ),
        ),
        onPressed: state.isLoading
            ? null
            : () {
                context.read<AuthBloc>().add(
                  RegisterSubmitted(
                    name: nameController.text,
                    email: emailController.text,
                    password: passwordController.text,
                  ),
                );
              },
        child: state.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "SIGN UP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginOption(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: RichText(
        text: const TextSpan(
          text: "Already have an account? ",
          style: TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: "Login",
              style: TextStyle(
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
