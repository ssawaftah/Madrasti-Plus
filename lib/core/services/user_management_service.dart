import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_config.dart';
import '../models/app_user.dart';

class UserManagementService {
  UserManagementService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: FirebaseConfig.firestoreDatabaseId,
            );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  Stream<List<AppUser>> watchUsers() {
    return _usersCollection.orderBy('email').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppUser.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) {
    return _usersCollection.doc(userId).set(
      {'role': role},
      SetOptions(merge: true),
    );
  }

  Future<void> updateLinkedStudentIds({
    required String userId,
    required List<String> linkedStudentIds,
  }) {
    return _usersCollection.doc(userId).set(
      {'linkedStudentIds': linkedStudentIds},
      SetOptions(merge: true),
    );
  }
}
