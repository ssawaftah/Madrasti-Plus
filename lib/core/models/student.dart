class Student {
  final String id;
  final String fullName;
  final String grade;
  final String section;
  final String? nfcUid;
  final bool isInsideSchool;
  final DateTime? lastAttendanceAt;

  const Student({
    required this.id,
    required this.fullName,
    required this.grade,
    required this.section,
    this.nfcUid,
    this.isInsideSchool = false,
    this.lastAttendanceAt,
  });

  Student copyWith({
    String? id,
    String? fullName,
    String? grade,
    String? section,
    String? nfcUid,
    bool? isInsideSchool,
    DateTime? lastAttendanceAt,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      nfcUid: nfcUid ?? this.nfcUid,
      isInsideSchool: isInsideSchool ?? this.isInsideSchool,
      lastAttendanceAt: lastAttendanceAt ?? this.lastAttendanceAt,
    );
  }
}
