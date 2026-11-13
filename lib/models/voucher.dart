import 'voucher_item.dart';

class Voucher {
  final String id;
  final String voucherNumber;
  final String type; // sales, purchase, receipt, payment
  final DateTime date;
  final String partyId;
  final String partyName;
  final String partyGstin;
  final String partyStateCode;
  final List<VoucherItem> items;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double totalAmount;
  final String? notes;
  final String status; // confirmed, draft, cancelled
  final String? rawVoiceTranscript;
  bool isTallySynced;

  Voucher({
    required this.id,
    required this.voucherNumber,
    required this.type,
    required this.date,
    required this.partyId,
    required this.partyName,
    required this.partyGstin,
    required this.partyStateCode,
    required this.items,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmount,
    this.notes,
    this.status = 'confirmed',
    this.rawVoiceTranscript,
    this.isTallySynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucherNumber': voucherNumber,
      'type': type,
      'date': date.toIso8601String(),
      'partyId': partyId,
      'partyName': partyName,
      'partyGstin': partyGstin,
      'partyStateCode': partyStateCode,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'totalAmount': totalAmount,
      'notes': notes,
      'status': status,
      'rawVoiceTranscript': rawVoiceTranscript,
      'isTallySynced': isTallySynced,
    };
  }

  factory Voucher.fromMap(Map<String, dynamic> map) {
    return Voucher(
      id: map['id'] ?? '',
      voucherNumber: map['voucherNumber'] ?? '',
      type: map['type'] ?? 'sales',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      partyId: map['partyId'] ?? '',
      partyName: map['partyName'] ?? '',
      partyGstin: map['partyGstin'] ?? '',
      partyStateCode: map['partyStateCode'] ?? '27',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => VoucherItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      cgst: (map['cgst'] as num?)?.toDouble() ?? 0.0,
      sgst: (map['sgst'] as num?)?.toDouble() ?? 0.0,
      igst: (map['igst'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'],
      status: map['status'] ?? 'confirmed',
      rawVoiceTranscript: map['rawVoiceTranscript'],
      isTallySynced: map['isTallySynced'] ?? false,
    );
  }
}
