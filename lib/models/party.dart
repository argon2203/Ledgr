class Party {
  final String id;
  final String name;
  final List<String> nicknames;
  final String gstin;
  final String stateCode;
  final String phone;
  final String address;
  double balance; // positive = to collect, negative = payable
  final String type; // customer, supplier, both

  Party({
    required this.id,
    required this.name,
    required this.nicknames,
    required this.gstin,
    required this.stateCode,
    required this.phone,
    required this.address,
    required this.balance,
    this.type = 'customer',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nicknames': nicknames,
      'gstin': gstin,
      'stateCode': stateCode,
      'phone': phone,
      'address': address,
      'balance': balance,
      'type': type,
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      nicknames: List<String>.from(map['nicknames'] ?? []),
      gstin: map['gstin'] ?? '',
      stateCode: map['stateCode'] ?? '27',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'customer',
    );
  }

  /// Checks if spoken or typed name matches this party's formal name or nicknames
  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    if (name.toLowerCase().contains(clean) || clean.contains(name.toLowerCase())) {
      return true;
    }
    for (final nick in nicknames) {
      if (nick.toLowerCase().contains(clean) || clean.contains(nick.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
