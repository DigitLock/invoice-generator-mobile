import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/invoice.dart';
import '../models/pagination.dart';
import '../providers/auth_provider.dart';
import '../providers/invoice_provider.dart';
import '../widgets/invoice_card.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import '../widgets/ad_placeholder.dart';

const _filters = [
  _Filter(null, 'All'),
  _Filter('draft', 'Draft'),
  _Filter('sent', 'Sent'),
  _Filter('partially_paid', 'Partially Paid'),
  _Filter('paid', 'Paid'),
  _Filter('cancelled', 'Cancelled'),
];

class _Filter {
  final String? value;
  final String label;
  const _Filter(this.value, this.label);
}

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  String? _statusFilter;
  String? _searchQuery;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<InvoiceListItem> _allItems = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  InvoiceListParams get _params => InvoiceListParams(
        page: _currentPage,
        pageSize: 20,
        status: _statusFilter,
        search: _searchQuery,
      );

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoadingMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    final params = _params;
    ref.read(invoiceListProvider(params).future).then((response) {
      if (mounted) {
        setState(() {
          _allItems.addAll(response.items);
          _hasMore = response.pagination.hasNext;
          _isLoadingMore = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _currentPage--;
          _isLoadingMore = false;
        });
      }
    });
  }

  void _resetAndLoad() {
    setState(() {
      _allItems.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });
    // Invalidate page 1 to force reload
    ref.invalidate(invoiceListProvider(InvoiceListParams(
      page: 1,
      pageSize: 20,
      status: _statusFilter,
      search: _searchQuery,
    )));
  }

  void _onFilterChanged(String? status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    _resetAndLoad();
  }

  void _onSearchSubmitted(String query) {
    _searchQuery = query.isEmpty ? null : query;
    _resetAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      return const Scaffold(body: LoadingIndicator());
    }

    final firstPageParams = InvoiceListParams(
      page: 1,
      pageSize: 20,
      status: _statusFilter,
      search: _searchQuery,
    );
    final firstPage = ref.watch(invoiceListProvider(firstPageParams));

    return Scaffold(
      appBar: _showSearch
          ? AppBar(
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search invoices...',
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _onSearchSubmitted,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                  });
                  if (_searchQuery != null) {
                    _searchQuery = null;
                    _resetAndLoad();
                  }
                },
              ),
            )
          : AppBar(
              title: const Text('Invoices'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _showSearch = true),
                ),
              ],
            ),
      body: Column(
        children: [
          _FilterChips(
            selectedStatus: _statusFilter,
            onChanged: _onFilterChanged,
          ),
          Expanded(
            child: firstPage.when(
              loading: () => const LoadingIndicator(),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: _resetAndLoad,
              ),
              data: (response) {
                // Seed _allItems from first page if empty
                if (_allItems.isEmpty && response.items.isNotEmpty) {
                  // Use addPostFrameCallback to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _allItems.isEmpty) {
                      setState(() {
                        _allItems.addAll(response.items);
                        _hasMore = response.pagination.hasNext;
                      });
                    }
                  });
                  return _buildList(response.items, response.pagination);
                }
                final items = _allItems.isEmpty ? response.items : _allItems;
                return _buildList(items, response.pagination);
              },
            ),
          ),
          const AdPlaceholder(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/invoices/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<InvoiceListItem> items, PaginationMeta pagination) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            const Text('No invoices found'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.push('/invoices/new'),
              child: const Text('Create Invoice'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _allItems.clear();
        _currentPage = 1;
        _hasMore = true;
        return ref.refresh(invoiceListProvider(InvoiceListParams(
          page: 1,
          pageSize: 20,
          status: _statusFilter,
          search: _searchQuery,
        )).future);
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return InvoiceCard(invoice: items[index]);
        },
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedStatus, required this.onChanged});

  final String? selectedStatus;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedStatus == filter.value;
          return FilterChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) => onChanged(filter.value),
          );
        },
      ),
    );
  }
}
