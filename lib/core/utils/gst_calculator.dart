class GstCalculationResult {
  final double quantity;
  final double rate;
  final double taxableAmount;
  final double gstRate;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalTax;
  final double totalAmount;
  final bool isInterState;

  GstCalculationResult({
    required this.quantity,
    required this.rate,
    required this.taxableAmount,
    required this.gstRate,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalTax,
    required this.totalAmount,
    required this.isInterState,
  });
}

class GstCalculator {
  /// Calculate GST breakup for a single item line
  static GstCalculationResult calculateItem({
    required double quantity,
    required double rate,
    required double gstRate, // e.g. 18.0
    required bool gstIncludedInRate,
    required String businessStateCode, // e.g. "27"
    required String partyStateCode,    // e.g. "27" or "24"
  }) {
    final isInterState = businessStateCode.trim() != partyStateCode.trim();

    double taxableAmount;
    double totalTax;
    double totalAmount;

    if (gstIncludedInRate) {
      // Rate includes tax: Rate = TaxableRate * (1 + gstRate / 100)
      final taxableRate = rate / (1.0 + (gstRate / 100.0));
      taxableAmount = quantity * taxableRate;
      totalTax = quantity * rate - taxableAmount;
      totalAmount = quantity * rate;
    } else {
      // Rate is exclusive of tax: Total = TaxableAmount + Tax
      taxableAmount = quantity * rate;
      totalTax = taxableAmount * (gstRate / 100.0);
      totalAmount = taxableAmount + totalTax;
    }

    // Round to 2 decimal places for financial accuracy
    taxableAmount = (taxableAmount * 100).round() / 100;
    totalTax = (totalTax * 100).round() / 100;
    totalAmount = (totalAmount * 100).round() / 100;

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    if (isInterState) {
      igst = totalTax;
    } else {
      cgst = ((totalTax / 2.0) * 100).round() / 100;
      sgst = ((totalTax / 2.0) * 100).round() / 100;
      // Handle 1 paisa round off if odd
      if ((cgst + sgst) != totalTax) {
        cgst = totalTax - sgst;
      }
    }

    return GstCalculationResult(
      quantity: quantity,
      rate: rate,
      taxableAmount: taxableAmount,
      gstRate: gstRate,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
      totalTax: totalTax,
      totalAmount: totalAmount,
      isInterState: isInterState,
    );
  }

  /// Extracts 2-digit state code from 15-digit GSTIN (e.g. "27AAAAA0000A1Z5" -> "27")
  static String getStateCodeFromGstin(String gstin, {String defaultCode = "27"}) {
    final clean = gstin.trim();
    if (clean.length >= 2 && RegExp(r'^\d{2}').hasMatch(clean)) {
      return clean.substring(0, 2);
    }
    return defaultCode;
  }
}
