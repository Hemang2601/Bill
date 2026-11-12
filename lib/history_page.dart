import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'core/core.dart';
import 'database_helper.dart';
import 'edit_invoice_page.dart';
import 'create_invoice.dart';

/// Premium, enterprise-grade Bill History & Search Screen for Shree Shakti Electric
/// Designed with a modern White Theme, desktop-first ledger, live search, and date filters.
class HistoryPage extends StatefulWidget {
  final bool autoFocusSearch;
  final String? initialQuery;

  const HistoryPage({
    super.key,
    this.autoFocusSearch = false,
    this.initialQuery,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  // Search & Filter State
  String _searchQuery = "";
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<String> _filters = const [
    "All Time",
    "This Month",
    "Last Month",
    "Last 3 Months",
    "Last 6 Months",
    "This Year",
  ];
  String _activeFilter = "All Time";
  bool _isCustomRange = false;

  // Overall database KPIs
  Map<String, dynamic> _kpiMetrics = {
    'totalCount': 0,
    'totalRev': 0.0,
    'currentMonthRev': 0.0,
  };

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
    }

    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocus.requestFocus();
        }
      });
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _fetchKpiMetrics();
    await _fetchDataFromDB();
    if (mounted) {
      _fadeController.forward();
    }
  }

  Future<void> _fetchKpiMetrics() async {
    try {
      final metrics = await DatabaseHelper.instance.getDashboardMetrics();
      if (mounted) {
        setState(() {
          _kpiMetrics = metrics;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDataFromDB() async {
    setState(() => _isLoading = true);

    try {
      final data = await DatabaseHelper.instance.getFilteredInvoices(
        searchQuery: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _invoices = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double get _totalVolume => _invoices.fold(
    0.0,
    (sum, item) =>
        sum + (double.tryParse(item['totalAmount']?.toString() ?? '0') ?? 0.0),
  );

  void _handleFilterSelection(String title) {
    final now = DateTime.now();

    setState(() {
      _activeFilter = title;
      _isCustomRange = false;

      if (title == "All Time") {
        _startDate = null;
        _endDate = null;
      } else if (title == "This Month") {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (title == "Last Month") {
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
      } else if (title == "Last 3 Months") {
        _startDate = DateTime(now.year, now.month - 2, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (title == "Last 6 Months") {
        _startDate = DateTime(now.year, now.month - 5, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (title == "This Year") {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
      }
    });

    _fetchDataFromDB();
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
        _isCustomRange = true;
        _activeFilter =
            "${DateFormat('d MMM').format(pickedRange.start)} - ${DateFormat('d MMM').format(pickedRange.end)}";
      });
      _fetchDataFromDB();
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = "";
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _activeFilter = "All Time";
      _isCustomRange = false;
    });
    _fetchDataFromDB();
  }

  // --- ACTIONS ---

  void _exportAllData() {
    if (_invoices.isEmpty) {
      AppNotification.showWarning(
        context,
        "No records available to export for current view",
      );
      return;
    }

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

    Share.share(report, subject: 'Sales Report - $_activeFilter');
  }

  void _editInvoice(Map<String, dynamic> inv) async {
    final bool? isUpdated = await Navigator.push(
      context,
      FadeSlidePageRoute(page: EditInvoicePage(existingInvoice: inv)),
    );
    if (isUpdated == true) {
      _fetchDataFromDB();
      _fetchKpiMetrics();
      if (!mounted) return;
      AppNotification.showSuccess(
        context,
        "Invoice #${inv['billNumber']} updated successfully!",
      );
    }
  }

  void _viewPdf(Map<String, dynamic> inv) async {
    final pdfPath = inv['pdfPath']?.toString() ?? '';
    final file = File(pdfPath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.push(
        context,
        FadeSlidePageRoute(
          page: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Document Preview: #${inv['billNumber']}",
                style: AppTypography.headingSmall,
              ),
            ),
            body: PdfPreview(build: (format) => bytes, useActions: true),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      AppDialog.showMissingPdfDialog(
        context: context,
        billNumber: inv['billNumber']?.toString() ?? '',
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> inv) async {
    final bool? confirmed = await AppDialog.showDeleteInvoiceConfirmation(
      context: context,
      billNumber: inv['billNumber']?.toString() ?? '',
      customerName: inv['customerName']?.toString(),
    );

    if (confirmed == true) {
      // 1. Delete associated PDF safely
      final pdfPath = inv['pdfPath']?.toString() ?? '';
      if (pdfPath.isNotEmpty) {
        final file = File(pdfPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      // 2. Delete database entry (cascades to invoice_items)
      final invoiceId = (inv['id'] as num?)?.toInt() ?? 0;
      await DatabaseHelper.instance.deleteInvoice(invoiceId);

      _fetchDataFromDB();
      _fetchKpiMetrics();

      if (mounted) {
        AppNotification.showSuccess(
          context,
          "Invoice #${inv['billNumber']} deleted successfully.",
        );
      }
    }
  }

  void _openModernDetail(Map<String, dynamic> inv) {
    AppDialog.showAppBottomSheet(
      context: context,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
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
                  size: 30,
                ),
              ),
            ),
            AppSpacing.gapVs,
            Center(
              child: Text(
                "TAX INVOICE DETAILS",
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            AppSpacing.gapVs,
            Center(
              child: AnimatedCountText(
                value: (inv['totalAmount'] as num?)?.toDouble() ?? 0.0,
                isCurrency: true,
                style: AppTypography.currencyDisplay.copyWith(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            AppSpacing.gapVm,
            const Divider(color: AppColors.border),
            AppSpacing.gapVs,
            _receiptRow(
              Icons.person_outline_rounded,
              "Customer Name",
              inv['customerName']?.toString() ?? "CASH CUSTOMER",
            ),
            _receiptRow(
              Icons.phone_android_rounded,
              "Phone Number",
              inv['phoneNumber']?.toString() ?? "N/A",
            ),
            _receiptRow(
              Icons.tag_rounded,
              "Bill Number",
              "#${inv['billNumber']}",
            ),
            _receiptRow(
              Icons.calendar_today_rounded,
              "Date Issued",
              inv['date']?.toString() ?? "",
            ),
            _receiptRow(
              Icons.folder_open_rounded,
              "Storage Path",
              inv['pdfPath']?.toString() ?? "N/A",
            ),
            AppSpacing.gapVl,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: "EDIT BILL",
                    icon: Icons.edit_rounded,
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      Navigator.pop(context);
                      _editInvoice(inv);
                    },
                  ),
                ),
                AppSpacing.gapHm,
                Expanded(
                  child: AppButton(
                    label: "SHARE PDF",
                    icon: Icons.share_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      final pdfPath = inv['pdfPath']?.toString() ?? '';
                      if (pdfPath.isNotEmpty && File(pdfPath).existsSync()) {
                        Share.shareXFiles(
                          [XFile(pdfPath)],
                          text:
                              'Invoice #${inv['billNumber']} - Shree Shakti Electric',
                        );
                      } else {
                        AppNotification.showError(
                          context,
                          "PDF file for #${inv['billNumber']} not found on disk",
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.gapVm,
            AppButton(
              label: "VIEW DOCUMENT PREVIEW",
              icon: Icons.visibility_rounded,
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              onPressed: () {
                Navigator.pop(context);
                _viewPdf(inv);
              },
            ),
            AppSpacing.gapVm,
            AppButton(
              label: "DELETE INVOICE RECORD",
              icon: Icons.delete_outline_rounded,
              variant: AppButtonVariant.danger,
              isFullWidth: true,
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(inv);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          AppSpacing.gapHs,
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapHm,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentRoute: '/history'),
      appBar: _buildTopHeader(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchKpiMetrics();
            await _fetchDataFromDB();
          },
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: AppResponsiveContainer(
              maxWidth: 1200,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildKpiOverviewBanner(),
                  AppSpacing.gapVl,
                  _buildSearchAndFilterCard(),
                  AppSpacing.gapVl,
                  _buildInvoiceListSection(),
                  AppSpacing.gapVxxxl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTopHeader() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
        ),
        tooltip: "Back to Dashboard",
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "BILL HISTORY & LEDGER",
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            "SHREE SHAKTI ELECTRIC • AUDIT & SEARCH",
            style: AppTypography.labelCaps.copyWith(
              fontSize: 9,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AppButton(
            label: "EXPORT",
            icon: Icons.ios_share_rounded,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            onPressed: _exportAllData,
          ),
        ),
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            tooltip: "Open Navigation Menu",
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- KPI OVERVIEW CARDS ---
  Widget _buildKpiOverviewBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 760;

        final cardFilteredVolume = AppStatCard(
          title: _activeFilter == "All Time"
              ? "Total Revenue"
              : "$_activeFilter Revenue",
          value: _totalVolume,
          isCurrency: true,
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primarySoft,
          badgeText: "FILTERED",
          badgeColor: AppColors.primary,
          badgeBgColor: AppColors.primarySoft,
        );

        final cardFilteredCount = AppStatCard(
          title: "Invoices Found",
          value: _invoices.length,
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.success,
          iconBgColor: AppColors.successSoft,
          badgeText: _activeFilter,
          badgeColor: AppColors.success,
          badgeBgColor: AppColors.successSoft,
        );

        final cardLifetimeVolume = AppStatCard(
          title: "Lifetime Revenue",
          value: _kpiMetrics['totalRev'] ?? 0.0,
          isCurrency: true,
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBgColor: const Color(0xFFF5F3FF),
          badgeText: "ALL TIME",
          badgeColor: const Color(0xFF7C3AED),
          badgeBgColor: const Color(0xFFF5F3FF),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cardFilteredVolume),
              AppSpacing.gapHm,
              Expanded(child: cardFilteredCount),
              AppSpacing.gapHm,
              Expanded(child: cardLifetimeVolume),
            ],
          );
        }

        return Column(
          children: [
            cardFilteredVolume,
            AppSpacing.gapVm,
            Row(
              children: [
                Expanded(child: cardFilteredCount),
                AppSpacing.gapHm,
                Expanded(child: cardLifetimeVolume),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- SEARCH AND FILTER CONTROLS ---
  Widget _buildSearchAndFilterCard() {
    final bool hasActiveFilters =
        _searchQuery.isNotEmpty || _activeFilter != "All Time";

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  hint:
                      "Search by Bill No. (#SE-...), Customer Name, or Phone...",
                  prefixIcon: Icons.search_rounded,
                  suffix: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                            _fetchDataFromDB();
                          },
                        )
                      : null,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                    _fetchDataFromDB();
                  },
                ),
              ),
              AppSpacing.gapHm,
              IconButton.filledTonal(
                icon: const Icon(
                  Icons.date_range_rounded,
                  color: AppColors.primary,
                ),
                tooltip: "Select Custom Date Range",
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primarySoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: _selectCustomDateRange,
              ),
              if (hasActiveFilters) ...[
                AppSpacing.gapHs,
                IconButton.filledTonal(
                  icon: const Icon(
                    Icons.filter_alt_off_rounded,
                    color: AppColors.danger,
                  ),
                  tooltip: "Clear All Filters",
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.dangerSoft,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: _resetFilters,
                ),
              ],
            ],
          ),
          AppSpacing.gapVm,
          // Horizontal Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _filters.length + (_isCustomRange ? 1 : 0),
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (_isCustomRange && index == _filters.length) {
                  return FilterChip(
                    selected: true,
                    label: Text(_activeFilter),
                    onSelected: (_) => _selectCustomDateRange(),
                    selectedColor: AppColors.primary,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }

                final title = _filters[index];
                final isActive = _activeFilter == title && !_isCustomRange;

                return FilterChip(
                  selected: isActive,
                  label: Text(title),
                  onSelected: (_) => _handleFilterSelection(title),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : AppColors.textPrimary,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isActive ? AppColors.primary : AppColors.border,
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- INVOICE LIST / TABLE ---
  Widget _buildInvoiceListSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: AppLoading(message: "Loading accounting ledger..."),
      );
    }

    if (_invoices.isEmpty) {
      if (_searchQuery.isNotEmpty || _activeFilter != "All Time") {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: "No Matching Records Found",
          message:
              "No invoices matched '$_searchQuery' for the selected timeframe ($_activeFilter).",
          actionLabel: "CLEAR ALL FILTERS",
          onAction: _resetFilters,
        );
      }

      return AppEmptyState(
        icon: Icons.receipt_long_rounded,
        title: "No Invoices Recorded Yet",
        message:
            "Invoices generated in Shree Shakti Electric will appear here in your ledger.",
        actionLabel: "CREATE FIRST BILL",
        onAction: () {
          Navigator.push(
            context,
            FadeSlidePageRoute(page: const CreateInvoicePage()),
          ).then((_) {
            _fetchDataFromDB();
            _fetchKpiMetrics();
          });
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktopTable = constraints.maxWidth >= 940;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppSectionHeader(
                    title: "Recorded Bills Ledger",
                    subtitle:
                        "Showing ${_invoices.length} entries for $_activeFilter",
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    "${_invoices.length} INVOICES",
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVm,
            if (isDesktopTable)
              _buildDesktopLedgerTable()
            else
              _buildMobileCardsList(),
          ],
        );
      },
    );
  }

  // --- DESKTOP LEDGER TABLE ---
  Widget _buildDesktopLedgerTable() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 140,
                  child: Text("BILL NUMBER", style: AppTypography.labelCaps),
                ),
                SizedBox(
                  width: 120,
                  child: Text("DATE", style: AppTypography.labelCaps),
                ),
                Expanded(
                  child: Text(
                    "CUSTOMER / PHONE",
                    style: AppTypography.labelCaps,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    "AMOUNT (₹)",
                    textAlign: TextAlign.right,
                    style: AppTypography.labelCaps,
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: Text(
                    "ACTIONS",
                    textAlign: TextAlign.center,
                    style: AppTypography.labelCaps,
                  ),
                ),
              ],
            ),
          ),
          // Table Body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _invoices.length,
            separatorBuilder: (context, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final inv = _invoices[index];
              final double amount =
                  (inv['totalAmount'] as num?)?.toDouble() ?? 0.0;
              final String customer =
                  inv['customerName']?.toString() ?? "CASH CUSTOMER";
              final String phone = inv['phoneNumber']?.toString() ?? "N/A";

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  hoverColor: AppColors.surfaceSubtle,
                  splashColor: AppColors.primarySoft.withAlpha(80),
                  onTap: () => _openModernDetail(inv),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  "#${inv['billNumber']}",
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            inv['date']?.toString() ?? '',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (phone != "N/A" && phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: Text(
                            CurrencyFormatter.format(amount),
                            textAlign: TextAlign.right,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                tooltip: "View Document",
                                onPressed: () => _viewPdf(inv),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share_rounded,
                                  size: 18,
                                  color: AppColors.success,
                                ),
                                tooltip: "Share PDF",
                                onPressed: () {
                                  final pdfPath =
                                      inv['pdfPath']?.toString() ?? '';
                                  if (pdfPath.isNotEmpty &&
                                      File(pdfPath).existsSync()) {
                                    Share.shareXFiles([
                                      XFile(pdfPath),
                                    ], text: 'Invoice #${inv['billNumber']}');
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppColors.warning,
                                ),
                                tooltip: "Edit Bill",
                                onPressed: () => _editInvoice(inv),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                tooltip: "Delete",
                                onPressed: () => _confirmDelete(inv),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- MOBILE CARDS LIST ---
  Widget _buildMobileCardsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _invoices.length,
      separatorBuilder: (context, _) => AppSpacing.gapVs,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final double amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final String customer =
            inv['customerName']?.toString() ?? "CASH CUSTOMER";
        final String phone = inv['phoneNumber']?.toString() ?? "N/A";

        return AppCard(
          padding: const EdgeInsets.all(14),
          onTap: () => _openModernDetail(inv),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
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
                          customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headingSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                "#${inv['billNumber']}",
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              inv['date']?.toString() ?? '',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapHs,
                  Text(
                    CurrencyFormatter.format(amount),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (phone != "N/A" && phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_android_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tap to view details",
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        tooltip: "View PDF",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _viewPdf(inv),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                        tooltip: "Share",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () {
                          final pdfPath = inv['pdfPath']?.toString() ?? '';
                          if (pdfPath.isNotEmpty &&
                              File(pdfPath).existsSync()) {
                            Share.shareXFiles([
                              XFile(pdfPath),
                            ], text: 'Invoice #${inv['billNumber']}');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        tooltip: "Edit",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _editInvoice(inv),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        tooltip: "Delete",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _confirmDelete(inv),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
