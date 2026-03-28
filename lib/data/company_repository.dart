import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company.dart';
import 'api_client.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(dio: ref.watch(dioProvider));
});

class CompanyRepository {
  final Dio _dio;

  CompanyRepository({required Dio dio}) : _dio = dio;

  Future<List<Company>> list() async {
    final response = await _dio.get('/companies');
    return (response.data as List<dynamic>)
        .map((e) => Company.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Company> getById(int id) async {
    final response = await _dio.get('/companies/$id');
    return Company.fromJson(response.data as Map<String, dynamic>);
  }
}
