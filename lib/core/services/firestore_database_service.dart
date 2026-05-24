import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_config.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';

class FirestoreDatabaseService {
  FirestoreDatabaseService({
    FirebaseFirestore? firestore,
    String? schoolId,
  })  : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: FirebaseConfig.firestoreDatabaseId,
            ),
        _schoolId = schoolId ?? FirebaseConfig.defaultSchoolId;

  final FirebaseFirestore _firestore;
  final String _schoolId;

  DocumentReference<Map<String, dynamic>> get _schoolDocument {
    return _firestore.collection('schools').doc(_schoolId);
  }

  CollectionReference<Map<String, dynamic>> get _studentsCollection {
    return _schoolDocument.collection('students');
  }

  CollectionReference<Map<String, dynamic>> get _attendanceRecordsCollection {
    return _schoolDocument.collection('attendance_records');
  }

  Future<void> ensureSchoolDocumentExists() async {
    await _schoolDocument.set(
      {
        'id': _schoolId,
        'name': 'Madrasti Plus Demo School',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<Student>> watchStudents() {
    return _studentsCollection.orderBy('fullName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Student.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
  }

  Stream<List<AttendanceRecord>> watchAttendanceRecords() {
    return _attendanceRecordsCollection
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AttendanceRecord.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
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
    await ensureSchoolDocumentExists();

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
    await ensureSchoolDocumentExists();
    await _studentsCollection.doc(student.id).set(student.toJson()..remove('id'));
  }

  Future<void> deleteStudent(String studentId) async {
    await _studentsCollection.doc(studentId).delete();
  }

  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    await ensureSchoolDocumentExists();
    await _attendanceRecordsCollection
        .doc(record.id)
        .set(record.toJson()..remove('id'));
  }

  Future<void> syncLocalData({
    required List<Student> students,
    required List<AttendanceRecord> attendanceRecords,
  }) async {
    final batch = _firestore.batch();

    batch.set(
      _schoolDocument,
      {
        'id': _schoolId,
        'name': 'Madrasti Plus Demo School',
        'updatedAt': FieldValue.serverTimestamp(),
        'studentsCount': students.length,
        'attendanceRecordsCount': attendanceRecords.length,
      },
      SetOptions(merge: true),
    );

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

    await batch.commit().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException(
          'انتهت مهلة الاتصال مع Firestore. تأكد من وجود قاعدة البيانات وصلاحيات الكتابة.',
        );
      },
    );
  }
}

class TimeoutException implements Exception {
  final String message;

  const TimeoutException(this.message);

  @override
  String toString() => message;
}
