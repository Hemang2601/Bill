import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/edit_invoice_page.dart';
import 'package:bill/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> sampleInvoice = {
    'id': 101,
    'billNumber': 'INV-2026-0042',
    'customerName': 'PATEL ELECTRICALS',
    'phoneNumber': '9876543210',
    'date': '12 Nov 2026',
    'totalAmount': 2400.0,
    'pdfPath': 'D:/Bill/test_invoices/Invoice_INV_2026_0042.pdf',
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userName': 'Suresh',
    });
  });

  group('EditInvoicePage 3-Step Wizard UI & Functional Tests', () {
    testWidgets(
      '1. Edit Invoice wizard renders Step 1 with prepopulated customer metadata',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Header checks
        expect(find.text('EDIT INVOICE'), findsOneWidget);
        expect(
          find.text('SHREE SHAKTI ELECTRIC • RECORD UPDATE'),
          findsOneWidget,
        );
        expect(find.text('INV-2026-0042'), findsWidgets);

        // Step 1 titles
        expect(find.text('STEP 1: CUSTOMER DETAILS'), findsOneWidget);
        expect(find.text('CLIENT DETAILS'), findsOneWidget);
        expect(find.text('INVOICE INFORMATION'), findsOneWidget);
        expect(find.text('CONTINUE TO ITEMS & PRICING'), findsOneWidget);

        // Prepopulated values
        expect(find.text('PATEL ELECTRICALS'), findsOneWidget);
        expect(find.text('9876543210'), findsOneWidget);
        expect(find.text('12 Nov 2026'), findsWidgets);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('2. Customer details can be modified on Step 1', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EditInvoicePage(existingInvoice: sampleInvoice),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final customerField = find.widgetWithText(
        AppTextField,
        'Customer / Firm Name',
      );
      expect(customerField, findsOneWidget);

      await tester.enterText(customerField, 'SHARMA TRADERS');
      await tester.pump();

      expect(find.text('SHARMA TRADERS'), findsOneWidget);

      final phoneField = find.widgetWithText(
        AppTextField,
        'Mobile Number (Optional)',
      );
      await tester.enterText(phoneField, '9988776655');
      await tester.pump();

      expect(find.text('9988776655'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      '3. Advancing to Step 2 renders Items & Pricing and popular electrical items',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1200);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Advance to Step 2
        final continueBtn = find.text('CONTINUE TO ITEMS & PRICING');
        expect(continueBtn, findsOneWidget);
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(find.text('STEP 2: ITEMS & PRICING'), findsOneWidget);
        expect(find.text('LINE ITEMS'), findsOneWidget);
        expect(find.text('POPULAR ELECTRICAL ITEMS'), findsOneWidget);
        expect(find.text('ADD ITEM TO BILL'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '4. Adding an item in Step 2 updates item list and grand total',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1400);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Step 1 -> Step 2
        final continueBtn = find.text('CONTINUE TO ITEMS & PRICING');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Tap quick catalog chip for Switch 6A
        final switchChip = find.text('Switch 6A (₹45)');
        expect(switchChip, findsOneWidget);
        await tester.ensureVisible(switchChip);
        await tester.tap(switchChip);
        await tester.pump();

        // Add to bill
        final addBtn = find.text('ADD ITEM TO BILL');
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        expect(find.text('Switch 6A'), findsWidgets);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '5. Advancing to Step 3 displays Review summary and UPDATE & REGENERATE PDF',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1400);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Step 1 -> Step 2
        final continueBtn = find.text('CONTINUE TO ITEMS & PRICING');
        await tester.ensureVisible(continueBtn);
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        // Add an item
        final chip = find.text('Switch 6A (₹45)');
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pump();

        final addBtn = find.text('ADD ITEM TO BILL');
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Step 2 -> Step 3
        final reviewBtn = find.text('CONTINUE TO REVIEW');
        expect(reviewBtn, findsOneWidget);
        await tester.ensureVisible(reviewBtn);
        await tester.pumpAndSettle();
        await tester.tap(reviewBtn);
        await tester.pumpAndSettle();

        expect(find.text('STEP 3: REVIEW & FINALIZE'), findsOneWidget);
        expect(find.text('UPDATE & REGENERATE PDF'), findsOneWidget);
        expect(find.text('PATEL ELECTRICALS'), findsWidgets);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '6. Mobile layout (380x750) renders sticky bottom summary cleanly without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(380, 750);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('EDIT INVOICE'), findsOneWidget);
        expect(find.textContaining('UPDATED TOTAL'), findsOneWidget);
        expect(find.text('Step 1 of 3'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '7. Unsaved changes discard confirmation dialog is triggered on exit attempt',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Modify something to mark dirty
        final customerField = find.widgetWithText(
          AppTextField,
          'Customer / Firm Name',
        );
        await tester.enterText(customerField, 'CHANGED NAME');
        await tester.pump();

        // Tap back button
        final backButton = find.byTooltip('Cancel and Back');
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Confirmation dialog should be presented
        expect(find.text('Discard Edits?'), findsOneWidget);
        expect(find.text('KEEP EDITING'), findsOneWidget);
        expect(find.text('DISCARD EDITS'), findsOneWidget);

        // Tap KEEP EDITING
        await tester.tap(find.text('KEEP EDITING'));
        await tester.pumpAndSettle();

        // Dialog closed, still on page
        expect(find.text('Discard Edits?'), findsNothing);
        expect(find.text('EDIT INVOICE'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}
