import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_record.dart';
import '../models/student.dart';

class MockDatabase {
  MockDatabase._();

  static const _studentsKey = 'mock_students';
  static const _attendanceRecordsKey = 'mock_attendance_records';

  static final List<Student> students = [];
  static final List<AttendanceRecord> attendanceRecords = [];

  static int get insideSchoolCount {
    return students.where((student) => student.isInsideSchool).length;
  }

  static int get outsideSchoolCount {
    return students.length - insideSchoolCount;
  }

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final studentsJson = prefs.getString(_studentsKey);
    final attendanceRecordsJson = prefs.getString(_attendanceRecordsKey);

    students
      ..clear()
      ..addAll(_decodeStudents(studentsJson));

    attendanceRecords
      ..clear()
      ..addAll(_decodeAttendanceRecords(attendanceRecordsJson));
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
    _save();
    return student;
  }

  static Student? findStudentByNfcUid(String nfcUid) {
    final normalizedUid = _normalizeNfcUid(nfcUid);

    if (normalizedUid.isEmpty) return null;

    for (final student in students) {
      if (_normalizeNfcUid(student.nfcUid ?? '') == normalizedUid) {
        return student;
      }
    }

    return null;
  }

  static bool isNfcUidAlreadyLinked(String nfcUid, {String? exceptStudentId}) {
    final normalizedUid = _normalizeNfcUid(nfcUid);

    if (normalizedUid.isEmpty) return false;

    return students.any((student) {
      final sameUid = _normalizeNfcUid(student.nfcUid ?? '') == normalizedUid;
      final sameStudent = student.id == exceptStudentId;
      return sameUid && !sameStudent;
    });
  }

  static Student? linkNfcUidToStudent({
    required String studentId,
    required String nfcUid,
  }) {
    final index = students.indexWhere((student) => student.id == studentId);

    if (index == -1) return null;

    final normalizedUid = _normalizeNfcUid(nfcUid);

    if (normalizedUid.isEmpty) return null;

    if (isNfcUidAlreadyLinked(normalizedUid, exceptStudentId: studentId)) {
      return null;
    }

    final updatedStudent = students[index].copyWith(nfcUid: normalizedUid);
    students[index] = updatedStudent;
    _save();
    return updatedStudent;
  }

  static AttendanceRecord? toggleStudentAttendance(String studentId) {
    final index = students.indexWhere((student) => student.id == studentId);

    if (index == -1) return null;

    return _toggleStudentAttendanceByIndex(index);
  }

  static AttendanceRecord? toggleStudentAttendanceByNfcUid(String nfcUid) {
    final normalizedUid = _normalizeNfcUid(nfcUid);

    if (normalizedUid.isEmpty) return null;

    final index = students.indexWhere(
      (student) => _normalizeNfcUid(student.nfcUid ?? '') == normalizedUid,
    );

    if (index == -1) return null;

    return _toggleStudentAttendanceByIndex(index);
  }

  static AttendanceRecord _toggleStudentAttendanceByIndex(int index) {
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
    _save();
    return record;
  }

  static Future<void> clearAll() async {
    students.clear();
    attendanceRecords.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_studentsKey);
    await prefs.remove(_attendanceRecordsKey);
  }

  static List<Student> _decodeStudents(String? value) {
    if (value == null || value.isEmpty) return [];

    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .map((item) => Student.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<AttendanceRecord> _decodeAttendanceRecords(String? value) {
    if (value == null || value.isEmpty) return [];

    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .map(
            (item) => AttendanceRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final studentsJson = jsonEncode(
      students.map((student) => student.toJson()).toList(),
    );
    final attendanceRecordsJson = jsonEncode(
      attendanceRecords.map((record) => record.toJson()).toList(),
    );

    await prefs.setString(_studentsKey, studentsJson);
    await prefs.setString(_attendanceRecordsKey, attendanceRecordsJson);
  }

  static String _normalizeNfcUid(String value) {
    return value.trim().replaceAll(' ', '').toUpperCase();
  }
}
