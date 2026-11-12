import 'package:intl/intl.dart';

/// Centralized Indian Rupee (₹) Currency and Number Formatter
abstract class CurrencyFormatter {
  static final NumberFormat _formatterWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _formatterCompact = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Formats amount in Indian Rupees: e.g. "₹12,450.00" or "₹12,450"
  static String format(num amount, {bool showDecimals = true}) {
    if (showDecimals) {
      return _formatterWithDecimals.format(amount).replaceAll('₹', '₹ ');
    }
    return _formatterCompact.format(amount).replaceAll('₹', '₹ ');
  }

  /// Formats numbers without currency symbol: e.g. "12,450.00"
  static String formatRaw(num amount, {bool showDecimals = true}) {
    final fmt = NumberFormat('#,##,##0.${showDecimals ? '00' : ''}', 'en_IN');
    return fmt.format(amount);
  }
}
