import 'package:flutter/material.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/screens/main_screen.dart';
import 'package:my_app/services/mart_service.dart';

class AppAuth extends StatefulWidget {
  const AppAuth({super.key});

  @override
  State<AppAuth> createState() => _AppAuthState();
}

class _AppAuthState extends State<AppAuth> {
  late final Future<bool> _session = MartService().restoreSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data == true
            ? const MainScreen()
            : const LoginScreen();
      },
    );
  }
}
