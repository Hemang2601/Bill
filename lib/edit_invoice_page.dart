import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'core/core.dart';
import 'database_helper.dart';
import 'services/invoice_pdf_service.dart';

/// Premium, enterprise-grade invoice editing screen for Shree Shakti Electric
/// Preserves original invoice ID, bill number, PDF paths, and updates SQLite in a transaction.
class EditInvoicePage extends StatefulWidget {
  final Map<String, dynamic> existingInvoice;

  const EditInvoicePage({super.key, required this.existingInvoice});

  @override
  State<EditInvoicePage> createState() => _EditInvoicePageState();
}

class _EditInvoicePageState extends State<EditInvoicePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final FocusNode _customerFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _items = [];
  late String _billNumber;
  bool _isLoadingItems = true;
  bool _isUpdating = false;
  bool _hasUnsavedChanges = false;

  final List<Map<String, String>> _catalogSuggestions = const [
    {"name": "Switch 6A", "price": "45"},
    {"name": "Socket 6A", "price": "85"},
    {"name": "LED Bulb 9W", "price": "120"},
    {"name": "1.5mm Wire Coil", "price": "1200"},
    {"name": "Fan Regulator", "price": "250"},
    {"name": "MCB 16A Single", "price": "180"},
    {"name": "LED Batten 20W", "price": "280"},
    {"name": "Anchor Modular Plate", "price": "95"},
  ];

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

    // Prepopulate existing invoice metadata
    _billNumber = widget.existingInvoice['billNumber']?.toString() ?? "UNKNOWN";
    _dateController.text =
        widget.existingInvoice['date']?.toString() ??
        DateFormat('dd MMM yyyy').format(DateTime.now());
    _customerName.text =
        widget.existingInvoice['customerName']?.toString() ?? "";
    _phoneNumber.text = widget.existingInvoice['phoneNumber']?.toString() ?? "";

    _customerName.addListener(_markDirty);
    _phoneNumber.addListener(_markDirty);

    _loadExistingItems();
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
    }
  }

  Future<void> _loadExistingItems() async {
    try {
      final invoiceId = (widget.existingInvoice['id'] as num?)?.toInt() ?? 0;
      final fetchedItems = await DatabaseHelper.instance.getInvoiceItems(
        invoiceId,
      );

      if (!mounted) return;
      setState(() {
        for (var item in fetchedItems) {
          _items.add({
            "name": TextEditingController(
              text: item['itemName']?.toString() ?? '',
            ),
            "qty": TextEditingController(
              text: (item['qty'] as num?)?.toString() ?? '1',
            ),
            "price": TextEditingController(
              text: (item['price'] as num?)?.toString() ?? '0',
            ),
            "nameFocus": FocusNode(),
            "qtyFocus": FocusNode(),
            "priceFocus": FocusNode(),
          });
        }
        if (_items.isEmpty) {
          _addNewItem(autoScroll: false, autoFocus: false);
        }
        _isLoadingItems = false;
        _hasUnsavedChanges = false;
      });
      _fadeController.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_items.isEmpty) {
          _addNewItem(autoScroll: false, autoFocus: false);
        }
        _isLoadingItems = false;
        _hasUnsavedChanges = false;
      });
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _customerName.dispose();
    _phoneNumber.dispose();
    _dateController.dispose();
    _customerFocus.dispose();
    _phoneFocus.dispose();

    for (final item in _items) {
      (item['name'] as TextEditingController?)?.dispose();
      (item['qty'] as TextEditingController?)?.dispose();
      (item['price'] as TextEditingController?)?.dispose();
      (item['nameFocus'] as FocusNode?)?.dispose();
      (item['qtyFocus'] as FocusNode?)?.dispose();
      (item['priceFocus'] as FocusNode?)?.dispose();
    }
    super.dispose();
  }

  void _addNewItem({
    String name = "",
    String price = "0",
    String qty = "1",
    bool autoScroll = true,
    bool autoFocus = false,
  }) {
    final nameController = TextEditingController(text: name);
    final qtyController = TextEditingController(text: qty);
    final priceController = TextEditingController(text: price);
    final nameFocus = FocusNode();
    final qtyFocus = FocusNode();
    final priceFocus = FocusNode();

    setState(() {
      _items.add({
        "name": nameController,
        "qty": qtyController,
        "price": priceController,
        "nameFocus": nameFocus,
        "qtyFocus": qtyFocus,
        "priceFocus": priceFocus,
      });
      _hasUnsavedChanges = true;
    });

    if (autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    if (autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameFocus.requestFocus();
      });
    }
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    setState(() {
      final removed = _items.removeAt(index);
      (removed['name'] as TextEditingController?)?.dispose();
      (removed['qty'] as TextEditingController?)?.dispose();
      (removed['price'] as TextEditingController?)?.dispose();
      (removed['nameFocus'] as FocusNode?)?.dispose();
      (removed['qtyFocus'] as FocusNode?)?.dispose();
      (removed['priceFocus'] as FocusNode?)?.dispose();
      _hasUnsavedChanges = true;
    });
  }

  void _onSelectCatalogItem(String name, String price) {
    HapticFeedback.lightImpact();
    if (_items.isNotEmpty) {
      final lastItem = _items.last;
      final lastName = (lastItem['name'] as TextEditingController).text.trim();
      final lastPrice = (lastItem['price'] as TextEditingController).text
          .trim();
      if (lastName.isEmpty && (lastPrice.isEmpty || lastPrice == "0")) {
        setState(() {
          (lastItem['name'] as TextEditingController).text = name;
          (lastItem['price'] as TextEditingController).text = price;
          _hasUnsavedChanges = true;
        });
        (lastItem['qtyFocus'] as FocusNode?)?.requestFocus();
        return;
      }
    }
    _addNewItem(name: name, price: price, autoScroll: true, autoFocus: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_items.isNotEmpty) {
        (_items.last['qtyFocus'] as FocusNode?)?.requestFocus();
      }
    });
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) {
      final q = (item['qty'] is TextEditingController)
          ? (double.tryParse((item['qty'] as TextEditingController).text) ??
                0.0)
          : (double.tryParse(item['qty']?.toString() ?? '0') ?? 0.0);
      final p = (item['price'] is TextEditingController)
          ? (double.tryParse((item['price'] as TextEditingController).text) ??
                0.0)
          : (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0);
      return sum + (q * p);
    });
  }

  int get _validItemsCount {
    return _items.where((item) {
      final name = (item['name'] as TextEditingController).text.trim();
      final price =
          double.tryParse((item['price'] as TextEditingController).text) ?? 0.0;
      return name.isNotEmpty || price > 0;
    }).length;
  }

  double get _totalQuantity {
    return _items.fold(0.0, (sum, item) {
      final q = (item['qty'] is TextEditingController)
          ? (double.tryParse((item['qty'] as TextEditingController).text) ??
                0.0)
          : 0.0;
      return sum + q;
    });
  }

  Future<bool> _handleAbandonCheck() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final bool? confirm = await AppDialog.showDiscardChangesConfirmation(
      context: context,
      title: "Discard Edits?",
      confirmLabel: "DISCARD EDITS",
    );

    return confirm == true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
        _hasUnsavedChanges = true;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    AppNotification.showError(context, message);
  }

  // --- PROCESS UPDATE ENGINE ---
  Future<void> _processUpdate() async {
    if (_isUpdating) return;

    final validItems = _items.where((item) {
      final name = (item['name'] as TextEditingController).text.trim();
      final qty =
          double.tryParse((item['qty'] as TextEditingController).text) ?? 0.0;
      final price =
          double.tryParse((item['price'] as TextEditingController).text) ?? 0.0;
      return name.isNotEmpty || (qty > 0 && price > 0);
    }).toList();

    if (validItems.isEmpty) {
      _showErrorSnackbar(
        "Please ensure at least one line item has a name or rate.",
      );
      return;
    }

    setState(() => _isUpdating = true);
    AppLoading.show(context, message: "Regenerating PDF & Updating Invoice...");

    try {
      final String finalCustomer = _customerName.text.trim().isEmpty
          ? "CASH CUSTOMER"
          : _customerName.text.trim().toUpperCase();
      final String finalPhone = _phoneNumber.text.trim().isEmpty
          ? "N/A"
          : _phoneNumber.text.trim();

      // 1. Regenerate PDF bytes using centralized InvoicePdfService
      final Uint8List pdfBytes = await InvoicePdfService.generateInvoicePdf(
        billNumber: _billNumber,
        customerName: finalCustomer,
        phoneNumber: finalPhone,
        date: _dateController.text,
        items: validItems,
        totalAmount: _subtotal,
      );

      // 2. Overwrite existing PDF file safely
      final String existingPdfPath =
          widget.existingInvoice['pdfPath']?.toString() ?? '';
      String targetPath = existingPdfPath;
      if (targetPath.isEmpty) {
        Directory? baseDir = await getExternalStorageDirectory();
        baseDir ??= await getApplicationDocumentsDirectory();
        targetPath =
            "${baseDir.path}/Shakti Electric/Invoice_${_billNumber.replaceAll('-', '_')}.pdf";
      }

      final File pdfFile = await InvoicePdfService.overwritePdfFile(
        targetPath: targetPath,
        billNumber: _billNumber,
        bytes: pdfBytes,
      );

      // 3. Update SQLite database in transaction
      final invoiceId = (widget.existingInvoice['id'] as num?)?.toInt() ?? 0;
      await DatabaseHelper.instance.updateCompleteInvoice(
        invoiceData: {
          'id': invoiceId,
          'billNumber': _billNumber,
          'customerName': finalCustomer,
          'phoneNumber': finalPhone,
          'date': _dateController.text,
          'totalAmount': _subtotal,
          'pdfPath': pdfFile.path,
        },
        items: validItems.map((item) {
          final name = (item['name'] as TextEditingController).text.trim();
          final qty =
              double.tryParse((item['qty'] as TextEditingController).text) ??
              0.0;
          final price =
              double.tryParse((item['price'] as TextEditingController).text) ??
              0.0;
          return {
            'invoiceId': invoiceId,
            'itemName': name.isEmpty ? "Electric Item" : name,
            'qty': qty,
            'price': price,
          };
        }).toList(),
      );

      _hasUnsavedChanges = false;
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // dismiss loading dialog
        _showSuccessDialog(pdfFile, pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // dismiss loading dialog
        _showErrorSnackbar("Failed to update invoice: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showSuccessDialog(File file, Uint8List pdfBytes) {
    AppDialog.showInvoiceSuccessDialog(
      context: context,
      billNumber: _billNumber,
      totalAmount: _subtotal,
      pdfFile: file,
      pdfBytes: pdfBytes,
      isNewInvoice: false,
      onFinish: () {
        Navigator.of(context).pop(); // dismiss modal
        Navigator.of(
          context,
        ).pop(true); // exit Edit page with true (triggers caller refresh)
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingItems) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: AppLoading(message: "Loading invoice details...")),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleAbandonCheck();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppNavigationDrawer(),
        appBar: _buildTopHeader(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideDesktop = constraints.maxWidth >= 940;

              return AppResponsiveContainer(
                maxWidth: 1100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: isWideDesktop
                    ? _buildDesktopLayout()
                    : _buildMobileLayout(),
              );
            },
          ),
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 940) {
              return _buildStickyBottomBar();
            }
            return const SizedBox.shrink();
          },
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
        tooltip: "Cancel and Back",
        onPressed: () async {
          if (await _handleAbandonCheck()) {
            if (mounted) Navigator.of(context).pop();
          }
        },
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "EDIT INVOICE",
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            "SHREE SHAKTI ELECTRIC • RECORD UPDATE",
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
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _billNumber,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- DESKTOP 2-COLUMN LAYOUT ---
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Customer Form & Line Items (Flex 7)
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomerCard(),
                AppSpacing.gapVl,
                _buildQuickCatalogSection(),
                AppSpacing.gapVl,
                _buildLineItemsSection(isWide: true),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        AppSpacing.gapHxl,
        // Right Column: Summary & Actions (Flex 4)
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInvoiceMetaCard(),
                AppSpacing.gapVl,
                _buildBillSummaryCard(),
                AppSpacing.gapVl,
                _buildDesktopActionsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- MOBILE / TABLET 1-COLUMN LAYOUT ---
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCustomerCard(),
          AppSpacing.gapVl,
          _buildQuickCatalogSection(),
          AppSpacing.gapVl,
          _buildLineItemsSection(isWide: false),
          AppSpacing.gapVl,
          _buildBillSummaryCard(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // --- CUSTOMER DETAILS CARD ---
  Widget _buildCustomerCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Customer & Invoice Info",
            subtitle: "Update recipient details for this invoice",
          ),
          AppSpacing.gapVm,
          AppTextField(
            controller: _customerName,
            focusNode: _customerFocus,
            label: "Customer / Firm Name",
            hint: "e.g. PATEL ELECTRICALS (defaults to CASH CUSTOMER)",
            prefixIcon: Icons.person_rounded,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _phoneFocus.requestFocus(),
            onChanged: (_) => setState(() {}),
          ),
          AppSpacing.gapVm,
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 500;
              final phoneField = AppTextField(
                controller: _phoneNumber,
                focusNode: _phoneFocus,
                label: "Mobile Number",
                hint: "e.g. 9876543210 (optional)",
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) {
                  if (_items.isNotEmpty) {
                    (_items[0]['nameFocus'] as FocusNode?)?.requestFocus();
                  }
                },
                onChanged: (_) => setState(() {}),
              );

              final dateField = AppTextField(
                controller: _dateController,
                readOnly: true,
                label: "Invoice Date",
                prefixIcon: Icons.calendar_today_rounded,
                suffix: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textSecondary,
                ),
                onTap: () => _selectDate(context),
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: phoneField),
                    AppSpacing.gapHm,
                    Expanded(child: dateField),
                  ],
                );
              }

              return Column(
                children: [phoneField, AppSpacing.gapVm, dateField],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- QUICK CATALOG SUGGESTIONS ---
  Widget _buildQuickCatalogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                "QUICK INVENTORY CHIPS",
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapVs,
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _catalogSuggestions.length,
            separatorBuilder: (context, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _catalogSuggestions[index];
              return ActionChip(
                elevation: 0,
                pressElevation: 1,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border, width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                avatar: const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  radius: 10,
                  child: Icon(Icons.add, size: 12, color: AppColors.primary),
                ),
                label: Text(
                  "${item['name']} (₹${item['price']})",
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                onPressed: () =>
                    _onSelectCatalogItem(item['name']!, item['price']!),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- LINE ITEMS SECTION ---
  Widget _buildLineItemsSection({required bool isWide}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: AppSectionHeader(
                  title: "Billing Line Items",
                  subtitle: "Products, spare parts, or services",
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
                  "${_items.length} ${_items.length == 1 ? 'ITEM' : 'ITEMS'}",
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVm,
          if (isWide) _buildDesktopTableHeader(),
          AppSpacing.gapVs,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, _) => AppSpacing.gapVs,
            itemBuilder: (context, index) => _buildItemTile(index, isWide),
          ),
          AppSpacing.gapVm,
          AppButton(
            label: "ADD NEW LINE ITEM",
            icon: Icons.add_rounded,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            isFullWidth: true,
            onPressed: () => _addNewItem(autoScroll: true, autoFocus: true),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            child: Text("#", style: AppTypography.labelCaps),
          ),
          const SizedBox(width: 8),
          const Expanded(
            flex: 5,
            child: Text("ITEM DESCRIPTION", style: AppTypography.labelCaps),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: Text("QTY", style: AppTypography.labelCaps),
          ),
          const SizedBox(width: 12),
          const Expanded(
            flex: 2,
            child: Text("RATE (₹)", style: AppTypography.labelCaps),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            width: 110,
            child: Text(
              "AMOUNT (₹)",
              textAlign: TextAlign.right,
              style: AppTypography.labelCaps,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildItemTile(int index, bool isWide) {
    final item = _items[index];
    final qty =
        double.tryParse((item['qty'] as TextEditingController).text) ?? 0.0;
    final price =
        double.tryParse((item['price'] as TextEditingController).text) ?? 0.0;
    final amount = qty * price;

    if (isWide) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                "${index + 1}",
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextField(
                controller: item['name'],
                focusNode: item['nameFocus'] as FocusNode?,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: "Item name / description...",
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) =>
                    (item['qtyFocus'] as FocusNode?)?.requestFocus(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: item['qty'],
                focusNode: item['qtyFocus'] as FocusNode?,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: "1",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) =>
                    (item['priceFocus'] as FocusNode?)?.requestFocus(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: item['price'],
                focusNode: item['priceFocus'] as FocusNode?,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: "0",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) {
                  if (index == _items.length - 1) {
                    _addNewItem(autoScroll: true, autoFocus: true);
                  } else {
                    (_items[index + 1]['nameFocus'] as FocusNode?)
                        ?.requestFocus();
                  }
                },
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: Text(
                CurrencyFormatter.format(amount),
                textAlign: TextAlign.right,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              tooltip: "Remove Item",
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      );
    }

    // Responsive Mobile Card
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item['name'],
                  focusNode: item['nameFocus'] as FocusNode?,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Item description...",
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) =>
                      (item['qtyFocus'] as FocusNode?)?.requestFocus(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                tooltip: "Remove Item",
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.border),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: item['qty'],
                  focusNode: item['qtyFocus'] as FocusNode?,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Qty",
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) =>
                      (item['priceFocus'] as FocusNode?)?.requestFocus(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: item['price'],
                  focusNode: item['priceFocus'] as FocusNode?,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Rate (₹)",
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (index == _items.length - 1) {
                      _addNewItem(autoScroll: true, autoFocus: true);
                    } else {
                      (_items[index + 1]['nameFocus'] as FocusNode?)
                          ?.requestFocus();
                    }
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "AMOUNT",
                    style: AppTypography.labelCaps.copyWith(fontSize: 9),
                  ),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BILL METADATA CARD (DESKTOP) ---
  Widget _buildInvoiceMetaCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Invoice Identification",
            subtitle: "Original system parameters preserved",
          ),
          AppSpacing.gapVs,
          _metaRow("INVOICE NO.", _billNumber, isHighlight: true),
          const Divider(height: 16, color: AppColors.border),
          _metaRow("DATE", _dateController.text),
          const Divider(height: 16, color: AppColors.border),
          _metaRow(
            "STATUS",
            "Updating Existing Record",
            badgeColor: AppColors.warning,
          ),
          const Divider(height: 16, color: AppColors.border),
          _metaRow("DOC FORMAT", "GST Estimate / Bill (A4)"),
        ],
      ),
    );
  }

  Widget _metaRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? badgeColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelCaps.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppSpacing.gapHs,
        if (badgeColor != null)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
        else
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  // --- BILL SUMMARY CARD ---
  Widget _buildBillSummaryCard() {
    return AppCard(
      backgroundColor: AppColors.surface,
      borderColor: AppColors.primary.withAlpha(50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: "Updated Summary",
            subtitle: "Live financial total & units",
          ),
          AppSpacing.gapVm,
          _summaryRow("Total Line Items", "$_validItemsCount"),
          AppSpacing.gapVs,
          _summaryRow(
            "Total Units / Quantity",
            _totalQuantity.toStringAsFixed(0),
          ),
          AppSpacing.gapVs,
          _summaryRow("Subtotal", CurrencyFormatter.format(_subtotal)),
          const Divider(height: 24, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NET PAYABLE",
                      style: AppTypography.labelCaps.copyWith(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Includes all goods & fitting",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapHs,
              AnimatedCountText(
                value: _subtotal,
                isCurrency: true,
                style: AppTypography.currencyLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppSpacing.gapHs,
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // --- DESKTOP ACTIONS CARD ---
  Widget _buildDesktopActionsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: "UPDATE & REGENERATE PDF",
            icon: Icons.update_rounded,
            variant: AppButtonVariant.primary,
            size: AppButtonSize.large,
            isLoading: _isUpdating,
            onPressed: _isUpdating ? null : _processUpdate,
          ),
          AppSpacing.gapVm,
          AppButton(
            label: "CANCEL / DISCARD EDITS",
            icon: Icons.close_rounded,
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            onPressed: () async {
              if (await _handleAbandonCheck()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  // --- STICKY BOTTOM BAR (MOBILE / TABLET) ---
  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.hover,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "UPDATED TOTAL",
                    style: AppTypography.labelCaps.copyWith(fontSize: 9),
                  ),
                  AnimatedCountText(
                    value: _subtotal,
                    isCurrency: true,
                    style: AppTypography.headingMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapHm,
            Expanded(
              flex: 6,
              child: AppButton(
                label: "UPDATE & SAVE",
                icon: Icons.update_rounded,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
                isLoading: _isUpdating,
                onPressed: _isUpdating ? null : _processUpdate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
