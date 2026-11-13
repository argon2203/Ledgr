class VoucherItem {
  final String itemId;
  final String itemName;
  final String hsn;
  double quantity;
  final String unit;
  double rate;
  final double gstRate;
  double taxableAmount;
  double cgst;
  double sgst;
  double igst;
  double total;

  VoucherItem({
    required this.itemId,
    required this.itemName,
    required this.hsn,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.gstRate,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'hsn': hsn,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'gstRate': gstRate,
      'taxableAmount': taxableAmount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'total': total,
    };
  }

  factory VoucherItem.fromMap(Map<String, dynamic> map) {
    return VoucherItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      hsn: map['hsn'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'pcs',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (map['taxableAmount'] as num?)?.toDouble() ?? 0.0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      igst: (map['igst'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
