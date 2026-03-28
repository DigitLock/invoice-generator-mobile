import '../../models/company.dart';

abstract class CompanyRepository {
  Future<List<Company>> list();
  Future<Company> getById(int id);
  Future<Company> create(Map<String, dynamic> data);
  Future<Company> update(int id, Map<String, dynamic> data);
}
