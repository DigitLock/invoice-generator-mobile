import 'package:dio/dio.dart';

import '../../models/bank_account.dart';
import '../repositories/bank_account_repository.dart';

class RemoteBankAccountRepository implements BankAccountRepository {
  final Dio _dio;

  RemoteBankAccountRepository({required Dio dio}) : _dio = dio;

  @override
  Future<List<BankAccount>> listByCompany(int companyId) async {
    final response = await _dio.get('/companies/$companyId/bank-accounts');
    return (response.data as List<dynamic>)
        .map((e) => BankAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BankAccount> create(int companyId, Map<String, dynamic> data) =>
      throw UnimplementedError('Bank account creation is read-only in online mode');
}
