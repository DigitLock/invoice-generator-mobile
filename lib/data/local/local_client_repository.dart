import 'package:sqflite/sqflite.dart';

import '../../models/client.dart';
import '../repositories/client_repository.dart';

class LocalClientRepository implements ClientRepository {
  final Database _db;

  LocalClientRepository({required Database db}) : _db = db;

  @override
  Future<List<Client>> list({String? status}) async {
    final where = status != null ? 'status = ?' : null;
    final whereArgs = status != null ? [status] : null;
    final rows = await _db.query('clients',
        where: where, whereArgs: whereArgs, orderBy: 'name ASC');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Client> getById(int id) async {
    final rows = await _db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw Exception('Client not found');
    return _fromRow(rows.first);
  }

  @override
  Future<Client> create(Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    final row = {
      'name': data['name'],
      'contact_person': data['contact_person'],
      'email': data['email'],
      'address': data['address'],
      'vat_number': data['vat_number'],
      'reg_number': data['reg_number'],
      'contract_reference': data['contract_reference'],
      'contract_notes': data['contract_notes'],
      'status': data['status'] ?? 'active',
      'created_at': now,
      'updated_at': now,
    };
    final id = await _db.insert('clients', row);
    return getById(id);
  }

  @override
  Future<Client> update(int id, Map<String, dynamic> data) async {
    final row = {
      'name': data['name'],
      'contact_person': data['contact_person'],
      'email': data['email'],
      'address': data['address'],
      'vat_number': data['vat_number'],
      'reg_number': data['reg_number'],
      'contract_reference': data['contract_reference'],
      'contract_notes': data['contract_notes'],
      'status': data['status'] ?? 'active',
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _db.update('clients', row, where: 'id = ?', whereArgs: [id]);
    return getById(id);
  }

  Client _fromRow(Map<String, dynamic> row) {
    return Client(
      id: row['id'] as int,
      name: row['name'] as String,
      contactPerson: row['contact_person'] as String?,
      email: row['email'] as String?,
      address: row['address'] as String,
      vatNumber: row['vat_number'] as String?,
      regNumber: row['reg_number'] as String?,
      contractReference: row['contract_reference'] as String?,
      contractNotes: row['contract_notes'] as String?,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
