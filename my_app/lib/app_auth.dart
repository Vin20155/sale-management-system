import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/screens/login_screen.dart';
import 'package:my_app/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAuth extends StatelessWidget {
  const AppAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final sp = snapshot.data;
        final hasSavedLogin = sp != null && sp.getString("EMAIL") != null && sp.getString("EMAIL")!.isNotEmpty;

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, data) {
            if (data.connectionState == ConnectionState.waiting && !hasSavedLogin) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (data.hasData || hasSavedLogin) {
              return const MainScreen();
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}