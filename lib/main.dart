import 'package:flutter/material.dart';

import 'app/madrasti_plus_app.dart';
import 'core/data/mock_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockDatabase.initialize();
  runApp(const MadrastiPlusApp());
}
