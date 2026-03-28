import 'package:dio/dio.dart';

import '../../models/company.dart';
import '../repositories/company_repository.dart';

class RemoteCompanyRepository implements CompanyRepository {
  final Dio _dio;

  RemoteCompanyRepository({required Dio dio}) : _dio = dio;

  @override
  Future<List<Company>> list() async {
    final response = await _dio.get('/companies');
    return (response.data as List<dynamic>)
        .map((e) => Company.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Company> getById(int id) async {
    final response = await _dio.get('/companies/$id');
    return Company.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Company> create(Map<String, dynamic> data) =>
      throw UnimplementedError('Company creation is read-only in online mode');

  @override
  Future<Company> update(int id, Map<String, dynamic> data) =>
      throw UnimplementedError('Company editing is read-only in online mode');
}
