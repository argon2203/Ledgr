import '../../models/voucher.dart';

abstract class ZohoConnector {
  Future<Map<String, dynamic>> convertVoucherToZohoPayload(Voucher voucher);
  Future<bool> sendVoucherToZoho(Voucher voucher);
  String get connectorName;
}

class MockZohoConnector implements ZohoConnector {
  @override
  String get connectorName => 'Zoho Books API Connector (Mock)';

  @override
  Future<Map<String, dynamic>> convertVoucherToZohoPayload(Voucher voucher) async {
    return {
      'customer_id': voucher.partyId,
      'customer_name': voucher.partyName,
      'invoice_number': voucher.voucherNumber,
      'date': voucher.date.toIso8601String().substring(0, 10),
      'line_items': voucher.items.map((item) => {
        'item_id': item.itemId,
        'name': item.itemName,
        'rate': item.rate,
        'quantity': item.quantity,
        'tax_id': item.gstRate.toString(),
      }).toList(),
      'sub_total': voucher.subtotal,
      'tax_total': voucher.cgst + voucher.sgst + voucher.igst,
      'total': voucher.totalAmount,
    };
  }

  @override
  Future<bool> sendVoucherToZoho(Voucher voucher) async {
    // In production, this issues an OAuth REST call to Zoho Books API
    return true;
  }
}
