import '../../models/company.dart';
import '../repositories/company_repository.dart';

/// Temporary stub for offline mode. Returns empty data.
/// Will be replaced by SQLite implementation in Stage 4.10.
class StubCompanyRepository implements CompanyRepository {
  @override
  Future<List<Company>> list() async => [];

  @override
  Future<Company> getById(int id) =>
      throw UnimplementedError('Offline company detail not yet implemented');
}
