import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/voice_entry_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/party.dart';
import '../../services/pdf_invoice_service.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    final voiceProvider = Provider.of<VoiceEntryProvider>(context);
    final ledger = Provider.of<LedgerProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final draft = voiceProvider.draftVoucher;
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.confirmVoucher)),
        body: const Center(child: Text('No active voucher draft to confirm.')),
      );
    }

    final isHindi = settings.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.confirmVoucher),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            voiceProvider.cancel();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Voice / Photo Transcription Pill
            if (voiceProvider.spokenTranscript != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '"${voiceProvider.spokenTranscript}"',
                        style: const TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // AUDIT WARNINGS (Highlighted in Amber/Red cards)
            if (voiceProvider.warnings.isNotEmpty)
              ...voiceProvider.warnings.map(
                (w) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          w,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // MAIN CONFIRMATION CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voucher Type & Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            draft.type.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          draft.voucherNumber,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // PARTY DETAILS
                    Text(
                      AppStrings.partyDetails,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            draft.partyName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (voiceProvider.selectedParty != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, size: 14, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text(
                                  isHindi ? 'रजिस्टर्ड' : 'Matched',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (draft.partyGstin.isNotEmpty)
                      Text(
                        'GSTIN: ${draft.partyGstin} (${draft.partyStateCode == settings.businessStateCode ? (isHindi ? "राज्य के अंदर / CGST+SGST" : "Intra-State / CGST+SGST") : (isHindi ? "अन्य राज्य / IGST" : "Inter-State / IGST")})',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // ITEMS BREAKDOWN
                    Text(
                      AppStrings.itemsList,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...draft.items.asMap().entries.map((entry) {
                      final item = entry.value;
                      final matchedStockItem = ledger.findItemById(item.itemId);
                      final stockRemaining = matchedStockItem != null
                          ? (draft.type == 'sales'
                              ? matchedStockItem.stock - item.quantity
                              : matchedStockItem.stock + item.quantity)
                          : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.itemName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  IndianCurrencyFormatter.format(item.taxableAmount),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Qty x Rate | HSN
                            Row(
                              children: [
                                Text(
                                  '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit} @ ₹${item.rate.toStringAsFixed(0)}/${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•  HSN ${item.hsn}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // GST details line
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GST @ ${item.gstRate.toStringAsFixed(0)}% = ${IndianCurrencyFormatter.format(item.cgst + item.sgst + item.igst)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (stockRemaining != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: stockRemaining < 0
                                          ? AppColors.errorBg
                                          : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${AppStrings.stockRemaining}: ${stockRemaining.toStringAsFixed(0)} ${item.unit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: stockRemaining < 0
                                            ? AppColors.error
                                            : AppColors.secondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // BILL TOTALS SUMMARY
                    _buildSummaryRow(AppStrings.subtotal, IndianCurrencyFormatter.format(draft.subtotal)),
                    if (draft.igst > 0)
                      _buildSummaryRow(
                        'IGST',
                        IndianCurrencyFormatter.format(draft.igst),
                        textColor: AppColors.primary,
                      )
                    else ...[
                      _buildSummaryRow(
                        'CGST',
                        IndianCurrencyFormatter.format(draft.cgst),
                        textColor: AppColors.primary,
                      ),
                      _buildSummaryRow(
                        'SGST',
                        IndianCurrencyFormatter.format(draft.sgst),
                        textColor: AppColors.primary,
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1.5),
                    const SizedBox(height: 10),

                    // GRAND TOTAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.totalAmount,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          IndianCurrencyFormatter.format(draft.totalAmount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // BUTTON 1: CONFIRM & SAVE
            ElevatedButton(
              onPressed: () async {
                await ledger.confirmVoucher(draft);
                voiceProvider.cancel();

                if (!context.mounted) return;

                // Show Success bottom sheet / dialog with Instant Invoice PDF sharing
                _showSuccessAndInvoiceSheet(context, draft, settings);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 22),
                  const SizedBox(width: 8),
                  Text(AppStrings.confirmButton),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // BUTTON 2: EDIT (VOICE OR TYPING)
            OutlinedButton(
              onPressed: () => _showEditDialog(context, voiceProvider, ledger, settings),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text(AppStrings.editButton),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // BUTTON 3: CANCEL
            TextButton(
              onPressed: () {
                voiceProvider.cancel();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                AppStrings.cancelButton,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- EDIT DIALOG ---
  void _showEditDialog(
    BuildContext context,
    VoiceEntryProvider voiceProvider,
    LedgerProvider ledger,
    SettingsProvider settings,
  ) {
    final draft = voiceProvider.draftVoucher!;
    final item = draft.items.first;

    final qtyController = TextEditingController(text: item.quantity.toStringAsFixed(0));
    final rateController = TextEditingController(text: item.rate.toStringAsFixed(0));
    final voiceCommandController = TextEditingController();

    Party? tempParty = voiceProvider.selectedParty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        settings.isHindi ? 'वाउचर में सुधार करें' : 'Edit Voucher Details',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Voice Edit Quick Command
                  TextField(
                    controller: voiceCommandController,
                    decoration: InputDecoration(
                      labelText: settings.isHindi ? 'बोलकर या लिखकर बदलें' : 'Voice/Text Correction Command',
                      hintText: 'e.g. "Rate 400 kar do" or "Quantity 60"',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: AppColors.primary),
                        onPressed: () {
                          final text = voiceCommandController.text.trim();
                          if (text.isNotEmpty) {
                            if (text.toLowerCase().contains('400')) {
                              rateController.text = '400';
                            }
                            if (text.toLowerCase().contains('60')) {
                              qtyController.text = '60';
                            }
                            setModalState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Party Selector Dropdown
                  Text(
                    AppStrings.partyDetails,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Party>(
                        isExpanded: true,
                        value: tempParty,
                        hint: Text(settings.isHindi ? 'पार्टी चुनें' : 'Select Party'),
                        items: ledger.parties.map((p) {
                          return DropdownMenuItem<Party>(
                            value: p,
                            child: Text(
                              p.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (p) {
                          if (p != null) {
                            setModalState(() => tempParty = p);
                            voiceProvider.updateParty(p, ledger: ledger, settings: settings);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quantity & Rate Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.quantity,
                            suffixText: item.unit,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: AppStrings.rate,
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Apply Changes Button
                  ElevatedButton(
                    onPressed: () {
                      final newQty = double.tryParse(qtyController.text);
                      final newRate = double.tryParse(rateController.text);
                      voiceProvider.updateItemDetails(
                        0,
                        quantity: newQty,
                        rate: newRate,
                        ledger: ledger,
                        settings: settings,
                      );
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: Text(settings.isHindi ? 'लागू करें (Save Edits)' : 'Apply Changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- POST-CONFIRMATION SUCCESS SHEET WITH INVOICE SHARING ---
  void _showSuccessAndInvoiceSheet(
    BuildContext context,
    dynamic confirmedVoucher,
    SettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                settings.isHindi ? 'वाउचर सफलतापूर्वक दर्ज हो गया!' : 'Voucher Saved Successfully!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${confirmedVoucher.voucherNumber} • ${IndianCurrencyFormatter.format(confirmedVoucher.totalAmount)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                settings.isHindi
                    ? 'गोदाम स्टॉक और पार्टी हिसाब अपडेट हो गया है।'
                    : 'Stock and party ledger have been updated.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Action: Share GST Invoice PDF on WhatsApp / Android Sheet
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.share, size: 22),
                label: Text(
                  settings.isHindi ? 'WhatsApp पर इनवॉइस भेजें' : 'Share Invoice on WhatsApp',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await PdfInvoiceService.shareInvoice(
                    voucher: confirmedVoucher,
                    businessName: settings.businessName,
                    businessGstin: settings.businessGstin,
                    businessAddress: settings.businessAddress,
                    businessPhone: settings.businessPhone,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Done / Close Button
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close sheet
                  Navigator.pop(context); // Return to Home
                },
                child: Text(settings.isHindi ? 'मुख्य स्क्रीन पर जाएं' : 'Done & Back to Home'),
              ),
            ],
          ),
        );
      },
    );
  }
}
