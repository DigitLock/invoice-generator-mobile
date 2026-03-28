class BankAccount {
  final int id;
  final int companyId;
  final String bankName;
  final String bankAddress;
  final String accountHolder;
  final String iban;
  final String swift;
  final String currency;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BankAccount({
    required this.id,
    required this.companyId,
    required this.bankName,
    required this.bankAddress,
    required this.accountHolder,
    required this.iban,
    required this.swift,
    required this.currency,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      bankName: json['bank_name'] as String,
      bankAddress: json['bank_address'] as String,
      accountHolder: json['account_holder'] as String,
      iban: json['iban'] as String,
      swift: json['swift'] as String,
      currency: json['currency'] as String,
      isDefault: json['is_default'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'bank_name': bankName,
        'bank_address': bankAddress,
        'account_holder': accountHolder,
        'iban': iban,
        'swift': swift,
        'currency': currency,
        'is_default': isDefault,
      };
}
