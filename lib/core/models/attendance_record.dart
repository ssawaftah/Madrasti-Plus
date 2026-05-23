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

  bool get isCheckIn => type == 'check_in';
}
