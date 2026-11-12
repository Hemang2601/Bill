import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/currency_formatter.dart';

/// Helper for converting numerical currency into Indian currency words
abstract class IndianAmountToWords {
  static const List<String> _units = [
    "",
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight",
    "Nine",
    "Ten",
    "Eleven",
    "Twelve",
    "Thirteen",
    "Fourteen",
    "Fifteen",
    "Sixteen",
    "Seventeen",
    "Eighteen",
    "Nineteen",
  ];

  static const List<String> _tens = [
    "",
    "",
    "Twenty",
    "Thirty",
    "Forty",
    "Fifty",
    "Sixty",
    "Seventy",
    "Eighty",
    "Ninety",
  ];

  static String _convertThreeDigits(int n) {
    String res = "";
    if (n >= 100) {
      res += "${_units[n ~/ 100]} Hundred ";
      n %= 100;
    }
    if (n >= 20) {
      final int t = n ~/ 10;
      final int u = n % 10;
      if (u > 0) {
        res += "${_tens[t]}-${_units[u]} ";
      } else {
        res += "${_tens[t]} ";
      }
      n = 0;
    }
    if (n > 0) {
      res += "${_units[n]} ";
    }
    return res.trim();
  }

  /// Converts number into Indian Rupee words (e.g. "Rupees Four Thousand Three Hundred Ninety-Five Only.")
  static String convert(double amount) {
    if (amount <= 0) return "Rupees Zero Only.";

    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    int temp = rupees;
    String words = "";

    // Crores (>= 1,00,00,000)
    if (temp >= 10000000) {
      final int crore = temp ~/ 10000000;
      words += "${_convertThreeDigits(crore)} Crore ";
      temp %= 10000000;
    }

    // Lakhs (>= 1,00,000)
    if (temp >= 100000) {
      final int lakh = temp ~/ 100000;
      words += "${_convertThreeDigits(lakh)} Lakh ";
      temp %= 100000;
    }

    // Thousands (>= 1,000)
    if (temp >= 1000) {
      final int thousand = temp ~/ 1000;
      words += "${_convertThreeDigits(thousand)} Thousand ";
      temp %= 1000;
    }

    // Hundreds and below
    if (temp > 0) {
      words += "${_convertThreeDigits(temp)} ";
    }

    words = words.trim();
    if (words.isEmpty) {
      words = "Zero";
    }

    String result = "Rupees $words";
    if (paise > 0) {
      result += " and ${_convertThreeDigits(paise)} Paise Only.";
    } else {
      result += " Only.";
    }

    return result;
  }
}

/// Centralized service for PDF Generation and File System persistence.
/// Designed for full-page commercial A4 Indian electrical shop invoices.
/// Perfectly reproduces traditional printed Indian business invoice design:
/// - Outer continuous rectangular border enclosing the entire document.
/// - Top bar: Page No., BILL OF SUPPLY, Original Copy.
/// - Centered company branding with specialization and contact info.
/// - Structured two-column Billing & Invoice Details box.
/// - Bordered item table with continuous vertical lines extending all the way down.
/// - Total row and Amount in Words row.
/// - Bottom 3-column box touching the bottom of the page (Terms, Bank Details, Signature).
abstract class InvoicePdfService {
  /// Builds the complete PDF document bytes
  static Future<Uint8List> generateInvoicePdf({
    required String billNumber,
    required String customerName,
    required String phoneNumber,
    required String date,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    // 1. Identify User and Load Manager Signature (internally mapped)
    final prefs = await SharedPreferences.getInstance();
    final String loggedInUser = (prefs.getString('userName') ?? "Suresh")
        .toLowerCase();

    final String sigAssetPath = loggedInUser.contains("hiren")
        ? 'assets/images/hiren.png'
        : 'assets/images/suresh.png';

    final ByteData signatureData = await rootBundle.load(sigAssetPath);
    final pw.MemoryImage signatureImage = pw.MemoryImage(
      signatureData.buffer.asUint8List(),
    );

    final String finalCustomer = customerName.trim().isEmpty
        ? "CASH CUSTOMER"
        : customerName.trim().toUpperCase();
    final String finalPhone = phoneNumber.trim().isEmpty
        ? "N/A"
        : phoneNumber.trim();

    // 2. Check if HSN or Unit columns are needed
    final bool hasHsn = items.any(
      (it) => it['hsn'] != null && it['hsn'].toString().trim().isNotEmpty,
    );
    final bool hasUnit = items.any(
      (it) => it['unit'] != null && it['unit'].toString().trim().isNotEmpty,
    );

    const double pageMargin = 20.0;
    const double contentHeight = 841.89 - (pageMargin * 2); // 801.89
    const double contentWidth = 595.28 - (pageMargin * 2); // 555.28

    // Chunk items per page (10 items per page for clean full-page presentation)
    const int itemsPerPage = 10;
    final int totalPages = items.isEmpty
        ? 1
        : (items.length / itemsPerPage).ceil();

    final pdf = pw.Document();

    for (int pageIdx = 0; pageIdx < totalPages; pageIdx++) {
      final int start = pageIdx * itemsPerPage;
      final int end = (start + itemsPerPage > items.length)
          ? items.length
          : start + itemsPerPage;
      final pageItems = items.isEmpty
          ? <Map<String, dynamic>>[]
          : items.sublist(start, end);
      final bool isLastPage = (pageIdx == totalPages - 1);
      final int currentPageNum = pageIdx + 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(pageMargin),
          build: (pw.Context context) {
            return pw.Container(
              width: contentWidth,
              height: contentHeight,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 1. Top bar: Page No | INVOICE | Original Copy
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.black,
                          width: 0.6,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Page No. $currentPageNum of $totalPages",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          "INVOICE",
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        pw.Text(
                          "Original Copy",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),

                  // 2. Company Name & Info Header (Cleaned: No GST, No PAN, No Email)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.black,
                          width: 0.6,
                        ),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "SHREE SHAKTI ELECTRIC",
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "Specialist in: All types of Electric Fitting, Wiring & Maintenance",
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "Mobile: +91 90336 60384, +91 70160 55176",
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Billing Details & Invoice Details Box
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.black,
                          width: 0.6,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Left Cell: Billing Details
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(
                                  color: PdfColors.black,
                                  width: 0.6,
                                ),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  "Billing Details",
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  "Name: $finalCustomer",
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  "Mobile: $finalPhone",
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Right Cell: Invoice Details
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                  children: [
                                    pw.SizedBox(
                                      width: 70,
                                      child: pw.Text(
                                        "Invoice Number :",
                                        style: const pw.TextStyle(fontSize: 8),
                                      ),
                                    ),
                                    pw.Text(
                                      billNumber,
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  children: [
                                    pw.SizedBox(
                                      width: 70,
                                      child: pw.Text(
                                        "Invoice Date   :",
                                        style: const pw.TextStyle(fontSize: 8),
                                      ),
                                    ),
                                    pw.Text(
                                      date,
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Table Header (Grey background)
                  _buildTableHeader(hasHsn, hasUnit),

                  // 5. Item Rows for current page
                  ...pageItems.asMap().entries.map((entry) {
                    final itemIdx = start + entry.key;
                    final it = entry.value;
                    return _buildItemRow(itemIdx + 1, it, hasHsn, hasUnit);
                  }),

                  // 6. Expanded Vertical Lines Filler (reaches all the way down)
                  pw.Expanded(
                    child: _buildVerticalLinesFiller(hasHsn, hasUnit),
                  ),

                  // If NOT the last page: show continuation note
                  if (!isLastPage)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(
                            color: PdfColors.black,
                            width: 0.6,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Invoice continued on next page...",
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.Text(
                            "Continued >>",
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // If IS last page: 7. Total Row, 8. Amount in Words, 9. Bottom 3-column Box touching bottom
                  if (isLastPage) ...[
                    // 7. Total Row
                    pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(
                            color: PdfColors.black,
                            width: 0.6,
                          ),
                          bottom: pw.BorderSide(
                            color: PdfColors.black,
                            width: 0.6,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                "Total",
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.Container(
                            width: (hasHsn && hasUnit) ? 75 : 80,
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 5,
                            ),
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                left: pw.BorderSide(
                                  color: PdfColors.black,
                                  width: 0.6,
                                ),
                              ),
                            ),
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              "Rs. ${CurrencyFormatter.formatRaw(totalAmount)}",
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 8. Amount in words strip
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.black,
                            width: 0.6,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            "Amount in Words: ",
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              IndianAmountToWords.convert(totalAmount),
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 9. Bottom 2-column box (Terms on left, Signature on right) - exactly touches bottom
                    pw.Container(
                      height: 90,
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          // Col 1: Terms and Conditions (Spacious)
                          pw.Expanded(
                            flex: 6,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  right: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 0.6,
                                  ),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    "Terms and Conditions:",
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 3),
                                  pw.Text(
                                    "E & O.E",
                                    style: const pw.TextStyle(
                                      fontSize: 7.5,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    "1. Goods once sold will not be taken back.",
                                    style: const pw.TextStyle(fontSize: 7.5),
                                  ),
                                  pw.Text(
                                    "2. Guarantee / warranty as per manufacturer policy.",
                                    style: const pw.TextStyle(fontSize: 7.5),
                                  ),
                                  pw.Text(
                                    "3. Subject to local jurisdiction only.",
                                    style: const pw.TextStyle(fontSize: 7.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Col 2: Signature Block
                          pw.Expanded(
                            flex: 4,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    "For, SHREE SHAKTI ELECTRIC",
                                    style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Container(
                                    width: 120,
                                    height: 40,
                                    alignment: pw.Alignment.center,
                                    child: pw.Image(
                                      signatureImage,
                                      fit: pw.BoxFit.contain,
                                    ),
                                  ),
                                  pw.Container(
                                    width: 130,
                                    height: 0.6,
                                    color: PdfColors.black,
                                  ),
                                  pw.Text(
                                    "Authorized Signatory",
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    return await pdf.save();
  }

  /// Builds Table Header with Grey Background and Thin Black Borders
  static pw.Widget _buildTableHeader(bool hasHsn, bool hasUnit) {
    if (hasHsn && hasUnit) {
      return pw.Container(
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFE5E7EB),
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
          ),
        ),
        child: pw.Row(
          children: [
            pw.Container(
              width: 28,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Sr.",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(width: 0.6, height: 18, color: PdfColors.black),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  "Item Description",
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            pw.Container(width: 0.6, height: 18, color: PdfColors.black),
            pw.Container(
              width: 50,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "HSN/SAC",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(width: 0.6, height: 18, color: PdfColors.black),
            pw.Container(
              width: 35,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Qty",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(width: 0.6, height: 18, color: PdfColors.black),
            pw.Container(
              width: 35,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                "Unit",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(width: 0.6, height: 18, color: PdfColors.black),
            pw.Container(
              width: 65,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Rate (Rs.)",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(width: 0.6, height: 18, color: PdfColors.black),
            pw.Container(
              width: 75,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Amount (Rs.)",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE5E7EB),
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 32,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              "Sr.",
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Container(width: 0.6, height: 18, color: PdfColors.black),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                "Item Description",
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.Container(width: 0.6, height: 18, color: PdfColors.black),
          pw.Container(
            width: 45,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              "Qty",
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Container(width: 0.6, height: 18, color: PdfColors.black),
          pw.Container(
            width: 70,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Rate (Rs.)",
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Container(width: 0.6, height: 18, color: PdfColors.black),
          pw.Container(
            width: 80,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Amount (Rs.)",
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single bordered Item Row
  static pw.Widget _buildItemRow(
    int sr,
    Map<String, dynamic> item,
    bool hasHsn,
    bool hasUnit,
  ) {
    final String name = (item['name'] is TextEditingController)
        ? (item['name'] as TextEditingController).text
        : (item['itemName']?.toString().isNotEmpty == true
              ? item['itemName'].toString()
              : (item['name']?.toString() ?? item['title']?.toString() ?? ''));
    final double qty = (item['qty'] is TextEditingController)
        ? (double.tryParse((item['qty'] as TextEditingController).text) ?? 0.0)
        : (double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0);
    final double price = (item['price'] is TextEditingController)
        ? (double.tryParse((item['price'] as TextEditingController).text) ??
              0.0)
        : (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0);

    final String qtyStr = (qty % 1 == 0)
        ? qty.toInt().toString()
        : qty.toStringAsFixed(2);
    final String priceStr = CurrencyFormatter.formatRaw(price);
    final String amountStr = CurrencyFormatter.formatRaw(qty * price);

    if (hasHsn && hasUnit) {
      return pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 28,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text("$sr", style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Container(width: 0.6, height: 20, color: PdfColors.black),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  name.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ),
            pw.Container(width: 0.6, height: 20, color: PdfColors.black),
            pw.Container(
              width: 50,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                item['hsn']?.toString() ?? '-',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.Container(width: 0.6, height: 20, color: PdfColors.black),
            pw.Container(
              width: 35,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(qtyStr, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Container(width: 0.6, height: 20, color: PdfColors.black),
            pw.Container(
              width: 35,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                item['unit']?.toString() ?? '-',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            pw.Container(width: 0.6, height: 20, color: PdfColors.black),
            pw.Container(
              width: 65,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(priceStr, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.Container(width: 0.6, height: 20, color: PdfColors.black),
            pw.Container(
              width: 75,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                amountStr,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 32,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text("$sr", style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Container(width: 0.6, height: 20, color: PdfColors.black),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                name.toUpperCase(),
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ),
          pw.Container(width: 0.6, height: 20, color: PdfColors.black),
          pw.Container(
            width: 45,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(qtyStr, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Container(width: 0.6, height: 20, color: PdfColors.black),
          pw.Container(
            width: 70,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(priceStr, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Container(width: 0.6, height: 20, color: PdfColors.black),
          pw.Container(
            width: 80,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              amountStr,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the vertical filler lines to span whatever remaining vertical space exists
  static pw.Widget _buildVerticalLinesFiller(bool hasHsn, bool hasUnit) {
    if (hasHsn && hasUnit) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(width: 28),
          pw.Container(width: 0.6, color: PdfColors.black),
          pw.Expanded(child: pw.Container()),
          pw.Container(width: 0.6, color: PdfColors.black),
          pw.Container(width: 50),
          pw.Container(width: 0.6, color: PdfColors.black),
          pw.Container(width: 35),
          pw.Container(width: 0.6, color: PdfColors.black),
          pw.Container(width: 35),
          pw.Container(width: 0.6, color: PdfColors.black),
          pw.Container(width: 65),
          pw.Container(width: 0.6, color: PdfColors.black),
          pw.Container(width: 75),
        ],
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(width: 32),
        pw.Container(width: 0.6, color: PdfColors.black),
        pw.Expanded(child: pw.Container()),
        pw.Container(width: 0.6, color: PdfColors.black),
        pw.Container(width: 45),
        pw.Container(width: 0.6, color: PdfColors.black),
        pw.Container(width: 70),
        pw.Container(width: 0.6, color: PdfColors.black),
        pw.Container(width: 80),
      ],
    );
  }

  /// Saves PDF bytes to disk in the standardized "Shakti Electric" folder
  static Future<File> savePdfToFile({
    required String billNumber,
    required Uint8List bytes,
  }) async {
    Directory? baseDir;
    try {
      baseDir = await getExternalStorageDirectory();
    } catch (_) {
      baseDir = null;
    }
    if (baseDir == null) {
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        baseDir = Directory.systemTemp;
      }
    }

    final Directory shaktiDir = Directory("${baseDir.path}/Shakti Electric");
    if (!await shaktiDir.exists()) {
      await shaktiDir.create(recursive: true);
    }

    final String fileName = "Invoice_${billNumber.replaceAll('-', '_')}.pdf";
    final File file = File("${shaktiDir.path}/$fileName");
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Overwrites an existing PDF file or saves to new path if target missing
  static Future<File> overwritePdfFile({
    required String targetPath,
    required String billNumber,
    required Uint8List bytes,
  }) async {
    final File targetFile = File(targetPath);
    final parentDir = targetFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile;
  }
}
