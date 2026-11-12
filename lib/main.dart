import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/core.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'splash_screen.dart';

void main() async {
  // Required for local storage and database initialization
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final bool showSplash;
  const MyApp({super.key, this.showSplash = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shree Shakti Electric',
      theme: AppTheme.lightTheme,
      home: showSplash ? const SplashScreen() : const AuthGate(),
    );
  }
}

/// Centralized AuthGate checking session state before routing
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: AppLoading(message: "Verifying Session..."),
          );
        }

        final bool isLoggedIn = snapshot.data?['isLoggedIn'] ?? false;
        final String userName = snapshot.data?['userName'] ?? "";

        if (isLoggedIn && userName.isNotEmpty) {
          return DashboardPage(userName: userName);
        } else {
          return const LoginPage();
        }
      },
    );
  }

  Future<Map<String, dynamic>> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
      'userName': prefs.getString('userName') ?? "",
    };
  }
}
