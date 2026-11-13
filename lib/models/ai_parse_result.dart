class AIParseItem {
  final String nameHeard;
  final String? matchedItemId;
  final double quantity;
  final String unit;
  final double rate;

  AIParseItem({
    required this.nameHeard,
    this.matchedItemId,
    required this.quantity,
    required this.unit,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name_heard': nameHeard,
      'matched_item_id': matchedItemId,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
    };
  }

  factory AIParseItem.fromJson(Map<String, dynamic> json) {
    return AIParseItem(
      nameHeard: json['name_heard']?.toString() ?? '',
      matchedItemId: json['matched_item_id']?.toString(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'pcs',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AIParseResult {
  final String voucherType; // sales, purchase, receipt, payment
  final String partyNameHeard;
  final String? matchedPartyId;
  final List<AIParseItem> items;
  final bool gstIncludedInRate;
  final String notes;
  final double confidence;
  final List<String> questionsForUser;
  final String? rawTranscript;

  AIParseResult({
    required this.voucherType,
    required this.partyNameHeard,
    this.matchedPartyId,
    required this.items,
    required this.gstIncludedInRate,
    required this.notes,
    required this.confidence,
    required this.questionsForUser,
    this.rawTranscript,
  });

  Map<String, dynamic> toJson() {
    return {
      'voucher_type': voucherType,
      'party_name_heard': partyNameHeard,
      'matched_party_id': matchedPartyId,
      'items': items.map((i) => i.toJson()).toList(),
      'gst_included_in_rate': gstIncludedInRate,
      'notes': notes,
      'confidence': confidence,
      'questions_for_user': questionsForUser,
      'raw_transcript': rawTranscript,
    };
  }

  factory AIParseResult.fromJson(Map<String, dynamic> json) {
    return AIParseResult(
      voucherType: json['voucher_type']?.toString().toLowerCase() ?? 'sales',
      partyNameHeard: json['party_name_heard']?.toString() ?? '',
      matchedPartyId: json['matched_party_id']?.toString(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => AIParseItem.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      gstIncludedInRate: json['gst_included_in_rate'] == true,
      notes: json['notes']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      questionsForUser: (json['questions_for_user'] as List<dynamic>? ?? [])
          .map((q) => q.toString())
          .toList(),
      rawTranscript: json['raw_transcript']?.toString(),
    );
  }
}
