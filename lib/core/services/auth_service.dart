import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_config.dart';
import '../models/app_user.dart';
import 'school_session_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: FirebaseConfig.firestoreDatabaseId,
            );

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Stream<AppUser?> watchCurrentAppUser() {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      return Stream<AppUser?>.value(null);
    }

    return _firestore.collection('users').doc(firebaseUser.uid).snapshots().map(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;

        return AppUser.fromJson({
          ...snapshot.data()!,
          'id': snapshot.id,
        });
      },
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
    String? schoolCode,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw StateError('تعذر تسجيل الدخول');
    }

    final appUser = await getOrCreateCurrentAppUser();
    final normalizedSchoolCode = (schoolCode ?? '').trim().toUpperCase();

    if (appUser.role == 'super_admin') {
      await SchoolSessionService.setActiveSchool(
        schoolId: appUser.schoolId,
        schoolCode: appUser.schoolCode.isEmpty ? 'PLATFORM' : appUser.schoolCode,
      );
      return credential;
    }

    if (normalizedSchoolCode.isEmpty) {
      await _firebaseAuth.signOut();
      throw const SchoolCodeException('أدخل رمز المدرسة');
    }

    final userSchoolCode = appUser.schoolCode.trim().toUpperCase();

    if (userSchoolCode.isEmpty || userSchoolCode != normalizedSchoolCode) {
      await _firebaseAuth.signOut();
      throw const SchoolCodeException('رمز المدرسة لا يطابق هذا الحساب');
    }

    await SchoolSessionService.setActiveSchool(
      schoolId: appUser.schoolId,
      schoolCode: appUser.schoolCode,
    );
    return credential;
  }

  Future<void> signOut() async {
    await SchoolSessionService.clear();
    return _firebaseAuth.signOut();
  }

  Future<AppUser> getOrCreateCurrentAppUser() async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw StateError('لا يوجد مستخدم مسجل دخول');
    }

    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      return AppUser.fromJson({
        ...snapshot.data()!,
        'id': snapshot.id,
      });
    }

    final newUser = AppUser(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? 'مدير النظام',
      email: firebaseUser.email ?? '',
      role: 'admin',
      schoolId: FirebaseConfig.defaultSchoolId,
      schoolCode: SchoolSessionService.activeSchoolCode,
    );

    await docRef.set(newUser.toJson());
    return newUser;
  }
}

class SchoolCodeException implements Exception {
  final String message;

  const SchoolCodeException(this.message);

  @override
  String toString() => message;
}
