class Item {
  final String id;
  final String name;
  final String hsn;
  final double gstRate; // e.g. 18.0
  final double defaultRate;
  final String unit; // roll, bag, piece, meter
  double stock;
  final double lowStockThreshold;

  Item({
    required this.id,
    required this.name,
    required this.hsn,
    required this.gstRate,
    required this.defaultRate,
    required this.unit,
    required this.stock,
    this.lowStockThreshold = 20.0,
  });

  bool get isLowStock => stock <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hsn': hsn,
      'gstRate': gstRate,
      'defaultRate': defaultRate,
      'unit': unit,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      hsn: map['hsn'] ?? '',
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 18.0,
      defaultRate: (map['defaultRate'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'piece',
      stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toDouble() ?? 20.0,
    );
  }

  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    final itemName = name.toLowerCase();
    return itemName.contains(clean) || clean.contains(itemName);
  }
}
