import 'package:flutter/material.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/voucher.dart';
import '../services/storage_service.dart';
import '../core/utils/currency_formatter.dart';
import '../core/connectors/tally_connector.dart';

class LedgerProvider extends ChangeNotifier {
  final StorageService _storage;
  final TallyConnector _tallyConnector;

  List<Party> _parties = [];
  List<Item> _items = [];
  List<Voucher> _vouchers = [];

  LedgerProvider(this._storage, {TallyConnector? tallyConnector})
      : _tallyConnector = tallyConnector ?? MockTallyConnector() {
    loadData();
  }

  List<Party> get parties => List.unmodifiable(_parties);
  List<Item> get items => List.unmodifiable(_items);
  List<Voucher> get vouchers => List.unmodifiable(_vouchers);
  TallyConnector get tallyConnector => _tallyConnector;

  void loadData() {
    _parties = _storage.loadParties();
    _items = _storage.loadItems();
    _vouchers = _storage.loadVouchers();
    notifyListeners();
  }

  // --- SUMMARY CARDS METRICS ---

  /// Total sales for today
  double get todaySales {
    final now = DateTime.now();
    return _vouchers
        .where((v) =>
            v.type == 'sales' &&
            v.date.year == now.year &&
            v.date.month == now.month &&
            v.date.day == now.day)
        .fold(0.0, (sum, v) => sum + v.totalAmount);
  }

  /// Total amount to collect (positive balances of customers)
  double get toCollect {
    return _parties
        .where((p) => p.balance > 0)
        .fold(0.0, (sum, p) => sum + p.balance);
  }

  /// Total amount we need to pay (negative balances)
  double get toPay {
    return _parties
        .where((p) => p.balance < 0)
        .fold(0.0, (sum, p) => sum + p.balance.abs());
  }

  /// List of items with low stock
  List<Item> get lowStockItems {
    return _items.where((i) => i.isLowStock).toList();
  }

  // --- MATCHING HELPERS ---

  Party? findPartyById(String? id) {
    if (id == null) return null;
    try {
      return _parties.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Party? findPartyByNameOrNickname(String query) {
    if (query.trim().isEmpty) return null;
    final clean = query.trim().toLowerCase();

    // 1. Exact match on party name
    for (final p in _parties) {
      if (p.name.toLowerCase() == clean) return p;
    }

    // 2. Exact match on nicknames
    for (final p in _parties) {
      for (final nick in p.nicknames) {
        if (nick.toLowerCase() == clean) return p;
      }
    }

    // 3. Partial match
    for (final p in _parties) {
      if (p.name.toLowerCase().contains(clean) || clean.contains(p.name.toLowerCase())) {
        return p;
      }
      for (final nick in p.nicknames) {
        if (nick.toLowerCase().contains(clean) || clean.contains(nick.toLowerCase())) {
          return p;
        }
      }
    }

    return null;
  }

  Item? findItemById(String? id) {
    if (id == null) return null;
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Item? findItemByName(String query) {
    if (query.trim().isEmpty) return null;
    final clean = query.trim().toLowerCase();

    // 1. Exact match
    for (final i in _items) {
      if (i.name.toLowerCase() == clean) return i;
    }

    // 2. Partial match
    for (final i in _items) {
      if (i.name.toLowerCase().contains(clean) || clean.contains(i.name.toLowerCase())) {
        return i;
      }
    }

    return null;
  }

  // --- CONFIRM & SAVE VOUCHER ---

  Future<void> confirmVoucher(Voucher voucher) async {
    // 1. Add voucher to top of list
    _vouchers.insert(0, voucher);

    // 2. Update Stock & Party Balance
    if (voucher.type == 'sales') {
      // Reduce stock
      for (final vItem in voucher.items) {
        final item = findItemById(vItem.itemId);
        if (item != null) {
          item.stock -= vItem.quantity;
        }
      }
      // Increase party balance (party owes us money)
      final party = findPartyById(voucher.partyId);
      if (party != null) {
        party.balance += voucher.totalAmount;
      }
    } else if (voucher.type == 'purchase') {
      // Increase stock
      for (final vItem in voucher.items) {
        final item = findItemById(vItem.itemId);
        if (item != null) {
          item.stock += vItem.quantity;
        }
      }
      // Decrease party balance (we owe supplier)
      final party = findPartyById(voucher.partyId);
      if (party != null) {
        party.balance -= voucher.totalAmount;
      }
    } else if (voucher.type == 'receipt') {
      // Party paid us -> balance decreases
      final party = findPartyById(voucher.partyId);
      if (party != null) {
        party.balance -= voucher.totalAmount;
      }
    } else if (voucher.type == 'payment') {
      // We paid supplier -> balance increases towards zero
      final party = findPartyById(voucher.partyId);
      if (party != null) {
        party.balance += voucher.totalAmount;
      }
    }

    // 3. Trigger Mock Tally Export in background
    _tallyConnector.sendVoucherToTally(voucher);

    // 4. Persist all updates
    await _storage.saveVouchers(_vouchers);
    await _storage.saveItems(_items);
    await _storage.saveParties(_parties);

    notifyListeners();
  }

  // --- ASK Q&A GROUNDED STRICTLY IN DATABASE ---

  String answerUserQuery(String query, {bool isHindi = false}) {
    final clean = query.trim().toLowerCase();

    // 1. Party balance query: "Ramesh Bhai ka kitna baaki hai?", "Patel Bhai ka balance", etc.
    for (final p in _parties) {
      bool partyMentioned = false;
      if (clean.contains(p.name.toLowerCase())) partyMentioned = true;
      for (final nick in p.nicknames) {
        if (clean.contains(nick.toLowerCase())) partyMentioned = true;
      }

      if (partyMentioned && (clean.contains('baaki') || clean.contains('baki') || clean.contains('balance') || clean.contains('kitna') || clean.contains('hisab') || clean.contains('account'))) {
        final formattedBal = IndianCurrencyFormatter.format(p.balance.abs());
        if (p.balance > 0) {
          if (isHindi) {
            return '${p.name} से कुल $formattedBal लेना बाकी है।';
          } else {
            return '${p.name} has an outstanding balance of $formattedBal to collect from them.';
          }
        } else if (p.balance < 0) {
          if (isHindi) {
            return '${p.name} को कुल $formattedBal देना बाकी है।';
          } else {
            return '${p.name} is owed $formattedBal (we need to pay them).';
          }
        } else {
          if (isHindi) {
            return '${p.name} का पूरा हिसाब चुकता है (₹0 बाकी)।';
          } else {
            return '${p.name} has a clear balance (₹0 pending).';
          }
        }
      }
    }

    // 2. Item stock query: "PVC roll ka stock kitna hai?", "cement kitna bacha hai"
    for (final item in _items) {
      if (clean.contains(item.name.toLowerCase()) || 
          (item.name.toLowerCase() == 'pvc roll' && clean.contains('pvc roll')) ||
          (item.name.toLowerCase().contains('cement') && clean.contains('cement'))) {
        if (clean.contains('stock') || clean.contains('kitna') || clean.contains('bacha') || clean.contains('available') || clean.contains('maal')) {
          final stockStr = '${item.stock.toStringAsFixed(item.stock % 1 == 0 ? 0 : 1)} ${item.unit}';
          final lowAlert = item.isLowStock 
              ? (isHindi ? ' (चेतावनी: स्टॉक कम है!)' : ' (Alert: Stock is low!)')
              : '';
          if (isHindi) {
            return '${item.name} का गोदाम में वर्तमान स्टॉक $stockStr है$lowAlert।';
          } else {
            return 'Current stock for ${item.name} is $stockStr$lowAlert.';
          }
        }
      }
    }

    // 3. Sales today query: "Aaj kitna sale hua?", "today's sale", "aaj ki bikri"
    if (clean.contains('aaj') || clean.contains('today')) {
      if (clean.contains('sale') || clean.contains('bikri') || clean.contains('bika') || clean.contains('vyapar') || clean.contains('business')) {
        final todaySalesFormatted = IndianCurrencyFormatter.format(todaySales);
        final now = DateTime.now();
        final count = _vouchers.where((v) =>
            v.type == 'sales' &&
            v.date.year == now.year &&
            v.date.month == now.month &&
            v.date.day == now.day).length;
        if (isHindi) {
          return 'आज कुल $todaySalesFormatted की बिक्री हुई है ($count वाउचर)।';
        } else {
          return 'Today\'s total sales are $todaySalesFormatted across $count voucher(s).';
        }
      }
    }

    // 4. Overall to collect query: "Kul kitna lena baaki hai?", "total to collect"
    if (clean.contains('collect') || ((clean.contains('kul') || clean.contains('total')) && clean.contains('lena'))) {
      final collectFormatted = IndianCurrencyFormatter.format(toCollect);
      if (isHindi) {
        return 'बाजार से कुल $collectFormatted लेना बाकी है।';
      } else {
        return 'Total outstanding amount to collect is $collectFormatted.';
      }
    }

    // 5. Low stock query: "Kon kon se item kam hai?", "low stock"
    if (clean.contains('low stock') || (clean.contains('stock') && (clean.contains('kam') || clean.contains('khatam')))) {
      final lowList = lowStockItems;
      if (lowList.isEmpty) {
        return isHindi ? 'सभी आइटम का स्टॉक पर्याप्त है।' : 'All items have sufficient stock.';
      }
      final names = lowList.map((i) => '${i.name} (${i.stock} ${i.unit})').join(', ');
      if (isHindi) {
        return 'कम स्टॉक वाले आइटम: $names। इन्हें तुरंत ऑर्डर करें।';
      } else {
        return 'Low stock items needing reorder: $names.';
      }
    }

    // Fallback response with exact ledger database facts
    if (isHindi) {
      return 'माफ़ कीजिए, मुझे इस प्रश्न का सीधा रिकॉर्ड नहीं मिला। आप किसी पार्टी का नाम (जैसे "रमेश भाई का कितना बाकी है?"), सामान का स्टॉक (जैसे "PVC roll का स्टॉक कितना है?"), या आज की बिक्री पूछ सकते हैं।';
    } else {
      return 'I could not find exact matching records for that query. Try asking: "Ramesh Bhai ka kitna baaki hai?", "Aaj kitna sale hua?", or "PVC roll ka stock kitna hai?".';
    }
  }

  // --- RE-SEED DEMO DATA ---
  Future<void> resetDemoData() async {
    await _storage.seedDemoData();
    loadData();
  }
}
