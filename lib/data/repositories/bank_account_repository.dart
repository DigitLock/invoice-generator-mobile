import '../../models/bank_account.dart';

abstract class BankAccountRepository {
  Future<List<BankAccount>> listByCompany(int companyId);
  Future<BankAccount> getById(int id);
  Future<BankAccount> create(int companyId, Map<String, dynamic> data);
  Future<BankAccount> update(int id, Map<String, dynamic> data);
  Future<void> delete(int id);
}
