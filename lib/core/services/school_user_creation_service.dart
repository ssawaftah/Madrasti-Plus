import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../config/firebase_config.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class SchoolUserCreationService {
  SchoolUserCreationService({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: FirebaseConfig.firestoreDatabaseId,
            ),
        _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Future<AppUser> createTeacher({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _createSchoolUser(
      fullName: fullName,
      email: email,
      password: password,
      role: 'teacher',
    );
  }

  Future<AppUser> createParent({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _createSchoolUser(
      fullName: fullName,
      email: email,
      password: password,
      role: 'parent',
    );
  }

  Future<AppUser> _createSchoolUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final currentUser = await _authService.getCurrentAppUserOrThrow();

    if (currentUser.role != 'admin') {
      throw StateError('فقط مدير المدرسة يستطيع إنشاء مستخدمين من هذه الشاشة');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final secondaryApp = await Firebase.initializeApp(
      name: 'school_user_creator_${DateTime.now().microsecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final createdUser = credential.user;

      if (createdUser == null) {
        throw StateError('تعذر إنشاء الحساب');
      }

      await createdUser.updateDisplayName(fullName.trim());

      final appUser = AppUser(
        id: createdUser.uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        role: role,
        schoolId: currentUser.schoolId,
        schoolCode: currentUser.schoolCode,
      );

      await _usersCollection.doc(createdUser.uid).set(appUser.toJson());
      await secondaryAuth.signOut();
      return appUser;
    } finally {
      await secondaryApp.delete();
    }
  }
}
