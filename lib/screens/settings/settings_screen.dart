import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import 'tally_sync_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final ledger = Provider.of<LedgerProvider>(context);
    final isHindi = settings.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tabSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. LANGUAGE SWITCH
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        isHindi ? 'भाषा / Language' : 'App Language',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('English (English)'),
                          selected: !isHindi,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: !isHindi ? Colors.white : AppColors.textPrimary,
                            fontWeight: !isHindi ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) settings.setLanguage('en');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('हिन्दी (Hindi)'),
                          selected: isHindi,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isHindi ? Colors.white : AppColors.textPrimary,
                            fontWeight: isHindi ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) settings.setLanguage('hi');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. BUSINESS DETAILS
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: AppColors.primary, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            isHindi ? 'व्यापार का विवरण' : 'Business Details',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                        onPressed: () => _showEditBusinessDialog(context, settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(isHindi ? 'फर्म का नाम:' : 'Firm Name:', settings.businessName),
                  _buildDetailRow('GSTIN:', settings.businessGstin),
                  _buildDetailRow(isHindi ? 'राज्य कोड:' : 'State Code:', '${settings.businessStateCode} (Maharashtra)'),
                  _buildDetailRow(isHindi ? 'पता:' : 'Address:', settings.businessAddress),
                  _buildDetailRow(isHindi ? 'फ़ोन:' : 'Phone:', settings.businessPhone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. CONNECT TALLY / ZOHO
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                child: Icon(Icons.sync_alt, color: AppColors.primary),
              ),
              title: Text(
                AppStrings.connectTallyZoho,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isHindi ? 'Tally XML एक्सपोर्ट और सिंक सेटिंग्स' : 'Tally XML export logs & status',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TallySyncScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 4. GEMINI API & BACKEND SETTINGS
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.smart_toy, color: Color(0xFF0284C7)),
              ),
              title: Text(
                isHindi ? 'Gemini AI बैकएंड सेटिंग्स' : 'Gemini AI & Backend Settings',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                settings.geminiApiKey.isNotEmpty
                    ? 'Direct Gemini API Key configured'
                    : 'Using Cloud Function endpoint / Built-in engine',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showBackendSettingsDialog(context, settings),
            ),
          ),
          const SizedBox(height: 14),

          // 5. RESET DEMO DATA
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.amber.shade50,
                child: Icon(Icons.restore, color: Colors.amber.shade800),
              ),
              title: Text(
                isHindi ? 'डेमो डेटा रीसेट करें' : 'Reset Demo Data',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isHindi
                    ? '8 पार्टियां, 15 आइटम और 20 वाउचर पुनः लोड करें'
                : 'Restore 8 parties, 15 items, and 20 demo vouchers',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              onTap: () async {
                await ledger.resetDemoData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isHindi ? 'डेमो डेटा सफलतापूर्वक रीसेट हो गया!' : 'Demo data reset successfully!',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 30),

          // APP VERSION & INFO
          Center(
            child: Column(
              children: [
                Text(
                  '${AppStrings.appName} v1.0.0',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  isHindi ? 'भारतीय व्यापारियों का विश्वस्त AI मुनीम' : 'Designed for Indian Traders & Wholesalers',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBusinessDialog(BuildContext context, SettingsProvider settings) {
    final nameCtrl = TextEditingController(text: settings.businessName);
    final gstinCtrl = TextEditingController(text: settings.businessGstin);
    final addrCtrl = TextEditingController(text: settings.businessAddress);
    final phoneCtrl = TextEditingController(text: settings.businessPhone);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(settings.isHindi ? 'व्यापार का विवरण बदलें' : 'Edit Business Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Firm Name')),
                const SizedBox(height: 10),
                TextField(controller: gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN (15 Digits)')),
                const SizedBox(height: 10),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                settings.updateBusinessDetails(
                  name: nameCtrl.text.trim(),
                  gstin: gstinCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showBackendSettingsDialog(BuildContext context, SettingsProvider settings) {
    final backendCtrl = TextEditingController(text: settings.backendUrl);
    final keyCtrl = TextEditingController(text: settings.geminiApiKey);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Gemini API / Cloud Function'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'In production, API keys stay on the backend Cloud Function or Cloud Run container.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: backendCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cloud Function URL',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Direct Gemini API Key (Optional)',
                    hintText: 'AIzaSy...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                settings.updateBackendSettings(
                  backendUrl: backendCtrl.text.trim(),
                  apiKey: keyCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
