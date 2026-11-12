import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bill/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 8 Micro-Interactions, Notifications & Dialogs Tests', () {
    testWidgets(
      '1. AppNotification displays success and error variants correctly',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => AppNotification.showSuccess(
                        context,
                        "Invoice created successfully",
                      ),
                      child: const Text("Show Success"),
                    ),
                    ElevatedButton(
                      onPressed: () => AppNotification.showError(
                        context,
                        "Failed to load database",
                      ),
                      child: const Text("Show Error"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Trigger Success
        await tester.tap(find.text("Show Success"));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text("Invoice created successfully"), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

        // Close notification using close icon
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Trigger Error
        await tester.tap(find.text("Show Error"));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text("Failed to load database"), findsOneWidget);
        expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '2. AppDialog.showDeleteInvoiceConfirmation renders formatted confirmation',
      (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await AppDialog.showDeleteInvoiceConfirmation(
                      context: context,
                      billNumber: "INV-2026-0005",
                      customerName: "PATEL ELECTRICALS",
                    );
                  },
                  child: const Text("Open Delete Dialog"),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text("Open Delete Dialog"));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text("Delete Invoice?"), findsOneWidget);
        expect(find.textContaining("INV-2026-0005"), findsOneWidget);
        expect(find.textContaining("PATEL ELECTRICALS"), findsOneWidget);
        expect(find.text("DELETE INVOICE"), findsOneWidget);
        expect(find.text("CANCEL"), findsOneWidget);

        // Confirm deletion
        await tester.tap(find.text("DELETE INVOICE"));
        await tester.pumpAndSettle();

        expect(result, isTrue);
        expect(find.text("Delete Invoice?"), findsNothing);
      },
    );

    testWidgets(
      '3. AppDialog.showDiscardChangesConfirmation renders warning dialog',
      (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await AppDialog.showDiscardChangesConfirmation(
                      context: context,
                      title: "Discard Edits?",
                      confirmLabel: "DISCARD EDITS",
                    );
                  },
                  child: const Text("Open Discard Dialog"),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text("Open Discard Dialog"));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text("Discard Edits?"), findsOneWidget);
        expect(find.text("KEEP EDITING"), findsOneWidget);
        expect(find.text("DISCARD EDITS"), findsOneWidget);

        // Cancel discard
        await tester.tap(find.text("KEEP EDITING"));
        await tester.pumpAndSettle();

        expect(result, isFalse);
      },
    );

    testWidgets('4. AppDialog.showLogoutConfirmation renders logout modal', (
      WidgetTester tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.showLogoutConfirmation(
                    context: context,
                    userName: "Suresh",
                  );
                },
                child: const Text("Open Logout Dialog"),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text("Open Logout Dialog"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Sign Out"), findsOneWidget);
      expect(find.textContaining("Suresh"), findsOneWidget);
      expect(find.text("SIGN OUT"), findsOneWidget);
      expect(find.text("CANCEL"), findsOneWidget);

      await tester.tap(find.text("CANCEL"));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets(
      '5. AppDialog.showInvoiceSuccessDialog renders complete success modal with actions',
      (WidgetTester tester) async {
        bool finished = false;
        final dummyFile = File("dummy.pdf");
        final dummyBytes = Uint8List(10);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppDialog.showInvoiceSuccessDialog(
                      context: context,
                      billNumber: "INV-2026-0088",
                      totalAmount: 4850.0,
                      pdfFile: dummyFile,
                      pdfBytes: dummyBytes,
                      isNewInvoice: true,
                      onFinish: () {
                        finished = true;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: const Text("Open Success Dialog"),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text("Open Success Dialog"));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text("Invoice Generated Successfully!"), findsOneWidget);
        expect(find.text("INV-2026-0088"), findsOneWidget);
        expect(find.text("SHARE PDF"), findsOneWidget);
        expect(find.text("VIEW / PRINT"), findsOneWidget);
        expect(find.text("FINISH & EXIT"), findsOneWidget);

        await tester.tap(find.text("FINISH & EXIT"));
        await tester.pumpAndSettle();

        expect(finished, isTrue);
      },
    );

    testWidgets('6. AppButton keyboard focus & Enter/Space activation', (
      WidgetTester tester,
    ) async {
      int pressCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: AppButton(
                label: "ACTIVATE ME",
                onPressed: () => pressCount++,
              ),
            ),
          ),
        ),
      );

      // Request focus
      final focusNode = Focus.of(tester.element(find.text("ACTIVATE ME")));
      focusNode.requestFocus();
      await tester.pump();

      // Press Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressCount, equals(1));

      // Press Space key
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(pressCount, equals(2));
    });

    testWidgets('7. AppShimmer renders and animates gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppShimmer(width: 200, height: 40)),
        ),
      );

      expect(find.byType(AppShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  });
}
