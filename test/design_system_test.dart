import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bill/core/core.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats Indian currency with decimals', () {
      final result = CurrencyFormatter.format(12450.50, showDecimals: true);
      expect(result.contains('12,450.50'), isTrue);
      expect(result.contains('₹'), isTrue);
    });

    test('formats Indian currency compact without decimals', () {
      final result = CurrencyFormatter.format(150000, showDecimals: false);
      expect(result.contains('1,50,000'), isTrue);
      expect(result.contains('₹'), isTrue);
    });

    test('formats raw numbers without currency symbol', () {
      final result = CurrencyFormatter.formatRaw(987654.32, showDecimals: true);
      expect(result, '9,87,654.32');
    });
  });

  group('Design System Widget Smoke Tests', () {
    testWidgets(
      'AppButton renders with primary variant and triggers callback',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppButton(
                label: 'CREATE INVOICE',
                icon: Icons.add,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.text('CREATE INVOICE'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        await tester.tap(find.text('CREATE INVOICE'));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      },
    );

    testWidgets('AppTextField accepts text input and shows label', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Customer Name',
              hint: 'Enter customer name',
              prefixIcon: Icons.person_outline,
            ),
          ),
        ),
      );

      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Enter customer name'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ramesh Patel');
      expect(controller.text, 'Ramesh Patel');
    });

    testWidgets('AppCard renders child with styled borders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AppCard(child: Text('Card Content'))),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('AppEmptyState renders icon, title and action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Bills Found',
              message: 'Try adjusting your filters or date range',
              actionLabel: 'Create Bill',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Bills Found'), findsOneWidget);
      expect(
        find.text('Try adjusting your filters or date range'),
        findsOneWidget,
      );
      expect(find.text('Create Bill'), findsOneWidget);

      await tester.tap(find.text('Create Bill'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppSectionHeader renders title and action label', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Latest Invoices',
              actionLabel: 'VIEW ALL',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('LATEST INVOICES'), findsOneWidget);
      expect(find.text('VIEW ALL'), findsOneWidget);

      await tester.tap(find.text('VIEW ALL'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });

    testWidgets(
      'AppStatCard renders financial metric with badge and animated counter',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: AppStatCard(
                title: 'Total Revenue',
                value: 75400,
                isCurrency: true,
                icon: Icons.trending_up,
                badgeText: 'LIVE',
              ),
            ),
          ),
        );

        expect(find.text('TOTAL REVENUE'), findsOneWidget);
        expect(find.text('LIVE'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byType(AnimatedCountText), findsOneWidget);
      },
    );
  });
}
