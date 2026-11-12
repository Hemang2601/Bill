import 'package:flutter/material.dart';
import 'core/core.dart';
import 'features/invoice/create/invoice_wizard_controller.dart';
import 'features/invoice/create/customer_details_step.dart';
import 'features/invoice/create/invoice_items_step.dart';
import 'features/invoice/create/invoice_review_step.dart';

/// Premium Multi-Step Invoice Creation Wizard for Shree Shakti Electric
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
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_controller.currentStep) {
      case 0:
        return CustomerDetailsStep(
          controller: _controller,
          onContinue: () {
            _controller.goToStep(1);
          },
        );
      case 1:
        return InvoiceItemsStep(
          controller: _controller,
          onBack: () {
            _controller.goToStep(0);
          },
          onContinue: () {
            _controller.goToStep(2);
          },
        );
      case 2:
        return InvoiceReviewStep(
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
      default:
        return const SizedBox();
    }
  }
}
