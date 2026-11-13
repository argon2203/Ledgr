import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/number_to_words.dart';
import '../../models/voucher.dart';
import '../../providers/settings_provider.dart';
import '../../services/pdf_invoice_service.dart';

class VoucherDetailScreen extends StatelessWidget {
  final Voucher voucher;

  const VoucherDetailScreen({super.key, required this.voucher});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('${voucher.voucherNumber} Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppStrings.shareOnWhatsApp,
            onPressed: () async {
              await PdfInvoiceService.shareInvoice(
                voucher: voucher,
                businessName: settings.businessName,
                businessGstin: settings.businessGstin,
                businessAddress: settings.businessAddress,
                businessPhone: settings.businessPhone,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Status & Type Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          voucher.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        voucher.partyName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        dateFormat.format(voucher.date),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    IndianCurrencyFormatter.format(voucher.totalAmount),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Party & GSTIN Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.partyDetails,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    _buildRow('Party Name:', voucher.partyName),
                    _buildRow('GSTIN:', voucher.partyGstin.isNotEmpty ? voucher.partyGstin : 'Unregistered'),
                    _buildRow('State Code:', voucher.partyStateCode),
                    if (voucher.notes != null && voucher.notes!.isNotEmpty)
                      _buildRow('Notes:', voucher.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Line Items
            if (voucher.items.isNotEmpty) ...[
              Text(
                AppStrings.itemsList,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...voucher.items.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              IndianCurrencyFormatter.format(item.total),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.quantity} ${item.unit} @ ₹${item.rate} • HSN ${item.hsn} • GST ${item.gstRate.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Taxable: ${IndianCurrencyFormatter.format(item.taxableAmount)} | Tax: ${IndianCurrencyFormatter.format(item.cgst + item.sgst + item.igst)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            // Tax Breakup Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRow(AppStrings.subtotal, IndianCurrencyFormatter.format(voucher.subtotal)),
                    if (voucher.igst > 0)
                      _buildRow('IGST', IndianCurrencyFormatter.format(voucher.igst), isTax: true)
                    else ...[
                      _buildRow('CGST', IndianCurrencyFormatter.format(voucher.cgst), isTax: true),
                      _buildRow('SGST', IndianCurrencyFormatter.format(voucher.sgst), isTax: true),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.totalAmount,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          IndianCurrencyFormatter.format(voucher.totalAmount),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '(${NumberToWords.convert(voucher.totalAmount)})',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share Invoice Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.share, size: 22),
              label: Text(
                isHindi ? 'WhatsApp पर इनवॉइस भेजें' : 'Share GST Invoice PDF',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await PdfInvoiceService.shareInvoice(
                  voucher: voucher,
                  businessName: settings.businessName,
                  businessGstin: settings.businessGstin,
                  businessAddress: settings.businessAddress,
                  businessPhone: settings.businessPhone,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTax = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isTax ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
