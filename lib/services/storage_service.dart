import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/voucher.dart';
import '../models/voucher_item.dart';

class StorageService {
  static const String _keyParties = 'ledgr_parties_v1';
  static const String _keyItems = 'ledgr_items_v1';
  static const String _keyVouchers = 'ledgr_vouchers_v1';
  static const String _keyInitialized = 'ledgr_initialized_v1';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    if (!prefs.containsKey(_keyInitialized)) {
      await service.seedDemoData();
      await prefs.setBool(_keyInitialized, true);
    }
    return service;
  }

  // PARTIES
  List<Party> loadParties() {
    final raw = _prefs.getString(_keyParties);
    if (raw == null || raw.isEmpty) return _getInitialParties();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((m) => Party.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return _getInitialParties();
    }
  }

  Future<void> saveParties(List<Party> parties) async {
    final raw = jsonEncode(parties.map((p) => p.toMap()).toList());
    await _prefs.setString(_keyParties, raw);
  }

  // ITEMS
  List<Item> loadItems() {
    final raw = _prefs.getString(_keyItems);
    if (raw == null || raw.isEmpty) return _getInitialItems();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((m) => Item.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return _getInitialItems();
    }
  }

  Future<void> saveItems(List<Item> items) async {
    final raw = jsonEncode(items.map((i) => i.toMap()).toList());
    await _prefs.setString(_keyItems, raw);
  }

  // VOUCHERS
  List<Voucher> loadVouchers() {
    final raw = _prefs.getString(_keyVouchers);
    if (raw == null || raw.isEmpty) return _getInitialVouchers();
    try {
      final list = jsonDecode(raw) as List;
      return list.map((m) => Voucher.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return _getInitialVouchers();
    }
  }

  Future<void> saveVouchers(List<Voucher> vouchers) async {
    final raw = jsonEncode(vouchers.map((v) => v.toMap()).toList());
    await _prefs.setString(_keyVouchers, raw);
  }

  Future<void> seedDemoData() async {
    await saveParties(_getInitialParties());
    await saveItems(_getInitialItems());
    await saveVouchers(_getInitialVouchers());
  }

  // INITIAL 8 PARTIES
  static List<Party> _getInitialParties() {
    return [
      Party(
        id: 'p1',
        name: 'Ramesh Traders',
        nicknames: ['Ramesh Bhai', 'Ramesh', 'Rameshji', 'रमेश भाई'],
        gstin: '27AABCR1122D1Z4',
        stateCode: '27',
        phone: '9820198201',
        address: 'Shop 14, APMC Market, Vashi, Navi Mumbai, Maharashtra',
        balance: 15000.0, // Amount to collect
        type: 'customer',
      ),
      Party(
        id: 'p2',
        name: 'Patel Hardware & Sanitary',
        nicknames: ['Patel Bhai', 'Patel Store', 'Patelji', 'पटेल भाई'],
        gstin: '24AADCP5544E1ZX',
        stateCode: '24', // Gujarat
        phone: '9825012345',
        address: 'Ring Road, Surat, Gujarat',
        balance: 38400.0,
        type: 'customer',
      ),
      Party(
        id: 'p3',
        name: 'Sharma Building Materials',
        nicknames: ['Sharmaji', 'Sharma Store', 'शर्मा जी'],
        gstin: '27AASPS9876G1ZA',
        stateCode: '27',
        phone: '9819033445',
        address: 'Station Road, Thane West, Maharashtra',
        balance: 7200.0,
        type: 'customer',
      ),
      Party(
        id: 'p4',
        name: 'Gupta Pipe House',
        nicknames: ['Guptaji', 'Gupta Traders', 'गुप्ता जी'],
        gstin: '27AAHFG3456K1Z9',
        stateCode: '27',
        phone: '9876543210',
        address: 'LBS Marg, Kurla West, Mumbai, Maharashtra',
        balance: -12500.0, // Payable
        type: 'both',
      ),
      Party(
        id: 'p5',
        name: 'Marathe Electricals',
        nicknames: ['Marathe Sahab', 'Marathe', 'मराठे साहेब'],
        gstin: '27AABCM6789P1Z2',
        stateCode: '27',
        phone: '9922001122',
        address: 'Shivaji Chowk, Pune, Maharashtra',
        balance: 22000.0,
        type: 'customer',
      ),
      Party(
        id: 'p6',
        name: 'Shree Ram Plumbing Works',
        nicknames: ['Shree Ram', 'Shriram Plumber', 'श्री राम'],
        gstin: '27AAACS1357Q1Z8',
        stateCode: '27',
        phone: '9422334455',
        address: 'MIDC Phase 2, Dombivli, Maharashtra',
        balance: 4500.0,
        type: 'customer',
      ),
      Party(
        id: 'p7',
        name: 'Krishna Sanitary & Tiles',
        nicknames: ['Krishna Bhai', 'Krishna Tiles', 'कृष्णा भाई'],
        gstin: '24AABCK2468R1Z1',
        stateCode: '24',
        phone: '9824056789',
        address: 'Morbi Ceramic Plaza, Morbi, Gujarat',
        balance: 56000.0,
        type: 'customer',
      ),
      Party(
        id: 'p8',
        name: 'Apex Wholesale Distributors',
        nicknames: ['Apex', 'Apex Supplier', 'एपेक्स'],
        gstin: '27AAAFA9999F1Z0',
        stateCode: '27',
        phone: '9167889900',
        address: 'Kalamboli Steel Market, Panvel, Maharashtra',
        balance: -85000.0,
        type: 'supplier',
      ),
    ];
  }

  // INITIAL 15 ITEMS
  static List<Item> _getInitialItems() {
    return [
      Item(
        id: 'i1',
        name: 'PVC Roll',
        hsn: '3917',
        gstRate: 18.0,
        defaultRate: 420.0,
        unit: 'roll',
        stock: 150.0,
        lowStockThreshold: 30.0,
      ),
      Item(
        id: 'i2',
        name: 'PVC Pipe 1 inch',
        hsn: '3917',
        gstRate: 18.0,
        defaultRate: 280.0,
        unit: 'meter',
        stock: 80.0,
        lowStockThreshold: 25.0,
      ),
      Item(
        id: 'i3',
        name: 'PVC Pipe 2 inch',
        hsn: '3917',
        gstRate: 18.0,
        defaultRate: 480.0,
        unit: 'meter',
        stock: 18.0, // Low stock alert!
        lowStockThreshold: 25.0,
      ),
      Item(
        id: 'i4',
        name: 'CPVC Elbow 25mm',
        hsn: '3917',
        gstRate: 18.0,
        defaultRate: 35.0,
        unit: 'piece',
        stock: 250.0,
        lowStockThreshold: 50.0,
      ),
      Item(
        id: 'i5',
        name: 'CPVC Tee 25mm',
        hsn: '3917',
        gstRate: 18.0,
        defaultRate: 45.0,
        unit: 'piece',
        stock: 190.0,
        lowStockThreshold: 40.0,
      ),
      Item(
        id: 'i6',
        name: 'PVC Solvent Cement 250ml',
        hsn: '3506',
        gstRate: 18.0,
        defaultRate: 160.0,
        unit: 'can',
        stock: 12.0, // Low stock alert!
        lowStockThreshold: 20.0,
      ),
      Item(
        id: 'i7',
        name: 'UltraTech Cement 50kg',
        hsn: '2523',
        gstRate: 28.0,
        defaultRate: 390.0,
        unit: 'bag',
        stock: 300.0,
        lowStockThreshold: 50.0,
      ),
      Item(
        id: 'i8',
        name: 'ACC Gold Cement 50kg',
        hsn: '2523',
        gstRate: 28.0,
        defaultRate: 375.0,
        unit: 'bag',
        stock: 210.0,
        lowStockThreshold: 50.0,
      ),
      Item(
        id: 'i9',
        name: 'Brass Ball Valve 1 inch',
        hsn: '8481',
        gstRate: 18.0,
        defaultRate: 320.0,
        unit: 'piece',
        stock: 45.0,
        lowStockThreshold: 15.0,
      ),
      Item(
        id: 'i10',
        name: 'Angle Cock Chrome',
        hsn: '8481',
        gstRate: 18.0,
        defaultRate: 260.0,
        unit: 'piece',
        stock: 65.0,
        lowStockThreshold: 20.0,
      ),
      Item(
        id: 'i11',
        name: 'PTFE Teflon Tape',
        hsn: '3919',
        gstRate: 18.0,
        defaultRate: 15.0,
        unit: 'roll',
        stock: 500.0,
        lowStockThreshold: 100.0,
      ),
      Item(
        id: 'i12',
        name: 'GI Nipple 1 inch',
        hsn: '7307',
        gstRate: 18.0,
        defaultRate: 45.0,
        unit: 'piece',
        stock: 15.0, // Low stock alert!
        lowStockThreshold: 30.0,
      ),
      Item(
        id: 'i13',
        name: 'Submersible Cable 2.5 sq mm',
        hsn: '8544',
        gstRate: 18.0,
        defaultRate: 85.0,
        unit: 'meter',
        stock: 350.0,
        lowStockThreshold: 50.0,
      ),
      Item(
        id: 'i14',
        name: 'Water Tank 500L Triple Layer',
        hsn: '3925',
        gstRate: 18.0,
        defaultRate: 3200.0,
        unit: 'piece',
        stock: 8.0,
        lowStockThreshold: 5.0,
      ),
      Item(
        id: 'i15',
        name: 'White Cement Birla 5kg',
        hsn: '2523',
        gstRate: 28.0,
        defaultRate: 130.0,
        unit: 'bag',
        stock: 70.0,
        lowStockThreshold: 20.0,
      ),
    ];
  }

  // INITIAL 20 VOUCHERS
  static List<Voucher> _getInitialVouchers() {
    final now = DateTime.now();
    return [
      // Today vouchers
      Voucher(
        id: 'v1',
        voucherNumber: 'SAL-2026-081',
        type: 'sales',
        date: now.subtract(const Duration(hours: 2)),
        partyId: 'p3',
        partyName: 'Sharma Building Materials',
        partyGstin: '27AASPS9876G1ZA',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i7',
            itemName: 'UltraTech Cement 50kg',
            hsn: '2523',
            quantity: 40,
            unit: 'bag',
            rate: 390.0,
            gstRate: 28.0,
            taxableAmount: 15600.0,
            cgst: 2184.0,
            sgst: 2184.0,
            igst: 0.0,
            total: 19968.0,
          ),
        ],
        subtotal: 15600.0,
        cgst: 2184.0,
        sgst: 2184.0,
        igst: 0.0,
        totalAmount: 19968.0,
        notes: 'Delivered at site 4',
      ),
      Voucher(
        id: 'v2',
        voucherNumber: 'REC-2026-042',
        type: 'receipt',
        date: now.subtract(const Duration(hours: 4)),
        partyId: 'p1',
        partyName: 'Ramesh Traders',
        partyGstin: '27AABCR1122D1Z4',
        partyStateCode: '27',
        items: [],
        subtotal: 10000.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 0.0,
        totalAmount: 10000.0,
        notes: 'Received via UPI / PhonePe',
      ),
      Voucher(
        id: 'v3',
        voucherNumber: 'SAL-2026-080',
        type: 'sales',
        date: now.subtract(const Duration(hours: 6)),
        partyId: 'p5',
        partyName: 'Marathe Electricals',
        partyGstin: '27AABCM6789P1Z2',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i13',
            itemName: 'Submersible Cable 2.5 sq mm',
            hsn: '8544',
            quantity: 100,
            unit: 'meter',
            rate: 85.0,
            gstRate: 18.0,
            taxableAmount: 8500.0,
            cgst: 765.0,
            sgst: 765.0,
            igst: 0.0,
            total: 10030.0,
          ),
        ],
        subtotal: 8500.0,
        cgst: 765.0,
        sgst: 765.0,
        igst: 0.0,
        totalAmount: 10030.0,
        notes: 'Urgent pump installation',
      ),

      // Yesterday and previous days (17 more vouchers)
      Voucher(
        id: 'v4',
        voucherNumber: 'SAL-2026-079',
        type: 'sales',
        date: now.subtract(const Duration(days: 1)),
        partyId: 'p2',
        partyName: 'Patel Hardware & Sanitary',
        partyGstin: '24AADCP5544E1ZX',
        partyStateCode: '24', // Gujarat (IGST)
        items: [
          VoucherItem(
            itemId: 'i9',
            itemName: 'Brass Ball Valve 1 inch',
            hsn: '8481',
            quantity: 20,
            unit: 'piece',
            rate: 320.0,
            gstRate: 18.0,
            taxableAmount: 6400.0,
            cgst: 0.0,
            sgst: 0.0,
            igst: 1152.0,
            total: 7552.0,
          ),
        ],
        subtotal: 6400.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 1152.0,
        totalAmount: 7552.0,
      ),
      Voucher(
        id: 'v5',
        voucherNumber: 'PUR-2026-031',
        type: 'purchase',
        date: now.subtract(const Duration(days: 1)),
        partyId: 'p8',
        partyName: 'Apex Wholesale Distributors',
        partyGstin: '27AAAFA9999F1Z0',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i1',
            itemName: 'PVC Roll',
            hsn: '3917',
            quantity: 100,
            unit: 'roll',
            rate: 360.0,
            gstRate: 18.0,
            taxableAmount: 36000.0,
            cgst: 3240.0,
            sgst: 3240.0,
            igst: 0.0,
            total: 42480.0,
          ),
        ],
        subtotal: 36000.0,
        cgst: 3240.0,
        sgst: 3240.0,
        igst: 0.0,
        totalAmount: 42480.0,
        notes: 'Inward lorry freight paid',
      ),
      Voucher(
        id: 'v6',
        voucherNumber: 'PAY-2026-015',
        type: 'payment',
        date: now.subtract(const Duration(days: 2)),
        partyId: 'p8',
        partyName: 'Apex Wholesale Distributors',
        partyGstin: '27AAAFA9999F1Z0',
        partyStateCode: '27',
        items: [],
        subtotal: 50000.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 0.0,
        totalAmount: 50000.0,
        notes: 'RTGS transfer ref #998822',
      ),
      Voucher(
        id: 'v7',
        voucherNumber: 'SAL-2026-078',
        type: 'sales',
        date: now.subtract(const Duration(days: 2)),
        partyId: 'p6',
        partyName: 'Shree Ram Plumbing Works',
        partyGstin: '27AAACS1357Q1Z8',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i4',
            itemName: 'CPVC Elbow 25mm',
            hsn: '3917',
            quantity: 50,
            unit: 'piece',
            rate: 35.0,
            gstRate: 18.0,
            taxableAmount: 1750.0,
            cgst: 157.5,
            sgst: 157.5,
            igst: 0.0,
            total: 2065.0,
          ),
          VoucherItem(
            itemId: 'i5',
            itemName: 'CPVC Tee 25mm',
            hsn: '3917',
            quantity: 30,
            unit: 'piece',
            rate: 45.0,
            gstRate: 18.0,
            taxableAmount: 1350.0,
            cgst: 121.5,
            sgst: 121.5,
            igst: 0.0,
            total: 1593.0,
          ),
        ],
        subtotal: 3100.0,
        cgst: 279.0,
        sgst: 279.0,
        igst: 0.0,
        totalAmount: 3658.0,
      ),
      Voucher(
        id: 'v8',
        voucherNumber: 'SAL-2026-077',
        type: 'sales',
        date: now.subtract(const Duration(days: 3)),
        partyId: 'p7',
        partyName: 'Krishna Sanitary & Tiles',
        partyGstin: '24AABCK2468R1Z1',
        partyStateCode: '24',
        items: [
          VoucherItem(
            itemId: 'i10',
            itemName: 'Angle Cock Chrome',
            hsn: '8481',
            quantity: 40,
            unit: 'piece',
            rate: 260.0,
            gstRate: 18.0,
            taxableAmount: 10400.0,
            cgst: 0.0,
            sgst: 0.0,
            igst: 1872.0,
            total: 12272.0,
          ),
        ],
        subtotal: 10400.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 1872.0,
        totalAmount: 12272.0,
      ),
      Voucher(
        id: 'v9',
        voucherNumber: 'REC-2026-041',
        type: 'receipt',
        date: now.subtract(const Duration(days: 3)),
        partyId: 'p7',
        partyName: 'Krishna Sanitary & Tiles',
        partyGstin: '24AABCK2468R1Z1',
        partyStateCode: '24',
        items: [],
        subtotal: 25000.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 0.0,
        totalAmount: 25000.0,
        notes: 'Cheque deposit #445511',
      ),
      Voucher(
        id: 'v10',
        voucherNumber: 'SAL-2026-076',
        type: 'sales',
        date: now.subtract(const Duration(days: 4)),
        partyId: 'p4',
        partyName: 'Gupta Pipe House',
        partyGstin: '27AAHFG3456K1Z9',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i2',
            itemName: 'PVC Pipe 1 inch',
            hsn: '3917',
            quantity: 30,
            unit: 'meter',
            rate: 280.0,
            gstRate: 18.0,
            taxableAmount: 8400.0,
            cgst: 756.0,
            sgst: 756.0,
            igst: 0.0,
            total: 9912.0,
          ),
        ],
        subtotal: 8400.0,
        cgst: 756.0,
        sgst: 756.0,
        igst: 0.0,
        totalAmount: 9912.0,
      ),
      Voucher(
        id: 'v11',
        voucherNumber: 'SAL-2026-075',
        type: 'sales',
        date: now.subtract(const Duration(days: 5)),
        partyId: 'p1',
        partyName: 'Ramesh Traders',
        partyGstin: '27AABCR1122D1Z4',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i11',
            itemName: 'PTFE Teflon Tape',
            hsn: '3919',
            quantity: 100,
            unit: 'roll',
            rate: 15.0,
            gstRate: 18.0,
            taxableAmount: 1500.0,
            cgst: 135.0,
            sgst: 135.0,
            igst: 0.0,
            total: 1770.0,
          ),
        ],
        subtotal: 1500.0,
        cgst: 135.0,
        sgst: 135.0,
        igst: 0.0,
        totalAmount: 1770.0,
      ),
      Voucher(
        id: 'v12',
        voucherNumber: 'PUR-2026-030',
        type: 'purchase',
        date: now.subtract(const Duration(days: 6)),
        partyId: 'p8',
        partyName: 'Apex Wholesale Distributors',
        partyGstin: '27AAAFA9999F1Z0',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i7',
            itemName: 'UltraTech Cement 50kg',
            hsn: '2523',
            quantity: 200,
            unit: 'bag',
            rate: 340.0,
            gstRate: 28.0,
            taxableAmount: 68000.0,
            cgst: 9520.0,
            sgst: 9520.0,
            igst: 0.0,
            total: 87040.0,
          ),
        ],
        subtotal: 68000.0,
        cgst: 9520.0,
        sgst: 9520.0,
        igst: 0.0,
        totalAmount: 87040.0,
      ),
      Voucher(
        id: 'v13',
        voucherNumber: 'SAL-2026-074',
        type: 'sales',
        date: now.subtract(const Duration(days: 7)),
        partyId: 'p3',
        partyName: 'Sharma Building Materials',
        partyGstin: '27AASPS9876G1ZA',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i14',
            itemName: 'Water Tank 500L Triple Layer',
            hsn: '3925',
            quantity: 2,
            unit: 'piece',
            rate: 3200.0,
            gstRate: 18.0,
            taxableAmount: 6400.0,
            cgst: 576.0,
            sgst: 576.0,
            igst: 0.0,
            total: 7552.0,
          ),
        ],
        subtotal: 6400.0,
        cgst: 576.0,
        sgst: 576.0,
        igst: 0.0,
        totalAmount: 7552.0,
      ),
      Voucher(
        id: 'v14',
        voucherNumber: 'REC-2026-040',
        type: 'receipt',
        date: now.subtract(const Duration(days: 8)),
        partyId: 'p2',
        partyName: 'Patel Hardware & Sanitary',
        partyGstin: '24AADCP5544E1ZX',
        partyStateCode: '24',
        items: [],
        subtotal: 20000.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 0.0,
        totalAmount: 20000.0,
        notes: 'IMPS payment received',
      ),
      Voucher(
        id: 'v15',
        voucherNumber: 'SAL-2026-073',
        type: 'sales',
        date: now.subtract(const Duration(days: 8)),
        partyId: 'p2',
        partyName: 'Patel Hardware & Sanitary',
        partyGstin: '24AADCP5544E1ZX',
        partyStateCode: '24',
        items: [
          VoucherItem(
            itemId: 'i15',
            itemName: 'White Cement Birla 5kg',
            hsn: '2523',
            quantity: 30,
            unit: 'bag',
            rate: 130.0,
            gstRate: 28.0,
            taxableAmount: 3900.0,
            cgst: 0.0,
            sgst: 0.0,
            igst: 1092.0,
            total: 4992.0,
          ),
        ],
        subtotal: 3900.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 1092.0,
        totalAmount: 4992.0,
      ),
      Voucher(
        id: 'v16',
        voucherNumber: 'SAL-2026-072',
        type: 'sales',
        date: now.subtract(const Duration(days: 9)),
        partyId: 'p5',
        partyName: 'Marathe Electricals',
        partyGstin: '27AABCM6789P1Z2',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i1',
            itemName: 'PVC Roll',
            hsn: '3917',
            quantity: 25,
            unit: 'roll',
            rate: 420.0,
            gstRate: 18.0,
            taxableAmount: 10500.0,
            cgst: 945.0,
            sgst: 945.0,
            igst: 0.0,
            total: 12390.0,
          ),
        ],
        subtotal: 10500.0,
        cgst: 945.0,
        sgst: 945.0,
        igst: 0.0,
        totalAmount: 12390.0,
      ),
      Voucher(
        id: 'v17',
        voucherNumber: 'PAY-2026-014',
        type: 'payment',
        date: now.subtract(const Duration(days: 10)),
        partyId: 'p4',
        partyName: 'Gupta Pipe House',
        partyGstin: '27AAHFG3456K1Z9',
        partyStateCode: '27',
        items: [],
        subtotal: 15000.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 0.0,
        totalAmount: 15000.0,
        notes: 'Monthly settlement part 1',
      ),
      Voucher(
        id: 'v18',
        voucherNumber: 'SAL-2026-071',
        type: 'sales',
        date: now.subtract(const Duration(days: 11)),
        partyId: 'p1',
        partyName: 'Ramesh Traders',
        partyGstin: '27AABCR1122D1Z4',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i6',
            itemName: 'PVC Solvent Cement 250ml',
            hsn: '3506',
            quantity: 10,
            unit: 'can',
            rate: 160.0,
            gstRate: 18.0,
            taxableAmount: 1600.0,
            cgst: 144.0,
            sgst: 144.0,
            igst: 0.0,
            total: 1888.0,
          ),
        ],
        subtotal: 1600.0,
        cgst: 144.0,
        sgst: 144.0,
        igst: 0.0,
        totalAmount: 1888.0,
      ),
      Voucher(
        id: 'v19',
        voucherNumber: 'SAL-2026-070',
        type: 'sales',
        date: now.subtract(const Duration(days: 12)),
        partyId: 'p6',
        partyName: 'Shree Ram Plumbing Works',
        partyGstin: '27AAACS1357Q1Z8',
        partyStateCode: '27',
        items: [
          VoucherItem(
            itemId: 'i12',
            itemName: 'GI Nipple 1 inch',
            hsn: '7307',
            quantity: 15,
            unit: 'piece',
            rate: 45.0,
            gstRate: 18.0,
            taxableAmount: 675.0,
            cgst: 60.75,
            sgst: 60.75,
            igst: 0.0,
            total: 796.5,
          ),
        ],
        subtotal: 675.0,
        cgst: 60.75,
        sgst: 60.75,
        igst: 0.0,
        totalAmount: 796.5,
      ),
      Voucher(
        id: 'v20',
        voucherNumber: 'SAL-2026-069',
        type: 'sales',
        date: now.subtract(const Duration(days: 13)),
        partyId: 'p7',
        partyName: 'Krishna Sanitary & Tiles',
        partyGstin: '24AABCK2468R1Z1',
        partyStateCode: '24',
        items: [
          VoucherItem(
            itemId: 'i8',
            itemName: 'ACC Gold Cement 50kg',
            hsn: '2523',
            quantity: 50,
            unit: 'bag',
            rate: 375.0,
            gstRate: 28.0,
            taxableAmount: 18750.0,
            cgst: 0.0,
            sgst: 0.0,
            igst: 5250.0,
            total: 24000.0,
          ),
        ],
        subtotal: 18750.0,
        cgst: 0.0,
        sgst: 0.0,
        igst: 5250.0,
        totalAmount: 24000.0,
      ),
    ];
  }
}
