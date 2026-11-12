import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/login_page.dart';
import 'package:bill/main.dart';
import 'package:bill/dashboard_page.dart';
import 'package:bill/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginPage Widget & Form Validation Tests', () {
    testWidgets('Renders all white-theme branding elements and input fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginPage()),
      );
      await tester.pumpAndSettle();

      // Verify branding
      expect(find.text('SHREE SHAKTI'), findsOneWidget);
      expect(find.text('ELECTRIC SERVICE • BILLING SYSTEM'), findsOneWidget);
      expect(find.text('Manager Sign In'), findsOneWidget);

      // Verify input fields
      expect(find.text('MANAGER USERNAME'), findsOneWidget);
      expect(find.text('SECURITY PIN / PASSWORD'), findsOneWidget);
      expect(find.text('SIGN IN TO TERMINAL'), findsOneWidget);
      expect(find.byIcon(Icons.electric_bolt_rounded), findsOneWidget);
    });

    testWidgets('Triggers validation errors on empty submission', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginPage()),
      );
      await tester.pumpAndSettle();

      // Tap Sign In with empty fields
      await tester.tap(find.text('SIGN IN TO TERMINAL'));
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Please enter your manager username'), findsOneWidget);
      expect(find.text('Please enter your PIN or password'), findsOneWidget);
    });

    testWidgets('Toggles password visibility on icon tap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginPage()),
      );
      await tester.pumpAndSettle();

      // Find password field by obscureText = true
      final passwordFinder = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.obscureText == true,
      );
      expect(passwordFinder, findsOneWidget);

      // Find visibility icon and tap it
      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      expect(visibilityIcon, findsOneWidget);
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // After tap, there should be 0 obscured TextFields
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TextField && widget.obscureText == true,
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('AuthGate routes to LoginPage when session is not logged in', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'isLoggedIn': false,
        'userName': '',
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(DashboardPage), findsNothing);
    });

    testWidgets(
      'AuthGate routes directly to DashboardPage when session is persisted',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'isLoggedIn': true,
          'userName': 'suresh',
        });

        await tester.pumpWidget(const MyApp());
        // Wait for FutureBuilder to complete
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardPage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
      },
    );
  });
}
