class FirebaseConfig {
  const FirebaseConfig._();

  static const bool isEnabled = true;

  static const String defaultSchoolId = 'school_001';

  // Cloud Firestore database ID. The default Firebase database ID is "(default)".
  // If you created a named Firestore database, replace this value with its ID.
  static const String firestoreDatabaseId = '(default)';
}
