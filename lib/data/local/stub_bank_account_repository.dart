import '../../models/bank_account.dart';
import '../repositories/bank_account_repository.dart';

/// Temporary stub for offline mode. Returns empty data.
/// Will be replaced by SQLite implementation in Stage 4.10.
class StubBankAccountRepository implements BankAccountRepository {
  @override
  Future<List<BankAccount>> listByCompany(int companyId) async => [];
}
