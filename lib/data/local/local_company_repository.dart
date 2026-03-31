import 'package:sqflite/sqflite.dart';

import '../../models/company.dart';
import '../repositories/company_repository.dart';

class LocalCompanyRepository implements CompanyRepository {
  final Database _db;

  LocalCompanyRepository({required Database db}) : _db = db;

  @override
  Future<List<Company>> list() async {
    final rows = await _db.query('companies', orderBy: 'name ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Company> getById(int id) async {
    final rows = await _db.query('companies', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw Exception('Company not found');
    return _fromRow(rows.first);
  }

  @override
  Future<Company> create(Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    final row = {
      'name': data['name'],
      'contact_person': data['contact_person'] ?? '',
      'address': data['address'],
      'phone': data['phone'],
      'vat_number': data['vat_number'],
      'reg_number': data['reg_number'],
      'created_at': now,
      'updated_at': now,
    };
    final id = await _db.insert('companies', row);
    return getById(id);
  }

  @override
  Future<Company> update(int id, Map<String, dynamic> data) async {
    final row = {
      'name': data['name'],
      'contact_person': data['contact_person'] ?? '',
      'address': data['address'],
      'phone': data['phone'],
      'vat_number': data['vat_number'],
      'reg_number': data['reg_number'],
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _db.update('companies', row, where: 'id = ?', whereArgs: [id]);
    return getById(id);
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('bank_accounts', where: 'company_id = ?', whereArgs: [id]);
    await _db.delete('companies', where: 'id = ?', whereArgs: [id]);
  }

  Company _fromRow(Map<String, dynamic> row) {
    return Company(
      id: row['id'] as int,
      name: row['name'] as String,
      contactPerson: (row['contact_person'] as String?) ?? '',
      address: row['address'] as String,
      phone: row['phone'] as String?,
      vatNumber: row['vat_number'] as String?,
      regNumber: row['reg_number'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
