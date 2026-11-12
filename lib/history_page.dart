import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'core/core.dart';
import 'database_helper.dart';
import 'services/invoice_status_service.dart';
import 'edit_invoice_page.dart';
import 'create_invoice.dart';

/// Clean High-Contrast White Theme Bill History & Ledger for Shree Shakti Electric Service
/// Dedicated Search Bar, Status Filter Chips (All, Paid, Pending), Date Period Filters,
/// and Clean White Cards with Status Pill Badges and Direct Action Buttons.
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
  Set<int> _paidInvoiceIds = {};
  bool _isLoading = true;

  // Search & Filter State
  String _searchQuery = "";
  String _statusFilter = "All"; // "All", "Paid", "Pending"
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
      final rawData = await DatabaseHelper.instance.getFilteredInvoices(
        searchQuery: _searchQuery,
        startDate: _startDate,
        endDate: _endDate,
      );
      final paidIds = await InvoiceStatusService.getPaidInvoiceIds();

      List<Map<String, dynamic>> filtered = rawData;
      if (_statusFilter == "Paid") {
        filtered = rawData
            .where((inv) => paidIds.contains((inv['id'] as num?)?.toInt() ?? 0))
            .toList();
      } else if (_statusFilter == "Pending") {
        filtered = rawData
            .where(
              (inv) => !paidIds.contains((inv['id'] as num?)?.toInt() ?? 0),
            )
            .toList();
      }

      if (mounted) {
        setState(() {
          _invoices = filtered;
          _paidInvoiceIds = paidIds;
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
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
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
      _statusFilter = "All";
      _startDate = null;
      _endDate = null;
      _activeFilter = "All Time";
      _isCustomRange = false;
    });
    _fetchDataFromDB();
  }

  Future<void> _togglePaidStatus(int invoiceId) async {
    HapticFeedback.selectionClick();
    final isNowPaid = await InvoiceStatusService.togglePaid(invoiceId);
    await _fetchDataFromDB();
    await _fetchKpiMetrics();

    if (!mounted) return;
    if (isNowPaid) {
      AppNotification.showSuccess(context, "Invoice marked as PAID");
    } else {
      AppNotification.showWarning(context, "Invoice marked as PENDING");
    }
  }

  void _exportAllData() {
    if (_invoices.isEmpty) {
      AppNotification.showWarning(
        context,
        "No records available to export for current view",
      );
      return;
    }

    String report = "SHREE SHAKTI ELECTRIC - SALES REPORT\n";
    report += "Status: $_statusFilter | Filter: $_activeFilter\n";
    report += "Generated on: ${DateTime.now().toString().split('.')[0]}\n";
    report += "------------------------------------------\n\n";

    for (var inv in _invoices) {
      final isPaid = _paidInvoiceIds.contains(
        (inv['id'] as num?)?.toInt() ?? 0,
      );
      report +=
          "Bill: #${inv['billNumber']} | Date: ${inv['date']} | Status: ${isPaid ? 'PAID' : 'PENDING'}\n";
      report += "Customer: ${inv['customerName']}\n";
      report += "Amount: ₹${inv['totalAmount']}\n";
      report += "------------------------------------------\n";
    }

    report += "\nTOTAL INVOICES: ${_invoices.length}";
    report += "\nTOTAL VOLUME: ₹${_totalVolume.toStringAsFixed(2)}";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppNavigationDrawer(currentRoute: '/history'),
      appBar: AppHeader(
        title: "BILL HISTORY & LEDGER",
        subtitle: "SHREE SHAKTI ELECTRIC • AUDIT & SEARCH",
        showDrawerButton: true,
        actions: [
          AppButton(
            label: "EXPORT",
            icon: Icons.ios_share_rounded,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            onPressed: _exportAllData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. KPI Overview Summary Cards
                    _buildKpiOverviewBanner(),
                    AppSpacing.gapVl,

                    // 2. Search & Dedicated Status Filters
                    _buildSearchAndFilterCard(),
                    AppSpacing.gapVl,

                    // 3. Invoices List / Cards
                    _buildInvoiceListSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
          iconColor: AppColors.paid,
          iconBgColor: AppColors.paidSoft,
          badgeText: _activeFilter,
          badgeColor: AppColors.paid,
          badgeBgColor: AppColors.paidSoft,
        );

        final cardLifetimeVolume = AppStatCard(
          title: "Lifetime Revenue",
          value: _kpiMetrics['totalRev'] ?? 0.0,
          isCurrency: true,
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.primaryLight,
          iconBgColor: AppColors.electricSoft,
          badgeText: "ALL TIME",
          badgeColor: AppColors.primaryLight,
          badgeBgColor: AppColors.electricSoft,
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
        _searchQuery.isNotEmpty ||
        _activeFilter != "All Time" ||
        _statusFilter != "All";

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar
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

          // 2. Dedicated Status Filter Chips: All, Paid, Pending (Horizontally scrollable for small screens)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "STATUS",
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _statusFilter == "All",
                  label: const Text("All"),
                  onSelected: (_) {
                    setState(() => _statusFilter = "All");
                    _fetchDataFromDB();
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _statusFilter == "All"
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _statusFilter == "All"
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  selected: _statusFilter == "Paid",
                  label: const Text("Paid"),
                  onSelected: (_) {
                    setState(() => _statusFilter = "Paid");
                    _fetchDataFromDB();
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.paid,
                  labelStyle: TextStyle(
                    color: _statusFilter == "Paid"
                        ? Colors.white
                        : AppColors.paid,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _statusFilter == "Paid"
                        ? AppColors.paid
                        : AppColors.paidBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  selected: _statusFilter == "Pending",
                  label: const Text("Pending"),
                  onSelected: (_) {
                    setState(() => _statusFilter = "Pending");
                    _fetchDataFromDB();
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.pending,
                  labelStyle: TextStyle(
                    color: _statusFilter == "Pending"
                        ? Colors.white
                        : AppColors.pending,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: _statusFilter == "Pending"
                        ? AppColors.pending
                        : AppColors.pendingBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapVs,

          // 3. Horizontal Date Filter Chips
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
      if (_searchQuery.isNotEmpty ||
          _activeFilter != "All Time" ||
          _statusFilter != "All") {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: "No Matching Records Found",
          message:
              "No invoices matched your filters (Search: '$_searchQuery', Status: $_statusFilter, Time: $_activeFilter).",
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
                    "Showing ${_invoices.length} entries (${_statusFilter == 'All' ? 'All' : _statusFilter} • $_activeFilter)",
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _invoices.length,
          separatorBuilder: (context, _) => AppSpacing.gapVs,
          itemBuilder: (context, index) {
            final inv = _invoices[index];
            return _buildInvoiceCard(inv);
          },
        ),
      ],
    );
  }

  // --- CLEAN WHITE INVOICE CARD ---
  Widget _buildInvoiceCard(Map<String, dynamic> inv) {
    final int invoiceId = (inv['id'] as num?)?.toInt() ?? 0;
    final bool isPaid = _paidInvoiceIds.contains(invoiceId);
    final String billNumber = inv['billNumber']?.toString() ?? "N/A";
    final String customer =
        inv['customerName']?.toString().toUpperCase() ?? "CASH CUSTOMER";
    final String date = inv['date']?.toString() ?? "";
    final String phone = inv['phoneNumber']?.toString() ?? "N/A";
    final double amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0.0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Icon
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
                  Icons.receipt_long_rounded,
                  color: isPaid ? AppColors.paid : AppColors.primary,
                  size: 22,
                ),
              ),
              AppSpacing.gapHm,

              // Invoice Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "#$billNumber",
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Pill Badge (Single-tap to toggle)
                        InkWell(
                          onTap: () => _togglePaidStatus(invoiceId),
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
                      customer,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (date.isNotEmpty) ...[
                          Text(
                            date,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (phone != "N/A" && phone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            "• $phone",
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Total Amount
              Text(
                CurrencyFormatter.format(amount),
                style: AppTypography.currencyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),

          // Action Buttons Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 1. Toggle Paid Status Action
              TextButton.icon(
                icon: Icon(
                  isPaid
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isPaid ? AppColors.paid : AppColors.pending,
                ),
                label: Text(
                  isPaid ? "Mark Pending" : "Mark Paid",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPaid ? AppColors.paid : AppColors.pending,
                  ),
                ),
                onPressed: () => _togglePaidStatus(invoiceId),
              ),
              const Spacer(),

              // 2. View/Print PDF Action
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
                tooltip: "View / Print PDF",
                onPressed: () => _viewPdf(inv),
              ),

              // 3. Edit Invoice (Matching Wizard) Action
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
                tooltip: "Edit Invoice",
                onPressed: () => _editInvoice(inv),
              ),

              // 4. Delete Invoice Action
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.danger,
                ),
                tooltip: "Delete",
                onPressed: () => _confirmDelete(inv),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
