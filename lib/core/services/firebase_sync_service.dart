import 'package:flutter/foundation.dart';

import '../models/attendance_record.dart';
import '../models/student.dart';
import 'firestore_database_service.dart';
import 'notification_service.dart';

class FirebaseSyncService {
  FirebaseSyncService._();

  static final FirestoreDatabaseService _firestoreService = FirestoreDatabaseService();
  static final NotificationService _notificationService = NotificationService();

  static Future<void> syncStudent(Student student) async {
    try {
      await _firestoreService.upsertStudent(student);
    } catch (error, stackTrace) {
      debugPrint('Failed to sync student to Firebase: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> syncAttendanceRecord({
    required AttendanceRecord record,
    required Student? student,
  }) async {
    try {
      await _firestoreService.addAttendanceRecord(record);

      if (student != null) {
        await _firestoreService.upsertStudent(student);
      }

      await _notificationService.createAttendanceNotifications(record: record);
    } catch (error, stackTrace) {
      debugPrint('Failed to sync attendance record to Firebase: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
