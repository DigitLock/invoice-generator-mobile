import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/invoice.dart';
import '../../models/pagination.dart';
import '../repositories/invoice_repository.dart';

class RemoteInvoiceRepository implements InvoiceRepository {
  final Dio _dio;

  RemoteInvoiceRepository({required Dio dio}) : _dio = dio;

  @override
  Future<PaginatedResponse<InvoiceListItem>> list({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    print('[RemoteInvoiceRepository] GET /invoices with params: page=$page, pageSize=$pageSize, status=$status');

    final response = await _dio.get('/invoices', queryParameters: queryParams);
    final data = response.data as Map<String, dynamic>;

    final invoices = (data['invoices'] as List<dynamic>)
        .map((e) => InvoiceListItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final pagination =
        PaginationMeta.fromJson(data['pagination'] as Map<String, dynamic>);

    return PaginatedResponse(items: invoices, pagination: pagination);
  }

  @override
  Future<Invoice> getById(int id) async {
    final response = await _dio.get('/invoices/$id');
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Invoice> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/invoices', data: data);
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Invoice> update(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/invoices/$id', data: data);
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    await _dio.delete('/invoices/$id');
  }

  @override
  Future<Invoice> changeStatus(int id, String status) async {
    final response = await _dio.patch(
      '/invoices/$id/status',
      data: {'status': status},
    );
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Invoice> toggleOverdue(int id, bool isOverdue) async {
    final response = await _dio.patch(
      '/invoices/$id/overdue',
      data: {'is_overdue': isOverdue},
    );
    return Invoice.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<String> downloadPdf(int id) async {
    final response = await _dio.get(
      '/invoices/$id/pdf',
      options: Options(responseType: ResponseType.bytes),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_$id.pdf');
    await file.writeAsBytes(response.data as List<int>);
    return file.path;
  }
}
