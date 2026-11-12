import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/core.dart';
import 'invoice_wizard_controller.dart';

/// Step 1: Customer Details of the Invoice Creation Wizard
class CustomerDetailsStep extends StatefulWidget {
  final InvoiceWizardController controller;
  final VoidCallback onContinue;

  const CustomerDetailsStep({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  @override
  State<CustomerDetailsStep> createState() => _CustomerDetailsStepState();
}

class _CustomerDetailsStepState extends State<CustomerDetailsStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.customerName,
    );
    _phoneController = TextEditingController(
      text: widget.controller.phoneNumber,
    );

    _nameController.addListener(_syncData);
    _phoneController.addListener(_syncData);
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncData);
    _phoneController.removeListener(_syncData);
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _syncData() {
    widget.controller.setCustomerInfo(
      name: _nameController.text,
      phone: _phoneController.text,
    );
  }

  void _validateAndContinue() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    final phone = _phoneController.text.trim();

    if (phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
      if (cleanPhone.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
        setState(() {
          _phoneError = "Please enter a valid 10-digit mobile number";
        });
        return;
      }
    }

    setState(() => _phoneError = null);
    widget.onContinue();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      widget.controller.setDate(DateFormat('dd MMM yyyy').format(picked));
    }
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
            constraints: const BoxConstraints(maxWidth: 720),
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
                          Icons.person_outline_rounded,
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
                              "STEP 1: CUSTOMER DETAILS",
                              style: AppTypography.labelCaps.copyWith(
                                fontSize: 10.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Enter Buyer or Business Information",
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

                // Customer Inputs Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: "Client Details",
                        subtitle: "Buyer and firm contact information",
                      ),
                      AppSpacing.gapVl,

                      // Customer Name Field
                      AppTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        label: "Customer / Firm Name",
                        hint:
                            "e.g. PATEL ELECTRICALS (defaults to CASH CUSTOMER)",
                        prefixIcon: Icons.business_rounded,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _phoneFocus.requestFocus();
                        },
                      ),

                      AppSpacing.gapVl,

                      // Mobile Number Field
                      AppTextField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        label: "Mobile Number (Optional)",
                        hint: "e.g. 9876543210 (10 digits)",
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        errorText: _phoneError,
                        onSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                          SystemChannels.textInput.invokeMethod(
                            'TextInput.hide',
                          );
                        },
                      ),

                      AppSpacing.gapVs,
                      Text(
                        "Leave Customer Name blank to automatically bill to \"CASH CUSTOMER\".",
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVl,

                // Invoice Metadata Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: "Invoice Information",
                        subtitle: "Sequential number and billing date",
                      ),
                      AppSpacing.gapVm,
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "INVOICE NUMBER",
                                    style: AppTypography.labelCaps.copyWith(
                                      fontSize: 9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.controller.billNumber,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapHs,
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "INVOICE DATE",
                                            style: AppTypography.labelCaps
                                                .copyWith(fontSize: 9),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.edit_calendar_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.controller.date,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapVxxl,

                // Continue Button
                AppButton(
                  label: "CONTINUE TO ITEMS & PRICING",
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  isFullWidth: true,
                  onPressed: _validateAndContinue,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
