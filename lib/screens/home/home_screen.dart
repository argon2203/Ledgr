import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/voice_entry_provider.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import '../confirmation/confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _recordingTimer;
  int _secondsRecorded = 0;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsRecorded = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsRecorded++);
      }
    });
  }

  void _stopTimer() {
    _recordingTimer?.cancel();
    _secondsRecorded = 0;
  }

  Future<void> _handleHoldToRecordStart(VoiceEntryProvider voiceProvider) async {
    _startTimer();
    await voiceProvider.startRecording();
  }

  Future<void> _handleHoldToRecordEnd(
    VoiceEntryProvider voiceProvider,
    LedgerProvider ledger,
    SettingsProvider settings, {
    String? explicitText,
  }) async {
    _stopTimer();
    await voiceProvider.stopAndProcess(
      ledger: ledger,
      settings: settings,
      fallbackSpokenText: explicitText ?? "Ramesh Bhai ko pachaas PVC roll bhejo, chaar sau bees ke rate pe, GST lagao aur entry kar do.",
    );

    if (mounted && voiceProvider.status == VoiceEntryStatus.readyForConfirmation) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
      );
    }
  }

  Future<void> _pickBillPhoto(
    VoiceEntryProvider voiceProvider,
    LedgerProvider ledger,
    SettingsProvider settings,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        await voiceProvider.processImageEntry(
          bytes,
          ledger: ledger,
          settings: settings,
        );

        if (mounted && voiceProvider.status == VoiceEntryStatus.readyForConfirmation) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
          );
        }
      }
    } catch (_) {
      // If camera unavailable (e.g. on Windows without camera hardware), pick from gallery
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (image != null) {
          final bytes = await image.readAsBytes();
          await voiceProvider.processImageEntry(
            bytes,
            ledger: ledger,
            settings: settings,
          );
          if (mounted && voiceProvider.status == VoiceEntryStatus.readyForConfirmation) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
            );
          }
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledger = Provider.of<LedgerProvider>(context);
    final voiceProvider = Provider.of<VoiceEntryProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final isHindi = settings.isHindi;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(settings.businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'GSTIN: ${settings.businessGstin}',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: isHindi ? 'रिफ्रेश' : 'Refresh',
            onPressed: () => ledger.loadData(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TOP 3 SUMMARY CARDS
                Row(
                  children: [
                    // Card 1: Today's Sales
                    Expanded(
                      child: _buildSummaryCard(
                        title: AppStrings.todaySales,
                        value: IndianCurrencyFormatter.format(ledger.todaySales),
                        icon: Icons.trending_up,
                        accentColor: AppColors.primary,
                        bgColor: AppColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Card 2: To Collect
                    Expanded(
                      child: _buildSummaryCard(
                        title: AppStrings.toCollect,
                        value: IndianCurrencyFormatter.format(ledger.toCollect),
                        icon: Icons.account_balance_wallet,
                        accentColor: const Color(0xFF0284C7), // Blue
                        bgColor: const Color(0xFFE0F2FE),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Card 3: Low Stock Alert Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: ledger.lowStockItems.isNotEmpty ? AppColors.warning : AppColors.border,
                      width: ledger.lowStockItems.isNotEmpty ? 1.5 : 1,
                    ),
                  ),
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
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: ledger.lowStockItems.isNotEmpty ? AppColors.warning : AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppStrings.lowStockItems,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: ledger.lowStockItems.isNotEmpty
                                    ? AppColors.warningBg
                                    : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ledger.lowStockItems.isNotEmpty
                                      ? AppColors.warning
                                      : AppColors.primary,
                                ),
                              ),
                              child: Text(
                                '${ledger.lowStockItems.length} ${AppStrings.itemsNeedReorder}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ledger.lowStockItems.isNotEmpty
                                      ? const Color(0xFF92400E)
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (ledger.lowStockItems.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: ledger.lowStockItems.take(3).map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: Text(
                                  '${item.name}: ${item.stock.toStringAsFixed(0)} ${item.unit} left',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // QUICK SPEECH DEMO SECTION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flash_on, color: AppColors.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            isHindi ? 'त्वरित डेमो परीक्षण (Tap to Test Voice)' : 'Quick Voice Demo Flow',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isHindi
                            ? 'माइक दबाकर बोलें या नीचे दिए गए डेमो वाक्य पर टैप करें:'
                            : 'Hold the central mic or tap this sample voice command to test instantly:',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),

                      // Demo Flow Trigger Card
                      InkWell(
                        onTap: () async {
                          const demoPhrase = "Ramesh Bhai ko pachaas PVC roll bhejo, chaar sau bees ke rate pe, GST lagao aur entry kar do.";
                          await voiceProvider.processTextEntry(demoPhrase, ledger: ledger, settings: settings);
                          if (!mounted) return;
                          if (voiceProvider.status == VoiceEntryStatus.readyForConfirmation) {
                            Navigator.push(
                              this.context,
                              MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  '"Ramesh Bhai ko pachaas PVC roll bhejo, chaar sau bees ke rate pe, GST lagao aur entry kar do."',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // RECENT ENTRIES SNIPPET
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHindi ? 'हाल के वाउचर' : 'Recent Vouchers',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${ledger.vouchers.length} Total',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...ledger.vouchers.take(4).map((v) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: v.type == 'sales'
                              ? AppColors.primaryContainer
                              : Colors.orange.shade50,
                          child: Icon(
                            v.type == 'sales' ? Icons.arrow_outward : Icons.arrow_downward,
                            size: 18,
                            color: v.type == 'sales' ? AppColors.primary : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.partyName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${v.voucherNumber} • ${v.type.toUpperCase()}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          IndianCurrencyFormatter.format(v.totalAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: v.type == 'sales' ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // BOTTOM DOCKED ACTION BAR (BIG MIC IN CENTRE + CAMERA BUTTON)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // State Caption
                  Text(
                    voiceProvider.isRecording
                        ? '${AppStrings.releaseToSend} (${_secondsRecorded}s)'
                        : (voiceProvider.isProcessing
                            ? AppStrings.processingAI
                            : AppStrings.holdToRecord),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: voiceProvider.isRecording ? AppColors.micRecording : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Camera Button (Photo of Handwritten Bill)
                      Material(
                        color: Colors.grey.shade100,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: voiceProvider.isProcessing
                              ? null
                              : () => _pickBillPhoto(voiceProvider, ledger, settings),
                          child: Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.secondary,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),

                      // BIG MIC BUTTON IN THE CENTRE (Hold to record, release to send)
                      GestureDetector(
                        onLongPressStart: (_) => _handleHoldToRecordStart(voiceProvider),
                        onLongPressEnd: (_) => _handleHoldToRecordEnd(voiceProvider, ledger, settings),
                        onTap: () {
                          // Tap triggers gentle guidance or demo action
                          if (!voiceProvider.isRecording) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isHindi
                                      ? 'बोलने के लिए माइक को दबाकर रखें, फिर छोड़ें'
                                      : 'Press and HOLD the mic to record your voice entry',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final scale = voiceProvider.isRecording ? _pulseAnimation.value : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: voiceProvider.isRecording
                                      ? AppColors.micRecording
                                      : AppColors.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (voiceProvider.isRecording
                                              ? AppColors.micRecording
                                              : AppColors.primary)
                                          .withOpacity(0.4),
                                      blurRadius: 18,
                                      spreadRadius: voiceProvider.isRecording ? 6 : 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  voiceProvider.isRecording ? Icons.mic : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Type entry fallback button
                      Material(
                        color: Colors.grey.shade100,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _showTypeEntryDialog(context, voiceProvider, ledger, settings),
                          child: Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.keyboard_alt_outlined,
                              color: AppColors.secondary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // FULL-SCREEN PROCESSING OVERLAY
          if (voiceProvider.isProcessing)
            Container(
              color: Colors.black.withOpacity(0.55),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3.5),
                      const SizedBox(height: 20),
                      Text(
                        voiceProvider.statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isHindi
                            ? 'Gemini Multimodal से पार्टी, सामान और GST निकाला जा रहा है...'
                            : 'Extracting party, items, and tax via Gemini Multimodal...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: bgColor,
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeEntryDialog(
    BuildContext context,
    VoiceEntryProvider voiceProvider,
    LedgerProvider ledger,
    SettingsProvider settings,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(settings.isHindi ? 'बोलकर या लिखकर दर्ज करें' : 'Type Entry Note'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: settings.isHindi
                  ? 'उदा. "रमेश भाई को पचास PVC roll 420 के रेट पे भेजो"'
                  : 'e.g. "Ramesh Bhai ko pachaas PVC roll bhejo, chaar sau bees ke rate pe, GST lagao"',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                Navigator.pop(ctx);
                if (text.isNotEmpty) {
                  await voiceProvider.processTextEntry(text, ledger: ledger, settings: settings);
                  if (!mounted) return;
                  if (voiceProvider.status == VoiceEntryStatus.readyForConfirmation) {
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(builder: (_) => const ConfirmationScreen()),
                    );
                  }
                }
              },
              child: const Text('Process'),
            ),
          ],
        );
      },
    );
  }
}
