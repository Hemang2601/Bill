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

  group('EditInvoicePage UI & Functional Tests', () {
    testWidgets(
      '1. Edit Invoice screen renders correctly with prepopulated metadata',
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

        // Section titles
        expect(find.text('CUSTOMER & INVOICE INFO'), findsOneWidget);
        expect(find.text('QUICK INVENTORY CHIPS'), findsOneWidget);
        expect(find.text('BILLING LINE ITEMS'), findsOneWidget);
        expect(find.text('INVOICE IDENTIFICATION'), findsOneWidget);
        expect(find.text('UPDATED SUMMARY'), findsOneWidget);
        expect(find.text('UPDATE & REGENERATE PDF'), findsOneWidget);

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

    testWidgets('2. Customer details can be modified', (
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

      final phoneField = find.widgetWithText(AppTextField, 'Mobile Number');
      await tester.enterText(phoneField, '9988776655');
      await tester.pump();

      expect(find.text('9988776655'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      '3. Adding and removing line items updates item count and subtotal',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1100);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // There is 1 default item row added if db returns empty in test mode
        expect(find.text('1 ITEM'), findsOneWidget);

        // Add a second item
        final addItemBtn = find.text('ADD NEW LINE ITEM');
        expect(addItemBtn, findsOneWidget);
        await tester.tap(addItemBtn);
        await tester.pump();

        expect(find.text('2 ITEMS'), findsOneWidget);

        // Tap remove on the second item
        final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
        expect(deleteButtons, findsNWidgets(2));
        await tester.tap(deleteButtons.last);
        await tester.pump();

        expect(find.text('1 ITEM'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '4. Quick catalog chip updates empty line item or appends new item',
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

        final switchChip = find.text('Switch 6A (₹45)');
        expect(switchChip, findsOneWidget);

        await tester.tap(switchChip);
        await tester.pump();

        expect(find.text('Switch 6A'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '5. Mobile layout renders sticky bottom bar and mobile items list',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: EditInvoicePage(existingInvoice: sampleInvoice),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Mobile sticky bottom bar contains 'UPDATED TOTAL' and 'UPDATE & SAVE'
        expect(find.text('UPDATED TOTAL'), findsOneWidget);
        expect(find.text('UPDATE & SAVE'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '6. Unsaved changes discard confirmation dialog is triggered on exit attempt',
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
