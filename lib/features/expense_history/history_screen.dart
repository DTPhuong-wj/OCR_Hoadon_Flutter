import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';
import '../expense_detail/detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final filterState = ref.watch(expenseFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Chi Tiêu'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sắp xếp',
            onSelected: (val) {
              ref.read(expenseFilterProvider.notifier).state = filterState
                  .copyWith(sortBy: val);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'newest', child: Text('Mới nhất trước')),
              PopupMenuItem(value: 'oldest', child: Text('Cũ nhất trước')),
              PopupMenuItem(
                value: 'amount_high',
                child: Text('Số tiền từ cao -> thấp'),
              ),
              PopupMenuItem(
                value: 'amount_low',
                child: Text('Số tiền từ thấp -> cao'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cửa hàng, nội dung...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(expenseFilterProvider.notifier).state =
                                  filterState.copyWith(query: '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (query) {
                    ref.read(expenseFilterProvider.notifier).state = filterState
                        .copyWith(query: query);
                  },
                ),

                const SizedBox(height: 10),

                // Horizontal Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filter Dropdown Chip
                      PopupMenuButton<String>(
                        onSelected: (catId) {
                          ref.read(expenseFilterProvider.notifier).state =
                              filterState.copyWith(category: catId);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('Tất cả danh mục'),
                          ),
                          ...AppConstants.categories.map(
                            (c) => PopupMenuItem(
                              value: c.id,
                              child: Text(c.label),
                            ),
                          ),
                        ],
                        child: Chip(
                          avatar: const Icon(Icons.category, size: 16),
                          label: Text(
                            filterState.category == 'all'
                                ? 'Danh mục: Tất cả'
                                : 'Danh mục: ${AppConstants.getCategoryInfo(filterState.category).label}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: filterState.category != 'all'
                              ? AppColors.primaryContainer
                              : AppColors.surfaceVariant,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Source Filter Dropdown Chip
                      PopupMenuButton<String>(
                        onSelected: (src) {
                          ref.read(expenseFilterProvider.notifier).state =
                              filterState.copyWith(sourceType: src);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'all',
                            child: Text('Tất cả nguồn'),
                          ),
                          PopupMenuItem(
                            value: AppConstants.sourceReceiptOcr,
                            child: Text('Quét Hóa Đơn'),
                          ),
                          PopupMenuItem(
                            value: AppConstants.sourceQrCode,
                            child: Text('Mã QR Thanh Toán'),
                          ),
                          PopupMenuItem(
                            value: AppConstants.sourcePaymentScreenshotOcr,
                            child: Text('Ảnh Chuyển Khoản'),
                          ),
                          PopupMenuItem(
                            value: AppConstants.sourceManual,
                            child: Text('Thủ Công'),
                          ),
                        ],
                        child: Chip(
                          avatar: const Icon(Icons.source, size: 16),
                          label: Text(
                            filterState.sourceType == 'all'
                                ? 'Nguồn: Tất cả'
                                : 'Nguồn: ${AppConstants.getSourceLabel(filterState.sourceType)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: filterState.sourceType != 'all'
                              ? AppColors.primaryContainer
                              : AppColors.surfaceVariant,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Date Range Picker Chip
                      ActionChip(
                        avatar: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          filterState.startDate != null
                              ? '${DateFormatter.formatDate(filterState.startDate!)} - ${filterState.endDate != null ? DateFormatter.formatDate(filterState.endDate!) : ""}'
                              : 'Thời gian: Tất cả',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (range != null) {
                            ref
                                .read(expenseFilterProvider.notifier)
                                .state = filterState.copyWith(
                              startDate: range.start,
                              endDate: range.end,
                            );
                          }
                        },
                      ),

                      if (filterState.category != 'all' ||
                          filterState.sourceType != 'all' ||
                          filterState.startDate != null ||
                          filterState.query.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.filter_alt_off,
                            color: AppColors.error,
                          ),
                          tooltip: 'Xóa bộ lọc',
                          onPressed: () {
                            _searchController.clear();
                            ref.read(expenseFilterProvider.notifier).state =
                                const ExpenseFilterState();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Expenses List
          Expanded(
            child: filteredExpenses.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'Không tìm thấy chi tiêu nào',
                    description: 'Không có kết quả khớp với tìm kiếm hoặc bộ lọc hiện tại.',
                    actionLabel: 'Xóa bộ lọc',
                    onActionPressed: () {
                      _searchController.clear();
                      ref.read(expenseFilterProvider.notifier).state =
                          const ExpenseFilterState();
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final item = filteredExpenses[index];
                      return ExpenseCard(
                        expense: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(expenseId: item.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
