import 'package:intl/intl.dart';
import '../../models/voucher.dart';

abstract class TallyConnector {
  Future<String> exportVoucherToTallyXml(Voucher voucher);
  Future<bool> sendVoucherToTally(Voucher voucher);
  String get connectorName;
}

/// Mock implementation that generates valid Tally XML and logs the transmission.
class MockTallyConnector implements TallyConnector {
  final List<String> exportHistory = [];

  @override
  String get connectorName => 'TallyPrime XML Connector (Mock)';

  @override
  Future<String> exportVoucherToTallyXml(Voucher voucher) async {
    final dateFormat = DateFormat('yyyyMMdd');
    final tallyDate = dateFormat.format(voucher.date);
    final voucherType = voucher.type.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln('<ENVELOPE>');
    buffer.writeln('  <HEADER>');
    buffer.writeln('    <TALLYREQUEST>Import Data</TALLYREQUEST>');
    buffer.writeln('  </HEADER>');
    buffer.writeln('  <BODY>');
    buffer.writeln('    <IMPORTDATA>');
    buffer.writeln('      <REQUESTDESC>');
    buffer.writeln('        <REPORTNAME>Vouchers</REPORTNAME>');
    buffer.writeln('      </REQUESTDESC>');
    buffer.writeln('      <REQUESTDATA>');
    buffer.writeln('        <TALLYMESSAGE xmlns:UDF="TallyUDF">');
    buffer.writeln('          <VOUCHER VCHTYPE="$voucherType" ACTION="Create">');
    buffer.writeln('            <DATE>$tallyDate</DATE>');
    buffer.writeln('            <VOUCHERTYPENAME>$voucherType</VOUCHERTYPENAME>');
    buffer.writeln('            <VOUCHERNUMBER>${voucher.voucherNumber}</VOUCHERNUMBER>');
    buffer.writeln('            <PARTYLEDGERNAME>${voucher.partyName}</PARTYLEDGERNAME>');
    buffer.writeln('            <NARRATION>${voucher.notes ?? "Generated via Ledgr AI"}</NARRATION>');
    buffer.writeln('            <AMOUNT>-${voucher.totalAmount.toStringAsFixed(2)}</AMOUNT>');
    
    // Ledger entries for Party
    buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
    buffer.writeln('              <LEDGERNAME>${voucher.partyName}</LEDGERNAME>');
    buffer.writeln('              <ISDEEMEDPOSITIVE>Yes</ISDEEMEDPOSITIVE>');
    buffer.writeln('              <AMOUNT>-${voucher.totalAmount.toStringAsFixed(2)}</AMOUNT>');
    buffer.writeln('            </ALLLEDGERENTRIES.LIST>');

    // Items line entries
    for (final item in voucher.items) {
      buffer.writeln('            <ALLINVENTORYENTRIES.LIST>');
      buffer.writeln('              <STOCKITEMNAME>${item.itemName}</STOCKITEMNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <RATE>${item.rate.toStringAsFixed(2)}/${item.unit}</RATE>');
      buffer.writeln('              <ACTUALQTY>${item.quantity} ${item.unit}</ACTUALQTY>');
      buffer.writeln('              <BILLEDQTY>${item.quantity} ${item.unit}</BILLEDQTY>');
      buffer.writeln('              <AMOUNT>${item.taxableAmount.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLINVENTORYENTRIES.LIST>');
    }

    // Taxes
    if (voucher.cgst > 0) {
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>Output CGST</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>${voucher.cgst.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');
    }
    if (voucher.sgst > 0) {
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>Output SGST</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>${voucher.sgst.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');
    }
    if (voucher.igst > 0) {
      buffer.writeln('            <ALLLEDGERENTRIES.LIST>');
      buffer.writeln('              <LEDGERNAME>Output IGST</LEDGERNAME>');
      buffer.writeln('              <ISDEEMEDPOSITIVE>No</ISDEEMEDPOSITIVE>');
      buffer.writeln('              <AMOUNT>${voucher.igst.toStringAsFixed(2)}</AMOUNT>');
      buffer.writeln('            </ALLLEDGERENTRIES.LIST>');
    }

    buffer.writeln('          </VOUCHER>');
    buffer.writeln('        </TALLYMESSAGE>');
    buffer.writeln('      </REQUESTDATA>');
    buffer.writeln('    </IMPORTDATA>');
    buffer.writeln('  </BODY>');
    buffer.writeln('</ENVELOPE>');

    final xml = buffer.toString();
    exportHistory.add('${voucher.voucherNumber} at ${DateTime.now().toIso8601String()}');
    return xml;
  }

  @override
  Future<bool> sendVoucherToTally(Voucher voucher) async {
    await exportVoucherToTallyXml(voucher);
    // Log simulation
    // In production, this posts to http://localhost:9000 or Tally bridge agent
    return true;
  }
}
