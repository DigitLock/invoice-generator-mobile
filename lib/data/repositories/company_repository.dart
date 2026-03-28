import '../../models/company.dart';

abstract class CompanyRepository {
  Future<List<Company>> list();
  Future<Company> getById(int id);
}
