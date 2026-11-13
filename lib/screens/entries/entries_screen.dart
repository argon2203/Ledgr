import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/ledger_provider.dart';
import '../../providers/settings_provider.dart';
import 'voucher_detail_screen.dart';

class EntriesScreen extends StatefulWidget {
  const EntriesScreen({super.key});

  @override
  State<EntriesScreen> createState() => _EntriesScreenState();
}

class _EntriesScreenState extends State<EntriesScreen> {
  String _selectedType = 'all'; // all, sales, purchase, receipt, payment
  final String _selectedDateFilter = 'all'; // all, today, week, month
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledger = Provider.of<LedgerProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isHindi = settings.isHindi;
    final dateFormat = DateFormat('dd MMM yyyy');

    final now = DateTime.now();
    final searchQuery = _searchController.text.trim().toLowerCase();

    final filteredVouchers = ledger.vouchers.where((v) {
      // 1. Type filter
      if (_selectedType != 'all' && v.type.toLowerCase() != _selectedType) {
        return false;
      }
      // 2. Date filter
      if (_selectedDateFilter == 'today') {
        if (v.date.year != now.year || v.date.month != now.month || v.date.day != now.day) {
          return false;
        }
      } else if (_selectedDateFilter == 'week') {
        if (now.difference(v.date).inDays > 7) {
          return false;
        }
      } else if (_selectedDateFilter == 'month') {
        if (now.difference(v.date).inDays > 30) {
          return false;
        }
      }
      // 3. Search query
      if (searchQuery.isNotEmpty) {
        final matchesParty = v.partyName.toLowerCase().contains(searchQuery);
        final matchesNumber = v.voucherNumber.toLowerCase().contains(searchQuery);
        final matchesItem = v.items.any((i) => i.itemName.toLowerCase().contains(searchQuery));
        if (!matchesParty && !matchesNumber && !matchesItem) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tabEntries),
      ),
      body: Column(
        children: [
          // SEARCH & FILTER HEADER
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 22),
                    hintText: isHindi ? 'पार्टी या वाउचर नंबर खोजें...' : 'Search party or voucher #...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() => _searchController.clear());
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),

                // Type Filter Chips (Sales, Purchase, Receipt, Payment)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', isHindi ? 'सभी (All)' : 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('sales', AppStrings.typeSales),
                      const SizedBox(width: 8),
                      _buildFilterChip('purchase', AppStrings.typePurchase),
                      const SizedBox(width: 8),
                      _buildFilterChip('receipt', AppStrings.typeReceipt),
                      const SizedBox(width: 8),
                      _buildFilterChip('payment', AppStrings.typePayment),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // VOUCHERS LIST
          Expanded(
            child: filteredVouchers.isEmpty
                ? Center(
                    child: Text(
                      isHindi ? 'कोई वाउचर नहीं मिला।' : 'No vouchers found.',
                      style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredVouchers.length,
                    itemBuilder: (context, index) {
                      final v = filteredVouchers[index];
                      final isSale = v.type == 'sales';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VoucherDetailScreen(voucher: v),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSale
                                      ? AppColors.primaryContainer
                                      : Colors.orange.shade50,
                                  child: Icon(
                                    isSale ? Icons.arrow_outward : Icons.arrow_downward,
                                    size: 20,
                                    color: isSale ? AppColors.primary : Colors.orange.shade800,
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${v.voucherNumber} • ${dateFormat.format(v.date)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (v.items.isNotEmpty)
                                        Text(
                                          v.items.map((i) => '${i.quantity} ${i.unit} ${i.itemName}').join(', '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      IndianCurrencyFormatter.format(v.totalAmount),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isSale ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSale ? AppColors.primaryContainer : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        v.type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSale ? AppColors.primary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String typeKey, String label) {
    final isSelected = _selectedType == typeKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = typeKey);
        }
      },
    );
  }
}
