import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/core.dart';
import 'invoice_wizard_controller.dart';

/// Step 2: Items & Pricing of the Invoice Creation Wizard
class InvoiceItemsStep extends StatefulWidget {
  final InvoiceWizardController controller;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const InvoiceItemsStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<InvoiceItemsStep> createState() => _InvoiceItemsStepState();
}

class _InvoiceItemsStepState extends State<InvoiceItemsStep> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _priceController = TextEditingController(
    text: "0",
  );

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _qtyFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  String? _itemError;

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
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    _qtyFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  double get _currentPreviewAmount {
    final q = double.tryParse(_qtyController.text) ?? 0.0;
    final p = double.tryParse(_priceController.text) ?? 0.0;
    return q * p;
  }

  void _onSelectSuggestion(String name, String price) {
    setState(() {
      _nameController.text = name;
      _priceController.text = price;
      if (_qtyController.text.isEmpty || _qtyController.text == "0") {
        _qtyController.text = "1";
      }
      _itemError = null;
    });
    _qtyFocus.requestFocus();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (name.isEmpty) {
      setState(() => _itemError = "Please enter an item name or description");
      _nameFocus.requestFocus();
      return;
    }

    if (qty <= 0) {
      setState(() => _itemError = "Quantity must be greater than zero");
      _qtyFocus.requestFocus();
      return;
    }

    if (price < 0) {
      setState(() => _itemError = "Rate cannot be negative");
      _priceFocus.requestFocus();
      return;
    }

    final success = widget.controller.addItem(
      name: name,
      qty: qty,
      price: price,
    );
    if (success) {
      setState(() {
        _nameController.clear();
        _qtyController.text = "1";
        _priceController.text = "0";
        _itemError = null;
      });
      // Proper keyboard dismissal on adding item
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      AppNotification.showSuccess(context, "Added \"$name\" to invoice");
    }
  }

  void _showEditItemDialog(int index) {
    final item = widget.controller.items[index];
    final editNameController = TextEditingController(text: item.name);
    final editQtyController = TextEditingController(text: item.qty.toString());
    final editPriceController = TextEditingController(
      text: item.price.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text("Edit Item #${index + 1}", style: AppTypography.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: editNameController,
              label: "Item Description",
              textCapitalization: TextCapitalization.words,
            ),
            AppSpacing.gapVm,
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: editQtyController,
                    label: "Quantity",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                AppSpacing.gapHm,
                Expanded(
                  child: AppTextField(
                    controller: editPriceController,
                    label: "Rate (₹)",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AppButton(
            label: "CANCEL",
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton(
            label: "SAVE CHANGES",
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
            onPressed: () {
              FocusScope.of(ctx).unfocus();
              SystemChannels.textInput.invokeMethod('TextInput.hide');
              final newName = editNameController.text.trim();
              final newQty = double.tryParse(editQtyController.text) ?? 0.0;
              final newPrice = double.tryParse(editPriceController.text) ?? 0.0;

              if (newName.isNotEmpty && newQty > 0 && newPrice >= 0) {
                widget.controller.editItem(
                  index,
                  name: newName,
                  qty: newQty,
                  price: newPrice,
                );
                Navigator.of(ctx).pop();
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    if (!widget.controller.hasValidItems) {
      AppNotification.showWarning(
        context,
        "Please add at least one line item to proceed to review",
      );
      return;
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryLight.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.primaryGlow,
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "STEP 2: ITEMS & PRICING",
                              style: AppTypography.labelCaps.copyWith(
                                fontSize: 10.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Add Products, Spare Parts or Services",
                              style: AppTypography.headingSmall.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVl,

                // Quick Inventory Chips Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "POPULAR ELECTRICAL ITEMS",
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVs,
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _catalogSuggestions.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = _catalogSuggestions[index];
                          return ActionChip(
                            elevation: 0,
                            pressElevation: 1,
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            avatar: const CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              radius: 10,
                              child: Icon(
                                Icons.add,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            label: Text(
                              "${item['name']} (₹${item['price']})",
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () => _onSelectSuggestion(
                              item['name']!,
                              item['price']!,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                AppSpacing.gapVl,

                // Add Item Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppSectionHeader(
                        title: "Add Line Item",
                        subtitle: "Type description, quantity and unit rate",
                      ),
                      AppSpacing.gapVm,

                      // Item Description
                      AppTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        label: "Product / Item Description *",
                        hint: "e.g. Havells 1.5 sq mm Wire Coil (90m)",
                        prefixIcon: Icons.electric_bolt_rounded,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        suffix: IconButton(
                          icon: const Icon(
                            Icons.keyboard_hide_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: "Dismiss Keyboard",
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            SystemChannels.textInput.invokeMethod(
                              'TextInput.hide',
                            );
                          },
                        ),
                        onChanged: (_) => setState(() => _itemError = null),
                        onSubmitted: (_) => _qtyFocus.requestFocus(),
                      ),

                      AppSpacing.gapVm,

                      // Quantity and Rate Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: AppTextField(
                              controller: _qtyController,
                              focusNode: _qtyFocus,
                              label: "Quantity *",
                              hint: "1",
                              prefixIcon: Icons.format_list_numbered_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              suffix: IconButton(
                                icon: const Icon(
                                  Icons.keyboard_hide_rounded,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                tooltip: "Dismiss Keyboard",
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  SystemChannels.textInput.invokeMethod(
                                    'TextInput.hide',
                                  );
                                },
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _priceFocus.requestFocus(),
                            ),
                          ),
                          AppSpacing.gapHm,
                          Expanded(
                            flex: 6,
                            child: AppTextField(
                              controller: _priceController,
                              focusNode: _priceFocus,
                              label: "Rate per Unit (₹) *",
                              hint: "0.00",
                              prefixIcon: Icons.currency_rupee_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.done,
                              suffix: IconButton(
                                icon: const Icon(
                                  Icons.keyboard_hide_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                tooltip: "Dismiss Keyboard",
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  SystemChannels.textInput.invokeMethod(
                                    'TextInput.hide',
                                  );
                                },
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                                SystemChannels.textInput.invokeMethod(
                                  'TextInput.hide',
                                );
                                _addItem();
                              },
                            ),
                          ),
                        ],
                      ),

                      if (_itemError != null) ...[
                        AppSpacing.gapVs,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.danger.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.danger,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _itemError!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      AppSpacing.gapVm,

                      // Calculated Amount Preview Strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "ITEM TOTAL PREVIEW",
                                style: AppTypography.labelCaps.copyWith(
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(_currentPreviewAmount),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      AppSpacing.gapVm,

                      // Add Item Button
                      AppButton(
                        label: "ADD ITEM TO BILL",
                        icon: Icons.add_circle_rounded,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.medium,
                        isFullWidth: true,
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVl,

                // Added Items List Section
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AppSectionHeader(
                              title: "Line Items",
                              subtitle:
                                  "${widget.controller.totalItemsCount} item(s) in this draft",
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(60),
                              ),
                            ),
                            child: Text(
                              "${widget.controller.totalItemsCount} ${widget.controller.totalItemsCount == 1 ? 'ITEM' : 'ITEMS'}",
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

                      if (widget.controller.items.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 36,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No items added yet",
                                style: AppTypography.headingSmall.copyWith(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Add a line item using the form above or pick from quick suggestions.",
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.controller.items.length,
                          separatorBuilder: (context, _) => AppSpacing.gapVs,
                          itemBuilder: (context, index) {
                            final it = widget.controller.items[index];
                            return _buildItemCard(index, it);
                          },
                        ),
                    ],
                  ),
                ),

                AppSpacing.gapVl,

                // Bill Summary Card
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "SUBTOTAL (${widget.controller.totalItemsCount} ITEMS)",
                              style: AppTypography.labelCaps,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.format(
                              widget.controller.subtotal,
                            ),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "GRAND TOTAL",
                              style: AppTypography.headingSmall.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedCountText(
                            value: widget.controller.grandTotal,
                            isCurrency: true,
                            style: AppTypography.headingMedium.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVxl,

                // Step Navigation Controls
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: AppButton(
                        label: "BACK",
                        icon: Icons.arrow_back_rounded,
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.large,
                        onPressed: widget.onBack,
                      ),
                    ),
                    AppSpacing.gapHm,
                    Expanded(
                      flex: 6,
                      child: AppButton(
                        label: "CONTINUE TO REVIEW",
                        icon: Icons.arrow_forward_rounded,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                        onPressed: _handleContinue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(int index, WizardItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "${item.qty} × ₹${CurrencyFormatter.formatRaw(item.price)}",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(item.amount),
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showEditItemDialog(index),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => widget.controller.removeItem(index),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
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
}
