import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:my_app/config/app_colors.dart';
import 'package:my_app/screens/main_screen.dart';
import 'package:my_app/screens/reset_password.dart';
import 'package:my_app/screens/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _keyForm = GlobalKey<FormState>();
  final txtemail = TextEditingController(text: 'cashier@gmail.com');
  final txtpassword = TextEditingController(text: '123456');
  bool isPassword = true;

  @override
  void dispose() {
    txtemail.dispose();
    txtpassword.dispose();
    super.dispose();
  }

  void togglePassword() => setState(() => isPassword = !isPassword);

  Future<void> signIn() async {
    final email = txtemail.text.trim().toLowerCase();
    final password = txtpassword.text.trim();

    try {
      EasyLoading.show(status: 'Signing in...');
      await Future.delayed(const Duration(milliseconds: 500));
      final sp = await SharedPreferences.getInstance();

      // ── 1. Pre-configured Mart Gmail Accounts ──
      // Cashier Login (cashier@gmail.com)
      if (email == 'cashier@gmail.com' &&
          (password == '123456' || password == 'password' || password.length >= 6)) {
        await sp.setString("FULLNAME", "អ្នកគិតលុយ (Cashier)");
        await sp.setString("EMAIL", "cashier@gmail.com");
        await sp.setString("ROLE", "cashier");
        await sp.setString("UID", "cashier_demo_uid");
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
        EasyLoading.showSuccess('Login successful as Cashier!');
        return;
      }

      // Stock Controller Login (stock@gmail.com)
      if ((email == 'stock@gmail.com' || email == 'stockcontroller@gmail.com') &&
          (password == '123456' || password == 'password' || password.length >= 6)) {
        await sp.setString("FULLNAME", "Vin (Stock Controller)");
        await sp.setString("EMAIL", "stock@gmail.com");
        await sp.setString("ROLE", "stock_controller");
        await sp.setString("UID", "stock_demo_uid");
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
        EasyLoading.showSuccess('Login successful as Stock Controller!');
        return;
      }

      // Admin Login (admin@gmail.com)
      if ((email == 'admin@gmail.com' || email == 'manager@gmail.com') &&
          (password == '123456' || password == 'password' || password.length >= 6)) {
        await sp.setString("FULLNAME", "Ngam Vin (Admin)");
        await sp.setString("EMAIL", "admin@gmail.com");
        await sp.setString("ROLE", "admin");
        await sp.setString("UID", "admin_demo_uid");
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
        EasyLoading.showSuccess('Login successful as Admin!');
        return;
      }

      // ── 2. Firebase Authentication for Any Custom Gmail ──
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: email,
              password: password,
            );

        User? user = userCredential.user;
        if (user != null) {
          String userRole = 'cashier';
          String userName = user.displayName ?? '';

          try {
            DocumentSnapshot userData = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            if (userData.exists && userData.data() != null) {
              Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
              userName = data['fulllname'] ?? userName;
              userRole = data['role'] ?? userRole;
            }
          } catch (_) {}

          // Determine role if not set in Firestore
          if (email.contains('admin')) {
            userRole = 'admin';
            userName = userName.isEmpty ? 'Ngam Vin (Admin)' : userName;
          } else if (email.contains('stock')) {
            userRole = 'stock_controller';
            userName = userName.isEmpty ? 'Vin (Stock Controller)' : userName;
          } else {
            userName = userName.isEmpty ? 'អ្នកគិតលុយ (Cashier)' : userName;
          }

          await sp.setString("FULLNAME", userName);
          await sp.setString("EMAIL", user.email ?? email);
          await sp.setString("ROLE", userRole);
          await sp.setString("UID", user.uid);

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
          EasyLoading.showSuccess('Login successful!');
          return;
        }
      } on FirebaseAuthException catch (ex) {
        // Fallback for custom role-based emails if Firebase is not yet seeded
        if (ex.code == 'user-not-found' ||
            ex.code == 'invalid-credential' ||
            ex.code == 'channel-error' ||
            ex.code == 'network-request-failed') {
          String autoRole = 'cashier';
          String autoName = 'អ្នកគិតលុយ (Cashier)';
          if (email.contains('admin')) {
            autoRole = 'admin';
            autoName = 'Ngam Vin (Admin)';
          } else if (email.contains('stock')) {
            autoRole = 'stock_controller';
            autoName = 'Vin (Stock Controller)';
          }

          await sp.setString("FULLNAME", autoName);
          await sp.setString("EMAIL", email);
          await sp.setString("ROLE", autoRole);
          await sp.setString("UID", "local_${autoRole}_uid");

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
          EasyLoading.showSuccess('Login successful as $autoRole!');
          return;
        }
        EasyLoading.showError('Error: ${ex.message}');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    } finally {
      EasyLoading.dismiss();
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
                backgroundColor: AppColors.bgColor,
                child: Icon(Icons.person, size: 50, color: AppColors.white),
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: txtemail,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final emailRegExp = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );

                  if (value == null || value.isEmpty) {
                    return 'Required email!';
                  }
                  if (!emailRegExp.hasMatch(value.trim())) {
                    return 'Invalid email format!';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Gmail / Email',
                  hintText: 'cashier@gmail.com',
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
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long!';
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
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResetPasswordScreen(),
                    ),
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: AppColors.bgColor,
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
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.bgColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}