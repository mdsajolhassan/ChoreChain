import 'package:flutter/material.dart';

import 'dart:async'; // টাইমারের জন্য

import '../main.dart'; // AuthWrapper (auto login/role check) // পরের পেজে যাওয়ার জন্য

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ৩ সেকেন্ড পর স্বয়ংক্রিয়ভাবে AuthScreen-এ চলে যাবে
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return; // widget dispose hoye gele crash thekabe
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'ChoreChain',
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
