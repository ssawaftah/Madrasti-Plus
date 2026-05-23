import '../models/attendance_record.dart';
import '../models/student.dart';

class MockDatabase {
  MockDatabase._();

  static final List<Student> students = [];
  static final List<AttendanceRecord> attendanceRecords = [];
}
