class School {
  final String id;
  final String code;
  final String name;
  final String governorate;
  final String address;
  final String phone;
  final String type;
  final String educationStage;
  final String studentGender;
  final String managerName;
  final String email;
  final String adminUserId;
  final String status;
  final DateTime createdAt;

  const School({
    required this.id,
    required this.code,
    required this.name,
    this.governorate = '',
    required this.address,
    this.phone = '',
    this.type = '',
    this.educationStage = '',
    this.studentGender = '',
    required this.managerName,
    required this.email,
    required this.adminUserId,
    this.status = 'inactive',
    required this.createdAt,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      type: json['type'] as String? ?? '',
      educationStage: json['educationStage'] as String? ?? '',
      studentGender: json['studentGender'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      adminUserId: json['adminUserId'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'governorate': governorate,
      'address': address,
      'phone': phone,
      'type': type,
      'educationStage': educationStage,
      'studentGender': studentGender,
      'managerName': managerName,
      'email': email,
      'adminUserId': adminUserId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
