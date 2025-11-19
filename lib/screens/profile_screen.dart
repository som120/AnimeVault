import 'package:ainme_vault/utils/transitions.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // import to access MainScreen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            SlideRightRoute(page: const MainScreen()),
          );
        }
      },
      child: const Center(
        child: Text(
          "Profile Screen",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
