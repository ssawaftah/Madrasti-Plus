import 'package:flutter/material.dart';
import '../../core/models/attendance_record.dart';
import '../../core/data/mock_database.dart';

class GateHomeScreen extends StatefulWidget {
  const GateHomeScreen({super.key});

  @override
  State<GateHomeScreen> createState() => _GateHomeScreenState();
}

class _GateHomeScreenState extends State<GateHomeScreen> {
  void _simulateScan(String studentId) {
    final index = MockDatabase.students.indexWhere(
      (student) => student.id == studentId,
    );

    if (index == -1) return;

    final student = MockDatabase.students[index];
    final newStatus = !student.isInsideSchool;
    final now = DateTime.now();
    final attendanceType = newStatus ? 'check_in' : 'check_out';

    setState(() {
      MockDatabase.students[index] = student.copyWith(
        isInsideSchool: newStatus,
        lastAttendanceAt: now,
      );

      MockDatabase.attendanceRecords.insert(
        0,
        AttendanceRecord(
          id: now.microsecondsSinceEpoch.toString(),
          studentId: student.id,
          studentName: student.fullName,
          type: attendanceType,
          timestamp: now,
        ),
      );
    });
    final message = newStatus
        ? 'تم تسجيل دخول ${student.fullName}'
        : 'تم تسجيل خروج ${student.fullName}';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                        : 'آخر تسجيل: ${student.lastAttendanceAt!.hour.toString().padLeft(2, '0')}:${student.lastAttendanceAt!.minute.toString().padLeft(2, '0')}';

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
