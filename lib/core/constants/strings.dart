class AppStrings {
  // Current language mode
  static bool isHindi = false;

  static String get appName => isHindi ? 'लेजर (Ledgr)' : 'Ledgr';
  static String get appTagline => isHindi 
      ? 'व्यापारियों का आसान AI मुनीम' 
      : 'AI Bookkeeper for Indian Traders';

  // Navigation
  static String get tabHome => isHindi ? 'होम' : 'Home';
  static String get tabEntries => isHindi ? 'खाता (Entries)' : 'Entries';
  static String get tabAsk => isHindi ? 'पूछें (Ask AI)' : 'Ask AI';
  static String get tabPartiesStock => isHindi ? 'पार्टी और स्टॉक' : 'Parties & Stock';
  static String get tabSettings => isHindi ? 'सेटिंग्स' : 'Settings';

  // Home Screen
  static String get holdToRecord => isHindi 
      ? 'बोलने के लिए दबाकर रखें' 
      : 'Hold to speak entry';
  static String get releaseToSend => isHindi 
      ? 'भेजने के लिए छोड़ें' 
      : 'Release to send';
  static String get takePhotoBill => isHindi 
      ? 'बिल की फोटो खींचें' 
      : 'Bill Photo / Scan';
  static String get listening => isHindi 
      ? 'सुन रहा हूँ... बोलिए' 
      : 'Listening... speak now';
  static String get processingAI => isHindi 
      ? 'AI बिल समझ रहा है...' 
      : 'AI is analyzing your voice note...';

  // Summary Cards
  static String get todaySales => isHindi ? 'आज की बिक्री' : 'Sales Today';
  static String get toCollect => isHindi ? 'कुल लेना बाकी' : 'To Collect';
  static String get lowStockItems => isHindi ? 'कम स्टॉक आइटम' : 'Low Stock Items';
  static String get itemsNeedReorder => isHindi ? 'आइटम तुरंत मंगाएं' : 'items need reorder';
  static String get viewAll => isHindi ? 'सभी देखें' : 'View All';

  // Confirmation Card
  static String get confirmVoucher => isHindi ? 'वाउचर पुष्टि करें' : 'Confirm Voucher';
  static String get partyDetails => isHindi ? 'पार्टी का नाम' : 'Party Details';
  static String get itemsList => isHindi ? 'सामान (Items)' : 'Items List';
  static String get quantity => isHindi ? 'मात्रा' : 'Quantity';
  static String get rate => isHindi ? 'रेट' : 'Rate';
  static String get hsnCode => isHindi ? 'HSN कोड' : 'HSN Code';
  static String get gstRate => isHindi ? 'GST %' : 'GST %';
  static String get gstAmount => isHindi ? 'GST राशि' : 'GST Amount';
  static String get subtotal => isHindi ? 'मूल मूल्य' : 'Subtotal';
  static String get totalAmount => isHindi ? 'कुल रकम' : 'Total Amount';
  static String get stockRemaining => isHindi ? 'बचा हुआ स्टॉक' : 'Stock Remaining';
  static String get confirmButton => isHindi ? 'वाउचर पक्का करें (Confirm)' : 'Confirm & Save';
  static String get editButton => isHindi ? 'सुधारें (Edit)' : 'Edit Details';
  static String get cancelButton => isHindi ? 'रद्द करें (Cancel)' : 'Cancel';
  static String get editVoiceOrText => isHindi 
      ? 'बोलकर या लिखकर सुधारें' 
      : 'Edit by voice or typing';

  // Warnings
  static String get unknownPartyWarning => isHindi 
      ? 'नई पार्टी: यह नाम रजिस्टर में नहीं मिला' 
      : 'Unknown Party: Not found in directory';
  static String get stockAlertWarning => isHindi 
      ? 'कम स्टॉक चेतावनी: गोदाम में इतना माल नहीं है' 
      : 'Stock Alert: Not enough stock available';
  static String get unusualRateWarning => isHindi 
      ? 'असामान्य रेट: पुराना रेट कुछ और था' 
      : 'Unusual Rate: Differs significantly from standard rate';

  // Ask Screen
  static String get askAnything => isHindi 
      ? 'व्यापार का कुछ भी पूछें...' 
      : 'Ask anything about your business...';
  static String get askExamples => isHindi 
      ? 'उदाहरण: "रमेश भाई का कितना बाकी है?", "आज कितना सेल हुआ?", "PVC roll का स्टॉक कितना है?"' 
      : 'Try: "Ramesh Bhai ka kitna baaki hai?", "Aaj kitna sale hua?", "PVC roll ka stock kitna hai?"';

  // Voucher Types
  static String get typeSales => isHindi ? 'बिक्री (Sale)' : 'Sales';
  static String get typePurchase => isHindi ? 'खरीद (Purchase)' : 'Purchase';
  static String get typeReceipt => isHindi ? 'पेमेंट मिली (Receipt)' : 'Receipt';
  static String get typePayment => isHindi ? 'पेमेंट दी (Payment)' : 'Payment';

  // Invoice
  static String get invoiceTitle => isHindi ? 'टैक्स इनवॉइस' : 'Tax Invoice';
  static String get shareOnWhatsApp => isHindi ? 'WhatsApp पर भेजें' : 'Share on WhatsApp';
  static String get downloadPdf => isHindi ? 'PDF डाउनलोड करें' : 'Download Invoice PDF';
  static String get billedTo => isHindi ? 'क्रेता / Bill To' : 'Bill To';
  static String get taxBreakup => isHindi ? 'टैक्स विवरण' : 'Tax Breakup';
  static String get amountInWords => isHindi ? 'शब्दों में राशि' : 'Amount in Words';

  // Tally & Zoho
  static String get connectTallyZoho => isHindi ? 'टैली / जोहो कनेक्ट' : 'Connect Tally / Zoho';
  static String get tallyConnected => isHindi ? 'टैली एक्सपोर्ट तैयार (Mock)' : 'Tally Sync Ready (Mock)';
  static String get lastSync => isHindi ? 'आखिरी सिंक' : 'Last Synced';
}
