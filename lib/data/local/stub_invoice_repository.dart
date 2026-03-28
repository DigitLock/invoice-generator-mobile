import '../../models/invoice.dart';
import '../../models/pagination.dart';
import '../repositories/invoice_repository.dart';

/// Temporary stub for offline mode. Returns empty data.
/// Will be replaced by SQLite implementation in Stage 4.10.
class StubInvoiceRepository implements InvoiceRepository {
  @override
  Future<PaginatedResponse<InvoiceListItem>> list({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
  }) async {
    return const PaginatedResponse(
      items: [],
      pagination: PaginationMeta(
        page: 1,
        pageSize: 20,
        totalItems: 0,
        totalPages: 0,
        hasNext: false,
        hasPrevious: false,
      ),
    );
  }

  @override
  Future<Invoice> getById(int id) =>
      throw UnimplementedError('Offline invoice detail not yet implemented');

  @override
  Future<Invoice> create(Map<String, dynamic> data) =>
      throw UnimplementedError('Offline invoice create not yet implemented');

  @override
  Future<Invoice> update(int id, Map<String, dynamic> data) =>
      throw UnimplementedError('Offline invoice update not yet implemented');

  @override
  Future<void> delete(int id) =>
      throw UnimplementedError('Offline invoice delete not yet implemented');

  @override
  Future<Invoice> changeStatus(int id, String status) =>
      throw UnimplementedError('Offline status change not yet implemented');

  @override
  Future<Invoice> toggleOverdue(int id, bool isOverdue) =>
      throw UnimplementedError('Offline overdue toggle not yet implemented');

  @override
  Future<String> downloadPdf(int id) =>
      throw UnimplementedError('Offline PDF not yet implemented');
}
