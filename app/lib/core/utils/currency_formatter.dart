import 'package:intl/intl.dart';

/// Utility class for formatting currency values
/// Primary format: Brazilian Real (BRL)
class CurrencyFormatter {
  static final _brlFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  static final _usdFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Formats a value to BRL currency (R$ 1.234,56)
  static String formatBRL(double value) {
    return _brlFormat.format(value);
  }

  /// Formats a value to USD currency (\$1,234.56)
  static String formatUSD(double value) {
    return _usdFormat.format(value);
  }

  /// Formats a value to BRL without the currency symbol (1.234,56)
  static String formatBRLWithoutSymbol(double value) {
    return NumberFormat('#,##0.00', 'pt_BR').format(value);
  }

  /// Parses a BRL formatted string to double
  static double? parseBRL(String value) {
    try {
      // Remove currency symbol and spaces
      String cleaned = value.replaceAll('R\$', '').trim();
      // Replace thousand separator and decimal separator
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Formats value with sign (+ or -)
  static String formatWithSign(double value) {
    final formatted = formatBRL(value.abs());
    return value >= 0 ? '+$formatted' : '-$formatted';
  }

  /// Formats value for compact display (1.2K, 1.5M, etc.)
  static String formatCompact(double value) {
    return NumberFormat.compact(locale: 'pt_BR').format(value);
  }
}
