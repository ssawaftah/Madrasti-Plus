import '../services/school_session_service.dart';

class FirebaseConfig {
  const FirebaseConfig._();

  static const bool isEnabled = true;

  static String get defaultSchoolId => SchoolSessionService.activeSchoolId;

  static const String fallbackSchoolId = 'school_001';

  // Cloud Firestore database ID from Firebase Console URL:
  // /firestore/databases/default/data
  static const String firestoreDatabaseId = 'default';
}
