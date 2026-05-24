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

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      grade: json['grade'] as String,
      section: json['section'] as String,
      nfcUid: json['nfcUid'] as String?,
      isInsideSchool: json['isInsideSchool'] as bool? ?? false,
      lastAttendanceAt: json['lastAttendanceAt'] == null
          ? null
          : DateTime.parse(json['lastAttendanceAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'grade': grade,
      'section': section,
      'nfcUid': nfcUid,
      'isInsideSchool': isInsideSchool,
      'lastAttendanceAt': lastAttendanceAt?.toIso8601String(),
    };
  }

  Student copyWith({
    String? id,
    String? fullName,
    String? grade,
    String? section,
    Object? nfcUid = _sentinel,
    bool? isInsideSchool,
    Object? lastAttendanceAt = _sentinel,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      nfcUid: identical(nfcUid, _sentinel) ? this.nfcUid : nfcUid as String?,
      isInsideSchool: isInsideSchool ?? this.isInsideSchool,
      lastAttendanceAt: identical(lastAttendanceAt, _sentinel)
          ? this.lastAttendanceAt
          : lastAttendanceAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();
