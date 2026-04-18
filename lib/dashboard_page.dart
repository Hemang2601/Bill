import 'dart:io';
import 'dart:ui';
import 'package:bill/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'create_invoice.dart';
import 'database_helper.dart';
import 'edit_invoice_page.dart'; // <-- ADDED THIS IMPORT

class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _allInvoices = [];
  Map<String, dynamic> _stats = {'totalCount': 0, 'totalRev': 0.0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllInvoices();
      final statsData = await DatabaseHelper.instance.getInvoiceStats();
      if (mounted) {
        setState(() {
          // Dashboard ONLY shows last 5
          _allInvoices = data.take(5).toList();
          _stats = statsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PREMIUM HEADER UPGRADE ---
  Widget _buildPremiumHeader() {
    String formatFullName(String name) {
      if (name.isEmpty) return "Lakhadiya";

      String capitalized = name.split(' ').map((str) {
        if (str.isEmpty) return "";
        return str[0].toUpperCase() + str.substring(1).toLowerCase();
      }).join(' ');

      if (!capitalized.contains("Lakhadiya")) {
        return "$capitalized Lakhadiya".trim();
      }
      return capitalized;
    }

    final String formattedName = formatFullName(widget.userName);

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      automaticallyImplyLeading: false,
      title: const Text(
        "SHREE SHAKTI",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 3,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
            onPressed: _showLogoutDialog,
          ),
        )
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E40AF), Color(0xFF1E1B4B)],
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.blueAccent, Colors.cyanAccent],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: const Color(0xFF0F172A),
                                    child: Text(
                                      formattedName.isNotEmpty ? formattedName[0] : "L",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "AUTHORIZED ADMIN",
                                        style: TextStyle(
                                          color: Colors.blueAccent.shade100,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gpp_good_rounded, color: Colors.greenAccent, size: 14),
                            SizedBox(width: 8),
                            Text(
                              "SECURE SESSION ACTIVE",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STATS WIDGET ---
  Widget _buildModernStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("TOTAL BILLS", _stats['totalCount'].toString(),
              const Color(0xFF1E40AF)),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _statItem("REVENUE", "₹${_stats['totalRev'].toStringAsFixed(0)}",
              const Color(0xFF10B981)),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _statItem("ACTIVE", "LIVE", const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
    ]);
  }

  // --- ACTION GRID ---
  Widget _buildActionGrid() {
    return Row(
      children: [
        _actionBtn("New Bill", Icons.add_rounded, const Color(0xFF2563EB), true, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const CreateInvoicePage()),
          ).then((_) => _refreshData());
        }),
        const SizedBox(width: 15),
        _actionBtn("History", Icons.history_rounded, const Color(0xFF64748B), false, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const HistoryPage()),
          ).then((_) => _refreshData());
        }),
      ],
    );
  }

  Widget _actionBtn(String title, IconData icon, Color color, bool isPrimary, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isPrimary ? null : Border.all(color: Colors.grey.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isPrimary ? Colors.white : color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                  color: isPrimary ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LIST ITEM CARD ---
  Widget _buildAdvancedInvoiceCard(Map<String, dynamic> invoice) {
    return GestureDetector(
      onTap: () => _showInvoiceOptions(invoice),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100)),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_outlined,
                    color: Color(0xFF1E40AF), size: 20)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      invoice['customerName']?.toString().toUpperCase() ??
                          "CASH CUSTOMER",
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 13)),
                  Text("INV #${invoice['billNumber']} • ${invoice['date']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Text("₹${invoice['totalAmount']}",
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF1E40AF))),
          ],
        ),
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---
  Future<void> _handleViewPdfOnly(Map<String, dynamic> invoice) async {
    final String? path = invoice['pdfPath'];
    if (path == null || !await File(path).exists()) {
      _showError("Document missing from local storage.");
      return;
    }
    final bytes = await File(path).readAsBytes();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.05),
            elevation: 0,
            title: Text("PREVIEW: #${invoice['billNumber']}",
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            centerTitle: true,
          ),
          body: Container(
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), color: Colors.white),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PdfPreview(build: (format) => bytes, useActions: false),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSharePdf(Map<String, dynamic> invoice) async {
    final path = invoice['pdfPath'];
    if (path != null && await File(path).exists()) {
      await Share.shareXFiles([XFile(path)],
          text: 'Invoice #${invoice['billNumber']}');
    }
  }

  void _confirmDelete(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Record?"),
        content: const Text("This action cannot be undone. Confirm?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await DatabaseHelper.instance.deleteInvoice(invoice['id']);
              Navigator.pop(context);
              _refreshData();
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UPDATED INVOICE OPTIONS WITH EDIT BUTTON ---
  void _showInvoiceOptions(Map<String, dynamic> invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            Row(
              children: [
                CircleAvatar(
                    backgroundColor: const Color(0xFF1E40AF).withOpacity(0.1),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Color(0xFF1E40AF))),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice['customerName'].toString().toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15)),
                      Text("Invoice #${invoice['billNumber']}",
                          style:
                          const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                ),
              ],
            ),
            const Divider(height: 30),

            _buildActionTile(
              icon: Icons.visibility_rounded,
              title: "View Bill",
              subtitle: "Open PDF Document",
              color: const Color(0xFF2563EB),
              onTap: () => _handleViewPdfOnly(invoice),
            ),

            // --- ADDED EDIT BUTTON HERE ---
            _buildActionTile(
              icon: Icons.edit_document,
              title: "Edit Bill",
              subtitle: "Modify items & regenerate PDF",
              color: Colors.orange,
              onTap: () async {
                Navigator.pop(context); // Close bottom sheet
                final bool? didUpdate = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditInvoicePage(existingInvoice: invoice),
                  ),
                );
                if (didUpdate == true) {
                  _refreshData();
                }
              },
            ),

            _buildActionTile(
              icon: Icons.share_rounded,
              title: "Share Bill",
              subtitle: "Send via social apps",
              color: const Color(0xFF10B981),
              onTap: () => _handleSharePdf(invoice),
            ),

            _buildActionTile(
              icon: Icons.delete_rounded,
              title: "Delete Record",
              subtitle: "Remove from storage",
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(invoice);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      subtitle:
      Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: Colors.grey),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent));
  }

  void _showLogoutDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Logout",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, a1, a2) => Container(),
      transitionBuilder: (ctx, a1, a2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * a1.value, sigmaY: 8 * a1.value),
          child: FadeTransition(
            opacity: a1,
            child: ScaleTransition(
              scale: a1,
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 32),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Sign Out",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Are you sure you want to end your secure session?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('isLoggedIn', false);
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (c) => const LoginPage()),
                                    (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              "LOGOUT",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBestExitAlert() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 12, 30, 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.power_settings_new_rounded,
                    color: Colors.orange, size: 35),
              ),
              const SizedBox(height: 20),
              const Text(
                "Exit Application?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to close the app? Any unsaved progress may be lost.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text(
                        "STAY",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => SystemNavigator.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text(
                        "CLOSE APP",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SliverFillRemaining(
        child: Center(
            child:
            Text("No records yet.", style: TextStyle(color: Colors.grey))));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showBestExitAlert();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildPremiumHeader(),
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildModernStats())),
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildActionGrid())),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF),
                              borderRadius: BorderRadius.circular(10))),
                      const SizedBox(width: 10),
                      const Text("LATEST 5 BILLS",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF475569),
                              fontSize: 11,
                              letterSpacing: 1.2)),
                      const Spacer(),

                      // --- VIEW ALL BUTTON WIRED UP HERE ---
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (c) => const HistoryPage()),
                          ).then((_) => _refreshData());
                        },
                        child: const Text("VIEW ALL",
                            style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
              _isLoading
                  ? const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(80),
                          child: CircularProgressIndicator())))
                  : _allInvoices.isEmpty
                  ? _buildEmptyState()
                  : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildAdvancedInvoiceCard(_allInvoices[index]),
                    childCount: _allInvoices.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),
        ),
      ),
    );
  }
}