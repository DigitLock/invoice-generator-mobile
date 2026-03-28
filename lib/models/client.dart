class Client {
  final int id;
  final String name;
  final String? contactPerson;
  final String? email;
  final String address;
  final String? vatNumber;
  final String? regNumber;
  final String? contractReference;
  final String? contractNotes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.name,
    this.contactPerson,
    this.email,
    required this.address,
    this.vatNumber,
    this.regNumber,
    this.contractReference,
    this.contractNotes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String,
      vatNumber: json['vat_number'] as String?,
      regNumber: json['reg_number'] as String?,
      contractReference: json['contract_reference'] as String?,
      contractNotes: json['contract_notes'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'contact_person': contactPerson,
        'email': email,
        'address': address,
        'vat_number': vatNumber,
        'reg_number': regNumber,
        'contract_reference': contractReference,
        'contract_notes': contractNotes,
        'status': status,
      };
}
