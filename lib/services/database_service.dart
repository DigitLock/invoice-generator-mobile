import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

final databaseServiceProvider = FutureProvider<Database>((ref) async {
  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, 'invoice_generator.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      final batch = db.batch();

      batch.execute('''
        CREATE TABLE IF NOT EXISTS companies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          contact_person TEXT NOT NULL DEFAULT '',
          address TEXT NOT NULL,
          phone TEXT,
          vat_number TEXT,
          reg_number TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      batch.execute('''
        CREATE TABLE IF NOT EXISTS clients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          contact_person TEXT,
          email TEXT,
          address TEXT NOT NULL,
          vat_number TEXT,
          reg_number TEXT,
          contract_reference TEXT,
          contract_notes TEXT,
          status TEXT NOT NULL DEFAULT 'active',
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      batch.execute('''
        CREATE TABLE IF NOT EXISTS bank_accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          company_id INTEGER NOT NULL REFERENCES companies(id),
          bank_name TEXT NOT NULL,
          bank_address TEXT NOT NULL DEFAULT '',
          account_holder TEXT NOT NULL DEFAULT '',
          iban TEXT NOT NULL,
          swift TEXT NOT NULL,
          currency TEXT NOT NULL DEFAULT 'EUR',
          is_default INTEGER NOT NULL DEFAULT 0,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      batch.execute('''
        CREATE TABLE IF NOT EXISTS invoices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          company_id INTEGER NOT NULL,
          client_id INTEGER NOT NULL,
          bank_account_id INTEGER NOT NULL,
          invoice_number TEXT NOT NULL,
          issue_date TEXT NOT NULL,
          due_date TEXT NOT NULL,
          currency TEXT NOT NULL DEFAULT 'EUR',
          status TEXT NOT NULL DEFAULT 'draft',
          is_overdue INTEGER NOT NULL DEFAULT 0,
          vat_rate TEXT NOT NULL DEFAULT '0',
          subtotal TEXT,
          vat_amount TEXT,
          total TEXT,
          contract_reference TEXT,
          external_reference TEXT,
          notes TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      batch.execute('''
        CREATE TABLE IF NOT EXISTS invoice_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
          description TEXT NOT NULL,
          quantity TEXT NOT NULL DEFAULT '1',
          unit_price TEXT NOT NULL DEFAULT '0',
          total TEXT NOT NULL DEFAULT '0',
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      await batch.commit(noResult: true);
    },
  );
});
