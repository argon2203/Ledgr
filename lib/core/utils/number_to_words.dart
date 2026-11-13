class NumberToWords {
  static const List<String> _units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convert(num amount) {
    if (amount == 0) return 'Zero Rupees Only';

    final rounded = amount.round();
    final words = _convertIndian(rounded);
    return '$words Rupees Only';
  }

  static String _convertIndian(int n) {
    if (n < 0) return 'Minus ${_convertIndian(-n)}';
    if (n == 0) return '';

    if (n < 20) return _units[n];
    if (n < 100) {
      return '${_tens[n ~/ 10]} ${_units[n % 10]}'.trim();
    }
    if (n < 1000) {
      final rem = n % 100;
      final remStr = rem != 0 ? ' and ${_convertIndian(rem)}' : '';
      return '${_units[n ~/ 100]} Hundred$remStr';
    }
    if (n < 100000) {
      final rem = n % 1000;
      final remStr = rem != 0 ? ' ${_convertIndian(rem)}' : '';
      return '${_convertIndian(n ~/ 1000)} Thousand$remStr';
    }
    if (n < 10000000) {
      final rem = n % 100000;
      final remStr = rem != 0 ? ' ${_convertIndian(rem)}' : '';
      return '${_convertIndian(n ~/ 100000)} Lakh$remStr';
    }

    final rem = n % 10000000;
    final remStr = rem != 0 ? ' ${_convertIndian(rem)}' : '';
    return '${_convertIndian(n ~/ 10000000)} Crore$remStr';
  }
}
