import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';

class PartiesStockScreen extends StatefulWidget {
  const PartiesStockScreen({super.key});

  @override
  State<PartiesStockScreen> createState() => _PartiesStockScreenState();
}

class _PartiesStockScreenState extends State<PartiesStockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = Provider.of<LedgerProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final query = _searchController.text.trim().toLowerCase();

    // Filter parties
    final filteredParties = ledger.parties.where((p) {
      if (query.isEmpty) return true;
      if (p.name.toLowerCase().contains(query)) return true;
      if (p.gstin.toLowerCase().contains(query)) return true;
      return p.nicknames.any((n) => n.toLowerCase().contains(query));
    }).toList();

    // Filter items
    final filteredItems = ledger.items.where((i) {
      if (query.isEmpty) return true;
      if (i.name.toLowerCase().contains(query)) return true;
      return i.hsn.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tabPartiesStock),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: isHindi ? 'पार्टियां (${ledger.parties.length})' : 'Parties (${ledger.parties.length})'),
            Tab(text: isHindi ? 'स्टॉक आइटम (${ledger.items.length})' : 'Stock Items (${ledger.items.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 22),
                hintText: isHindi ? 'पार्टी, उपनाम, या आइटम खोजें...' : 'Search party, nickname or item...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),

          // TAB VIEWS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: PARTIES LIST
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredParties.length,
                  itemBuilder: (context, index) {
                    final party = filteredParties[index];
                    final isToCollect = party.balance > 0;
                    final isPayable = party.balance < 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    party.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      IndianCurrencyFormatter.format(party.balance.abs()),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isToCollect
                                            ? AppColors.primary
                                            : (isPayable ? AppColors.error : AppColors.textSecondary),
                                      ),
                                    ),
                                    Text(
                                      isToCollect
                                          ? (isHindi ? 'लेना बाकी' : 'To Collect')
                                          : (isPayable
                                              ? (isHindi ? 'देना बाकी' : 'To Pay')
                                              : (isHindi ? 'हिसाब चुकता' : 'Settled')),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isToCollect
                                            ? AppColors.primary
                                            : (isPayable ? AppColors.error : AppColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Nicknames Chips
                            if (party.nicknames.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: party.nicknames.map((nick) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.record_voice_over, size: 12, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          nick,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 6),

                            // GSTIN & Address
                            Text(
                              'GSTIN: ${party.gstin} • State: ${party.stateCode}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            Text(
                              'Ph: ${party.phone} • ${party.address}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // TAB 2: STOCK ITEMS LIST
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: item.isLowStock
                                  ? AppColors.warningBg
                                  : AppColors.primaryContainer,
                              child: Icon(
                                Icons.inventory_2,
                                color: item.isLowStock ? AppColors.warning : AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (item.isLowStock)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warningBg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.warning),
                                          ),
                                          child: Text(
                                            isHindi ? 'कम स्टॉक' : 'Low Stock',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF92400E),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'HSN ${item.hsn} • GST ${item.gstRate.toStringAsFixed(0)}% • Rate: ₹${item.defaultRate.toStringAsFixed(0)}/${item.unit}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.stock.toStringAsFixed(item.stock % 1 == 0 ? 0 : 1)} ${item.unit}',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: item.isLowStock ? AppColors.warning : AppColors.primary,
                                  ),
                                ),
                                Text(
                                  isHindi ? 'उपलब्ध' : 'in stock',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
