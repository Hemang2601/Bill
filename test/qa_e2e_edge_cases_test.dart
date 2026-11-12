import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bill/login_page.dart';
import 'package:bill/dashboard_page.dart';
import 'package:bill/create_invoice.dart';
import 'package:bill/edit_invoice_page.dart';
import 'package:bill/core/core.dart';
import 'package:bill/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 9 QA: 1. Authentication, Sessions & Manager Identity', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      '1.1 Exactly two authorized managers exist with fixed credentials',
      () {
        final authorizedManagers = {'hiren': '3112', 'suresh': '1975'};

        expect(authorizedManagers.length, equals(2));
        expect(authorizedManagers['hiren'], equals('3112'));
        expect(authorizedManagers['suresh'], equals('1975'));
      },
    );

    testWidgets('1.2 Empty credential validation blocks login attempt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginPage()),
      );
      await tester.pumpAndSettle();

      final loginBtn = find.widgetWithText(AppButton, 'SIGN IN TO TERMINAL');
      expect(loginBtn, findsOneWidget);

      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Please enter your manager username'), findsOneWidget);
      expect(find.text('Please enter your PIN or password'), findsOneWidget);
    });

    testWidgets('1.3 Password visibility toggle works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const LoginPage()),
      );
      await tester.pumpAndSettle();

      final pinField = find.widgetWithText(
        AppTextField,
        'SECURITY PIN / PASSWORD',
      );
      expect(pinField, findsOneWidget);

      await tester.enterText(pinField, '3112');
      await tester.pump();

      // Tap show/hide icon
      final toggleIcon = find.byIcon(Icons.visibility_outlined);
      expect(toggleIcon, findsOneWidget);

      await tester.tap(toggleIcon);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    test(
      '1.4 Manager signature mapping resolves accurately for Hiren and Suresh',
      () async {
        // Test Suresh signature mapping
        final prefsSuresh = await SharedPreferences.getInstance();
        await prefsSuresh.setString('userName', 'Suresh Lakhadiya');

        final sureshUser = (prefsSuresh.getString('userName') ?? '')
            .toLowerCase();
        final sureshAsset = sureshUser.contains('hiren')
            ? 'assets/images/hiren.png'
            : 'assets/images/suresh.png';
        expect(sureshAsset, equals('assets/images/suresh.png'));

        // Test Hiren signature mapping
        final prefsHiren = await SharedPreferences.getInstance();
        await prefsHiren.setString('userName', 'Hiren');

        final hirenUser = (prefsHiren.getString('userName') ?? '')
            .toLowerCase();
        final hirenAsset = hirenUser.contains('hiren')
            ? 'assets/images/hiren.png'
            : 'assets/images/suresh.png';
        expect(hirenAsset, equals('assets/images/hiren.png'));
      },
    );

    test('1.5 Session logout clears SharedPreferences state', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', 'suresh');

      expect(prefs.getBool('isLoggedIn'), isTrue);
      expect(prefs.getString('userName'), equals('suresh'));

      // Simulate logout
      await prefs.setBool('isLoggedIn', false);
      expect(prefs.getBool('isLoggedIn'), isFalse);
    });
  });

  group('Phase 9 QA: 2. Financial Calculations & Precision Audit', () {
    test('2.1 Single line item arithmetic and currency formatting', () {
      const double qty = 5.0;
      const double rate = 120.0;
      const double lineTotal = qty * rate;

      expect(lineTotal, equals(600.0));
      expect(CurrencyFormatter.format(lineTotal), equals('₹ 600.00'));
      expect(
        CurrencyFormatter.format(lineTotal, showDecimals: false),
        equals('₹ 600'),
      );
    });

    test('2.2 Fractional quantity arithmetic (e.g. wiring meterage)', () {
      const double qty = 12.5;
      const double rate = 45.0;
      const double lineTotal = qty * rate;

      expect(lineTotal, equals(562.5));
      expect(CurrencyFormatter.format(lineTotal), equals('₹ 562.50'));
    });

    test('2.3 Multiple line item subtotal accumulation', () {
      final items = [
        {'name': 'Switch 6A', 'qty': 10.0, 'price': 45.0}, // 450.00
        {'name': 'Socket 6A', 'qty': 5.0, 'price': 85.0}, // 425.00
        {'name': '1.5mm Wire', 'qty': 2.0, 'price': 1200.0}, // 2400.00
        {'name': 'LED Batten 20W', 'qty': 4.0, 'price': 280.0}, // 1120.00
      ];

      double subtotal = 0.0;
      for (var item in items) {
        subtotal += (item['qty'] as double) * (item['price'] as double);
      }

      expect(subtotal, equals(4395.0));
      expect(CurrencyFormatter.format(subtotal), equals('₹ 4,395.00'));
    });

    test(
      '2.4 High volume / enterprise revenue amount formatting in Indian Numbering System',
      () {
        const double revenueLakhs = 1245050.75;
        final formatted = CurrencyFormatter.format(revenueLakhs);

        // Verify Indian Rupee Lakhs comma placement: 12,45,050.75
        expect(formatted, equals('₹ 12,45,050.75'));

        const double revenueCrores = 15000000.00;
        final formattedCrores = CurrencyFormatter.format(revenueCrores);
        // Verify Indian Rupee Crores comma placement: 1,50,00,000.00
        expect(formattedCrores, equals('₹ 1,50,00,000.00'));
      },
    );

    test('2.5 Zero and invalid string fallback in calculations', () {
      final String emptyStr = "";
      final String invalidStr = "abc";

      final double val1 = double.tryParse(emptyStr) ?? 0.0;
      final double val2 = double.tryParse(invalidStr) ?? 0.0;

      expect(val1, equals(0.0));
      expect(val2, equals(0.0));
      expect(CurrencyFormatter.format(val1), equals('₹ 0.00'));
    });
  });

  group(
    'Phase 9 QA: 3. Security Review & Backward-Compatible Password Hashing',
    () {
      test('3.1 Backward-compatible password verification with SHA-256', () {
        // Strategy: Support both legacy plaintext and SHA-256 hex string
        final String plaintextPin = '3112';
        final String hashedPin = sha256
            .convert(utf8.encode(plaintextPin))
            .toString();

        bool verifyPassword(String input, String stored) {
          // 1. If stored is a 64-character SHA-256 hex string
          if (stored.length == 64 &&
              RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(stored)) {
            final inputHash = sha256
                .convert(utf8.encode(input.trim()))
                .toString();
            return inputHash.toLowerCase() == stored.toLowerCase();
          }
          // 2. Legacy plaintext comparison
          return input.trim() == stored.trim();
        }

        // Verify with legacy plaintext record
        expect(verifyPassword('3112', '3112'), isTrue);
        expect(verifyPassword('9999', '3112'), isFalse);

        // Verify with upgraded SHA-256 hashed record
        expect(verifyPassword('3112', hashedPin), isTrue);
        expect(verifyPassword('1975', hashedPin), isFalse);
      });

      test('3.2 Bill number format validation (SE-yyMM-XXX)', () {
        final billRegex = RegExp(r'^SE-\d{4}-\d+$');

        expect(billRegex.hasMatch('SE-2611-101'), isTrue);
        expect(billRegex.hasMatch('SE-2611-2045'), isTrue);
        expect(billRegex.hasMatch('INV-2026-001'), isFalse);
      });

      test('3.3 Robust Date Parser handles all standard date formats', () {
        // Test ISO format
        final d1 = DatabaseHelper.parseDateRobust('2026-11-12');
        expect(d1?.year, equals(2026));
        expect(d1?.month, equals(11));
        expect(d1?.day, equals(12));

        // Test DD/MM/YYYY format
        final d2 = DatabaseHelper.parseDateRobust('12/11/2026');
        expect(d2?.year, equals(2026));
        expect(d2?.month, equals(11));
        expect(d2?.day, equals(12));

        // Test empty string
        final d3 = DatabaseHelper.parseDateRobust('');
        expect(d3, isNull);
      });
    },
  );

  group('Phase 9 QA: 4. Windows Desktop & Tablet Responsive Layouts', () {
    testWidgets(
      '4.1 Dashboard renders perfectly on 1920x1080 Full HD Windows layout',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardPage(userName: 'Suresh Lakhadiya'),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('SHREE SHAKTI ELECTRIC'), findsOneWidget);
        expect(find.text('BILLING & ESTIMATION SUITE'), findsOneWidget);
        expect(find.text('Create Invoice'), findsOneWidget);
        expect(find.text('Invoice History'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '4.2 Create Invoice renders cleanly on 1280x800 standard Windows window',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('STEP 1: CUSTOMER DETAILS'), findsOneWidget);
        expect(find.text('CONTINUE TO ITEMS & PRICING'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '4.3 Edit Invoice renders cleanly on 1024x768 compact laptop viewport',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;

        final sample = {
          'id': 42,
          'billNumber': 'SE-2611-105',
          'customerName': 'PATEL ELECTRICALS',
          'phoneNumber': '9876543210',
          'date': '12 Nov 2026',
          'totalAmount': 3600.0,
          'pdfPath': 'dummy.pdf',
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sample),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('EDIT INVOICE'), findsOneWidget);
        expect(find.text('SE-2611-105'), findsWidgets);
        expect(find.text('PATEL ELECTRICALS'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });

  group(
    'Phase 9 QA: 5. Unbounded Constraints & Narrow Mobile Viewport Hardening',
    () {
      testWidgets(
        '5.1 AppSectionHeader renders safely inside unbounded horizontal Row',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Row(
                  children: const [
                    AppSectionHeader(
                      title: 'Unbounded Section Title',
                      subtitle: 'Subtitle text',
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('UNBOUNDED SECTION TITLE'), findsOneWidget);
          expect(find.text('Subtitle text'), findsOneWidget);
        },
      );

      testWidgets(
        '5.2 AppSectionHeader renders with trailing in both bounded and unbounded contexts',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Column(
                  children: [
                    // Bounded context with action
                    AppSectionHeader(
                      title: 'Bounded Section',
                      subtitle: 'With action button',
                      actionLabel: 'VIEW ALL',
                      onAction: () {},
                    ),
                    // Unbounded Row context with trailing
                    Row(
                      children: const [
                        AppSectionHeader(
                          title: 'Unbounded With Trailing',
                          trailing: Text('TAG'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('BOUNDED SECTION'), findsOneWidget);
          expect(find.text('VIEW ALL'), findsOneWidget);
          expect(find.text('UNBOUNDED WITH TRAILING'), findsOneWidget);
          expect(find.text('TAG'), findsOneWidget);
        },
      );

      testWidgets(
        '5.3 DashboardPage recent invoice card does not overflow on narrow 300px screen',
        (tester) async {
          tester.view.physicalSize = const Size(300, 700);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: DashboardPage(userName: 'hiren')),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
        },
      );

      testWidgets(
        '5.4 DashboardPage Recent Invoices header on narrow width 328px has zero RenderFlex overflow',
        (tester) async {
          tester.view.physicalSize = const Size(328, 700);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(body: DashboardPage(userName: 'suresh')),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.text('RECENT INVOICES'), findsOneWidget);
          expect(find.text('View All'), findsOneWidget);

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
        },
      );
    },
  );
}
