import 'package:flutter/material.dart';

import 'app/madrasti_plus_app.dart';
import 'core/config/firebase_config.dart';
import 'core/data/mock_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (FirebaseConfig.isEnabled) {
    // After running FlutterFire CLI, uncomment the imports below and initialize Firebase:
    // import 'package:firebase_core/firebase_core.dart';
    // import 'firebase_options.dart';
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  await MockDatabase.initialize();
  runApp(const MadrastiPlusApp());
}
