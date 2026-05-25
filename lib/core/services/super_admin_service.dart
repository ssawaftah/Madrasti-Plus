import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../config/firebase_config.dart';
import '../models/app_user.dart';
import '../models/school.dart';

class PlatformStats {
  final int totalSchools;
  final int totalStudents;
  final int totalUsers;
  final int activeSchools;
  final int suspendedSchools;

  const PlatformStats({
    required this.totalSchools,
    required this.totalStudents,
    required this.totalUsers,
    required this.activeSchools,
    required this.suspendedSchools,
  });

  factory PlatformStats.fromSchoolsOnly(List<School> schools) {
    return PlatformStats(
      totalSchools: schools.length,
      totalStudents: 0,
      totalUsers: 0,
      activeSchools: schools.length,
      suspendedSchools: 0,
    );
  }
}

class SuperAdminService {
  SuperAdminService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: FirebaseConfig.firestoreDatabaseId,
          );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _schoolsCollection {
    return _firestore.collection('schools');
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Stream<List<School>> watchSchools() {
    return _schoolsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return School.fromJson({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  Future<PlatformStats> fetchPlatformStats() async {
    final schoolsSnapshot = await _schoolsCollection.get();
    final totalSchools = schoolsSnapshot.docs.length;
    final suspendedSchools = schoolsSnapshot.docs.where((doc) {
      final status = (doc.data()['status'] as String? ?? 'active').toLowerCase();
      return status == 'suspended' || status == 'inactive' || status == 'stopped';
    }).length;
    final activeSchools = totalSchools - suspendedSchools;

    final usersCount = await _safeCount(_usersCollection);
    final studentsCount = await _safeCount(_firestore.collectionGroup('students'));

    return PlatformStats(
      totalSchools: totalSchools,
      totalStudents: studentsCount,
      totalUsers: usersCount,
      activeSchools: activeSchools,
      suspendedSchools: suspendedSchools,
    );
  }

  Future<int> _safeCount(Query<Map<String, dynamic>> query) async {
    try {
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<School> createSchool({
    required String name,
    String code = '',
    required String address,
    required String managerName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final schoolDoc = _schoolsCollection.doc();
    final requestedCode = code.trim().toUpperCase();
    final schoolCode = requestedCode.isEmpty
        ? _generateSchoolCode(name, schoolDoc.id)
        : requestedCode;

    final existingCode = await _schoolsCollection
        .where('code', isEqualTo: schoolCode)
        .limit(1)
        .get();

    if (existingCode.docs.isNotEmpty) {
      throw StateError('رمز الشركة/المدرسة مستخدم بالفعل');
    }

    final secondaryAppName =
        'school_creator_${DateTime.now().microsecondsSinceEpoch}';
    final secondaryApp = await Firebase.initializeApp(
      name: secondaryAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final adminUser = credential.user;

      if (adminUser == null) {
        throw StateError('تعذر إنشاء حساب مدير المدرسة');
      }

      await adminUser.updateDisplayName(managerName.trim());

      final school = School(
        id: schoolDoc.id,
        code: schoolCode,
        name: name.trim(),
        address: address.trim(),
        managerName: managerName.trim(),
        email: normalizedEmail,
        adminUserId: adminUser.uid,
        createdAt: DateTime.now(),
      );

      final appUser = AppUser(
        id: adminUser.uid,
        fullName: managerName.trim(),
        email: normalizedEmail,
        role: 'admin',
        schoolId: school.id,
        schoolCode: school.code,
      );

      await _firestore.runTransaction((transaction) async {
        transaction.set(schoolDoc, {
          ...school.toJson(),
          'status': 'active',
        });
        transaction.set(_usersCollection.doc(adminUser.uid), appUser.toJson());
      });

      await secondaryAuth.signOut();
      return school;
    } finally {
      await secondaryApp.delete();
    }
  }

  String _generateSchoolCode(String schoolName, String schoolId) {
    final cleaned = schoolName.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final prefix = cleaned.isEmpty
        ? 'SCH'
        : cleaned.substring(0, cleaned.length < 3 ? cleaned.length : 3);
    final suffix = schoolId.substring(0, 5).toUpperCase();
    return '$prefix-$suffix';
  }
}
