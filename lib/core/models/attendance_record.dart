class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String type; // check_in أو check_out
  final DateTime timestamp;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.timestamp,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  bool get isCheckIn => type == 'check_in';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
