import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/invoice_repository.dart';
import '../models/invoice.dart';
import '../models/pagination.dart';

final invoiceListProvider =
    FutureProvider.family<PaginatedResponse<InvoiceListItem>, InvoiceListParams>(
        (ref, params) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.list(
    page: params.page,
    pageSize: params.pageSize,
    status: params.status,
    search: params.search,
  );
});

final invoiceDetailProvider = FutureProvider.family<Invoice, int>((ref, id) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getById(id);
});

class InvoiceListParams {
  final int page;
  final int pageSize;
  final String? status;
  final String? search;

  const InvoiceListParams({
    this.page = 1,
    this.pageSize = 20,
    this.status,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceListParams &&
          page == other.page &&
          pageSize == other.pageSize &&
          status == other.status &&
          search == other.search;

  @override
  int get hashCode => Object.hash(page, pageSize, status, search);
}
