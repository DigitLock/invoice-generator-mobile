import '../../models/bank_account.dart';

abstract class BankAccountRepository {
  Future<List<BankAccount>> listByCompany(int companyId);
  Future<BankAccount> create(int companyId, Map<String, dynamic> data);
}
