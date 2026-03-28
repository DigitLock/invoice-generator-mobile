class Company {
  final int id;
  final String name;
  final String contactPerson;
  final String address;
  final String? phone;
  final String? vatNumber;
  final String? regNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.address,
    this.phone,
    this.vatNumber,
    this.regNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      contactPerson: json['contact_person'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      vatNumber: json['vat_number'] as String?,
      regNumber: json['reg_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'contact_person': contactPerson,
        'address': address,
        'phone': phone,
        'vat_number': vatNumber,
        'reg_number': regNumber,
      };
}
