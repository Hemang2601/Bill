import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/core.dart';
import 'database_helper.dart';
import 'services/invoice_status_service.dart';
import 'login_page.dart';
import 'create_invoice.dart';
import 'history_page.dart';
import 'edit_invoice_page.dart';

/// Clean High-Contrast White Theme Dashboard for Shree Shakti Electric Service
/// Focused KPI Overview: Total Revenue, Paid Amount, Pending Amount, Total Invoices
/// Streamlined Navigation: Create Invoice & Invoice History (No clutter, no monthly chart, no search bar)
class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _recentInvoices = [];
  Set<int> _paidInvoiceIds = {};
  Map<String, dynamic> _metrics = {
    'totalCount': 0,
    'totalRev': 0.0,
    'paidAmount': 0.0,
    'pendingAmount': 0.0,
  };
  bool _isLoading = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      final paidIds = await InvoiceStatusService.getPaidInvoiceIds();

      double totalRev = (metricsData['totalRev'] as num?)?.toDouble() ?? 0.0;
      double paidAmount = 0.0;

      for (final inv in allData) {
        final id = (inv['id'] as num?)?.toInt() ?? 0;
        final amt = (inv['totalAmount'] as num?)?.toDouble() ?? 0.0;
        if (paidIds.contains(id)) {
          paidAmount += amt;
        }
      }

      final double pendingAmount = totalRev > paidAmount
          ? totalRev - paidAmount
          : 0.0;

      if (!mounted) return;
      setState(() {
        _recentInvoices = allData.take(6).toList();
        _paidInvoiceIds = paidIds;
        _metrics = {
          'totalCount': (metricsData['totalCount'] as num?)?.toInt() ?? 0,
          'totalRev': totalRev,
          'paidAmount': paidAmount,
          'pendingAmount': pendingAmount,
        };
        _isLoading = false;
      });

      _animController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleInvoicePaid(int invoiceId) async {
    HapticFeedback.selectionClick();
    final isNowPaid = await InvoiceStatusService.togglePaid(invoiceId);
    await _refreshData();

    if (!mounted) return;
    if (isNowPaid) {
      AppNotification.showSuccess(context, "Invoice marked as PAID");
    } else {
      AppNotification.showWarning(context, "Invoice marked as PENDING");
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

  Future<void> _handleEdit(Map<String, dynamic> invoice) async {
    final result = await Navigator.of(
      context,
    ).push(FadeSlidePageRoute(page: EditInvoicePage(existingInvoice: invoice)));
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _handleLogout() async {
    final bool? confirmed = await AppDialog.showLogoutConfirmation(
      context: context,
      userName: widget.userName,
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.setString('userName', '');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        FadeSlidePageRoute(page: const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showErrorSnackbar(String msg) {
    AppNotification.showError(context, msg);
  }

  void _showManagerProfileSheet(String managerName) {
    AppBottomSheet.show(
      context: context,
      title: "Active Session Details",
      subtitle: "Authenticated electrical terminal manager",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    managerName.isNotEmpty ? managerName[0].toUpperCase() : "M",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        managerName,
                        style: AppTypography.headingMedium.copyWith(
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Manager & Authorized Signatory",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paidSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.paidBorder),
                        ),
                        child: Text(
                          "Active Session",
                          style: AppTypography.labelCaps.copyWith(
                            color: AppColors.paid,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapVxl,
          AppButton(
            label: "LOG OUT TERMINAL",
            icon: Icons.logout_rounded,
            variant: AppButtonVariant.danger,
            isFullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String managerName = _formatFullName(widget.userName);
    final String todayDate = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentRoute: '/dashboard'),
      appBar: _buildTopHeader(managerName),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Welcome Header Banner
                      _buildWelcomeBanner(managerName, todayDate),
                      AppSpacing.gapVxl,

                      // 2. Focused Revenue & Billing Summary Section
                      _buildRevenueSummarySection(),
                      AppSpacing.gapVxxl,

                      // 3. Primary Focused Navigation Actions (Create & History)
                      _buildPrimaryNavigationActions(),
                      AppSpacing.gapVxxl,

                      // 4. Recent Invoices List
                      _buildRecentInvoicesSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopHeader(String managerName) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            tooltip: "Navigation Menu",
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Icon(
                Icons.electric_bolt_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
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

  Widget _buildRevenueSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: "Revenue & Billing Summary",
          subtitle: "Live ledger overview and payment status",
        ),
        AppSpacing.gapVm,
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isWideDesktop = constraints.maxWidth >= 880;

            final card1 = AppStatCard(
              title: "Total Revenue",
              value: _metrics['totalRev'],
              isCurrency: true,
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primarySoft,
              badgeText: "LIFETIME",
              badgeColor: AppColors.primary,
              badgeBgColor: AppColors.primarySoft,
            );

            final card2 = AppStatCard(
              title: "Paid Amount",
              value: _metrics['paidAmount'],
              isCurrency: true,
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.paid,
              iconBgColor: AppColors.paidSoft,
              badgeText: "PAID",
              badgeColor: AppColors.paid,
              badgeBgColor: AppColors.paidSoft,
            );

            final card3 = AppStatCard(
              title: "Pending Amount",
              value: _metrics['pendingAmount'],
              isCurrency: true,
              icon: Icons.pending_actions_rounded,
              iconColor: AppColors.pending,
              iconBgColor: AppColors.pendingSoft,
              badgeText: "DUE",
              badgeColor: AppColors.pending,
              badgeBgColor: AppColors.pendingSoft,
            );

            final card4 = AppStatCard(
              title: "Total Invoices",
              value: _metrics['totalCount'],
              icon: Icons.receipt_long_rounded,
              iconColor: AppColors.primaryLight,
              iconBgColor: AppColors.electricSoft,
              badgeText: "ALL BILLS",
              badgeColor: AppColors.primaryLight,
              badgeBgColor: AppColors.electricSoft,
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

            // Mobile & Tablet 2x2 Clean Grid
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
        ),
      ],
    );
  }

  Widget _buildPrimaryNavigationActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isHorizontal = constraints.maxWidth >= 640;

        final createInvoiceCard = AppCard(
          backgroundColor: AppColors.surface,
          borderColor: AppColors.primary.withAlpha(80),
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
                    colors: [AppColors.primary, AppColors.primaryDark],
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
                            "Create Invoice",
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
                            "NEW BILL",
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

        final historyCard = AppCard(
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.paidSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.paidBorder),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.paid,
                  size: 26,
                ),
              ),
              AppSpacing.gapHm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invoice History",
                      style: AppTypography.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Audit ledger, search & status filters",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
                size: 20,
              ),
            ],
          ),
        );

        if (isHorizontal) {
          return Row(
            children: [
              Expanded(child: createInvoiceCard),
              AppSpacing.gapHm,
              Expanded(child: historyCard),
            ],
          );
        }

        return Column(
          children: [createInvoiceCard, AppSpacing.gapVm, historyCard],
        );
      },
    );
  }

  Widget _buildRecentInvoicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppSectionHeader(
              title: "Recent Invoices",
              subtitle: "Latest billing entries and payment state",
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .push(FadeSlidePageRoute(page: const HistoryPage()))
                    .then((_) => _refreshData());
              },
              icon: const Text(
                "View All",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
            ),
          ],
        ),
        AppSpacing.gapVm,
        if (_isLoading)
          const AppCard(
            child: SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          )
        else if (_recentInvoices.isEmpty)
          _buildEmptyInvoicesState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentInvoices.length,
            separatorBuilder: (context, _) => AppSpacing.gapVs,
            itemBuilder: (context, index) {
              final inv = _recentInvoices[index];
              return _buildInvoiceCard(inv);
            },
          ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final int invoiceId = (invoice['id'] as num?)?.toInt() ?? 0;
    final bool isPaid = _paidInvoiceIds.contains(invoiceId);
    final String billNumber = invoice['billNumber']?.toString() ?? "N/A";
    final String customerName =
        invoice['customerName']?.toString().toUpperCase() ?? "CASH CUSTOMER";
    final String date = invoice['date']?.toString() ?? "";
    final double amount = (invoice['totalAmount'] as num?)?.toDouble() ?? 0.0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => _handleViewPdf(invoice),
      child: Row(
        children: [
          // Invoice Document Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPaid ? AppColors.paidSoft : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPaid ? AppColors.paidBorder : AppColors.border,
              ),
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: isPaid ? AppColors.paid : AppColors.primary,
              size: 22,
            ),
          ),
          AppSpacing.gapHm,

          // Metadata Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "#$billNumber",
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Pill Badge (Tappable to toggle)
                    InkWell(
                      onTap: () => _toggleInvoicePaid(invoiceId),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppColors.paidSoft
                              : AppColors.pendingSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPaid
                                ? AppColors.paidBorder
                                : AppColors.pendingBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPaid
                                  ? Icons.check_circle_rounded
                                  : Icons.hourglass_top_rounded,
                              size: 11,
                              color: isPaid
                                  ? AppColors.paid
                                  : AppColors.pending,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPaid ? "PAID" : "PENDING",
                              style: AppTypography.labelCaps.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isPaid
                                    ? AppColors.paid
                                    : AppColors.pending,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  customerName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Amount & Direct Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.format(amount),
                style: AppTypography.currencyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View/Print PDF Action
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: "View / Print PDF",
                    onPressed: () => _handleViewPdf(invoice),
                  ),
                  // Edit Action
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: "Edit Invoice",
                    onPressed: () => _handleEdit(invoice),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInvoicesState() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            AppSpacing.gapVm,
            Text(
              "No Invoices Recorded Yet",
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.gapVxs,
            Text(
              "Start your electrical retail ledger by creating your first bill.",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapVl,
            AppButton(
              label: "CREATE FIRST BILL",
              icon: Icons.add_rounded,
              size: AppButtonSize.medium,
              onPressed: () {
                Navigator.of(context)
                    .push(FadeSlidePageRoute(page: const CreateInvoicePage()))
                    .then((_) => _refreshData());
              },
            ),
          ],
        ),
      ),
    );
  }
}
