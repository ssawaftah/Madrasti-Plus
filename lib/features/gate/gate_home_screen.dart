import 'package:flutter/material.dart';

import '../../core/data/mock_database.dart';

class GateHomeScreen extends StatefulWidget {
  const GateHomeScreen({super.key});

  @override
  State<GateHomeScreen> createState() => _GateHomeScreenState();
}

class _GateHomeScreenState extends State<GateHomeScreen> {
  void _simulateScan(String studentId) {
    final record = MockDatabase.toggleStudentAttendance(studentId);

    if (record == null) return;

    setState(() {});

    final message = record.isCheckIn
        ? 'تم تسجيل دخول ${record.studentName}'
        : 'تم تسجيل خروج ${record.studentName}';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final students = MockDatabase.students;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الحارس - NFC'), centerTitle: true),
        body: students.isEmpty
            ? const Center(
                child: Text(
                  'لا يوجد طلاب بعد. أضف طالب من شاشة الإدارة أولًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'محاكاة مسح بطاقة الطالب',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذه خطوة تجريبية قبل ربط NFC الحقيقي.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 20),

                  ...students.map((student) {
                    final statusText = student.isInsideSchool
                        ? 'داخل المدرسة'
                        : 'خارج المدرسة';

                    final lastScanText = student.lastAttendanceAt == null
                        ? 'لا يوجد تسجيل بعد'
                        : 'آخر تسجيل: ${_formatTime(student.lastAttendanceAt!)}';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          student.isInsideSchool ? Icons.login : Icons.logout,
                        ),
                        title: Text(student.fullName),
                        subtitle: Text('الحالة: $statusText\n$lastScanText'),
                        isThreeLine: true,
                        trailing: FilledButton(
                          onPressed: () => _simulateScan(student.id),
                          child: const Text('مسح تجريبي'),
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
