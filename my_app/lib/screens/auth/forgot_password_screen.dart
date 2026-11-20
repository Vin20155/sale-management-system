import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/services/mart_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialUsername;

  const ForgotPasswordScreen({
    super.key,
    this.initialUsername = '',
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _keyForm = GlobalKey<FormState>();
  late final TextEditingController _txtUsername;
  final _txtNewPassword = TextEditingController();
  final _txtConfirmPassword = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _txtUsername = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _txtUsername.dispose();
    _txtNewPassword.dispose();
    _txtConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (!_keyForm.currentState!.validate()) return;

    EasyLoading.show(status: 'Resetting password...');
    final error = await MartService().resetPassword(
      username: _txtUsername.text.trim(),
      newPassword: _txtNewPassword.text,
    );
    EasyLoading.dismiss();

    if (!mounted) return;
    if (error != null) {
      EasyLoading.showError(error);
      return;
    }

    EasyLoading.showSuccess('Password reset successful! Please login.');
    Navigator.pop(context, _txtUsername.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Form(
        key: _keyForm,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 50,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enter your username or email and choose a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _txtUsername,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
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
                controller: _txtNewPassword,
                obscureText: _obscureNew,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a new password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _txtConfirmPassword,
                obscureText: _obscureConfirm,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your new password.';
                  }
                  if (value != _txtNewPassword.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: AppColors.primary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ),
                onPressed: _submitReset,
                child: const Text(
                  'Reset Password',
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

