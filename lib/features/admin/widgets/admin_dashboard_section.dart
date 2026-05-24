import 'package:flutter/material.dart';

import '../../../core/data/mock_database.dart';
import 'firebase_sync_button.dart';

class AdminDashboardSection extends StatelessWidget {
  const AdminDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final students = MockDatabase.students;
    final records = MockDatabase.attendanceRecords;
    final insideCount = MockDatabase.insideSchoolCount;
    final outsideCount = MockDatabase.outsideSchoolCount;
    final todayRecords = records.where(_isToday).length;
    final linkedNfcCount = students.where((student) => student.nfcUid != null).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'لوحة التحكم',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'نظرة تشغيلية سريعة على المدرسة اليوم.',
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _DashboardMetricCard(
              title: 'الطلاب',
              value: students.length.toString(),
              icon: Icons.groups,
              color: const Color(0xFF2563EB),
            ),
            _DashboardMetricCard(
              title: 'داخل المدرسة',
              value: insideCount.toString(),
              icon: Icons.check_circle,
              color: const Color(0xFF16A34A),
            ),
            _DashboardMetricCard(
              title: 'خارج المدرسة',
              value: outsideCount.toString(),
              icon: Icons.cancel,
              color: const Color(0xFFDC2626),
            ),
            _DashboardMetricCard(
              title: 'حركات اليوم',
              value: todayRecords.toString(),
              icon: Icons.receipt_long,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'جاهزية NFC',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: students.isEmpty ? 0 : linkedNfcCount / students.length,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 10),
                Text(
                  '$linkedNfcCount من ${students.length} طالب لديهم بطاقة NFC مربوطة.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const FirebaseSyncButton(),
        const SizedBox(height: 14),
        const _QuickHintCard(),
      ],
    );
  }

  bool _isToday(record) {
    final now = DateTime.now();
    final dateTime = record.timestamp as DateTime;
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _QuickHintCard extends StatelessWidget {
  const _QuickHintCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tips_and_updates, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'استخدم زر NFC في الأعلى لربط بطاقة بسرعة، أو انتقل إلى تبويب الطلاب للإدارة الكاملة.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
