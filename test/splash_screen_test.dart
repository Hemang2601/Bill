import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/splash_screen.dart';
import 'package:bill/login_page.dart';
import 'package:bill/dashboard_page.dart';
import 'package:bill/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String artifactDir =
      r'C:\Users\Admin\.gemini\antigravity\brain\984986f9-e387-41a0-9ff9-9ba97a78e1bf';

  group('Premium Splash Screen Tests - Shree Shakti Electric', () {
    testWidgets(
      '1. Splash screen renders branding, emblem, title, tagline and progress track',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'isLoggedIn': false,
          'userName': '',
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 600),
            ),
          ),
        );
        await tester.pump();

        // Verify Deep Navy background (#071A35)
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, const Color(0xFF071A35));

        // Advance animation slightly to reveal elements
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('SHREE SHAKTI ELECTRIC'), findsOneWidget);
        expect(find.text('SMART BILLING. SIMPLE BUSINESS.'), findsOneWidget);
        expect(find.byIcon(Icons.electric_bolt_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '2. Cold startup without logged-in session routes smoothly to LoginPage',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'isLoggedIn': false,
          'userName': '',
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 400),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();

        expect(find.byType(LoginPage), findsOneWidget);
      },
    );

    testWidgets(
      '3. Startup with active session routes directly to DashboardPage with manager name',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'isLoggedIn': true,
          'userName': 'Suresh',
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 400),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardPage), findsOneWidget);
        expect(find.textContaining('Suresh'), findsWidgets);
      },
    );

    testWidgets(
      '4. Desktop Layout (1280x800) renders cleanly with balanced spacing and no overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 600),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('SHREE SHAKTI ELECTRIC'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '5. Mobile Layout (360x700) adapts proportionally without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 600),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('SHREE SHAKTI ELECTRIC'), findsOneWidget);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets(
      '6. Dynamic window resizing does not disrupt animation controller',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1000, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 600),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Resize window dynamically to tablet
        tester.view.physicalSize = const Size(768, 1024);
        await tester.pump(const Duration(milliseconds: 100));

        // Resize window dynamically to narrow mobile
        tester.view.physicalSize = const Size(320, 600);
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );

    testWidgets('7. Capture SplashScreen Visual Previews (Desktop & Mobile)', (
      WidgetTester tester,
    ) async {
      final desktopKey = GlobalKey();

      // 1. Capture Desktop View (1200 x 800)
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        RepaintBoundary(
          key: desktopKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 2000),
            ),
          ),
        ),
      );
      // Advance to full brand reveal scene (Scene 3 & 4)
      await tester.pump(const Duration(milliseconds: 1200));

      await tester.runAsync(() async {
        final boundary =
            desktopKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final file = File('$artifactDir/splash_screen_desktop.png');
        await file.writeAsBytes(pngBytes);
        expect(file.existsSync(), isTrue);
      });

      // 2. Capture Mobile View (390 x 844)
      final mobileKey = GlobalKey();
      tester.view.physicalSize = const Size(390, 844);

      await tester.pumpWidget(
        RepaintBoundary(
          key: mobileKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreen(
              overrideDuration: Duration(milliseconds: 2000),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));

      await tester.runAsync(() async {
        final boundary =
            mobileKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();

        final file = File('$artifactDir/splash_screen_mobile.png');
        await file.writeAsBytes(pngBytes);
        expect(file.existsSync(), isTrue);
      });

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}
