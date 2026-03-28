import '../../models/bank_account.dart';

abstract class BankAccountRepository {
  Future<List<BankAccount>> listByCompany(int companyId);
}
