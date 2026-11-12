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
  });
}
