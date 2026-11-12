import 'package:shared_preferences/shared_preferences.dart';

/// Manages Paid / Pending status persistence for Invoices without altering SQLite schema
class InvoiceStatusService {
  static const String _paidInvoicesKey = 'paid_invoice_ids_v1';

  /// Returns the set of invoice IDs that have been marked as PAID
  static Future<Set<int>> getPaidInvoiceIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_paidInvoicesKey) ?? [];
    return list.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  /// Checks if a specific invoice is marked as PAID
  static Future<bool> isPaid(int invoiceId) async {
    final set = await getPaidInvoiceIds();
    return set.contains(invoiceId);
  }

  /// Toggles the paid status of an invoice
  static Future<bool> togglePaid(int invoiceId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getPaidInvoiceIds();
    bool isNowPaid;
    if (set.contains(invoiceId)) {
      set.remove(invoiceId);
      isNowPaid = false;
    } else {
      set.add(invoiceId);
      isNowPaid = true;
    }
    await prefs.setStringList(
      _paidInvoicesKey,
      set.map((e) => e.toString()).toList(),
    );
    return isNowPaid;
  }

  /// Sets the paid status explicitly
  static Future<void> setPaid(int invoiceId, bool paid) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getPaidInvoiceIds();
    if (paid) {
      set.add(invoiceId);
    } else {
      set.remove(invoiceId);
    }
    await prefs.setStringList(
      _paidInvoicesKey,
      set.map((e) => e.toString()).toList(),
    );
  }
}
