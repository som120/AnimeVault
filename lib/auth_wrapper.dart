import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ainme_vault/main.dart';
import 'package:ainme_vault/screens/login_screen.dart';

/// Auth wrapper that listens to authentication state and routes accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, show main screen
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

        // Otherwise, show login screen
        return const LoginScreen();
      },
    );
  }
}
