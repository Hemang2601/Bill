import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database_helper.dart';

/// Item data model for the invoice creation & editing wizard
class WizardItem {
  String name;
  double qty;
  double price;

  WizardItem({required this.name, required this.qty, required this.price});

  double get amount => qty * price;

  Map<String, dynamic> toMap() => {
    'name': name,
    'qty': qty,
    'price': price,
    'amount': amount,
  };
}

/// Central controller managing the state and steps of the Invoice Wizard
/// Supports both new bill creation and existing bill modification.
class InvoiceWizardController extends ChangeNotifier {
  final bool isEdit;
  final int? existingInvoiceId;
  final String? existingPdfPath;

  int _currentStep = 0;
  String _billNumber = "";
  String _date = "";
  String _customerName = "";
  String _phoneNumber = "";
  final List<WizardItem> _items = [];
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  bool _isLoadingItems = false;

  InvoiceWizardController({
    this.isEdit = false,
    this.existingInvoiceId,
    this.existingPdfPath,
    String? initialBillNumber,
    String? initialDate,
    String? initialCustomerName,
    String? initialPhoneNumber,
    List<WizardItem>? initialItems,
  }) {
    if (isEdit) {
      _billNumber = initialBillNumber ?? "";
      _date = initialDate ?? DateFormat('dd MMM yyyy').format(DateTime.now());
      _customerName = initialCustomerName ?? "";
      _phoneNumber = initialPhoneNumber ?? "";
      if (initialItems != null && initialItems.isNotEmpty) {
        _items.addAll(initialItems);
      } else if (existingInvoiceId != null) {
        loadExistingItems(existingInvoiceId!);
      }
    } else {
      _date = DateFormat('dd MMM yyyy').format(DateTime.now());
      _billNumber =
          "SE-${DateFormat('yyMM').format(DateTime.now())}-${(100 + (DateTime.now().second % 890 + 1)).toString()}";
      _initSequentialBillNumber();
    }
  }

  // Getters
  int get currentStep => _currentStep;
  String get billNumber => _billNumber;
  String get date => _date;
  String get customerName => _customerName;
  String get phoneNumber => _phoneNumber;
  List<WizardItem> get items => List.unmodifiable(_items);
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isLoadingItems => _isLoadingItems;

  double get subtotal => _items.fold(0.0, (sum, it) => sum + it.amount);
  double get grandTotal => subtotal;
  int get totalItemsCount => _items.length;
  bool get hasValidItems => _items.isNotEmpty;

  String get finalCustomerName => _customerName.trim().isEmpty
      ? "CASH CUSTOMER"
      : _customerName.trim().toUpperCase();

  String get finalPhoneNumber =>
      _phoneNumber.trim().isEmpty ? "N/A" : _phoneNumber.trim();

  Future<void> _initSequentialBillNumber() async {
    try {
      final nextNum = await DatabaseHelper.instance.generateNextBillNumber();
      _billNumber = nextNum;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadExistingItems(int invoiceId) async {
    _isLoadingItems = true;
    notifyListeners();
    try {
      final fetched = await DatabaseHelper.instance.getInvoiceItems(invoiceId);
      _items.clear();
      for (final item in fetched) {
        _items.add(
          WizardItem(
            name: item['itemName']?.toString() ?? '',
            qty: (item['qty'] as num?)?.toDouble() ?? 1.0,
            price: (item['price'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }
      if (_items.isEmpty) {
        // Fallback default item for easy editing
        _items.add(WizardItem(name: "Switch 6A", qty: 1.0, price: 45.0));
      }
    } catch (_) {
      if (_items.isEmpty) {
        _items.add(WizardItem(name: "Switch 6A", qty: 1.0, price: 45.0));
      }
    }
    _isLoadingItems = false;
    notifyListeners();
  }

  void setDate(String newDate) {
    _date = newDate;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void setCustomerInfo({required String name, required String phone}) {
    _customerName = name;
    _phoneNumber = phone;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  bool addItem({
    required String name,
    required double qty,
    required double price,
  }) {
    if (name.trim().isEmpty || qty <= 0 || price < 0) return false;

    _items.add(WizardItem(name: name.trim(), qty: qty, price: price));
    _hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  bool editItem(
    int index, {
    required String name,
    required double qty,
    required double price,
  }) {
    if (index < 0 || index >= _items.length) return false;
    if (name.trim().isEmpty || qty <= 0 || price < 0) return false;

    _items[index] = WizardItem(name: name.trim(), qty: qty, price: price);
    _hasUnsavedChanges = true;
    notifyListeners();
    return true;
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void markClean() {
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> toDbItemsList([int? invoiceId]) {
    final effectiveId = invoiceId ?? existingInvoiceId;
    return _items.map((it) {
      final map = <String, dynamic>{
        'itemName': it.name,
        'qty': it.qty,
        'price': it.price,
      };
      if (effectiveId != null) {
        map['invoiceId'] = effectiveId;
      }
      return map;
    }).toList();
  }

  List<Map<String, dynamic>> toPdfItemsList() {
    return _items
        .map(
          (it) => {
            'name': it.name,
            'qty': it.qty,
            'price': it.price,
            'amount': it.amount,
          },
        )
        .toList();
  }
}
