class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String schoolId;
  final List<String> linkedStudentIds;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.schoolId,
    this.linkedStudentIds = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? 'مستخدم',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'parent',
      schoolId: json['schoolId'] as String? ?? 'school_001',
      linkedStudentIds: (json['linkedStudentIds'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'schoolId': schoolId,
      'linkedStudentIds': linkedStudentIds,
    };
  }
}
