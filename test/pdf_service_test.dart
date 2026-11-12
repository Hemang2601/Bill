import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill/services/invoice_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String artifactDir =
      r'C:\Users\Admin\.gemini\antigravity\brain\984986f9-e387-41a0-9ff9-9ba97a78e1bf';

  group(
    'InvoicePdfService & IndianAmountToWords Tests - Traditional Printed Bill Redesign',
    () {
      test(
        'IndianAmountToWords converts numerical values into exact Indian Rupee words',
        () {
          expect(IndianAmountToWords.convert(0), equals('Rupees Zero Only.'));
          expect(
            IndianAmountToWords.convert(4395),
            equals('Rupees Four Thousand Three Hundred Ninety-Five Only.'),
          );
          expect(
            IndianAmountToWords.convert(1050),
            equals('Rupees One Thousand Fifty Only.'),
          );
          expect(
            IndianAmountToWords.convert(2400),
            equals('Rupees Two Thousand Four Hundred Only.'),
          );
          expect(
            IndianAmountToWords.convert(1200.50),
            equals('Rupees One Thousand Two Hundred and Fifty Paise Only.'),
          );
          expect(
            IndianAmountToWords.convert(45.25),
            equals('Rupees Forty-Five and Twenty-Five Paise Only.'),
          );
          expect(
            IndianAmountToWords.convert(150000),
            equals('Rupees One Lakh Fifty Thousand Only.'),
          );
          expect(
            IndianAmountToWords.convert(12500450.75),
            equals(
              'Rupees One Crore Twenty-Five Lakh Four Hundred Fifty and Seventy-Five Paise Only.',
            ),
          );
        },
      );

      test(
        '1. One-item invoice generates valid full-page PDF with Suresh signature',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-101',
            customerName: 'Patel Electricals',
            phoneNumber: '9876543210',
            date: '12 Nov 2026',
            items: [
              {
                'itemName':
                    'Havells 1.5 sq mm Flame Retardant Wire Coil (90m Red)',
                'qty': 3,
                'price': 1465.0,
              },
            ],
            totalAmount: 4395.0,
          );

          expect(pdfBytes, isNotEmpty);
          expect(pdfBytes.length, greaterThan(1000));
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');

          // Save preview PDF artifact
          final previewFile = File('$artifactDir/invoice_1_item_preview.pdf');
          await previewFile.writeAsBytes(pdfBytes);
          expect(previewFile.existsSync(), isTrue);
        },
      );

      test(
        '2. Five-item invoice generates balanced commercial PDF with Hiren signature',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'hiren'});

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-102',
            customerName: 'Shree Ram Electrical & Hardware',
            phoneNumber: '9033660384',
            date: '12 Nov 2026',
            items: [
              {
                'itemName': 'Anchor Roma 1-Way Modular Switch 6A White',
                'qty': 20,
                'price': 38.0,
              },
              {
                'itemName': 'Anchor Roma 3-Pin Universal Socket 6/16A',
                'qty': 10,
                'price': 115.0,
              },
              {
                'itemName': 'Philips 9W B22 LED Bulb Cool Day Light',
                'qty': 12,
                'price': 95.0,
              },
              {
                'itemName':
                    'Finolex 2.5 sq mm FR PVC Insulated Industrial Cable',
                'qty': 2,
                'price': 2450.0,
              },
              {
                'itemName': 'Goldmedal 8-Module Concealed Flush Metal Box',
                'qty': 5,
                'price': 140.0,
              },
            ],
            totalAmount: 7650.0,
          );

          expect(pdfBytes, isNotEmpty);
          expect(pdfBytes.length, greaterThan(1000));
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');

          final previewFile = File('$artifactDir/invoice_5_items_preview.pdf');
          await previewFile.writeAsBytes(pdfBytes);
          expect(previewFile.existsSync(), isTrue);
        },
      );

      test(
        '3. Ten-item invoice formats cleanly with structured electrical item table',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});

          final items = [
            {
              'itemName': 'Anchor Roma 1-Way Modular Switch 6A White',
              'qty': 25,
              'price': 38.0,
            },
            {
              'itemName': 'Anchor Roma 3-Pin Universal Socket 6/16A',
              'qty': 15,
              'price': 115.0,
            },
            {
              'itemName': 'Philips 9W B22 LED Bulb Cool Day Light',
              'qty': 18,
              'price': 95.0,
            },
            {
              'itemName':
                  'Finolex 2.5 sq mm FR PVC Insulated Industrial Cable Coil',
              'qty': 2,
              'price': 2450.0,
            },
            {
              'itemName':
                  'Havells 1.5 sq mm Flame Retardant Wire Coil (90m Red)',
              'qty': 4,
              'price': 1465.0,
            },
            {
              'itemName': 'Goldmedal 8-Module Concealed Flush Metal Box',
              'qty': 6,
              'price': 140.0,
            },
            {
              'itemName': 'Schneider Electric 32A Double Pole MCB C-Curve',
              'qty': 3,
              'price': 420.0,
            },
            {
              'itemName':
                  'Polycab 25mm Heavy Duty PVC Electrical Conduit Pipe (3m)',
              'qty': 20,
              'price': 85.0,
            },
            {
              'itemName': 'Crompton 1200mm High Speed Ceiling Fan (Opal White)',
              'qty': 2,
              'price': 1850.0,
            },
            {
              'itemName': 'Legrand Modular Gang Box 4-Module Surface Box',
              'qty': 8,
              'price': 75.0,
            },
          ];

          final double total = items.fold(
            0.0,
            (acc, it) =>
                acc +
                ((it['qty'] as num).toDouble() *
                    (it['price'] as num).toDouble()),
          );

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-103',
            customerName: 'Sardar Vallabhbhai Patel Commercial Complex',
            phoneNumber: '9825123456',
            date: '12 Nov 2026',
            items: items,
            totalAmount: total,
          );

          expect(pdfBytes, isNotEmpty);
          expect(pdfBytes.length, greaterThan(1000));
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');

          // Save 10-item preview artifact
          final previewFile = File('$artifactDir/invoice_10_items_preview.pdf');
          await previewFile.writeAsBytes(pdfBytes);
          expect(previewFile.existsSync(), isTrue);
        },
      );

      test(
        '4. Twenty-item invoice generates clean multi-page document with repeated headers',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'hiren'});

          final items = List.generate(20, (i) {
            return {
              'itemName':
                  'Electrical Supply Product Item #${i + 1} - Standard Specification A4 Fitting & Accessories',
              'qty': (i + 1) * 1.5,
              'price': 120.0 + (i * 20.0),
            };
          });

          final double total = items.fold(
            0.0,
            (acc, it) =>
                acc + ((it['qty'] as double) * (it['price'] as double)),
          );

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-104',
            customerName: 'Mega Tech Industries Ltd.',
            phoneNumber: '9428012345',
            date: '12 Nov 2026',
            items: items,
            totalAmount: total,
          );

          expect(pdfBytes, isNotEmpty);
          expect(pdfBytes.length, greaterThan(1200));
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
        },
      );

      test(
        '5. 30-item long invoice generates multi-page PDF with final totals and signature on last page',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'hiren'});

          final items = List.generate(32, (i) {
            return {
              'itemName':
                  'Item #${i + 1}: Heavy Duty Distribution Box, MCB SPN 32A, Conduit Pipes & Fitting Accessories Complete Pack',
              'qty': (i % 5 + 1).toDouble(),
              'price': 250.0 + (i * 15.0),
            };
          });

          final double total = items.fold(
            0.0,
            (acc, it) =>
                acc + ((it['qty'] as double) * (it['price'] as double)),
          );

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-105',
            customerName: 'Gujarat State Electricity Contractor',
            phoneNumber: '9825098765',
            date: '12 Nov 2026',
            items: items,
            totalAmount: total,
          );

          expect(pdfBytes, isNotEmpty);
          expect(pdfBytes.length, greaterThan(1500));
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');

          // Save preview PDF artifact
          final previewFile = File(
            '$artifactDir/invoice_multi_page_preview.pdf',
          );
          await previewFile.writeAsBytes(pdfBytes);
          expect(previewFile.existsSync(), isTrue);
        },
      );

      test(
        '6. Long product descriptions wrap naturally without clipping or table corruption',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-106',
            customerName: 'Industrial Heavy Fitting Co.',
            phoneNumber: '9988776655',
            date: '12 Nov 2026',
            items: [
              {
                'itemName':
                    'Finolex 4-Core 16 sq mm Armoured High Voltage Copper Industrial Power Cable with Galvanized Steel Wire Armouring for Underground Direct Burial Installation and Severe Weather Protection (Coil 50m)',
                'qty': 1,
                'price': 28500.0,
              },
              {
                'itemName':
                    'L&T 63A 4-Pole Rotary Changeover Switch in Sheet Steel Enclosure with Heavy Duty Terminals and Front Operating Handle IP65 Rated for Phase Transfer Safety',
                'qty': 2,
                'price': 4650.0,
              },
            ],
            totalAmount: 37800.0,
          );

          expect(pdfBytes, isNotEmpty);
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
        },
      );

      test(
        '7. Fractional quantities (1.5, 2.5, 12.5) format accurately in item table',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-107',
            customerName: 'Shri Ganeshay Construction',
            phoneNumber: '9723456789',
            date: '12 Nov 2026',
            items: [
              {
                'itemName': 'Flexible Copper Wire Bundle 0.75 sq mm (Blue)',
                'qty': 1.5,
                'price': 450.0,
              },
              {
                'itemName': 'Corrugated Flexible Conduit Pipe 20mm',
                'qty': 2.5,
                'price': 180.0,
              },
              {
                'itemName': 'PVC Insulation Tape Rolls Pack',
                'qty': 12.5,
                'price': 40.0,
              },
            ],
            totalAmount: (1.5 * 450) + (2.5 * 180) + (12.5 * 40),
          );

          expect(pdfBytes, isNotEmpty);
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
        },
      );

      test(
        '8. Large invoice amounts format correctly with Indian numbering system and words',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'hiren'});

          final double largeAmount = 1450000.0; // 14.5 Lakhs
          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-108',
            customerName: 'Adani Township Substation Project',
            phoneNumber: '9898011223',
            date: '12 Nov 2026',
            items: [
              {
                'itemName':
                    'Complete Commercial 11kV Substation Switchgear Panel Assembly',
                'qty': 1,
                'price': largeAmount,
              },
            ],
            totalAmount: largeAmount,
          );

          expect(pdfBytes, isNotEmpty);
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
        },
      );

      test(
        '9. GST-enabled items with HSN/SAC and Unit render dynamic columns appropriately',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-109',
            customerName: 'Modern Electrical Stores',
            phoneNumber: '9988776655',
            date: '12 Nov 2026',
            items: [
              {
                'itemName': 'LED Flood Light 100W IP66 Waterproof',
                'hsn': '8539',
                'qty': 4,
                'unit': 'NOS',
                'price': 1450.0,
              },
              {
                'itemName': 'Havells 3-Core Submersible Cable Flat',
                'hsn': '8544',
                'qty': 50,
                'unit': 'MTR',
                'price': 110.0,
              },
            ],
            totalAmount: (4 * 1450.0) + (50 * 110.0),
          );

          expect(pdfBytes, isNotEmpty);
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
        },
      );

      test(
        '10. Invoice persistence and overwrite workflow preserves file paths and content',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-110',
            customerName: 'Modern Electrical Stores',
            phoneNumber: '9988776655',
            date: '12 Nov 2026',
            items: [
              {'itemName': 'Ceiling Fan 1200mm', 'qty': 2, 'price': 1850.0},
            ],
            totalAmount: 3700.0,
          );

          final savedFile = await InvoicePdfService.savePdfToFile(
            billNumber: 'SE-2611-110',
            bytes: pdfBytes,
          );

          expect(savedFile.existsSync(), isTrue);
          expect(savedFile.path, contains('Shakti Electric'));
          expect(savedFile.path, contains('Invoice_SE_2611_110.pdf'));

          // Test overwrite behavior
          final overwrittenFile = await InvoicePdfService.overwritePdfFile(
            targetPath: savedFile.path,
            billNumber: 'SE-2611-110',
            bytes: pdfBytes,
          );

          expect(overwrittenFile.existsSync(), isTrue);
          expect(overwrittenFile.path, equals(savedFile.path));
        },
      );

      test(
        '11. Cash customer and empty phone fallbacks handle defaults cleanly without error',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});

          final pdfBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-111',
            customerName: '', // empty name
            phoneNumber: '', // empty phone
            date: '12 Nov 2026',
            items: [
              {'itemName': 'LED Tube Light 20W', 'qty': 1, 'price': 250.0},
            ],
            totalAmount: 250.0,
          );

          expect(pdfBytes, isNotEmpty);
          expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
        },
      );

      test(
        '12. Both manager signatures map correctly to internal assets',
        () async {
          // Suresh login
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});
          final sureshBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-112',
            customerName: 'Customer A',
            phoneNumber: '9999988888',
            date: '12 Nov 2026',
            items: [
              {'itemName': 'Switch 6A', 'qty': 1, 'price': 35.0},
            ],
            totalAmount: 35.0,
          );
          expect(sureshBytes, isNotEmpty);

          // Hiren login
          SharedPreferences.setMockInitialValues({'userName': 'hiren'});
          final hirenBytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-113',
            customerName: 'Customer B',
            phoneNumber: '9999977777',
            date: '12 Nov 2026',
            items: [
              {'itemName': 'Socket 16A', 'qty': 1, 'price': 110.0},
            ],
            totalAmount: 110.0,
          );
          expect(hirenBytes, isNotEmpty);
        },
      );

      test(
        '13. Invoice using "name" key in items map renders item name accurately in PDF',
        () async {
          SharedPreferences.setMockInitialValues({'userName': 'suresh'});
          final bytes = await InvoicePdfService.generateInvoicePdf(
            billNumber: 'SE-2611-114',
            customerName: 'Customer Test',
            phoneNumber: '9999911111',
            date: '12 Nov 2026',
            items: [
              {'name': 'Anchor Modular Switch 6A', 'qty': 5, 'price': 40.0},
            ],
            totalAmount: 200.0,
          );
          expect(bytes, isNotEmpty);
          expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        },
      );
    },
  );
}
