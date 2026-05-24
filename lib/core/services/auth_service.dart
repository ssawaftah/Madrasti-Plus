import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_config.dart';
import '../models/app_user.dart';

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
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() {
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
    );

    await docRef.set(newUser.toJson());
    return newUser;
  }
}
