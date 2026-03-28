import '../../models/invoice.dart';
import '../../models/pagination.dart';

abstract class InvoiceRepository {
  Future<PaginatedResponse<InvoiceListItem>> list({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
  });
  Future<Invoice> getById(int id);
  Future<Invoice> create(Map<String, dynamic> data);
  Future<Invoice> update(int id, Map<String, dynamic> data);
  Future<void> delete(int id);
  Future<Invoice> changeStatus(int id, String status);
  Future<Invoice> toggleOverdue(int id, bool isOverdue);
  Future<String> downloadPdf(int id);
}
