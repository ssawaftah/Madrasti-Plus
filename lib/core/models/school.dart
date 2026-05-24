class School {
  final String id;
  final String code;
  final String name;
  final String address;
  final String managerName;
  final String email;
  final String adminUserId;
  final DateTime createdAt;

  const School({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.managerName,
    required this.email,
    required this.adminUserId,
    required this.createdAt,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      adminUserId: json['adminUserId'] as String? ?? '',
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'address': address,
      'managerName': managerName,
      'email': email,
      'adminUserId': adminUserId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
