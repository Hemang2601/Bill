import 'package:flutter/material.dart';
import 'core/core.dart';
import 'features/invoice/create/invoice_wizard_controller.dart';
import 'features/invoice/create/customer_details_step.dart';
import 'features/invoice/create/invoice_items_step.dart';
import 'features/invoice/create/invoice_review_step.dart';

/// Premium Multi-Step Invoice Creation Wizard for Shree Shakti Electric Service
/// Clean White Theme, high-contrast typography, and sticky bottom summary bar.
/// Step 1: Customer Details
/// Step 2: Items & Pricing
/// Step 3: Review & Generate Invoice PDF
class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  late final InvoiceWizardController _controller;
  int _lastStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = InvoiceWizardController();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<bool> _handleAbandonCheck() async {
    if (!_controller.hasUnsavedChanges) return true;

    final bool? confirm = await AppDialog.showDiscardChangesConfirmation(
      context: context,
      title: "Discard Bill Draft?",
      message:
          "Are you sure you want to discard this bill draft? All entered recipient details and items will be lost.",
    );
    return confirm == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_controller.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _handleAbandonCheck();
        if (shouldLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawer: const AppNavigationDrawer(currentRoute: '/create-bill'),
        appBar: AppHeader(
          title: "CREATE NEW BILL",
          subtitle: "SHREE SHAKTI ELECTRIC • WIZARD",
          showBackButton: true,
          onBack: () async {
            if (_controller.currentStep > 0) {
              _controller.previousStep();
            } else {
              final shouldLeave = await _handleAbandonCheck();
              if (shouldLeave && context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: StepProgressIndicator(
              currentStep: _controller.currentStep,
              onStepTapped: (stepIndex) {
                if (stepIndex == 0) {
                  _controller.goToStep(0);
                } else if (stepIndex == 1) {
                  _controller.goToStep(1);
                } else if (stepIndex == 2 && _controller.hasValidItems) {
                  _controller.goToStep(2);
                }
              },
            ),
          ),
        ),
        body: _buildCurrentStepView(),
        bottomNavigationBar: _buildStickyBottomSummaryBar(),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    final bool isForward = _controller.currentStep >= _lastStep;
    _lastStep = _controller.currentStep;

    Widget stepWidget;
    switch (_controller.currentStep) {
      case 0:
        stepWidget = CustomerDetailsStep(
          key: const ValueKey('step_customer'),
          controller: _controller,
          onContinue: () {
            _controller.goToStep(1);
          },
        );
        break;
      case 1:
        stepWidget = InvoiceItemsStep(
          key: const ValueKey('step_items'),
          controller: _controller,
          onBack: () {
            _controller.goToStep(0);
          },
          onContinue: () {
            _controller.goToStep(2);
          },
        );
        break;
      case 2:
        stepWidget = InvoiceReviewStep(
          key: const ValueKey('step_review'),
          controller: _controller,
          onBack: () {
            _controller.goToStep(1);
          },
          onEditCustomer: () {
            _controller.goToStep(0);
          },
          onEditItems: () {
            _controller.goToStep(1);
          },
          onComplete: () {
            Navigator.of(context).pop(true);
          },
        );
        break;
      default:
        stepWidget = const SizedBox(key: ValueKey('step_empty'));
    }

    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetTween =
            Tween<Offset>(
              begin: Offset(isForward ? 0.05 : -0.05, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(
          position: offsetTween,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: stepWidget,
    );
  }

  Widget _buildStickyBottomSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: AppShadows.barTop,
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "LIVE TOTAL (${_controller.totalItemsCount} ${_controller.totalItemsCount == 1 ? 'ITEM' : 'ITEMS'})",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 9.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          CurrencyFormatter.format(_controller.grandTotal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.currencyMedium.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                "Step ${_controller.currentStep + 1} of 3",
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
