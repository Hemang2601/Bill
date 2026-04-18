import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Make sure this is in pubspec.yaml
import 'login_page.dart';
import 'dashboard_page.dart';

void main() async {
  // --- CRITICAL ADDITION ---
  // Required for local storage and database initialization
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shree Shakti Electric',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          primary: const Color(0xFF1E40AF),
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // CHANGE: Use AuthGate instead of LoginPage
      home: const AuthGate(),
    );
  }
}

// --- NEW AUTH GATE CLASS ---
// This checks if a user is already logged in before showing a screen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkSession(),
      builder: (context, snapshot) {
        // Show a blank screen with a loader while checking memory
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E40AF))),
          );
        }

        final bool isLoggedIn = snapshot.data?['isLoggedIn'] ?? false;
        final String userName = snapshot.data?['userName'] ?? "";

        // If true, jump straight to Dashboard. If false, show Login.
        if (isLoggedIn && userName.isNotEmpty) {
          return DashboardPage(userName: userName);
        } else {
          return const LoginPage();
        }
      },
    );
  }

  // Reads the saved login data from the phone's disk
  Future<Map<String, dynamic>> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
      'userName': prefs.getString('userName') ?? "",
    };
  }
}