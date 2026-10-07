import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/app_translations.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parent_main_screen.dart';
import 'screens/child_main_screen.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  if (!kIsWeb && Platform.isWindows) {
    await GoogleSignInDart.register(clientId: '581784052392-1smq7nmkq7mqtioepku0r5b3s0qmlktn.apps.googleusercontent.com');
  }
  
  await AppTranslations.init();
  runApp(const MyApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppTranslations.localeNotifier,
      builder: (_, String currentLang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, ThemeMode currentMode, _) {
            return MaterialApp(
              title: 'ChoreChain',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppTheme.primary,
                  brightness: Brightness.dark,
                ),
              ),
              themeMode: currentMode,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                String role = userSnapshot.data!['role'] ?? 'Child';
                if (role.toLowerCase() == 'parent') {
                  return const ParentMainScreen();
                } else {
                  return const ChildMainScreen();
                }
              }
              return const LoginScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
