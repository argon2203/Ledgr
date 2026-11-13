import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ledgr/core/utils/currency_formatter.dart';
import 'package:ledgr/core/utils/gst_calculator.dart';
import 'package:ledgr/core/utils/number_to_words.dart';
import 'package:ledgr/services/storage_service.dart';
import 'package:ledgr/services/gemini_service.dart';
import 'package:ledgr/services/pdf_invoice_service.dart';
import 'package:ledgr/providers/ledger_provider.dart';
import 'package:ledgr/providers/settings_provider.dart';
import 'package:ledgr/providers/voice_entry_provider.dart';
import 'package:ledgr/core/connectors/tally_connector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Core Utilities Tests', () {
    test('Indian Currency Formatter formats numbers correctly', () {
      expect(IndianCurrencyFormatter.format(124780), '₹1,24,780');
      expect(IndianCurrencyFormatter.format(24780), '₹24,780');
      expect(IndianCurrencyFormatter.format(21000), '₹21,000');
      expect(IndianCurrencyFormatter.format(3780), '₹3,780');
      expect(IndianCurrencyFormatter.format(500), '₹500');
      expect(IndianCurrencyFormatter.format(1000000), '₹10,00,000');
    });

    test('Number to Words converts Indian currency correctly', () {
      expect(
        NumberToWords.convert(24780),
        'Twenty Four Thousand Seven Hundred and Eighty Rupees Only',
      );
      expect(
        NumberToWords.convert(124780),
        'One Lakh Twenty Four Thousand Seven Hundred and Eighty Rupees Only',
      );
    });

    test('GST Calculator calculates exact Intra-state CGST & SGST', () {
      final res = GstCalculator.calculateItem(
        quantity: 50,
        rate: 420,
        gstRate: 18.0,
        gstIncludedInRate: false,
        businessStateCode: '27',
        partyStateCode: '27',
      );

      expect(res.taxableAmount, 21000.0);
      expect(res.cgst, 1890.0);
      expect(res.sgst, 1890.0);
      expect(res.igst, 0.0);
      expect(res.totalTax, 3780.0);
      expect(res.totalAmount, 24780.0);
    });

    test('GST Calculator calculates Inter-state IGST', () {
      final res = GstCalculator.calculateItem(
        quantity: 50,
        rate: 420,
        gstRate: 18.0,
        gstIncludedInRate: false,
        businessStateCode: '27',
        partyStateCode: '24', // Gujarat
      );

      expect(res.taxableAmount, 21000.0);
      expect(res.cgst, 0.0);
      expect(res.sgst, 0.0);
      expect(res.igst, 3780.0);
      expect(res.totalTax, 3780.0);
      expect(res.totalAmount, 24780.0);
    });
  });

  group('End-to-End Demo Flow Test', () {
    late StorageService storage;
    late LedgerProvider ledger;
    late SettingsProvider settings;
    late VoiceEntryProvider voiceProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
      final prefs = await SharedPreferences.getInstance();
      settings = SettingsProvider(prefs);
      ledger = LedgerProvider(storage);
      voiceProvider = VoiceEntryProvider();
    });

    test('Complete Demo Flow from Voice Note to Balance Q&A', () async {
      // Step 0: Verify initial state
      final initialRamesh = ledger.findPartyByNameOrNickname('Ramesh Bhai');
      expect(initialRamesh, isNotNull);
      expect(initialRamesh!.name, 'Ramesh Traders');
      expect(initialRamesh.balance, 15000.0);

      final initialPvcRoll = ledger.findItemByName('PVC Roll');
      expect(initialPvcRoll, isNotNull);
      expect(initialPvcRoll!.stock, 150.0);

      // Step 1: Voice input note
      const voiceCommand = "Ramesh Bhai ko pachaas PVC roll bhejo, chaar sau bees ke rate pe, GST lagao aur entry kar do.";
      await voiceProvider.processTextEntry(voiceCommand, ledger: ledger, settings: settings);

      // Step 2: Verify confirmation card draft
      expect(voiceProvider.status, VoiceEntryStatus.readyForConfirmation);
      final draft = voiceProvider.draftVoucher;
      expect(draft, isNotNull);
      expect(draft!.partyName, 'Ramesh Traders');
      expect(draft.items.length, 1);

      final item = draft.items.first;
      expect(item.itemName, 'PVC Roll');
      expect(item.quantity, 50.0);
      expect(item.rate, 420.0);
      expect(item.taxableAmount, 21000.0);
      expect(item.cgst, 1890.0);
      expect(item.sgst, 1890.0);
      expect(item.total, 24780.0);
      expect(draft.subtotal, 21000.0);
      expect(draft.cgst + draft.sgst + draft.igst, 3780.0);
      expect(draft.totalAmount, 24780.0);

      // Verify stock remaining calculation before save
      final stockRemaining = initialPvcRoll.stock - item.quantity;
      expect(stockRemaining, 100.0);

      // Step 3: User confirms voucher
      await ledger.confirmVoucher(draft);
      voiceProvider.cancel();

      // Verify stock is reduced
      final updatedPvcRoll = ledger.findItemById(item.itemId);
      expect(updatedPvcRoll!.stock, 100.0);

      // Verify party balance is updated (15,000 + 24,780 = 39,780)
      final updatedRamesh = ledger.findPartyById(initialRamesh.id);
      expect(updatedRamesh!.balance, 39780.0);

      // Verify GST Invoice PDF generation
      final pdfBytes = await PdfInvoiceService.generateInvoicePdf(
        voucher: draft,
        businessName: settings.businessName,
        businessGstin: settings.businessGstin,
        businessAddress: settings.businessAddress,
        businessPhone: settings.businessPhone,
      );
      expect(pdfBytes.isNotEmpty, true);

      // Verify Mock Tally XML generation
      final tallyConnector = MockTallyConnector();
      final tallyXml = await tallyConnector.exportVoucherToTallyXml(draft);
      expect(tallyXml.contains('<VOUCHER VCHTYPE="SALES" ACTION="Create">'), true);
      expect(tallyXml.contains('<PARTYLEDGERNAME>Ramesh Traders</PARTYLEDGERNAME>'), true);
      expect(tallyXml.contains('<STOCKITEMNAME>PVC Roll</STOCKITEMNAME>'), true);
      expect(tallyXml.contains('<AMOUNT>-24780.00</AMOUNT>'), true);

      // Step 4: Ask Q&A - Ramesh Bhai ka kitna baaki hai?
      final answerBalanceHindi = ledger.answerUserQuery("Ramesh Bhai ka kitna baaki hai?", isHindi: true);
      expect(answerBalanceHindi.contains('₹39,780'), true);
      expect(answerBalanceHindi.contains('Ramesh Traders'), true);

      final answerBalanceEnglish = ledger.answerUserQuery("Ramesh Bhai ka kitna baaki hai?", isHindi: false);
      expect(answerBalanceEnglish.contains('₹39,780'), true);

      // Ask: Aaj kitna sale hua?
      final answerSale = ledger.answerUserQuery("Aaj kitna sale hua?", isHindi: true);
      expect(answerSale.contains('आज कुल'), true);

      // Ask: PVC roll ka stock kitna hai?
      final answerStock = ledger.answerUserQuery("PVC roll ka stock kitna hai?", isHindi: true);
      expect(answerStock.contains('100 roll'), true);
    });
  });
}
