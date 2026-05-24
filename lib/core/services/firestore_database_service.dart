import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/firebase_config.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';

class FirestoreDatabaseService {
  FirestoreDatabaseService({
    FirebaseFirestore? firestore,
    String? schoolId,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _schoolId = schoolId ?? FirebaseConfig.defaultSchoolId;

  final FirebaseFirestore _firestore;
  final String _schoolId;

  CollectionReference<Map<String, dynamic>> get _studentsCollection {
    return _firestore.collection('schools').doc(_schoolId).collection('students');
  }

  CollectionReference<Map<String, dynamic>> get _attendanceRecordsCollection {
    return _firestore
        .collection('schools')
        .doc(_schoolId)
        .collection('attendance_records');
  }

  Future<List<Student>> fetchStudents() async {
    final snapshot = await _studentsCollection.orderBy('fullName').get();

    return snapshot.docs.map((doc) {
      return Student.fromJson({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  }

  Future<List<AttendanceRecord>> fetchAttendanceRecords() async {
    final snapshot = await _attendanceRecordsCollection
        .orderBy('timestamp', descending: true)
        .limit(200)
        .get();

    return snapshot.docs.map((doc) {
      return AttendanceRecord.fromJson({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  }

  Future<Student> addStudent({
    required String fullName,
    required String grade,
    required String section,
  }) async {
    final docRef = _studentsCollection.doc();
    final student = Student(
      id: docRef.id,
      fullName: fullName,
      grade: grade,
      section: section,
    );

    await docRef.set(student.toJson()..remove('id'));
    return student;
  }

  Future<void> upsertStudent(Student student) async {
    await _studentsCollection.doc(student.id).set(student.toJson()..remove('id'));
  }

  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    await _attendanceRecordsCollection
        .doc(record.id)
        .set(record.toJson()..remove('id'));
  }

  Future<void> syncLocalData({
    required List<Student> students,
    required List<AttendanceRecord> attendanceRecords,
  }) async {
    final batch = _firestore.batch();

    for (final student in students) {
      batch.set(
        _studentsCollection.doc(student.id),
        student.toJson()..remove('id'),
      );
    }

    for (final record in attendanceRecords) {
      batch.set(
        _attendanceRecordsCollection.doc(record.id),
        record.toJson()..remove('id'),
      );
    }

    await batch.commit();
  }
}
