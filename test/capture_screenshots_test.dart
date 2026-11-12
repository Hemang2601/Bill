import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/login_page.dart';
import 'package:bill/dashboard_page.dart';
import 'package:bill/create_invoice.dart';
import 'package:bill/history_page.dart';
import 'package:bill/edit_invoice_page.dart';
import 'package:bill/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const artifactDir =
      r'C:\Users\Admin\.gemini\antigravity\brain\984986f9-e387-41a0-9ff9-9ba97a78e1bf';

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'userName': 'Suresh',
    });
  });

  testWidgets('Capture LoginPage Screenshot - Desktop & Mobile', (
    WidgetTester tester,
  ) async {
    final dir = Directory(artifactDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final desktopKey = GlobalKey();

    // 1. Capture Login Desktop View (1200 x 800)
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: desktopKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary =
          desktopKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final desktopFile = File('$artifactDir/login_screen_desktop.png');
      await desktopFile.writeAsBytes(pngBytes, flush: true);
    });

    // 2. Capture Login Mobile View (412 x 840)
    final mobileKey = GlobalKey();
    tester.view.physicalSize = const Size(412, 840);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: mobileKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final mobileBoundary =
          mobileKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image mobileImage = await mobileBoundary.toImage(
        pixelRatio: 1.0,
      );
      final mobileByteData = await mobileImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final mobileBytes = mobileByteData!.buffer.asUint8List();

      final mobileFile = File('$artifactDir/login_screen_mobile.png');
      await mobileFile.writeAsBytes(mobileBytes, flush: true);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Capture DashboardPage Screenshot - Desktop & Mobile', (
    WidgetTester tester,
  ) async {
    final desktopDashKey = GlobalKey();

    // 1. Capture Dashboard Desktop View (1200 x 850)
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: desktopDashKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Suresh Lakhadiya'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.runAsync(() async {
      final boundary =
          desktopDashKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final desktopFile = File('$artifactDir/dashboard_screen_desktop.png');
      await desktopFile.writeAsBytes(pngBytes, flush: true);
    });

    // 2. Capture Dashboard Mobile View (412 x 860)
    final mobileDashKey = GlobalKey();
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: mobileDashKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const DashboardPage(userName: 'Suresh Lakhadiya'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.runAsync(() async {
      final mobileBoundary =
          mobileDashKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image mobileImage = await mobileBoundary.toImage(
        pixelRatio: 1.0,
      );
      final mobileByteData = await mobileImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final mobileBytes = mobileByteData!.buffer.asUint8List();

      final mobileFile = File('$artifactDir/dashboard_screen_mobile.png');
      await mobileFile.writeAsBytes(mobileBytes, flush: true);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Capture CreateInvoicePage Screenshot - Desktop & Mobile', (
    WidgetTester tester,
  ) async {
    final desktopCreateKey = GlobalKey();

    // 1. Capture Create Invoice Desktop View (1200 x 850)
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: desktopCreateKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const CreateInvoicePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Populate realistic data for screenshot
    final customerField = find.widgetWithText(
      AppTextField,
      'Customer / Firm Name',
    );
    if (customerField.evaluate().isNotEmpty) {
      await tester.enterText(customerField, 'PATEL ELECTRICALS');
      await tester.pump();
    }

    final phoneField = find.widgetWithText(AppTextField, 'Mobile Number');
    if (phoneField.evaluate().isNotEmpty) {
      await tester.enterText(phoneField, '98250 12345');
      await tester.pump();
    }

    // Tap a catalog chip to populate first item
    final switchChip = find.text('Switch 6A (₹45)');
    if (switchChip.evaluate().isNotEmpty) {
      await tester.tap(switchChip);
      await tester.pumpAndSettle();
    }

    // Add another item
    final wireChip = find.text('1.5mm Wire Coil (₹1200)');
    if (wireChip.evaluate().isNotEmpty) {
      await tester.tap(wireChip);
      await tester.pumpAndSettle();
    }

    await tester.runAsync(() async {
      final boundary =
          desktopCreateKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final desktopFile = File('$artifactDir/create_invoice_desktop.png');
      await desktopFile.writeAsBytes(pngBytes, flush: true);
    });

    // 2. Capture Create Invoice Mobile View (412 x 880)
    final mobileCreateKey = GlobalKey();
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: mobileCreateKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const CreateInvoicePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final mobileCustomer = find.widgetWithText(
      AppTextField,
      'Customer / Firm Name',
    );
    if (mobileCustomer.evaluate().isNotEmpty) {
      await tester.enterText(mobileCustomer, 'PATEL ELECTRICALS');
      await tester.pump();
    }

    final mobileChip = find.text('Switch 6A (₹45)');
    if (mobileChip.evaluate().isNotEmpty) {
      await tester.tap(mobileChip);
      await tester.pumpAndSettle();
    }

    await tester.runAsync(() async {
      final mobileBoundary =
          mobileCreateKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image mobileImage = await mobileBoundary.toImage(
        pixelRatio: 1.0,
      );
      final mobileByteData = await mobileImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final mobileBytes = mobileByteData!.buffer.asUint8List();

      final mobileFile = File('$artifactDir/create_invoice_mobile.png');
      await mobileFile.writeAsBytes(mobileBytes, flush: true);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Capture HistoryPage Screenshot - Desktop & Mobile', (
    WidgetTester tester,
  ) async {
    final desktopHistoryKey = GlobalKey();

    // 1. Capture History Desktop View (1200 x 850)
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: desktopHistoryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const HistoryPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.runAsync(() async {
      final boundary =
          desktopHistoryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final desktopFile = File('$artifactDir/history_screen_desktop.png');
      await desktopFile.writeAsBytes(pngBytes, flush: true);
    });

    // 2. Capture History Mobile View (412 x 880)
    final mobileHistoryKey = GlobalKey();
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: mobileHistoryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const HistoryPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.runAsync(() async {
      final mobileBoundary =
          mobileHistoryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image mobileImage = await mobileBoundary.toImage(
        pixelRatio: 1.0,
      );
      final mobileByteData = await mobileImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final mobileBytes = mobileByteData!.buffer.asUint8List();

      final mobileFile = File('$artifactDir/history_screen_mobile.png');
      await mobileFile.writeAsBytes(mobileBytes, flush: true);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Capture EditInvoicePage Screenshot - Desktop & Mobile', (
    WidgetTester tester,
  ) async {
    final desktopEditKey = GlobalKey();

    final Map<String, dynamic> sampleInvoice = {
      'id': 101,
      'billNumber': 'INV-2026-0042',
      'customerName': 'PATEL ELECTRICALS & HARDWARE',
      'phoneNumber': '9876543210',
      'date': '12 Nov 2026',
      'totalAmount': 2450.0,
      'pdfPath': 'D:/Bill/test_invoices/Invoice_INV_2026_0042.pdf',
    };

    // 1. Capture Edit Invoice Desktop View (1200 x 850)
    tester.view.physicalSize = const Size(1200, 850);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: desktopEditKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: EditInvoicePage(existingInvoice: sampleInvoice),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.runAsync(() async {
      final boundary =
          desktopEditKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final desktopFile = File('$artifactDir/edit_invoice_desktop.png');
      await desktopFile.writeAsBytes(pngBytes, flush: true);
    });

    // 2. Capture Edit Invoice Mobile View (412 x 880)
    final mobileEditKey = GlobalKey();
    tester.view.physicalSize = const Size(412, 880);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      RepaintBoundary(
        key: mobileEditKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: EditInvoicePage(existingInvoice: sampleInvoice),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.runAsync(() async {
      final mobileBoundary =
          mobileEditKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image mobileImage = await mobileBoundary.toImage(
        pixelRatio: 1.0,
      );
      final mobileByteData = await mobileImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final mobileBytes = mobileByteData!.buffer.asUint8List();

      final mobileFile = File('$artifactDir/edit_invoice_mobile.png');
      await mobileFile.writeAsBytes(mobileBytes, flush: true);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Capture Dialog Screenshots - Delete Confirmation & Success', (
    WidgetTester tester,
  ) async {
    final dialogKey = GlobalKey();

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;

    // 1. Capture Delete Invoice Dialog
    await tester.pumpWidget(
      RepaintBoundary(
        key: dialogKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppDialog.showDeleteInvoiceConfirmation(
                    context: context,
                    billNumber: 'INV-2026-0042',
                    customerName: 'PATEL ELECTRICALS',
                  );
                });
                return const Center(child: Text("Shree Shakti Electric"));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.runAsync(() async {
      final boundary =
          dialogKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final deleteDialogFile = File(
        '$artifactDir/dialog_delete_confirmation.png',
      );
      await deleteDialogFile.writeAsBytes(pngBytes, flush: true);
    });

    // 2. Capture Discard Changes Dialog
    final discardKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: discardKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppDialog.showDiscardChangesConfirmation(
                    context: context,
                    title: "Discard Invoice?",
                    message:
                        "Are you sure you want to discard this bill? All entered customer details and items will be lost.",
                  );
                });
                return const Center(child: Text("Shree Shakti Electric"));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.runAsync(() async {
      final boundary =
          discardKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final discardDialogFile = File(
        '$artifactDir/dialog_discard_confirmation.png',
      );
      await discardDialogFile.writeAsBytes(pngBytes, flush: true);
    });

    // 3. Capture Sign Out Dialog
    final logoutKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: logoutKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppDialog.showLogoutConfirmation(
                    context: context,
                    userName: "Suresh",
                  );
                });
                return const Center(child: Text("Shree Shakti Electric"));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.runAsync(() async {
      final boundary =
          logoutKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final logoutDialogFile = File(
        '$artifactDir/dialog_logout_confirmation.png',
      );
      await logoutDialogFile.writeAsBytes(pngBytes, flush: true);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
    'Capture CreateInvoice Wizard Steps & Navigation Drawer Screenshots',
    (WidgetTester tester) async {
      // 1. Capture Step 1: Customer Details
      final step1Key = GlobalKey();
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        RepaintBoundary(
          key: step1Key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const CreateInvoicePage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Enter sample customer details
      final customerField = find.widgetWithText(
        AppTextField,
        'Customer / Firm Name',
      );
      final phoneField = find.widgetWithText(
        AppTextField,
        'Mobile Number (Optional)',
      );
      await tester.enterText(customerField, 'PATEL ELECTRICALS');
      await tester.enterText(phoneField, '9876543210');
      await tester.pump();

      await tester.runAsync(() async {
        final boundary =
            step1Key.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final step1File = File('$artifactDir/wizard_step1_customer.png');
        await step1File.writeAsBytes(pngBytes, flush: true);
      });

      // 2. Advance to Step 2: Items & Pricing
      await tester.tap(find.text('CONTINUE TO ITEMS & PRICING'));
      await tester.pumpAndSettle();

      // Add some sample items
      await tester.tap(find.text('Switch 6A (₹45)'));
      await tester.pump();
      await tester.tap(find.text('ADD ITEM TO BILL'));
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

      await tester.enterText(nameField, 'Anchor Roma Socket 6A');
      await tester.enterText(qtyField, '4');
      await tester.enterText(priceField, '85');
      await tester.pump();
      await tester.tap(find.text('ADD ITEM TO BILL'));
      await tester.pumpAndSettle();

      await tester.enterText(nameField, 'Philips LED Bulb 9W Cool Day');
      await tester.enterText(qtyField, '6');
      await tester.enterText(priceField, '120');
      await tester.pump();
      await tester.tap(find.text('ADD ITEM TO BILL'));
      await tester.pumpAndSettle();

      // Dismiss notification snackbar before continuing
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary =
            step1Key.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final step2File = File('$artifactDir/wizard_step2_items.png');
        await step2File.writeAsBytes(pngBytes, flush: true);
      });

      // 3. Advance to Step 3: Review & Finalize
      await tester.ensureVisible(find.text('CONTINUE TO REVIEW'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUE TO REVIEW'));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary =
            step1Key.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final step3File = File('$artifactDir/wizard_step3_review.png');
        await step3File.writeAsBytes(pngBytes, flush: true);
      });

      // 4. Capture Navigation Drawer
      final scaffoldKey = GlobalKey<ScaffoldState>();
      final drawerWidgetKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: drawerWidgetKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: Scaffold(
              key: scaffoldKey,
              appBar: AppBar(title: const Text("Test")),
              drawer: const AppNavigationDrawer(currentRoute: '/dashboard'),
              body: const Center(child: Text("Dashboard")),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Open drawer
      scaffoldKey.currentState?.openDrawer();
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary =
            drawerWidgetKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final drawerFile = File('$artifactDir/app_navigation_drawer.png');
        await drawerFile.writeAsBytes(pngBytes, flush: true);
      });

      // 5. Expand Manager Profile Accordion in Drawer
      final profileTile = find.text('Suresh Lakhadiya');
      await tester.tap(profileTile);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary =
            drawerWidgetKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final profileFile = File(
          '$artifactDir/manager_profile_accordion_expanded.png',
        );
        await profileFile.writeAsBytes(pngBytes, flush: true);
      });

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
