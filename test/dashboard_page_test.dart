import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/dashboard_page.dart';
import 'package:bill/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userName': 'Suresh',
    });
  });

  group('DashboardPage UI & Responsive Layout Tests', () {
    testWidgets('Renders header, branding, manager name and greeting', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Suresh'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SHREE SHAKTI ELECTRIC'), findsOneWidget);
      expect(find.text('BILLING & ESTIMATION SUITE'), findsOneWidget);
      expect(find.textContaining('Suresh'), findsWidgets);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('Renders all 4 business statistics cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Hiren'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TOTAL REVENUE'), findsOneWidget);
      expect(find.text('PAID AMOUNT'), findsOneWidget);
      expect(find.text('PENDING AMOUNT'), findsOneWidget);
      expect(find.text('TOTAL INVOICES'), findsOneWidget);
    });

    testWidgets('Renders quick action cards for New Bill and History', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Suresh'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Create Invoice'), findsOneWidget);
      expect(find.text('NEW BILL'), findsOneWidget);
      expect(find.text('Invoice History'), findsOneWidget);
    });

    testWidgets('Displays empty state gracefully when no invoices exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Suresh'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No Invoices Recorded Yet'), findsOneWidget);
      expect(find.text('CREATE FIRST BILL'), findsOneWidget);
    });

    testWidgets(
      'Renders cleanly on desktop viewport (1200x800) without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardPage(userName: 'Suresh Lakhadiya'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('SHREE SHAKTI ELECTRIC'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      'Renders cleanly on mobile viewport (400x800) without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardPage(userName: 'Suresh'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('SHREE SHAKTI ELECTRIC'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('Sign out button triggers confirmation dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Suresh'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final logoutBtn = find.byIcon(Icons.logout_rounded);
      expect(logoutBtn, findsOneWidget);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('Back press on Dashboard triggers Exit Application confirmation dialog', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Suresh'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);

      final popScope = tester.widget<PopScope<Object?>>(popScopeFinder);
      expect(popScope.canPop, isFalse);

      // Simulate system back button / gesture
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Exit Application'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to exit Shree Shakti Electric Service?',
        ),
        findsOneWidget,
      );
      expect(find.text('EXIT'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Tapping CANCEL dismisses the dialog safely
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('Exit Application'), findsNothing);
    });
  });
}
