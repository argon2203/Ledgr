import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/voucher.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/number_to_words.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoicePdf({
    required Voucher voucher,
    required String businessName,
    required String businessGstin,
    required String businessAddress,
    required String businessPhone,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MM-yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          final isInterState = voucher.igst > 0;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // HEADER
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('0F5132'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          businessName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          businessAddress,
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                        pw.Text(
                          'GSTIN: $businessGstin  |  Phone: $businessPhone',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Original for Recipient',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // INVOICE METADATA & BILLED TO
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: Billed To
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BILLED TO:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            voucher.partyName,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.Text(
                            'GSTIN: ${voucher.partyGstin.isNotEmpty ? voucher.partyGstin : "URP (Unregistered)"}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            'State Code: ${voucher.partyStateCode}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    // Right: Invoice No & Date
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildMetaRow('Invoice No:', voucher.voucherNumber),
                          _buildMetaRow('Date:', dateFormat.format(voucher.date)),
                          _buildMetaRow('Place of Supply:', voucher.partyStateCode),
                          _buildMetaRow('Reverse Charge:', 'No'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ITEMS TABLE
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // Sr
                  1: const pw.FlexColumnWidth(4.0), // Description
                  2: const pw.FlexColumnWidth(1.4), // HSN
                  3: const pw.FlexColumnWidth(1.2), // Qty
                  4: const pw.FlexColumnWidth(1.4), // Rate
                  5: const pw.FlexColumnWidth(1.8), // Taxable
                  6: const pw.FlexColumnWidth(1.0), // GST %
                  7: const pw.FlexColumnWidth(2.0), // Total
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
                    children: [
                      _cell('#', isHeader: true, align: pw.TextAlign.center),
                      _cell('Item Description', isHeader: true),
                      _cell('HSN', isHeader: true, align: pw.TextAlign.center),
                      _cell('Qty', isHeader: true, align: pw.TextAlign.center),
                      _cell('Rate (Rs.)', isHeader: true, align: pw.TextAlign.right),
                      _cell('Taxable (Rs.)', isHeader: true, align: pw.TextAlign.right),
                      _cell('GST %', isHeader: true, align: pw.TextAlign.center),
                      _cell('Total (Rs.)', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Items
                  ...voucher.items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        _cell('$index', align: pw.TextAlign.center),
                        _cell(item.itemName),
                        _cell(item.hsn, align: pw.TextAlign.center),
                        _cell('${item.quantity} ${item.unit}', align: pw.TextAlign.center),
                        _cell(item.rate.toStringAsFixed(2), align: pw.TextAlign.right),
                        _cell(item.taxableAmount.toStringAsFixed(2), align: pw.TextAlign.right),
                        _cell('${item.gstRate.toStringAsFixed(0)}%', align: pw.TextAlign.center),
                        _cell(item.total.toStringAsFixed(2), align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 10),

              // TOTALS & TAX BREAKUP
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Amount in words on left
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Amount Chargeable (in words):',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            NumberToWords.convert(voucher.totalAmount),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('0F5132'),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Terms & Conditions:\n1. Goods once sold will not be taken back.\n2. Payment within 15 days.',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  // Tax breakup table on right
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        children: [
                          _summaryRow('Taxable Amount:', 'Rs. ${IndianCurrencyFormatter.format(voucher.subtotal, showSymbol: false)}'),
                          if (!isInterState) ...[
                            _summaryRow('CGST:', 'Rs. ${IndianCurrencyFormatter.format(voucher.cgst, showSymbol: false)}'),
                            _summaryRow('SGST:', 'Rs. ${IndianCurrencyFormatter.format(voucher.sgst, showSymbol: false)}'),
                          ] else ...[
                            _summaryRow('IGST:', 'Rs. ${IndianCurrencyFormatter.format(voucher.igst, showSymbol: false)}'),
                          ],
                          pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                          _summaryRow(
                            'Total Invoice Value:',
                            'Rs. ${IndianCurrencyFormatter.format(voucher.totalAmount, showSymbol: false)}',
                            isBold: true,
                            fontSize: 11,
                            textColor: PdfColor.fromHex('0F5132'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // SIGNATURE BLOCK
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'This is a computer generated invoice.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'For $businessName',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 35),
                      pw.Text(
                        'Authorised Signatory',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey900,
        ),
      ),
    );
  }

  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> shareInvoice({
    required Voucher voucher,
    required String businessName,
    required String businessGstin,
    required String businessAddress,
    required String businessPhone,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      voucher: voucher,
      businessName: businessName,
      businessGstin: businessGstin,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${voucher.voucherNumber}_${voucher.partyName.replaceAll(" ", "_")}.pdf',
    );
  }
}
