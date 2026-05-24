class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String schoolId;
  final String schoolCode;
  final List<String> linkedStudentIds;
  final List<String> assignedGrades;
  final List<String> assignedSections;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.schoolId,
    this.schoolCode = '',
    this.linkedStudentIds = const [],
    this.assignedGrades = const [],
    this.assignedSections = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? 'مستخدم',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'parent',
      schoolId: json['schoolId'] as String? ?? 'school_001',
      schoolCode: json['schoolCode'] as String? ?? '',
      linkedStudentIds: _stringListFromJson(json['linkedStudentIds']),
      assignedGrades: _stringListFromJson(json['assignedGrades']),
      assignedSections: _stringListFromJson(json['assignedSections']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'schoolId': schoolId,
      'schoolCode': schoolCode,
      'linkedStudentIds': linkedStudentIds,
      'assignedGrades': assignedGrades,
      'assignedSections': assignedSections,
    };
  }

  static List<String> _stringListFromJson(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) return const [];

      return normalized
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [value.toString().trim()].where((item) => item.isNotEmpty).toList();
  }
}
