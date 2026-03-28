import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/client.dart';
import 'api_client.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(dio: ref.watch(dioProvider));
});

class ClientRepository {
  final Dio _dio;

  ClientRepository({required Dio dio}) : _dio = dio;

  Future<List<Client>> list({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get('/clients', queryParameters: queryParams);
    return (response.data as List<dynamic>)
        .map((e) => Client.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Client> getById(int id) async {
    final response = await _dio.get('/clients/$id');
    return Client.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Client> create(Map<String, dynamic> data) async {
    final response = await _dio.post('/clients', data: data);
    return Client.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Client> update(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/clients/$id', data: data);
    return Client.fromJson(response.data as Map<String, dynamic>);
  }
}
