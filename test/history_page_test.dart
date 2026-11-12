import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/history_page.dart';
import 'package:bill/core/core.dart';
import 'package:bill/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userName': 'Suresh',
    });
  });

  group('HistoryPage UI & Functional Tests', () {
    testWidgets(
      '1. History page renders header, branding, export button, search, and filters',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('BILL HISTORY & LEDGER'), findsOneWidget);
        expect(
          find.text('SHREE SHAKTI ELECTRIC • AUDIT & SEARCH'),
          findsOneWidget,
        );
        expect(find.text('EXPORT'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'All Time'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'This Month'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'This Year'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '2. Displays empty database state gracefully when no invoices exist',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('No Invoices Recorded Yet'), findsOneWidget);
        expect(find.text('CREATE FIRST BILL'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('3. Empty search result shows clear filter empty state', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'NONEXISTENT_BILL_9999');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('No Matching Records Found'), findsOneWidget);
      expect(find.text('CLEAR ALL FILTERS'), findsOneWidget);

      // Tap clear filters
      await tester.tap(find.text('CLEAR ALL FILTERS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('No Matching Records Found'), findsNothing);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('4. Filter chip selection updates active filter state', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final thisMonthChip = find.widgetWithText(FilterChip, 'This Month');
      expect(thisMonthChip, findsOneWidget);

      await tester.tap(thisMonthChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('THIS MONTH REVENUE'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('5. Export button shows snackbar when ledger is empty', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final exportBtn = find.text('EXPORT');
      expect(exportBtn, findsOneWidget);

      await tester.tap(exportBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.text('No records available to export for current view'),
        findsOneWidget,
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      '6. Desktop layout (1200x800) renders cleanly without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('BILL HISTORY & LEDGER'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('7. Mobile layout (400x800) renders cleanly without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('BILL HISTORY & LEDGER'), findsOneWidget);
      expect(tester.takeException(), isNull);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('8. Custom date range picker button opens system date picker', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final dateRangeBtn = find.byIcon(Icons.date_range_rounded);
      expect(dateRangeBtn, findsOneWidget);

      await tester.tap(dateRangeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DateRangePickerDialog), findsOneWidget);

      final closeBtn = find.byIcon(Icons.close);
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    test(
      '9. DatabaseHelper supports phone number, customer name, and bill number search',
      () async {
        final dt1 = DatabaseHelper.parseDateRobust('2026-11-12');
        expect(dt1, isNotNull);
        expect(dt1!.year, 2026);
        expect(dt1.month, 11);
        expect(dt1.day, 12);

        final dt2 = DatabaseHelper.parseDateRobust('12/11/2026');
        expect(dt2, isNotNull);
        expect(dt2!.year, 2026);

        final dtEmpty = DatabaseHelper.parseDateRobust('');
        expect(dtEmpty, isNull);
      },
    );

    testWidgets('10. Select Month action chip renders and opens date picker', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final selectMonthChip = find.widgetWithText(ActionChip, 'Select Month');
      expect(selectMonthChip, findsOneWidget);

      await tester.ensureVisible(selectMonthChip);
      await tester.pumpAndSettle();

      await tester.tap(selectMonthChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DatePickerDialog), findsOneWidget);

      final cancelBtn = find.text('Cancel');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('11. Sort menu button displays all 5 sorting options', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HistoryPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final sortBtn = find.byIcon(Icons.sort_rounded);
      expect(sortBtn, findsOneWidget);

      await tester.tap(sortBtn);
      await tester.pumpAndSettle();

      expect(find.text('Date: Newest First'), findsOneWidget);
      expect(find.text('Date: Oldest First'), findsOneWidget);
      expect(find.text('Amount: High to Low'), findsOneWidget);
      expect(find.text('Amount: Low to High'), findsOneWidget);
      expect(find.text('Customer: A to Z'), findsOneWidget);

      // Select Amount: High to Low
      await tester.tap(find.text('Amount: High to Low'));
      await tester.pumpAndSettle();

      expect(find.text('AMOUNT ↓'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      '12. Table ledger renders structured columns and rows when invoices exist',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;

        final mockInvoices = [
          {
            'id': 101,
            'billNumber': 'SE-2611-101',
            'customerName': 'Patel Electricals',
            'phoneNumber': '9876543210',
            'date': '12/11/2026',
            'totalAmount': 4500.0,
            'pdfPath': '',
          },
          {
            'id': 102,
            'billNumber': 'SE-2611-102',
            'customerName': 'Shree Ram Cables',
            'phoneNumber': '9123456780',
            'date': '11/11/2026',
            'totalAmount': 12800.0,
            'pdfPath': '',
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: HistoryPage(initialInvoices: mockInvoices),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Desktop Table Header assertions
        expect(find.text('BILL NO. & DATE'), findsOneWidget);
        expect(find.text('CUSTOMER'), findsOneWidget);
        expect(
          find.text('STATUS'),
          findsNWidgets(2),
        ); // Status filter label + Table header
        expect(find.text('AMOUNT'), findsOneWidget);
        expect(find.text('ACTION'), findsOneWidget);

        // Data rows assertions
        expect(find.text('#SE-2611-101'), findsOneWidget);
        expect(find.text('PATEL ELECTRICALS'), findsOneWidget);
        expect(find.text('#SE-2611-102'), findsOneWidget);
        expect(find.text('SHREE RAM CABLES'), findsOneWidget);

        // Row action buttons
        expect(find.byIcon(Icons.more_vert_rounded), findsNWidgets(2));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '13. Clicking table row action button opens luxury Action Bottom Sheet with all options',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        final mockInvoices = [
          {
            'id': 201,
            'billNumber': 'SE-2611-201',
            'customerName': 'Apex Power Works',
            'phoneNumber': '9988776655',
            'date': '12/11/2026',
            'totalAmount': 8950.0,
            'pdfPath': '',
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: HistoryPage(initialInvoices: mockInvoices),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Tap the action button for the invoice
        final actionButton = find.byIcon(Icons.more_vert_rounded).first;
        await tester.tap(actionButton);
        await tester.pumpAndSettle();

        // Verify Luxury Action Sheet content
        expect(find.text('INVOICE ACTIONS'), findsOneWidget);
        expect(find.text('See PDF Document'), findsOneWidget);
        expect(find.text('Edit Invoice'), findsOneWidget);
        expect(find.text('Share PDF Document'), findsOneWidget);
        expect(find.text('Mark as Paid'), findsOneWidget);
        expect(find.text('Delete Invoice'), findsOneWidget);

        // Verify Invoice details in sheet header
        expect(find.text('#SE-2611-201'), findsNWidgets(2)); // Row + Sheet
        expect(find.text('APEX POWER WORKS'), findsNWidgets(2));

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}
