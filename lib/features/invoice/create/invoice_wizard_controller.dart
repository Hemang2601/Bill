import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../database_helper.dart';

/// Item data model for the invoice creation wizard
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

/// Central controller managing the state and steps of the Invoice Creation Wizard
class InvoiceWizardController extends ChangeNotifier {
  int _currentStep = 0;
  String _billNumber = "";
  String _date = "";
  String _customerName = "";
  String _phoneNumber = "";
  final List<WizardItem> _items = [];
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  InvoiceWizardController() {
    _date = DateFormat('dd MMM yyyy').format(DateTime.now());
    _billNumber =
        "SE-${DateFormat('yyMM').format(DateTime.now())}-${(100 + (DateTime.now().second % 890 + 1)).toString()}";
    _initSequentialBillNumber();
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

  List<Map<String, dynamic>> toDbItemsList() {
    return _items
        .map((it) => {'itemName': it.name, 'qty': it.qty, 'price': it.price})
        .toList();
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
