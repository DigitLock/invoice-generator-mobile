import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/invoice.dart';
import '../../models/company.dart';
import '../../models/client.dart';
import '../../models/bank_account.dart';
import '../../models/pagination.dart';
import '../../services/local_pdf_service.dart';
import '../repositories/invoice_repository.dart';

const _allowedTransitions = {
  'draft': ['sent', 'cancelled'],
  'sent': ['partially_paid', 'paid', 'cancelled'],
  'partially_paid': ['paid', 'cancelled'],
};

class LocalInvoiceRepository implements InvoiceRepository {
  final Database _db;
  final LocalPdfService _pdfService;

  LocalInvoiceRepository({required Database db, required LocalPdfService pdfService})
      : _db = db,
        _pdfService = pdfService;

  @override
  Future<PaginatedResponse<InvoiceListItem>> list({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
  }) async {
    final where = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      where.add('i.status = ?');
      args.add(status);
    }
    if (search != null && search.isNotEmpty) {
      where.add('i.invoice_number LIKE ?');
      args.add('%$search%');
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';
    final offset = (page - 1) * pageSize;

    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM invoices i $whereClause',
      args,
    );
    final totalItems = Sqflite.firstIntValue(countResult) ?? 0;
    final totalPages = (totalItems / pageSize).ceil();

    final rows = await _db.rawQuery('''
      SELECT i.*,
             c.name AS company_name,
             cl.name AS client_name,
             (SELECT COUNT(*) FROM invoice_items WHERE invoice_id = i.id) AS items_count
      FROM invoices i
      LEFT JOIN companies c ON c.id = i.company_id
      LEFT JOIN clients cl ON cl.id = i.client_id
      $whereClause
      ORDER BY i.created_at DESC
      LIMIT ? OFFSET ?
    ''', [...args, pageSize, offset]);

    final items = rows.map((row) => InvoiceListItem(
          id: row['id'] as int,
          invoiceNumber: row['invoice_number'] as String,
          issueDate: row['issue_date'] as String,
          dueDate: row['due_date'] as String?,
          status: row['status'] as String,
          isOverdue: (row['is_overdue'] as int) == 1,
          currency: row['currency'] as String,
          companyName: (row['company_name'] as String?) ?? '',
          clientName: (row['client_name'] as String?) ?? '',
          subtotal: (row['subtotal'] as String?) ?? '0.00',
          vatAmount: (row['vat_amount'] as String?) ?? '0.00',
          total: (row['total'] as String?) ?? '0.00',
          itemsCount: (row['items_count'] as int?) ?? 0,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
        )).toList();

    return PaginatedResponse(
      items: items,
      pagination: PaginationMeta(
        page: page,
        pageSize: pageSize,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNext: page < totalPages,
        hasPrevious: page > 1,
      ),
    );
  }

  @override
  Future<Invoice> getById(int id) async {
    final rows = await _db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw Exception('Invoice not found');
    final row = rows.first;

    final companyId = row['company_id'] as int;
    final clientId = row['client_id'] as int;
    final bankAccountId = row['bank_account_id'] as int;

    final companyRows = await _db.query('companies', where: 'id = ?', whereArgs: [companyId]);
    final clientRows = await _db.query('clients', where: 'id = ?', whereArgs: [clientId]);
    final bankRows = await _db.query('bank_accounts', where: 'id = ?', whereArgs: [bankAccountId]);
    final itemRows = await _db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [id], orderBy: 'id ASC');

    return Invoice(
      id: row['id'] as int,
      invoiceNumber: row['invoice_number'] as String,
      userId: '',
      familyId: '',
      companyId: companyId,
      clientId: clientId,
      bankAccountId: bankAccountId,
      issueDate: row['issue_date'] as String,
      dueDate: row['due_date'] as String?,
      currency: row['currency'] as String,
      status: row['status'] as String,
      isOverdue: (row['is_overdue'] as int) == 1,
      vatRate: (row['vat_rate'] as String?) ?? '0',
      subtotal: (row['subtotal'] as String?) ?? '0.00',
      vatAmount: (row['vat_amount'] as String?) ?? '0.00',
      total: (row['total'] as String?) ?? '0.00',
      contractReference: row['contract_reference'] as String?,
      externalReference: row['external_reference'] as String?,
      notes: row['notes'] as String?,
      company: companyRows.isNotEmpty ? _companyFromRow(companyRows.first) : null,
      client: clientRows.isNotEmpty ? _clientFromRow(clientRows.first) : null,
      bankAccount: bankRows.isNotEmpty ? _bankAccountFromRow(bankRows.first) : null,
      items: itemRows.map(_itemFromRow).toList(),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Future<Invoice> create(Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    final items = (data['items'] as List<dynamic>?) ?? [];
    final vatRate = double.tryParse(data['vat_rate']?.toString() ?? '0') ?? 0;

    // Calculate totals
    double subtotal = 0;
    for (final item in items) {
      final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
      subtotal += (qty * price * 100).roundToDouble() / 100;
    }
    final vatAmount = (subtotal * vatRate / 100 * 100).roundToDouble() / 100;
    final total = subtotal + vatAmount;

    // Generate invoice number
    final invoiceNumber = await _generateNumber(data['issue_date'] as String);

    final id = await _db.insert('invoices', {
      'company_id': data['company_id'],
      'client_id': data['client_id'],
      'bank_account_id': data['bank_account_id'],
      'invoice_number': invoiceNumber,
      'issue_date': data['issue_date'],
      'due_date': data['due_date'],
      'currency': data['currency'] ?? 'EUR',
      'vat_rate': data['vat_rate']?.toString() ?? '0',
      'subtotal': subtotal.toStringAsFixed(2),
      'vat_amount': vatAmount.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
      'contract_reference': data['contract_reference'],
      'external_reference': data['external_reference'],
      'notes': data['notes'],
      'status': 'draft',
      'is_overdue': 0,
      'created_at': now,
      'updated_at': now,
    });

    for (final item in items) {
      final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
      final itemTotal = (qty * price * 100).roundToDouble() / 100;

      await _db.insert('invoice_items', {
        'invoice_id': id,
        'description': item['description'],
        'quantity': item['quantity']?.toString() ?? '1',
        'unit_price': item['unit_price']?.toString() ?? '0',
        'total': itemTotal.toStringAsFixed(2),
        'created_at': now,
        'updated_at': now,
      });
    }

    return getById(id);
  }

  @override
  Future<Invoice> update(int id, Map<String, dynamic> data) async {
    final now = DateTime.now().toIso8601String();
    final items = (data['items'] as List<dynamic>?) ?? [];
    final vatRate = double.tryParse(data['vat_rate']?.toString() ?? '0') ?? 0;

    double subtotal = 0;
    for (final item in items) {
      final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
      subtotal += (qty * price * 100).roundToDouble() / 100;
    }
    final vatAmount = (subtotal * vatRate / 100 * 100).roundToDouble() / 100;
    final total = subtotal + vatAmount;

    await _db.update('invoices', {
      'company_id': data['company_id'],
      'client_id': data['client_id'],
      'bank_account_id': data['bank_account_id'],
      'invoice_number': data['invoice_number'],
      'issue_date': data['issue_date'],
      'due_date': data['due_date'],
      'currency': data['currency'] ?? 'EUR',
      'vat_rate': data['vat_rate']?.toString() ?? '0',
      'subtotal': subtotal.toStringAsFixed(2),
      'vat_amount': vatAmount.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
      'contract_reference': data['contract_reference'],
      'external_reference': data['external_reference'],
      'notes': data['notes'],
      'updated_at': now,
    }, where: 'id = ?', whereArgs: [id]);

    // Replace items
    await _db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    for (final item in items) {
      final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      final price = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
      final itemTotal = (qty * price * 100).roundToDouble() / 100;

      await _db.insert('invoice_items', {
        'invoice_id': id,
        'description': item['description'],
        'quantity': item['quantity']?.toString() ?? '1',
        'unit_price': item['unit_price']?.toString() ?? '0',
        'total': itemTotal.toStringAsFixed(2),
        'created_at': now,
        'updated_at': now,
      });
    }

    return getById(id);
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    await _db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Invoice> changeStatus(int id, String status) async {
    final rows = await _db.query('invoices', where: 'id = ?', whereArgs: [id], columns: ['status']);
    if (rows.isEmpty) throw Exception('Invoice not found');
    final current = rows.first['status'] as String;

    final allowed = _allowedTransitions[current];
    if (allowed == null || !allowed.contains(status)) {
      throw Exception('Transition from "$current" to "$status" is not allowed');
    }

    await _db.update('invoices', {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);

    return getById(id);
  }

  @override
  Future<Invoice> toggleOverdue(int id, bool isOverdue) async {
    final rows = await _db.query('invoices', where: 'id = ?', whereArgs: [id], columns: ['status']);
    if (rows.isEmpty) throw Exception('Invoice not found');
    if (rows.first['status'] == 'draft') {
      throw Exception('Overdue flag cannot be set on draft invoices');
    }

    await _db.update('invoices', {
      'is_overdue': isOverdue ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [id]);

    return getById(id);
  }

  @override
  Future<String> downloadPdf(int id) async {
    final invoice = await getById(id);
    return _pdfService.generatePdf(invoice);
  }

  Future<String> _generateNumber(String issueDate) async {
    final date = DateTime.tryParse(issueDate) ?? DateTime.now();
    final dateStr = DateFormat('ddMMyyyy').format(date);
    final prefix = 'INV-$dateStr-';

    final result = await _db.rawQuery(
      "SELECT COUNT(*) as cnt FROM invoices WHERE invoice_number LIKE ?",
      ['$prefix%'],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return '$prefix${(count + 1).toString().padLeft(3, '0')}';
  }

  Company _companyFromRow(Map<String, dynamic> row) {
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

  Client _clientFromRow(Map<String, dynamic> row) {
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

  BankAccount _bankAccountFromRow(Map<String, dynamic> row) {
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

  InvoiceItem _itemFromRow(Map<String, dynamic> row) {
    return InvoiceItem(
      id: row['id'] as int,
      invoiceId: row['invoice_id'] as int,
      description: row['description'] as String,
      quantity: row['quantity'] as String,
      unitPrice: row['unit_price'] as String,
      total: row['total'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
