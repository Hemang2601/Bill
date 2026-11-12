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

enum HistorySortOption {
  dateDesc("Date: Newest First", "NEWEST"),
  dateAsc("Date: Oldest First", "OLDEST"),
  amountDesc("Amount: High to Low", "AMOUNT ↓"),
  amountAsc("Amount: Low to High", "AMOUNT ↑"),
  customerAsc("Customer: A to Z", "A-Z");

  final String label;
  final String shortLabel;
  const HistorySortOption(this.label, this.shortLabel);
}

/// Clean High-Contrast White Theme Bill History & Ledger for Shree Shakti Electric Service
/// Dedicated Search Bar, Status Filter Chips (All, Paid, Pending), Date Period Filters,
/// and Clean White Cards with Status Pill Badges and Direct Action Buttons.
class HistoryPage extends StatefulWidget {
  final bool autoFocusSearch;
  final String? initialQuery;
  final List<Map<String, dynamic>>? initialInvoices;

  const HistoryPage({
    super.key,
    this.autoFocusSearch = false,
    this.initialQuery,
    this.initialInvoices,
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
  HistorySortOption _sortOption = HistorySortOption.dateDesc;
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

  void _applySorting(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      switch (_sortOption) {
        case HistorySortOption.dateDesc:
          final d1 =
              DatabaseHelper.parseDateRobust(a['date']?.toString() ?? '') ??
              DateTime(1970);
          final d2 =
              DatabaseHelper.parseDateRobust(b['date']?.toString() ?? '') ??
              DateTime(1970);
          final comp = d2.compareTo(d1);
          if (comp != 0) return comp;
          return ((b['id'] as num?)?.toInt() ?? 0).compareTo(
            (a['id'] as num?)?.toInt() ?? 0,
          );
        case HistorySortOption.dateAsc:
          final d1 =
              DatabaseHelper.parseDateRobust(a['date']?.toString() ?? '') ??
              DateTime(1970);
          final d2 =
              DatabaseHelper.parseDateRobust(b['date']?.toString() ?? '') ??
              DateTime(1970);
          final comp = d1.compareTo(d2);
          if (comp != 0) return comp;
          return ((a['id'] as num?)?.toInt() ?? 0).compareTo(
            (b['id'] as num?)?.toInt() ?? 0,
          );
        case HistorySortOption.amountDesc:
          final a1 = (a['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final a2 = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
          return a2.compareTo(a1);
        case HistorySortOption.amountAsc:
          final a1 = (a['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final a2 = (b['totalAmount'] as num?)?.toDouble() ?? 0.0;
          return a1.compareTo(a2);
        case HistorySortOption.customerAsc:
          final c1 = (a['customerName']?.toString() ?? '').toLowerCase();
          final c2 = (b['customerName']?.toString() ?? '').toLowerCase();
          return c1.compareTo(c2);
      }
    });
  }

  void _changeSortOption(HistorySortOption newOption) {
    setState(() {
      _sortOption = newOption;
      _applySorting(_invoices);
    });
  }

  Future<void> _fetchDataFromDB() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> rawData;
      if (widget.initialInvoices != null) {
        rawData = widget.initialInvoices!.where((inv) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final num = (inv['billNumber']?.toString() ?? '').toLowerCase();
            final cust = (inv['customerName']?.toString() ?? '').toLowerCase();
            final phone = (inv['phoneNumber']?.toString() ?? '').toLowerCase();
            if (!num.contains(q) && !cust.contains(q) && !phone.contains(q)) {
              return false;
            }
          }
          return true;
        }).toList();
      } else {
        rawData = await DatabaseHelper.instance.getFilteredInvoices(
          searchQuery: _searchQuery,
          startDate: _startDate,
          endDate: _endDate,
        );
      }
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

      _applySorting(filtered);

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

  Future<void> _selectSpecificMonth() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDatePickerMode: DatePickerMode.year,
      helpText: "SELECT MONTH & YEAR",
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

    if (pickedDate != null) {
      setState(() {
        _startDate = DateTime(pickedDate.year, pickedDate.month, 1);
        _endDate = DateTime(pickedDate.year, pickedDate.month + 1, 0);
        _isCustomRange = true;
        _activeFilter = DateFormat('MMMM yyyy').format(pickedDate);
      });
      _fetchDataFromDB();
    }
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
      _sortOption = HistorySortOption.dateDesc;
    });
    _fetchDataFromDB();
  }

  void _shareInvoicePdf(Map<String, dynamic> inv) async {
    final pdfPath = inv['pdfPath']?.toString() ?? '';
    final file = File(pdfPath);
    if (await file.exists()) {
      final billNumber = inv['billNumber']?.toString() ?? '';
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Invoice #$billNumber from Shree Shakti Electric');
    } else {
      if (!mounted) return;
      AppDialog.showMissingPdfDialog(
        context: context,
        billNumber: inv['billNumber']?.toString() ?? '',
      );
    }
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
              AppSpacing.gapHs,
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
              AppSpacing.gapHs,
              PopupMenuButton<HistorySortOption>(
                tooltip: "Sort Invoices",
                initialValue: _sortOption,
                onSelected: _changeSortOption,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.surface,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryLight.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _sortOption.shortLabel,
                        style: AppTypography.labelCaps.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => HistorySortOption.values.map((opt) {
                  final bool isSelected = opt == _sortOption;
                  return PopupMenuItem<HistorySortOption>(
                    value: opt,
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
              itemCount: _filters.length + 1 + (_isCustomRange ? 1 : 0),
              separatorBuilder: (context, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index < _filters.length) {
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
                }

                if (index == _filters.length) {
                  return ActionChip(
                    avatar: const Icon(
                      Icons.calendar_month_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    label: const Text("Select Month"),
                    backgroundColor: AppColors.primarySoft,
                    side: BorderSide(
                      color: AppColors.primaryLight.withAlpha(50),
                    ),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: _selectSpecificMonth,
                  );
                }

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 640;

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
            _buildInvoiceTable(isDesktop),
          ],
        );
      },
    );
  }

  // --- STRUCTURED ACCOUNTING LEDGER TABLE ---
  Widget _buildInvoiceTable(bool isDesktop) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildTableHeader(isDesktop),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invoices.length,
              separatorBuilder: (context, _) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final inv = _invoices[index];
                return _buildTableRow(inv, isDesktop);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- TABLE HEADER ---
  Widget _buildTableHeader(bool isDesktop) {
    return Container(
      color: AppColors.surfaceSubtle,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    "BILL NO. & DATE",
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    "CUSTOMER",
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      "STATUS",
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "AMOUNT",
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 50,
                  child: Center(
                    child: Text(
                      "ACTION",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    "CUSTOMER & BILL",
                    style: AppTypography.labelCaps.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      "STATUS",
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "AMOUNT",
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 44,
                  child: Center(
                    child: Text(
                      "ACT",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- TABLE ROW ---
  Widget _buildTableRow(Map<String, dynamic> inv, bool isDesktop) {
    final int invoiceId = (inv['id'] as num?)?.toInt() ?? 0;
    final bool isPaid = _paidInvoiceIds.contains(invoiceId);
    final String billNumber = inv['billNumber']?.toString() ?? "N/A";
    final String customer =
        inv['customerName']?.toString().toUpperCase() ?? "CASH CUSTOMER";
    final String date = inv['date']?.toString() ?? "";
    final String phone = inv['phoneNumber']?.toString() ?? "";
    final double amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showInvoiceActionSheet(inv),
        hoverColor: AppColors.primarySoft.withAlpha(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isDesktop
              ? Row(
                  children: [
                    // Column 1: Bill No & Date
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "#$billNumber",
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: 13.5,
                            ),
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

                    // Column 2: Customer Name & Phone
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (phone.isNotEmpty && phone != "N/A") ...[
                            const SizedBox(height: 2),
                            Text(
                              phone,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Column 3: Status Badge (Tap to toggle directly)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: InkWell(
                          onTap: () => _togglePaidStatus(invoiceId),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColors.paidSoft
                                  : AppColors.pendingSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPaid
                                    ? AppColors.paidBorder
                                    : AppColors.pendingBorder,
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
                      ),
                    ),

                    // Column 4: Amount
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.format(amount),
                          style: AppTypography.currencyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    // Column 5: Action Button
                    SizedBox(
                      width: 50,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: "Options",
                          onPressed: () => _showInvoiceActionSheet(inv),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Mobile Column 1: Customer & Bill Info
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "#$billNumber${date.isNotEmpty ? ' • $date' : ''}",
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Mobile Column 2: Status
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: InkWell(
                          onTap: () => _togglePaidStatus(invoiceId),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? AppColors.paidSoft
                                  : AppColors.pendingSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPaid
                                    ? AppColors.paidBorder
                                    : AppColors.pendingBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaid
                                      ? Icons.check_circle_rounded
                                      : Icons.hourglass_top_rounded,
                                  size: 10,
                                  color: isPaid
                                      ? AppColors.paid
                                      : AppColors.pending,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isPaid ? "PAID" : "PEND",
                                  style: AppTypography.labelCaps.copyWith(
                                    fontSize: 8.5,
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
                      ),
                    ),

                    // Mobile Column 3: Amount
                    Expanded(
                      flex: 4,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.format(amount),
                          style: AppTypography.currencyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Mobile Column 4: Action Button
                    SizedBox(
                      width: 44,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 19,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: "Options",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: () => _showInvoiceActionSheet(inv),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // --- LUXURY INVOICE ACTION MODAL SHEET ---
  void _showInvoiceActionSheet(Map<String, dynamic> inv) {
    HapticFeedback.mediumImpact();
    final int invoiceId = (inv['id'] as num?)?.toInt() ?? 0;
    final bool isPaid = _paidInvoiceIds.contains(invoiceId);
    final String billNumber = inv['billNumber']?.toString() ?? "N/A";
    final String customer =
        inv['customerName']?.toString().toUpperCase() ?? "CASH CUSTOMER";
    final String date = inv['date']?.toString() ?? "";
    final String phone = inv['phoneNumber']?.toString() ?? "";
    final double amount = (inv['totalAmount'] as num?)?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice Details Card in Sheet Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isPaid
                            ? AppColors.paidSoft
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPaid
                              ? AppColors.paidBorder
                              : AppColors.primaryLight.withAlpha(50),
                        ),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: isPaid ? AppColors.paid : AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? AppColors.paidSoft
                                      : AppColors.pendingSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isPaid
                                        ? AppColors.paidBorder
                                        : AppColors.pendingBorder,
                                  ),
                                ),
                                child: Text(
                                  isPaid ? "PAID" : "PENDING",
                                  style: AppTypography.labelCaps.copyWith(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: isPaid
                                        ? AppColors.paid
                                        : AppColors.pending,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (date.isNotEmpty || phone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (date.isNotEmpty) date,
                                if (phone.isNotEmpty) phone,
                              ].join(" • "),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
              ),
              const SizedBox(height: 16),

              Text(
                "INVOICE ACTIONS",
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Action 1: See PDF (View & Print)
              _buildSheetActionTile(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primarySoft,
                title: "See PDF Document",
                subtitle: "View, zoom and print generated PDF invoice",
                onTap: () {
                  Navigator.pop(sheetContext);
                  _viewPdf(inv);
                },
              ),
              const SizedBox(height: 8),

              // Action 2: Edit Invoice
              _buildSheetActionTile(
                icon: Icons.edit_note_rounded,
                iconColor: AppColors.brandNavy,
                iconBgColor: AppColors.primarySoft,
                title: "Edit Invoice",
                subtitle: "Modify customer details, items, or prices",
                onTap: () {
                  Navigator.pop(sheetContext);
                  _editInvoice(inv);
                },
              ),
              const SizedBox(height: 8),

              // Action 3: Share PDF
              _buildSheetActionTile(
                icon: Icons.share_rounded,
                iconColor: AppColors.electricBlue,
                iconBgColor: AppColors.electricSoft,
                title: "Share PDF Document",
                subtitle: "Send invoice via WhatsApp, email or message",
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareInvoicePdf(inv);
                },
              ),
              const SizedBox(height: 8),

              // Action 4: Toggle Paid / Pending
              _buildSheetActionTile(
                icon: isPaid
                    ? Icons.hourglass_top_rounded
                    : Icons.check_circle_rounded,
                iconColor: isPaid ? AppColors.pending : AppColors.paid,
                iconBgColor: isPaid
                    ? AppColors.pendingSoft
                    : AppColors.paidSoft,
                title: isPaid ? "Mark as Pending" : "Mark as Paid",
                subtitle: isPaid
                    ? "Change status to unpaid/pending"
                    : "Record customer payment as received",
                onTap: () {
                  Navigator.pop(sheetContext);
                  _togglePaidStatus(invoiceId);
                },
              ),
              const SizedBox(height: 8),

              // Action 5: Delete Invoice (Destructive)
              _buildSheetActionTile(
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.danger,
                iconBgColor: AppColors.dangerSoft,
                title: "Delete Invoice",
                subtitle: "Permanently delete record and stored PDF file",
                isDestructive: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(inv);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.dangerSoft.withAlpha(60)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDestructive
                  ? AppColors.danger.withAlpha(50)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDestructive
                            ? AppColors.danger
                            : AppColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDestructive ? AppColors.danger : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
