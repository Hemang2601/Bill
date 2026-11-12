import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/core.dart';
import 'database_helper.dart';
import 'login_page.dart';
import 'create_invoice.dart';
import 'history_page.dart';
import 'edit_invoice_page.dart';

/// Premium Option D — Mobile Pro Dashboard for Shree Shakti Electric
/// Deep Navy & Charcoal surfaces, Electric Blue primary actions,
/// Amber highlights, smooth mobile bottom navigation & responsive desktop sidebar.
class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _recentInvoices = [];
  Map<String, dynamic> _metrics = {
    'totalCount': 0,
    'totalRev': 0.0,
    'currentMonthRev': 0.0,
    'customerCount': 0,
  };
  bool _isLoading = true;
  int _currentNavIndex = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _refreshData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final allData = await DatabaseHelper.instance.getAllInvoices();
      final metricsData = await DatabaseHelper.instance.getDashboardMetrics();

      if (!mounted) return;
      setState(() {
        _recentInvoices = allData.take(5).toList();
        _metrics = metricsData;
        _isLoading = false;
      });

      _animController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatFullName(String name) {
    if (name.isEmpty) return "Suresh Lakhadiya";

    final capitalized = name
        .split(' ')
        .map((str) {
          if (str.isEmpty) return "";
          return str[0].toUpperCase() + str.substring(1).toLowerCase();
        })
        .join(' ');

    if (!capitalized.toLowerCase().contains("lakhadiya")) {
      return "$capitalized Lakhadiya".trim();
    }
    return capitalized;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return "Good morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good afternoon";
    } else {
      return "Good evening";
    }
  }

  // --- ACTIONS ---

  Future<void> _handleViewPdf(Map<String, dynamic> invoice) async {
    final String? path = invoice['pdfPath'];
    if (path == null || !await File(path).exists()) {
      _showErrorSnackbar("Invoice document not found in local storage.");
      return;
    }

    final bytes = await File(path).readAsBytes();
    if (!mounted) return;

    await Navigator.of(context).push(
      FadeSlidePageRoute(
        page: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            title: Text(
              "Invoice #${invoice['billNumber']}",
              style: AppTypography.headingMedium,
            ),
            centerTitle: true,
          ),
          body: AppResponsiveContainer(
            padding: AppSpacing.screenPadding,
            child: ClipRRect(
              borderRadius: AppRadius.l,
              child: PdfPreview(
                build: (format) => bytes,
                useActions: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSharePdf(Map<String, dynamic> invoice) async {
    final String? path = invoice['pdfPath'];
    if (path != null && await File(path).exists()) {
      await Share.shareXFiles([
        XFile(path),
      ], text: 'Invoice #${invoice['billNumber']} from Shree Shakti Electric');
    } else {
      _showErrorSnackbar("Unable to share: PDF file is missing.");
    }
  }

  Future<void> _handleEditInvoice(Map<String, dynamic> invoice) async {
    final bool? didUpdate = await Navigator.of(context).push<bool>(
      FadeSlidePageRoute(page: EditInvoicePage(existingInvoice: invoice)),
    );

    if (didUpdate == true) {
      _refreshData();
    }
  }

  Future<void> _handleDeleteInvoice(Map<String, dynamic> invoice) async {
    final bool? confirm = await AppDialog.showDeleteInvoiceConfirmation(
      context: context,
      billNumber: invoice['billNumber']?.toString() ?? '',
      customerName: invoice['customerName']?.toString(),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteInvoice(invoice['id']);

      final String? pdfPath = invoice['pdfPath'];
      if (pdfPath != null) {
        final file = File(pdfPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      if (!mounted) return;
      _refreshData();
      AppNotification.showSuccess(
        context,
        "Invoice #${invoice['billNumber']} deleted permanently.",
      );
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await AppDialog.showLogoutConfirmation(
      context: context,
      userName: widget.userName,
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        FadeSlidePageRoute(page: const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _handleExitApp() async {
    final bool? confirm = await AppDialog.showConfirmation(
      context: context,
      title: "Exit Application?",
      message: "Are you sure you want to close Shree Shakti Electric Billing?",
      confirmLabel: "EXIT",
      cancelLabel: "STAY",
      iconType: DialogIconType.info,
    );

    if (confirm == true) {
      SystemNavigator.pop();
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    AppNotification.showError(context, message);
  }

  void _showInvoiceOptions(Map<String, dynamic> invoice) {
    AppDialog.showAppBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primaryLight,
                      size: 24,
                    ),
                  ),
                ),
                AppSpacing.gapHm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice['customerName']?.toString().toUpperCase() ??
                            "CASH CUSTOMER",
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Invoice #${invoice['billNumber']} • ${invoice['date']}",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 28),
            _buildActionOptionTile(
              icon: Icons.visibility_outlined,
              title: "View Invoice PDF",
              subtitle: "Open document viewer and printing preview",
              color: AppColors.primaryLight,
              onTap: () {
                Navigator.of(context).pop();
                _handleViewPdf(invoice);
              },
            ),
            _buildActionOptionTile(
              icon: Icons.edit_outlined,
              title: "Edit Invoice",
              subtitle: "Modify billing items, quantities or rates",
              color: AppColors.amberLight,
              onTap: () {
                Navigator.of(context).pop();
                _handleEditInvoice(invoice);
              },
            ),
            _buildActionOptionTile(
              icon: Icons.share_outlined,
              title: "Share Invoice",
              subtitle: "Send via WhatsApp, social apps or email",
              color: AppColors.success,
              onTap: () {
                Navigator.of(context).pop();
                _handleSharePdf(invoice);
              },
            ),
            _buildActionOptionTile(
              icon: Icons.delete_outline_rounded,
              title: "Delete Record",
              subtitle: "Permanently delete this invoice and PDF",
              color: AppColors.danger,
              onTap: () {
                Navigator.of(context).pop();
                _handleDeleteInvoice(invoice);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: onTap,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.m),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(60), width: 1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  void _showManagerProfileSheet(String managerName) {
    AppDialog.showAppBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    managerName.isNotEmpty ? managerName[0].toUpperCase() : "M",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(managerName, style: AppTypography.headingMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Authorized Terminal Manager",
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primaryLight,
              ),
              title: const Text("Manager Account"),
              subtitle: Text(
                widget.userName.toLowerCase(),
                style: AppTypography.bodySmall,
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.storage_rounded,
                color: AppColors.amberLight,
              ),
              title: const Text("SQLite Database"),
              subtitle: const Text(
                "shree_shakti.db • Schema v3",
                style: AppTypography.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: "SIGN OUT",
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.danger,
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- UI BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final String formattedManager = _formatFullName(widget.userName);
    final String todayDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.now());
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 900;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleExitApp();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildTopHeader(formattedManager),
        drawer: AppNavigationDrawer(
          currentRoute: '/dashboard',
          managerName: widget.userName,
          onRefreshParent: _refreshData,
        ),
        body: isDesktop
            ? Row(
                children: [
                  _buildDesktopSidebar(formattedManager),
                  Expanded(
                    child: _buildMainDashboardContent(
                      formattedManager,
                      todayDate,
                    ),
                  ),
                ],
              )
            : _buildMainDashboardContent(formattedManager, todayDate),
        bottomNavigationBar: null,
      ),
    );
  }

  Widget _buildDesktopSidebar(String managerName) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadows.primaryGlow,
                ),
                child: const Center(
                  child: Icon(
                    Icons.electric_bolt_rounded,
                    color: AppColors.amberLight,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SHREE SHAKTI",
                      style: AppTypography.headingSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "COMMERCIAL MANAGEMENT SUITE",
                      style: AppTypography.labelCaps.copyWith(
                        fontSize: 8.5,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "MAIN NAVIGATION",
            style: AppTypography.labelCaps.copyWith(
              fontSize: 9.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          _buildSidebarNavItem(
            icon: Icons.dashboard_rounded,
            label: "Dashboard",
            isActive: _currentNavIndex == 0,
            onTap: () => setState(() => _currentNavIndex = 0),
          ),
          _buildSidebarNavItem(
            icon: Icons.add_circle_outline_rounded,
            label: "Create Bill",
            isActive: false,
            highlightBadge: "NEW",
            onTap: () {
              Navigator.of(context)
                  .push(FadeSlidePageRoute(page: const CreateInvoicePage()))
                  .then((_) => _refreshData());
            },
          ),
          _buildSidebarNavItem(
            icon: Icons.receipt_long_rounded,
            label: "Invoice History",
            isActive: false,
            onTap: () {
              Navigator.of(context)
                  .push(FadeSlidePageRoute(page: const HistoryPage()))
                  .then((_) => _refreshData());
            },
          ),
          const Spacer(),
          // Manager Profile in Sidebar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    managerName.isNotEmpty ? managerName[0].toUpperCase() : "M",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        managerName.split(' ')[0],
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Partner",
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.power_settings_new_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  tooltip: "Sign Out",
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    String? highlightBadge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryLight.withAlpha(100)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? AppColors.primaryLight
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (highlightBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amberSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.amberBorder, width: 1),
                  ),
                  child: Text(
                    highlightBadge,
                    style: const TextStyle(
                      color: AppColors.amberLight,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDashboardContent(String formattedManager, String todayDate) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryLight,
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: AppResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeBanner(formattedManager, todayDate),
                AppSpacing.gapVxxl,
                _buildStatisticsGrid(),
                AppSpacing.gapVm,
                _buildSecondaryAnalyticsStrip(),
                AppSpacing.gapVxxl,
                _buildQuickActionCards(),
                AppSpacing.gapVxxl,
                _buildRecentInvoicesSection(),
                AppSpacing.gapVxxxl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopHeader(String managerName) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: const Center(
              child: Icon(
                Icons.electric_bolt_rounded,
                color: AppColors.amberLight,
                size: 20,
              ),
            ),
          ),
          AppSpacing.gapHs,
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SHREE SHAKTI ELECTRIC",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "BILLING & ESTIMATION SUITE",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 9,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          tooltip: "Sign Out",
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeBanner(String managerName, String todayDate) {
    final String greeting = _getGreeting();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$greeting, ${managerName.split(' ')[0]} 👋",
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapVxxs,
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.amberLight,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      todayDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _showManagerProfileSheet(managerName),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    managerName.isNotEmpty ? managerName[0].toUpperCase() : "M",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  managerName.split(' ')[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideDesktop = constraints.maxWidth >= 880;
        final bool isTabletOrNarrow =
            constraints.maxWidth >= 540 && !isWideDesktop;

        final card1 = AppStatCard(
          title: "Total Invoices",
          value: _metrics['totalCount'],
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primarySoft,
          badgeText: "ALL TIME",
          badgeColor: AppColors.primary,
          badgeBgColor: AppColors.primarySoft,
        );

        final card2 = AppStatCard(
          title: "Total Revenue",
          value: _metrics['totalRev'],
          isCurrency: true,
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.emeraldGreen,
          iconBgColor: AppColors.emeraldSoft,
          badgeText: "LIFETIME",
          badgeColor: AppColors.emeraldGreen,
          badgeBgColor: AppColors.emeraldSoft,
        );

        final card3 = AppStatCard(
          title: "Total Customers",
          value: _metrics['customerCount'],
          icon: Icons.people_alt_rounded,
          iconColor: AppColors.premiumViolet,
          iconBgColor: AppColors.violetSoft,
          badgeText: "ACTIVE",
          badgeColor: AppColors.premiumViolet,
          badgeBgColor: AppColors.violetSoft,
        );

        final card4 = AppStatCard(
          title: "Recent Bills",
          value: _recentInvoices.length,
          icon: Icons.history_edu_rounded,
          iconColor: AppColors.warmAmber,
          iconBgColor: AppColors.amberSoft,
          badgeText: "RECENT",
          badgeColor: AppColors.warmAmber,
          badgeBgColor: AppColors.amberSoft,
        );

        if (isWideDesktop) {
          return Row(
            children: [
              Expanded(child: card1),
              AppSpacing.gapHm,
              Expanded(child: card2),
              AppSpacing.gapHm,
              Expanded(child: card3),
              AppSpacing.gapHm,
              Expanded(child: card4),
            ],
          );
        }

        if (isTabletOrNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  AppSpacing.gapHm,
                  Expanded(child: card2),
                ],
              ),
              AppSpacing.gapVm,
              Row(
                children: [
                  Expanded(child: card3),
                  AppSpacing.gapHm,
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        // Mobile 2x2 Grid
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: card1),
                AppSpacing.gapHm,
                Expanded(child: card2),
              ],
            ),
            AppSpacing.gapVm,
            Row(
              children: [
                Expanded(child: card3),
                AppSpacing.gapHm,
                Expanded(child: card4),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryAnalyticsStrip() {
    final currentMonthLabel = DateFormat('MMMM yyyy').format(DateTime.now());
    final double monthRev =
        (_metrics['currentMonthRev'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.electricSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.electricBorder.withAlpha(80)),
            ),
            child: const Center(
              child: Icon(
                Icons.calendar_month_rounded,
                color: AppColors.electricBlue,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MONTHLY PERFORMANCE ($currentMonthLabel)",
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Recorded Month Revenue: ${CurrencyFormatter.format(monthRev)}",
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryLight.withAlpha(50)),
            ),
            child: Text(
              "Current Cycle",
              style: AppTypography.labelCaps.copyWith(
                fontSize: 9.5,
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isHorizontal = constraints.maxWidth >= 720;

        final newBillCard = AppCard(
          backgroundColor: AppColors.surface,
          borderColor: AppColors.primaryLight.withAlpha(90),
          padding: const EdgeInsets.all(18),
          onTap: () {
            Navigator.of(context)
                .push(FadeSlidePageRoute(page: const CreateInvoicePage()))
                .then((_) => _refreshData());
          },
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadows.primaryGlow,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              AppSpacing.gapHm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Create New Bill",
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.amberBorder,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            "FAST ENTRY",
                            style: TextStyle(
                              color: AppColors.amberAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Multi-step billing wizard & PDF print",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        );

        final viewBillsCard = AppCard(
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.all(18),
          onTap: () {
            Navigator.of(context)
                .push(FadeSlidePageRoute(page: const HistoryPage()))
                .then((_) => _refreshData());
          },
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.emeraldBorder.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.emeraldGreen,
                  size: 24,
                ),
              ),
              AppSpacing.gapHm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "View All Bills",
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Complete ledger & history",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        );

        final searchInvoiceCard = AppCard(
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.all(18),
          onTap: () {
            Navigator.of(context)
                .push(
                  FadeSlidePageRoute(
                    page: const HistoryPage(autoFocusSearch: true),
                  ),
                )
                .then((_) => _refreshData());
          },
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.violetSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.violetBorder.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.premiumViolet,
                  size: 24,
                ),
              ),
              AppSpacing.gapHm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Search Invoice",
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Find by number or customer",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        );

        return Column(
          children: [
            newBillCard,
            AppSpacing.gapVm,
            if (isHorizontal)
              Row(
                children: [
                  Expanded(child: viewBillsCard),
                  AppSpacing.gapHm,
                  Expanded(child: searchInvoiceCard),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: viewBillsCard),
                  AppSpacing.gapHm,
                  Expanded(child: searchInvoiceCard),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildRecentInvoicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: "Recent Invoices",
          subtitle: "Latest 5 bills recorded in the system",
          actionLabel: "VIEW ALL",
          onAction: () {
            Navigator.of(context)
                .push(FadeSlidePageRoute(page: const HistoryPage()))
                .then((_) => _refreshData());
          },
        ),
        AppSpacing.gapVs,
        if (_isLoading) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: AppLoading(message: "Loading invoice ledger..."),
          ),
        ] else if (_recentInvoices.isEmpty) ...[
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: "No Invoices Yet",
            message:
                "You haven't recorded any invoices yet. Create your first bill to start tracking transactions.",
            actionLabel: "CREATE FIRST BILL",
            onAction: () {
              Navigator.of(context)
                  .push(FadeSlidePageRoute(page: const CreateInvoicePage()))
                  .then((_) => _refreshData());
            },
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentInvoices.length,
            separatorBuilder: (context, index) => AppSpacing.gapVs,
            itemBuilder: (context, index) {
              return _buildInvoiceCard(_recentInvoices[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final customerName =
        invoice['customerName']?.toString().toUpperCase() ?? "CASH CUSTOMER";
    final billNumber = invoice['billNumber']?.toString() ?? "";
    final date = invoice['date']?.toString() ?? "";
    final amount = (invoice['totalAmount'] as num?)?.toDouble() ?? 0.0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      onTap: () => _showInvoiceOptions(invoice),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.description_outlined,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ),
          ),
          AppSpacing.gapHm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: AppTypography.headingSmall.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        "#$billNumber",
                        style: AppTypography.labelCaps.copyWith(
                          fontSize: 10,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapHs,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: AppTypography.currencyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
