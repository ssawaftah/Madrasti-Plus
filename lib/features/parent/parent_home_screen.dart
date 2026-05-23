import 'package:flutter/material.dart';

import '../../core/data/mock_database.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final students = MockDatabase.students;
    final records = MockDatabase.attendanceRecords;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ولي الأمر'), centerTitle: true),
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
                    'أبنائي',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'متابعة حالة الدخول والخروج بشكل تجريبي.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  ...students.map((student) {
                    final statusText = student.isInsideSchool
                        ? 'داخل المدرسة'
                        : 'خارج المدرسة';

                    final lastScanText = student.lastAttendanceAt == null
                        ? 'لا يوجد تسجيل بعد'
                        : 'آخر تسجيل: ${student.lastAttendanceAt!.hour.toString().padLeft(2, '0')}:${student.lastAttendanceAt!.minute.toString().padLeft(2, '0')}';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          student.isInsideSchool
                              ? Icons.check_circle
                              : Icons.cancel,
                        ),
                        title: Text(student.fullName),
                        subtitle: Text(
                          'الصف: ${student.grade} - الشعبة: ${student.section}\nالحالة: $statusText\n$lastScanText',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'سجل الحضور',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (records.isEmpty)
                    const Text('لا يوجد سجل حضور بعد.')
                  else
                    ...records.map((record) {
                      final typeText = record.isCheckIn ? 'دخول' : 'خروج';
                      final timeText =
                          '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            record.isCheckIn ? Icons.login : Icons.logout,
                          ),
                          title: Text('${record.studentName} - $typeText'),
                          subtitle: Text('الوقت: $timeText'),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
