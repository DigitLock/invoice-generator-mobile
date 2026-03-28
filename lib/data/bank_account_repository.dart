import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bank_account.dart';
import 'api_client.dart';

final bankAccountRepositoryProvider = Provider<BankAccountRepository>((ref) {
  return BankAccountRepository(dio: ref.watch(dioProvider));
});

class BankAccountRepository {
  final Dio _dio;

  BankAccountRepository({required Dio dio}) : _dio = dio;

  Future<List<BankAccount>> listByCompany(int companyId) async {
    final response = await _dio.get('/companies/$companyId/bank-accounts');
    return (response.data as List<dynamic>)
        .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
