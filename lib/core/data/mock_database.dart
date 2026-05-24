import '../models/attendance_record.dart';
import '../models/student.dart';

class MockDatabase {
  MockDatabase._();

  static final List<Student> students = [];
  static final List<AttendanceRecord> attendanceRecords = [];

  static int get insideSchoolCount {
    return students.where((student) => student.isInsideSchool).length;
  }

  static int get outsideSchoolCount {
    return students.length - insideSchoolCount;
  }

  static Student addStudent({
    required String fullName,
    required String grade,
    required String section,
  }) {
    final student = Student(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: fullName,
      grade: grade,
      section: section,
    );

    students.add(student);
    return student;
  }

  static AttendanceRecord? toggleStudentAttendance(String studentId) {
    final index = students.indexWhere((student) => student.id == studentId);

    if (index == -1) return null;

    final student = students[index];
    final now = DateTime.now();
    final newStatus = !student.isInsideSchool;
    final attendanceType = newStatus ? 'check_in' : 'check_out';

    students[index] = student.copyWith(
      isInsideSchool: newStatus,
      lastAttendanceAt: now,
    );

    final record = AttendanceRecord(
      id: now.microsecondsSinceEpoch.toString(),
      studentId: student.id,
      studentName: student.fullName,
      type: attendanceType,
      timestamp: now,
    );

    attendanceRecords.insert(0, record);
    return record;
  }
}
