import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/create_invoice.dart';
import 'package:bill/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userName': 'Suresh',
    });
  });

  group('CreateInvoicePage 3-Step Wizard UI & Functional Tests', () {
    testWidgets(
      '1. Wizard renders correctly with Step Indicator and Step 1 Customer Details',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('CREATE NEW BILL'), findsOneWidget);
        expect(find.text('SHREE SHAKTI ELECTRIC • WIZARD'), findsOneWidget);

        // Verify Step Indicator items
        expect(find.text('Customer'), findsOneWidget);
        expect(find.text('Items'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);

        // Verify Step 1 fields
        expect(find.text('STEP 1: CUSTOMER DETAILS'), findsOneWidget);
        expect(
          find.widgetWithText(AppTextField, 'Customer / Firm Name'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(AppTextField, 'Mobile Number (Optional)'),
          findsOneWidget,
        );
        expect(find.text('CONTINUE TO ITEMS & PRICING'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '2. Keyboard Next and Done actions work across Customer fields',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final customerField = find.widgetWithText(
          AppTextField,
          'Customer / Firm Name',
        );
        final phoneField = find.widgetWithText(
          AppTextField,
          'Mobile Number (Optional)',
        );

        await tester.enterText(customerField, 'PATEL ELECTRICALS');
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();

        expect(find.text('PATEL ELECTRICALS'), findsOneWidget);

        await tester.enterText(phoneField, '9876543210');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.text('9876543210'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('3. Invalid phone number shows validation error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateInvoicePage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final phoneField = find.widgetWithText(
        AppTextField,
        'Mobile Number (Optional)',
      );
      await tester.enterText(phoneField, '12345'); // invalid length
      await tester.pump();

      final continueBtn = find.text('CONTINUE TO ITEMS & PRICING');
      await tester.tap(continueBtn);
      await tester.pump();

      expect(
        find.text('Please enter a valid 10-digit mobile number'),
        findsOneWidget,
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      '4. Advancing to Step 2 renders Items & Pricing screen with quick chips',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Tap Continue
        final continueBtn = find.text('CONTINUE TO ITEMS & PRICING');
        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        expect(find.text('STEP 2: ITEMS & PRICING'), findsOneWidget);
        expect(find.text('POPULAR ELECTRICAL ITEMS'), findsOneWidget);
        expect(find.text('Switch 6A (₹45)'), findsOneWidget);
        expect(find.text('ADD ITEM TO BILL'), findsOneWidget);
        expect(find.text('No items added yet'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '5. Quick catalog chip inserts item and user can add it to bill',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Continue to step 2
        await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
        await tester.pumpAndSettle();

        // Tap chip
        final switchChip = find.text('Switch 6A (₹45)');
        await tester.tap(switchChip);
        await tester.pump();

        expect(find.text('Switch 6A'), findsOneWidget);
        expect(find.text('45'), findsOneWidget);

        // Tap Add item to bill
        await tester.tap(find.text('ADD ITEM TO BILL'));
        await tester.pumpAndSettle();

        expect(find.text('1 ITEM'), findsOneWidget);
        expect(find.text('Switch 6A'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '6. Adding multiple items with fractional quantities calculates grand total accurately',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
        await tester.pumpAndSettle();

        // Add Item 1: 2.5 × ₹100 = ₹250
        final nameField = find.widgetWithText(
          AppTextField,
          'Product / Item Description *',
        );
        final qtyField = find.widgetWithText(AppTextField, 'Quantity *');
        final priceField = find.widgetWithText(
          AppTextField,
          'Rate per Unit (₹) *',
        );

        await tester.enterText(nameField, 'Flexible Conduit Pipe');
        await tester.enterText(qtyField, '2.5');
        await tester.enterText(priceField, '100');
        await tester.pump();

        await tester.tap(find.text('ADD ITEM TO BILL'));
        await tester.pumpAndSettle();

        // Add Item 2: 1 × ₹750 = ₹750
        await tester.enterText(nameField, 'Distribution Box');
        await tester.enterText(qtyField, '1');
        await tester.enterText(priceField, '750');
        await tester.pump();

        await tester.tap(find.text('ADD ITEM TO BILL'));
        await tester.pumpAndSettle();

        expect(find.text('2 ITEMS'), findsOneWidget);
        // Grand Total = 250 + 750 = 1000
        expect(find.textContaining('1,000.00'), findsWidgets);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('7. Removing an item updates item count and total', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateInvoicePage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
      await tester.pumpAndSettle();

      // Add Item via chip
      await tester.tap(find.text('Switch 6A (₹45)'));
      await tester.pump();
      await tester.tap(find.text('ADD ITEM TO BILL'));
      await tester.pumpAndSettle();

      expect(find.text('1 ITEM'), findsOneWidget);

      // Delete item
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('No items added yet'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('8. Empty items list prevents advancing to Step 3', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateInvoicePage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
      await tester.pumpAndSettle();

      // Tap Continue to Review without items
      await tester.ensureVisible(find.text('CONTINUE TO REVIEW'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUE TO REVIEW'));
      await tester.pump();

      // Should still be on Step 2
      expect(find.text('STEP 2: ITEMS & PRICING'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      '9. Step 3 renders complete review summary with Customer info, Items, and Grand Total',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Step 1: Customer
        final customerField = find.widgetWithText(
          AppTextField,
          'Customer / Firm Name',
        );
        await tester.enterText(customerField, 'PATEL ELECTRICALS');
        await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
        await tester.pumpAndSettle();

        // Step 2: Items
        await tester.tap(find.text('Switch 6A (₹45)'));
        await tester.pump();
        await tester.tap(find.text('ADD ITEM TO BILL'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('CONTINUE TO REVIEW'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUE TO REVIEW'));
        await tester.pumpAndSettle();

        // Step 3: Review
        expect(find.text('STEP 3: REVIEW & FINALIZE'), findsOneWidget);
        expect(find.text('PATEL ELECTRICALS'), findsOneWidget);
        expect(find.text('Switch 6A'), findsOneWidget);
        expect(find.text('SAVE & GENERATE PDF'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('10. Previous step navigation (Back) preserves entered data', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateInvoicePage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Enter customer name
      final customerField = find.widgetWithText(
        AppTextField,
        'Customer / Firm Name',
      );
      await tester.enterText(customerField, 'KISHAN WIRES');
      await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
      await tester.pumpAndSettle();

      // Tap Back to Customer
      await tester.ensureVisible(find.text('BACK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BACK'));
      await tester.pumpAndSettle();

      // Verify name is preserved
      expect(find.text('KISHAN WIRES'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets(
      '11. Unsaved changes confirmation dialog triggers on exit attempt',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final customerField = find.widgetWithText(
          AppTextField,
          'Customer / Firm Name',
        );
        await tester.enterText(customerField, 'CHANGES EXIST');
        await tester.pump();

        // Tap Back button in AppHeader
        final backBtn = find.byTooltip('Back');
        expect(backBtn, findsOneWidget);
        await tester.tap(backBtn);
        await tester.pumpAndSettle();

        expect(find.text('Discard Bill Draft?'), findsOneWidget);
        expect(find.text('KEEP EDITING'), findsOneWidget);
        expect(find.text('DISCARD'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '12. Desktop layout (1200x800) renders cleanly without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('CREATE NEW BILL'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '13. Mobile layout (380x750) renders cleanly without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(380, 750);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('CREATE NEW BILL'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '14. Entering item name, qty, and rate per unit and submitting unfocuses keyboard and adds item without keyboard icons in fields',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Advance to step 2
        await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
        await tester.pumpAndSettle();

        final nameField = find.widgetWithText(
          AppTextField,
          'Product / Item Description *',
        );
        final qtyField = find.widgetWithText(AppTextField, 'Quantity *');
        final priceField = find.widgetWithText(
          AppTextField,
          'Rate per Unit (₹) *',
        );

        await tester.enterText(nameField, 'MCB 32A Double Pole');
        await tester.pump();
        await tester.enterText(qtyField, '3');
        await tester.pump();
        await tester.enterText(priceField, '450');
        await tester.pump();

        // Keyboard hide icons are removed from the input fields as requested
        final dismissIcons = find.byIcon(Icons.keyboard_hide_rounded);
        expect(dismissIcons, findsNothing);

        // Tap price field and submit via keyboard done action
        await tester.tap(priceField);
        await tester.pumpAndSettle();

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(find.text('1 ITEM'), findsOneWidget);
        expect(find.text('MCB 32A Double Pole'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}
