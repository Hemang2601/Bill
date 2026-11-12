import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/main.dart';
import 'package:bill/core/core.dart';

import 'package:bill/splash_screen.dart';
import 'package:bill/login_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches with AppTheme.lightTheme and SplashScreen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': false,
      'userName': '',
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify MaterialApp configuration
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'Shree Shakti Electric');
    expect(app.theme?.scaffoldBackgroundColor, AppColors.background);
    expect(app.theme?.colorScheme.primary, AppColors.primary);

    // Verify SplashScreen exists on startup
    expect(find.byType(SplashScreen), findsOneWidget);

    // Settle splash animation to verify transition into AuthGate and LoginPage
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
