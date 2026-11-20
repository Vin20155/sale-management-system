import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/screens/auth/forgot_password_screen.dart';
import 'package:my_app/screens/dashboard/main_screen.dart';
import 'package:my_app/services/mart_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _keyForm = GlobalKey<FormState>();
  final txtemail = TextEditingController();
  final txtpassword = TextEditingController();
  bool isPassword = true;

  @override
  void dispose() {
    txtemail.dispose();
    txtpassword.dispose();
    super.dispose();
  }

  void togglePassword() => setState(() => isPassword = !isPassword);

  Future<void> signIn() async {
    final username = txtemail.text.trim();
    final password = txtpassword.text;

    EasyLoading.show(status: 'Signing in...');
    final error = await MartService().authenticate(
      username: username,
      password: password,
    );
    EasyLoading.dismiss();

    if (!mounted) return;
    if (error != null) {
      EasyLoading.showError(error);
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
    EasyLoading.showSuccess('Login successful!');
  }

  Future<void> openForgotPassword() async {
    final updatedUsername = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ForgotPasswordScreen(
          initialUsername: txtemail.text.trim(),
        ),
      ),
    );
    if (updatedUsername != null && updatedUsername.isNotEmpty) {
      txtemail.text = updatedUsername;
      txtpassword.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Form(
        key: _keyForm,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 35),
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 50, color: AppColors.white),
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: txtemail,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your username or email.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Username / Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: txtpassword,
                obscureText: isPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required password!';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: togglePassword,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: openForgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: AppColors.primary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
                onPressed: () {
                  if (_keyForm.currentState!.validate()) {
                    signIn();
                  }
                },
                child: const Text(
                  'Login',
                  style: TextStyle(color: AppColors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
