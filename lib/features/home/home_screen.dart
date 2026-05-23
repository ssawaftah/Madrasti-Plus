import 'package:flutter/material.dart';
import '../admin/admin_home_screen.dart';
import '../gate/gate_home_screen.dart';
import '../parent/parent_home_screen.dart';
import '../teacher/teacher_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _HomeCard(
        title: 'ولي الأمر',
        subtitle: 'متابعة الأبناء وسجل الحضور',
        icon: Icons.family_restroom,
        onTap: () => _openScreen(context, const ParentHomeScreen()),
      ),
      _HomeCard(
        title: 'الحارس',
        subtitle: 'مسح بطاقة NFC وتسجيل الدخول والخروج',
        icon: Icons.nfc,
        onTap: () => _openScreen(context, const GateHomeScreen()),
      ),
      _HomeCard(
        title: 'المعلم',
        subtitle: 'إدارة الحضور والملاحظات',
        icon: Icons.school,
        onTap: () => _openScreen(context, const TeacherHomeScreen()),
      ),
      _HomeCard(
        title: 'الإدارة',
        subtitle: 'إدارة الطلاب والصفوف',
        icon: Icons.admin_panel_settings,
        onTap: () => _openScreen(context, const AdminHomeScreen()),
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
              'نسخة MVP أولية لاختبار التدفق الأساسي للنظام.',
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
