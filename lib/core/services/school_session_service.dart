import 'package:shared_preferences/shared_preferences.dart';

import '../config/firebase_config.dart';

class SchoolSessionService {
  SchoolSessionService._();

  static const _schoolIdKey = 'active_school_id';
  static const _schoolCodeKey = 'active_school_code';

  static String _activeSchoolId = FirebaseConfig.defaultSchoolId;
  static String _activeSchoolCode = '';

  static String get activeSchoolId => _activeSchoolId;
  static String get activeSchoolCode => _activeSchoolCode;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _activeSchoolId = prefs.getString(_schoolIdKey) ?? FirebaseConfig.defaultSchoolId;
    _activeSchoolCode = prefs.getString(_schoolCodeKey) ?? '';
  }

  static Future<void> setActiveSchool({
    required String schoolId,
    required String schoolCode,
  }) async {
    _activeSchoolId = schoolId;
    _activeSchoolCode = schoolCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_schoolIdKey, schoolId);
    await prefs.setString(_schoolCodeKey, schoolCode);
  }

  static Future<void> clear() async {
    _activeSchoolId = FirebaseConfig.defaultSchoolId;
    _activeSchoolCode = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_schoolIdKey);
    await prefs.remove(_schoolCodeKey);
  }
}
