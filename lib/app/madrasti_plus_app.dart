import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';

class MadrastiPlusApp extends StatelessWidget {
  const MadrastiPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Madrasti Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
      ),
      home: const HomeScreen(),
    );
  }
}
