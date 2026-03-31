import 'package:sqflite/sqflite.dart';

import '../../models/bank_account.dart';
import '../repositories/bank_account_repository.dart';

class LocalBankAccountRepository implements BankAccountRepository {
  final Database _db;

  LocalBankAccountRepository({required Database db}) : _db = db;

  @override
  Future<List<BankAccount>> listByCompany(int companyId) async {
    final rows = await _db.query('bank_accounts',
        where: 'company_id = ?', whereArgs: [companyId]);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<BankAccount> create(int companyId, Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    final row = {
      'company_id': companyId,
      'bank_name': data['bank_name'],
      'bank_address': data['bank_address'] ?? '',
      'account_holder': data['account_holder'] ?? '',
      'iban': data['iban'],
      'swift': data['swift'],
      'currency': data['currency'] ?? 'EUR',
      'is_default': (data['is_default'] == true) ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
    final id = await _db.insert('bank_accounts', row);
    final rows =
        await _db.query('bank_accounts', where: 'id = ?', whereArgs: [id]);
    return _fromRow(rows.first);
  }

  @override
  Future<BankAccount> getById(int id) async {
    final rows =
        await _db.query('bank_accounts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw Exception('Bank account not found');
    return _fromRow(rows.first);
  }

  @override
  Future<BankAccount> update(int id, Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    final row = {
      'bank_name': data['bank_name'],
      'bank_address': data['bank_address'] ?? '',
      'account_holder': data['account_holder'] ?? '',
      'iban': data['iban'],
      'swift': data['swift'],
      'currency': data['currency'] ?? 'EUR',
      'is_default': (data['is_default'] == true) ? 1 : 0,
      'updated_at': now,
    };
    await _db.update('bank_accounts', row, where: 'id = ?', whereArgs: [id]);
    return getById(id);
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('bank_accounts', where: 'id = ?', whereArgs: [id]);
  }

  BankAccount _fromRow(Map<String, dynamic> row) {
    return BankAccount(
      id: row['id'] as int,
      companyId: row['company_id'] as int,
      bankName: row['bank_name'] as String,
      bankAddress: (row['bank_address'] as String?) ?? '',
      accountHolder: (row['account_holder'] as String?) ?? '',
      iban: row['iban'] as String,
      swift: row['swift'] as String,
      currency: row['currency'] as String,
      isDefault: (row['is_default'] as int) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
