import 'package:flutter/material.dart';

void main() {
  runApp(const MadrastiPlusApp());
}

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
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _HomeCard(
        title: 'ولي الأمر',
        subtitle: 'متابعة الأبناء وسجل الحضور',
        icon: Icons.family_restroom,
        onTap: () {},
      ),
      _HomeCard(
        title: 'الحارس',
        subtitle: 'مسح بطاقة NFC وتسجيل الدخول والخروج',
        icon: Icons.nfc,
        onTap: () {},
      ),
      _HomeCard(
        title: 'المعلم',
        subtitle: 'إدارة الحضور والملاحظات',
        icon: Icons.school,
        onTap: () {},
      ),
      _HomeCard(
        title: 'الإدارة',
        subtitle: 'إدارة الطلاب والصفوف',
        icon: Icons.admin_panel_settings,
        onTap: () {},
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Madrasti Plus'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'اختر نوع المستخدم',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'هذه نسخة MVP أولية لاختبار التدفق الأساسي للنظام.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            ...cards,
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 34),
        title: Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_back_ios_new),
        onTap: onTap,
      ),
    );
  }
}
