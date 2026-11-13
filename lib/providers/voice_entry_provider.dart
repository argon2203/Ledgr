import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/voucher.dart';
import '../models/voucher_item.dart';
import '../models/ai_parse_result.dart';
import '../core/utils/gst_calculator.dart';
import '../services/audio_recorder_service.dart';
import '../services/gemini_service.dart';
import 'ledger_provider.dart';
import 'settings_provider.dart';

enum VoiceEntryStatus { idle, recording, processing, readyForConfirmation, error }

class VoiceEntryProvider extends ChangeNotifier {
  final AudioRecorderService _recorder = AudioRecorderService();
  VoiceEntryStatus _status = VoiceEntryStatus.idle;
  String _statusMessage = '';
  
  Uint8List? _audioBytes;
  Uint8List? _imageBytes;
  String? _spokenTranscript;

  AIParseResult? _parseResult;
  Voucher? _draftVoucher;
  List<String> _warnings = [];

  // Working state for Confirmation Screen (editable fields)
  Party? _selectedParty;
  String _selectedVoucherType = 'sales';
  List<VoucherItem> _draftItems = [];
  bool _gstIncludedInRate = false;
  String _notes = '';

  VoiceEntryStatus get status => _status;
  bool get isRecording => _status == VoiceEntryStatus.recording;
  bool get isProcessing => _status == VoiceEntryStatus.processing;
  String get statusMessage => _statusMessage;
  
  Uint8List? get audioBytes => _audioBytes;
  Uint8List? get imageBytes => _imageBytes;
  AIParseResult? get parseResult => _parseResult;
  Voucher? get draftVoucher => _draftVoucher;
  List<String> get warnings => _warnings;
  Party? get selectedParty => _selectedParty;
  String get selectedVoucherType => _selectedVoucherType;
  List<VoucherItem> get draftItems => _draftItems;
  bool get gstIncludedInRate => _gstIncludedInRate;
  String? get spokenTranscript => _spokenTranscript;

  // --- RECORDING ACTIONS ---

  Future<void> startRecording() async {
    _status = VoiceEntryStatus.recording;
    _statusMessage = 'Listening... Speak now';
    notifyListeners();
    await _recorder.startRecording();
  }

  Future<void> stopAndProcess({
    required LedgerProvider ledger,
    required SettingsProvider settings,
    String? fallbackSpokenText,
  }) async {
    _status = VoiceEntryStatus.processing;
    _statusMessage = settings.isHindi ? 'AI बिल समझ रहा है...' : 'Ledgr AI is analyzing your entry...';
    notifyListeners();

    _audioBytes = await _recorder.stopRecording();
    _spokenTranscript = fallbackSpokenText ?? "Ramesh Bhai ko pachaas PVC roll bhejo, chaar sau bees ke rate pe, GST lagao aur entry kar do.";

    await _processWithGemini(
      ledger: ledger,
      settings: settings,
      audioBytes: _audioBytes,
      textInput: _spokenTranscript,
    );
  }

  Future<void> processTextEntry(
    String text, {
    required LedgerProvider ledger,
    required SettingsProvider settings,
  }) async {
    _status = VoiceEntryStatus.processing;
    _statusMessage = settings.isHindi ? 'AI समझ रहा है...' : 'AI is processing entry...';
    _spokenTranscript = text;
    notifyListeners();

    await _processWithGemini(
      ledger: ledger,
      settings: settings,
      textInput: text,
    );
  }

  Future<void> processImageEntry(
    Uint8List imageBytes, {
    required LedgerProvider ledger,
    required SettingsProvider settings,
  }) async {
    _status = VoiceEntryStatus.processing;
    _statusMessage = settings.isHindi ? 'AI बिल फोटो पढ़ रहा है...' : 'AI is analyzing bill image...';
    _imageBytes = imageBytes;
    notifyListeners();

    await _processWithGemini(
      ledger: ledger,
      settings: settings,
      imageBytes: imageBytes,
    );
  }

  // --- GEMINI MULTIMODAL CALL & DART GST COMPUTATION ---

  Future<void> _processWithGemini({
    required LedgerProvider ledger,
    required SettingsProvider settings,
    Uint8List? audioBytes,
    Uint8List? imageBytes,
    String? textInput,
  }) async {
    try {
      final result = await GeminiService.parseVoucher(
        audioBytes: audioBytes,
        imageBytes: imageBytes,
        textInput: textInput,
        parties: ledger.parties,
        items: ledger.items,
        backendUrl: settings.backendUrl,
        directApiKey: settings.geminiApiKey,
      );

      _parseResult = result;
      _selectedVoucherType = result.voucherType;
      _gstIncludedInRate = result.gstIncludedInRate;
      _notes = result.notes;

      // 1. Resolve Party (Check ID or matching nicknames)
      Party? party = ledger.findPartyById(result.matchedPartyId);
      if (party == null && result.partyNameHeard.isNotEmpty) {
        party = ledger.findPartyByNameOrNickname(result.partyNameHeard);
      }
      _selectedParty = party;

      // 2. Build Voucher Items & Run GST Calculations strictly in Dart
      _draftItems = [];
      for (final rawItem in result.items) {
        Item? matchedItem = ledger.findItemById(rawItem.matchedItemId);
        if (matchedItem == null && rawItem.nameHeard.isNotEmpty) {
          matchedItem = ledger.findItemByName(rawItem.nameHeard);
        }

        final gstRate = matchedItem?.gstRate ?? 18.0;
        final hsn = matchedItem?.hsn ?? '3917';
        final unit = matchedItem?.unit ?? rawItem.unit;
        final itemName = matchedItem?.name ?? rawItem.nameHeard;
        final itemId = matchedItem?.id ?? const Uuid().v4();

        final calc = GstCalculator.calculateItem(
          quantity: rawItem.quantity,
          rate: rawItem.rate,
          gstRate: gstRate,
          gstIncludedInRate: _gstIncludedInRate,
          businessStateCode: settings.businessStateCode,
          partyStateCode: _selectedParty?.stateCode ?? settings.businessStateCode,
        );

        _draftItems.add(
          VoucherItem(
            itemId: itemId,
            itemName: itemName,
            hsn: hsn,
            quantity: calc.quantity,
            unit: unit,
            rate: calc.rate,
            gstRate: calc.gstRate,
            taxableAmount: calc.taxableAmount,
            cgst: calc.cgst,
            sgst: calc.sgst,
            igst: calc.igst,
            total: calc.totalAmount,
          ),
        );
      }

      // If no items extracted, create a fallback single line
      if (_draftItems.isEmpty) {
        final defItem = ledger.items.first;
        final calc = GstCalculator.calculateItem(
          quantity: 1.0,
          rate: defItem.defaultRate,
          gstRate: defItem.gstRate,
          gstIncludedInRate: false,
          businessStateCode: settings.businessStateCode,
          partyStateCode: _selectedParty?.stateCode ?? settings.businessStateCode,
        );
        _draftItems.add(
          VoucherItem(
            itemId: defItem.id,
            itemName: defItem.name,
            hsn: defItem.hsn,
            quantity: 1.0,
            unit: defItem.unit,
            rate: defItem.defaultRate,
            gstRate: defItem.gstRate,
            taxableAmount: calc.taxableAmount,
            cgst: calc.cgst,
            sgst: calc.sgst,
            igst: calc.igst,
            total: calc.totalAmount,
          ),
        );
      }

      _recalculateTotalsAndWarnings(ledger: ledger, settings: settings);

      _status = VoiceEntryStatus.readyForConfirmation;
      notifyListeners();
    } catch (e) {
      _status = VoiceEntryStatus.error;
      _statusMessage = 'Error analyzing entry: $e';
      notifyListeners();
    }
  }

  // --- RECALCULATE DART TOTALS & CHECK AUDIT WARNINGS ---

  void _recalculateTotalsAndWarnings({
    required LedgerProvider ledger,
    required SettingsProvider settings,
  }) {
    _warnings = [];

    // Check Warning 1: Unknown party
    if (_selectedParty == null) {
      _warnings.add(
        settings.isHindi
            ? 'अज्ञात पार्टी: रजिस्टर में यह पार्टी नहीं मिली। कृपया पार्टी चुनें।'
            : 'Unknown Party: Not found in directory. Please select or confirm.',
      );
    }

    double subtotal = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;
    double totalAmount = 0.0;

    for (final item in _draftItems) {
      final calc = GstCalculator.calculateItem(
        quantity: item.quantity,
        rate: item.rate,
        gstRate: item.gstRate,
        gstIncludedInRate: _gstIncludedInRate,
        businessStateCode: settings.businessStateCode,
        partyStateCode: _selectedParty?.stateCode ?? settings.businessStateCode,
      );

      item.taxableAmount = calc.taxableAmount;
      item.cgst = calc.cgst;
      item.sgst = calc.sgst;
      item.igst = calc.igst;
      item.total = calc.totalAmount;

      subtotal += calc.taxableAmount;
      cgst += calc.cgst;
      sgst += calc.sgst;
      igst += calc.igst;
      totalAmount += calc.totalAmount;

      // Check Warning 2: Stock too low
      final matchedStockItem = ledger.findItemById(item.itemId);
      if (matchedStockItem != null && _selectedVoucherType == 'sales') {
        if (matchedStockItem.stock < item.quantity) {
          _warnings.add(
            settings.isHindi
                ? 'कम स्टॉक: "${item.itemName}" का उपलब्ध स्टॉक सिर्फ ${matchedStockItem.stock} ${item.unit} है, जबकि बिक्री ${item.quantity} ${item.unit} की है।'
                : 'Stock Warning: Only ${matchedStockItem.stock} ${item.unit} available for "${item.itemName}", selling ${item.quantity} ${item.unit}.',
          );
        }
      }

      // Check Warning 3: Unusual rate (> 25% difference from standard default)
      if (matchedStockItem != null && matchedStockItem.defaultRate > 0) {
        final diff = (item.rate - matchedStockItem.defaultRate).abs() / matchedStockItem.defaultRate;
        if (diff > 0.25) {
          _warnings.add(
            settings.isHindi
                ? 'असामान्य रेट: "${item.itemName}" का मानक रेट ₹${matchedStockItem.defaultRate} है, जबकि आपने ₹${item.rate} डाला है।'
                : 'Rate Alert: Standard rate for "${item.itemName}" is ₹${matchedStockItem.defaultRate}, entered ₹${item.rate}.',
          );
        }
      }
    }

    // Add any questions returned from AI
    if (_parseResult != null && _parseResult!.questionsForUser.isNotEmpty) {
      _warnings.addAll(_parseResult!.questionsForUser);
    }

    final voucherNumber = 'SAL-${DateTime.now().year}-${(ledger.vouchers.length + 82).toString().padLeft(3, '0')}';

    _draftVoucher = Voucher(
      id: const Uuid().v4(),
      voucherNumber: voucherNumber,
      type: _selectedVoucherType,
      date: DateTime.now(),
      partyId: _selectedParty?.id ?? 'p_temp',
      partyName: _selectedParty?.name ?? (_parseResult?.partyNameHeard.isNotEmpty == true ? _parseResult!.partyNameHeard : 'New Party'),
      partyGstin: _selectedParty?.gstin ?? '',
      partyStateCode: _selectedParty?.stateCode ?? settings.businessStateCode,
      items: _draftItems,
      subtotal: (subtotal * 100).round() / 100,
      cgst: (cgst * 100).round() / 100,
      sgst: (sgst * 100).round() / 100,
      igst: (igst * 100).round() / 100,
      totalAmount: (totalAmount * 100).round() / 100,
      notes: _notes,
      rawVoiceTranscript: _spokenTranscript,
    );
  }

  // --- USER EDITS IN CONFIRMATION SCREEN ---

  void updateParty(Party party, {required LedgerProvider ledger, required SettingsProvider settings}) {
    _selectedParty = party;
    _recalculateTotalsAndWarnings(ledger: ledger, settings: settings);
    notifyListeners();
  }

  void updateItemDetails(
    int index, {
    double? quantity,
    double? rate,
    double? gstRate,
    required LedgerProvider ledger,
    required SettingsProvider settings,
  }) {
    if (index >= 0 && index < _draftItems.length) {
      if (quantity != null) _draftItems[index].quantity = quantity;
      if (rate != null) _draftItems[index].rate = rate;
      _recalculateTotalsAndWarnings(ledger: ledger, settings: settings);
      notifyListeners();
    }
  }

  void toggleGstIncluded({required LedgerProvider ledger, required SettingsProvider settings}) {
    _gstIncludedInRate = !_gstIncludedInRate;
    _recalculateTotalsAndWarnings(ledger: ledger, settings: settings);
    notifyListeners();
  }

  void cancel() {
    _status = VoiceEntryStatus.idle;
    _draftVoucher = null;
    _warnings = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
