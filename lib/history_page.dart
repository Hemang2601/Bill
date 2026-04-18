import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

import 'database_helper.dart';
import 'edit_invoice_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  // Active Filter States
  String _searchQuery = "";
  DateTime? _startDate;
  DateTime? _endDate;

  // Real-World Accounting Filter Options
  final List<String> _filters = [
    "All Time",
    "This Month",
    "Last Month",
    "Last 3 Months",
    "Last 6 Months",
    "This Year"
  ];
  String _activeFilter = "All Time";

  // Premium Luxury Palette
  final Color kPrimary = const Color(0xFF4338CA);
  final Color kPrimaryLight = const Color(0xFF818CF8);
  final Color kDark = const Color(0xFF0F172A);
  final Color kAccent = const Color(0xFF10B981);
  final Color kBg = const Color(0xFFF8FAFC);
  final Color kCard = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchDataFromDB(); // Initial Load - defaults to "All Time"
  }

  // --- REFRESH DATABASE LOGIC ---
  Future<void> _fetchDataFromDB() async {
    setState(() => _isLoading = true);

    // Calls the DB method with the calculated boundaries
    final data = await DatabaseHelper.instance.getFilteredInvoices(
      searchQuery: _searchQuery,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() {
      _invoices = data;
      _isLoading = false;
    });
  }

  double get _totalVolume => _invoices.fold(0.0, (sum, item) =>
  sum + (double.tryParse(item['totalAmount'].toString()) ?? 0.0));

  // --- LOGIC: REAL-WORLD MONTHLY CALCULATIONS ---
  void _handleFilterSelection(String title) {
    final now = DateTime.now();

    setState(() {
      _activeFilter = title;

      if (title == "All Time") {
        _startDate = null;
        _endDate = null;
      }
      else if (title == "This Month") {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month
      }
      else if (title == "Last Month") {
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0); // Last day of previous month
      }
      else if (title == "Last 3 Months") {
        _startDate = DateTime(now.year, now.month - 2, 1); // Current month + 2 previous
        _endDate = DateTime(now.year, now.month + 1, 0);
      }
      else if (title == "Last 6 Months") {
        _startDate = DateTime(now.year, now.month - 5, 1); // Current month + 5 previous
        _endDate = DateTime(now.year, now.month + 1, 0);
      }
      else if (title == "This Year") {
        _startDate = DateTime(now.year, 1, 1); // Jan 1st
        _endDate = DateTime(now.year, 12, 31); // Dec 31st
      }
    });

    // Re-fetch data immediately based on new date boundaries
    _fetchDataFromDB();
  }

  // --- UI: BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildAnimatedHeader(),
          _buildSearchBox(),
          _buildModernFilterBar(),
          _buildInvoiceList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 70,
      backgroundColor: kBg.withOpacity(0.85),
      elevation: 0,
      centerTitle: false,
      actions: [
        // --- EXPORT BUTTON ---
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Center(
            child: Material(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _exportAllData, // Method defined below
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.ios_share_rounded, color: kPrimary, size: 18),
                      const SizedBox(width: 6),
                      Text("EXPORT",
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimary, kPrimaryLight]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 15),
          Text("History", // Shortened to fit beside Export
              style: TextStyle(color: kDark, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 15),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: kDark.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 12))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Icon(Icons.insert_chart_rounded, size: 140, color: Colors.white.withOpacity(0.03)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: kAccent.withOpacity(0.2), shape: BoxShape.circle),
                      child: Icon(Icons.trending_up_rounded, color: kAccent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _activeFilter == "All Time" ? "TOTAL REVENUE" : "${_activeFilter.toUpperCase()} REVENUE",
                      style: const TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text("₹${_totalVolume.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                ),
                const SizedBox(height: 10),
                Text("${_invoices.length} Bills Found",
                    style: TextStyle(color: kPrimaryLight, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
          ),
          child: TextField(
            onChanged: (v) {
              _searchQuery = v;
              _fetchDataFromDB(); // Instantly search DB on typing
            },
            style: TextStyle(fontWeight: FontWeight.w700, color: kDark, fontSize: 15),
            decoration: InputDecoration(
              hintText: "Search Customer Name or Bill ID...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
              prefixIcon: Icon(Icons.search_rounded, color: kPrimary.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterBar() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            String title = _filters[index];
            bool isActive = _activeFilter == title;
            return GestureDetector(
              onTap: () => _handleFilterSelection(title),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isActive ? kPrimary : kCard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isActive) BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
                    if (!isActive) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                  border: Border.all(color: isActive ? kPrimary : Colors.grey.shade200, width: isActive ? 0 : 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.3
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInvoiceList() {
    if (_isLoading) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    if (_invoices.isEmpty) return _buildEmptyState();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (ctx, index) {
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 350 + (index * 50)),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutQuart,
              builder: (context, double value, child) => Opacity(
                opacity: value,
                child: Transform.translate(offset: Offset(0, 30 * (1 - value)), child: child),
              ),
              child: _buildInvoiceItem(_invoices[index]),
            );
          },
          childCount: _invoices.length,
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(Map<String, dynamic> inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _openModernDetail(inv),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: kPrimary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv['customerName']?.toString().toUpperCase() ?? "UNKNOWN",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w900, color: kDark, fontSize: 16, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "#${inv['billNumber']}",
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(inv['date'].toString(), style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${inv['totalAmount']}",
                      style: TextStyle(fontWeight: FontWeight.w900, color: kAccent, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openModernDetail(Map<String, dynamic> inv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows bottom sheet to expand to screen height
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, -10))],
          ),
          // FIXED OVERFLOW: Wrapped the column in a SingleChildScrollView
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 35),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: kPrimary, size: 45),
                ),
                const SizedBox(height: 16),
                const Text("RECEIPT GENERATED", style: TextStyle(letterSpacing: 2.5, fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("₹${inv['totalAmount']}", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: kDark, letterSpacing: -1.5)),
                ),
                const SizedBox(height: 25),
                Row(
                  children: List.generate(
                    40,
                        (index) => Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _receiptRow(Icons.person_outline_rounded, "Customer", inv['customerName']),
                _receiptRow(Icons.tag_rounded, "Bill Number", "#${inv['billNumber']}"),
                _receiptRow(Icons.calendar_today_rounded, "Date Issued", inv['date']),
                const SizedBox(height: 35),
                Row(
                  children: [
                    Expanded(child: _safeActionButton(Icons.edit_document, "Edit", Colors.orange.shade500, () {
                      Navigator.pop(context);
                      _editInvoice(inv);
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _safeActionButton(Icons.share_rounded, "Share", kAccent, () {
                      Share.shareXFiles([XFile(inv['pdfPath'])]);
                    })),
                  ],
                ),
                const SizedBox(height: 12),
                _safeActionButton(Icons.visibility_rounded, "View Original Document", kPrimary, () => _viewPdf(inv)),
                const SizedBox(height: 12),
                _safeActionButton(Icons.delete_forever_rounded, "Delete Record", Colors.red.shade50, () {
                  Navigator.pop(context);
                  _confirmDelete(inv);
                }, textColor: Colors.redAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: kDark, fontWeight: FontWeight.w900, fontSize: 15)
            ),
          ),
        ],
      ),
    );
  }

  Widget _safeActionButton(IconData icon, String label, Color bgColor, VoidCallback onTap, {Color textColor = Colors.white}) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
              Flexible( // Ensures text doesn't cause width overflow
                child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textColor, letterSpacing: 0.3)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editInvoice(Map<String, dynamic> inv) async {
    final bool? isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditInvoicePage(existingInvoice: inv)),
    );
    if (isUpdated == true) {
      _fetchDataFromDB();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Invoice updated successfully!", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: kAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _viewPdf(Map<String, dynamic> inv) async {
    final file = File(inv['pdfPath']);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (c) => Scaffold(
        appBar: AppBar(backgroundColor: kDark, title: const Text("Document Preview", style: TextStyle(fontWeight: FontWeight.bold)), foregroundColor: Colors.white, centerTitle: true),
        body: PdfPreview(build: (format) => bytes, useActions: true),
      )));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("PDF file not found!", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> inv) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Text("Delete Record?", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        content: const Text("This action cannot be undone. The database record and associated PDF file will be permanently removed.",
            style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 14)),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: () async {
              await DatabaseHelper.instance.deleteInvoice(inv['id']);
              Navigator.pop(c);
              _fetchDataFromDB();
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.08), blurRadius: 30, spreadRadius: 10)]
              ),
              child: Icon(Icons.receipt_long_rounded, size: 70, color: Colors.grey.shade300),
            ),
            const SizedBox(height: 25),
            Text("No Bills Found", style: TextStyle(color: kDark, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text("No bills match your current filters.", style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _exportAllData() {
    if (_invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data to export"))
      );
      return;
    }

    // Creating a text-based report of the current view
    String report = "SHREE SHAKTI ELECTRIC - SALES REPORT\n";
    report += "Filter: $_activeFilter\n";
    report += "Generated on: ${DateTime.now().toString().split('.')[0]}\n";
    report += "------------------------------------------\n\n";

    for (var inv in _invoices) {
      report += "Bill: #${inv['billNumber']} | Date: ${inv['date']}\n";
      report += "Customer: ${inv['customerName']}\n";
      report += "Amount: ₹${inv['totalAmount']}\n";
      report += "------------------------------------------\n";
    }

    report += "\nTOTAL INVOICES: ${_invoices.length}";
    report += "\nTOTAL REVENUE: ₹${_totalVolume.toStringAsFixed(2)}";

    // Open Share Sheet
    Share.share(report, subject: 'Sales Report - $_activeFilter');
  }
}