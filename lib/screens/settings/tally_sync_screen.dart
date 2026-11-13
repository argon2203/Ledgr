import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';

class TallySyncScreen extends StatefulWidget {
  const TallySyncScreen({super.key});

  @override
  State<TallySyncScreen> createState() => _TallySyncScreenState();
}

class _TallySyncScreenState extends State<TallySyncScreen> {
  String _sampleXml = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSampleXml();
  }

  Future<void> _loadSampleXml() async {
    final ledger = Provider.of<LedgerProvider>(context, listen: false);
    if (ledger.vouchers.isNotEmpty) {
      final xml = await ledger.tallyConnector.exportVoucherToTallyXml(ledger.vouchers.first);
      if (mounted) {
        setState(() => _sampleXml = xml);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = Provider.of<LedgerProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.connectTallyZoho),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CONNECTOR STATUS CARD
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryContainer,
                          child: Icon(Icons.sync_alt, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ledger.tallyConnector.connectorName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isHindi ? 'स्थिति: एक्टिव और तैयार (Mock Bridge)' : 'Status: Active & Connected (Mock Bridge)',
                                style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isHindi
                          ? 'हर कन्फर्म हुआ वाउचर अपने आप Tally XML फॉर्मेट में एक्सपोर्ट हो जाता है। बाद में इसे असली Tally ODBC या Zoho Books API से जोड़ा जा सकता है।'
                          : 'Every confirmed voucher is automatically formatted and queued in Tally XML. In production, this bridges directly to TallyPrime port 9000 or Zoho Books REST API.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TEST SYNC ACTION
            ElevatedButton.icon(
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(isHindi ? 'सभी वाउचर टैली में सिंक करें (Test Sync)' : 'Sync All Vouchers to Tally (Mock Test)'),
              onPressed: _isExporting
                  ? null
                  : () async {
                      setState(() => _isExporting = true);
                      for (final v in ledger.vouchers.take(5)) {
                        await ledger.tallyConnector.sendVoucherToTally(v);
                      }
                      await Future.delayed(const Duration(milliseconds: 600));
                      if (!mounted) return;
                      setState(() => _isExporting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isHindi
                                ? 'सफलतापूर्वक 5 वाउचर Tally XML में प्रोसेस किए गए!'
                                : 'Successfully processed 5 vouchers in Tally XML format!',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
            ),
            const SizedBox(height: 24),

            // LIVE XML INSPECTOR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isHindi ? 'Tally XML पेलोड नमूना:' : 'Sample Tally XML Output:',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(isHindi ? 'रिफ्रेश' : 'Reload'),
                  onPressed: _loadSampleXml,
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  _sampleXml.isNotEmpty ? _sampleXml : 'Loading XML export...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFE2E8F0),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
