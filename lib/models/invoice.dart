import 'company.dart';
import 'client.dart';
import 'bank_account.dart';

class Invoice {
  final int id;
  final String invoiceNumber;
  final int userId;
  final int familyId;
  final int companyId;
  final int clientId;
  final int bankAccountId;
  final String issueDate;
  final String dueDate;
  final String currency;
  final String status;
  final bool isOverdue;
  final String vatRate;
  final String subtotal;
  final String vatAmount;
  final String total;
  final String? contractReference;
  final String? externalReference;
  final String? notes;
  final Company? company;
  final Client? client;
  final BankAccount? bankAccount;
  final List<InvoiceItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.userId,
    required this.familyId,
    required this.companyId,
    required this.clientId,
    required this.bankAccountId,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.status,
    required this.isOverdue,
    required this.vatRate,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    this.contractReference,
    this.externalReference,
    this.notes,
    this.company,
    this.client,
    this.bankAccount,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      userId: json['user_id'] as int,
      familyId: json['family_id'] as int,
      companyId: json['company_id'] as int,
      clientId: json['client_id'] as int,
      bankAccountId: json['bank_account_id'] as int,
      issueDate: json['issue_date'] as String,
      dueDate: json['due_date'] as String,
      currency: json['currency'] as String,
      status: json['status'] as String,
      isOverdue: json['is_overdue'] as bool,
      vatRate: json['vat_rate'] as String,
      subtotal: json['subtotal'] as String,
      vatAmount: json['vat_amount'] as String,
      total: json['total'] as String,
      contractReference: json['contract_reference'] as String?,
      externalReference: json['external_reference'] as String?,
      notes: json['notes'] as String?,
      company: json['company'] != null
          ? Company.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null
          ? Client.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      bankAccount: json['bank_account'] != null
          ? BankAccount.fromJson(json['bank_account'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class InvoiceItem {
  final int id;
  final int invoiceId;
  final String description;
  final String quantity;
  final String unitPrice;
  final String total;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as int,
      invoiceId: json['invoice_id'] as int,
      description: json['description'] as String,
      quantity: json['quantity'] as String,
      unitPrice: json['unit_price'] as String,
      total: json['total'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

class InvoiceListItem {
  final int id;
  final String invoiceNumber;
  final String issueDate;
  final String dueDate;
  final String status;
  final bool isOverdue;
  final String currency;
  final String companyName;
  final String clientName;
  final String subtotal;
  final String vatAmount;
  final String total;
  final int itemsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceListItem({
    required this.id,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.isOverdue,
    required this.currency,
    required this.companyName,
    required this.clientName,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
    required this.itemsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvoiceListItem.fromJson(Map<String, dynamic> json) {
    return InvoiceListItem(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      issueDate: json['issue_date'] as String,
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
      isOverdue: json['is_overdue'] as bool,
      currency: json['currency'] as String,
      companyName: json['company_name'] as String,
      clientName: json['client_name'] as String,
      subtotal: json['subtotal'] as String,
      vatAmount: json['vat_amount'] as String,
      total: json['total'] as String,
      itemsCount: json['items_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
