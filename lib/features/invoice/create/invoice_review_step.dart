import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../database_helper.dart';
import '../../../services/invoice_pdf_service.dart';
import 'invoice_wizard_controller.dart';

/// Step 3: Review & Generate Invoice of the Creation Wizard
class InvoiceReviewStep extends StatefulWidget {
  final InvoiceWizardController controller;
  final VoidCallback onBack;
  final VoidCallback onEditCustomer;
  final VoidCallback onEditItems;
  final VoidCallback onComplete;

  const InvoiceReviewStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onEditCustomer,
    required this.onEditItems,
    required this.onComplete,
  });

  @override
  State<InvoiceReviewStep> createState() => _InvoiceReviewStepState();
}

class _InvoiceReviewStepState extends State<InvoiceReviewStep> {
  bool _isProcessing = false;

  Future<void> _handleSaveAndGeneratePdf() async {
    if (_isProcessing) return;

    if (!widget.controller.hasValidItems) {
      AppNotification.showWarning(
        context,
        "Cannot save an invoice without line items",
      );
      return;
    }

    setState(() => _isProcessing = true);
    widget.controller.setSaving(true);

    try {
      // 1. Generate PDF document bytes first (ensures PDF compiles cleanly before touching DB)
      final pdfBytes = await InvoicePdfService.generateInvoicePdf(
        billNumber: widget.controller.billNumber,
        customerName: widget.controller.finalCustomerName,
        phoneNumber: widget.controller.finalPhoneNumber,
        date: widget.controller.date,
        items: widget.controller.toPdfItemsList(),
        totalAmount: widget.controller.grandTotal,
      );

      // 2. Save PDF to local device storage in Shakti Electric folder
      final File pdfFile = await InvoicePdfService.savePdfToFile(
        billNumber: widget.controller.billNumber,
        bytes: pdfBytes,
      );

      // 3. Prepare Invoice Record for SQLite with confirmed pdfPath
      final invoiceData = {
        'billNumber': widget.controller.billNumber,
        'customerName': widget.controller.finalCustomerName,
        'phoneNumber': widget.controller.finalPhoneNumber,
        'date': widget.controller.date,
        'totalAmount': widget.controller.grandTotal,
        'pdfPath': pdfFile.path,
      };

      final itemsData = widget.controller.toDbItemsList();

      // 4. Insert invoice and items atomically into SQLite
      await DatabaseHelper.instance.saveCompleteInvoice(invoiceData, itemsData);

      widget.controller.markClean();
      widget.controller.setSaving(false);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 6. Show Success Dialog with Share & Print Actions
      await AppDialog.showInvoiceSuccessDialog(
        context: context,
        billNumber: widget.controller.billNumber,
        totalAmount: widget.controller.grandTotal,
        pdfFile: pdfFile,
        pdfBytes: pdfBytes,
        isNewInvoice: true,
        onFinish: () {
          Navigator.of(context).pop(); // Dismiss success dialog
          widget.onComplete(); // Exit wizard
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      widget.controller.setSaving(false);
      AppNotification.showError(context, "Failed to generate invoice: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return SingleChildScrollView(
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
                        Icons.check_circle_outline_rounded,
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
                            "STEP 3: REVIEW & FINALIZE",
                            style: AppTypography.labelCaps.copyWith(
                              fontSize: 10.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Review Bill Details Before Generating PDF",
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

              // 1. Customer & Invoice Info Summary Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: AppSectionHeader(
                            title: "Invoice & Recipient",
                            subtitle: "Buyer information & metadata",
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text(
                            "Edit",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: widget.onEditCustomer,
                        ),
                      ],
                    ),
                    AppSpacing.gapVm,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
                            "Customer Name",
                            ctrl.finalCustomerName,
                            isBold: true,
                          ),
                          const Divider(height: 16),
                          _summaryRow("Mobile Number", ctrl.finalPhoneNumber),
                          const Divider(height: 16),
                          _summaryRow(
                            "Invoice Number",
                            ctrl.billNumber,
                            isHighlight: true,
                          ),
                          const Divider(height: 16),
                          _summaryRow("Invoice Date", ctrl.date),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapVl,

              // 2. Line Items Breakdown Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppSectionHeader(
                            title: "Line Items Breakdown",
                            subtitle:
                                "${ctrl.totalItemsCount} item(s) to be billed",
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text(
                            "Edit",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: widget.onEditItems,
                        ),
                      ],
                    ),
                    AppSpacing.gapVm,
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.items.length,
                        separatorBuilder: (context, _) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = ctrl.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "${index + 1}.",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        "${item.qty} × ₹${CurrencyFormatter.formatRaw(item.price)}",
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.amount),
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapVl,

              // 3. Final Total & Amount in Words Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("TOTAL ITEMS", style: AppTypography.labelCaps),
                        Text(
                          "${ctrl.totalItemsCount}",
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVs,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("SUBTOTAL", style: AppTypography.labelCaps),
                        Text(
                          CurrencyFormatter.format(ctrl.subtotal),
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "GRAND TOTAL",
                          style: AppTypography.headingSmall.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        AnimatedCountText(
                          value: ctrl.grandTotal,
                          isCurrency: true,
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.spellcheck_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              IndianAmountToWords.convert(ctrl.grandTotal),
                              style: AppTypography.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.gapVxxl,

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: AppButton(
                      label: "BACK TO ITEMS",
                      icon: Icons.arrow_back_rounded,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.large,
                      onPressed: _isProcessing ? null : widget.onBack,
                    ),
                  ),
                  AppSpacing.gapHm,
                  Expanded(
                    flex: 6,
                    child: AppButton(
                      label: "SAVE & GENERATE PDF",
                      icon: Icons.picture_as_pdf_rounded,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isLoading: _isProcessing,
                      onPressed: _isProcessing
                          ? null
                          : _handleSaveAndGeneratePdf,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: isBold || isHighlight
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
