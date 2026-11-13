class IndianCurrencyFormatter {
  /// Formats amount into Indian currency string, e.g. 124780 -> "₹1,24,780"
  static String format(num amount, {bool showDecimals = false, bool showSymbol = true}) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formatted;
    if (showDecimals) {
      formatted = _formatIndianNumberWithDecimals(absAmount);
    } else {
      formatted = _formatIndianInteger(absAmount.round());
    }

    final symbol = showSymbol ? '₹' : '';
    final sign = isNegative ? '-' : '';
    return '$sign$symbol$formatted';
  }

  static String _formatIndianInteger(int number) {
    final str = number.toString();
    if (str.length <= 3) return str;

    // Last 3 digits
    final last3 = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);

    // Group the rest by 2 digits from right to left
    final buffer = StringBuffer();
    int count = 0;
    for (int i = rest.length - 1; i >= 0; i--) {
      buffer.write(rest[i]);
      count++;
      if (count == 2 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }

    final restFormatted = buffer.toString().split('').reversed.join('');
    return '$restFormatted,$last3';
  }

  static String _formatIndianNumberWithDecimals(num number) {
    final fixed = number.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = int.parse(parts[0]);
    final decimalPart = parts[1];
    return '${_formatIndianInteger(integerPart)}.$decimalPart';
  }
}
