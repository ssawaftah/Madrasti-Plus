import 'package:flutter/material.dart';

import '../../core/data/mock_database.dart';

class GateHomeScreen extends StatefulWidget {
  const GateHomeScreen({super.key});

  @override
  State<GateHomeScreen> createState() => _GateHomeScreenState();
}

class _GateHomeScreenState extends State<GateHomeScreen> {
  final _nfcUidController = TextEditingController();

  @override
  void dispose() {
    _nfcUidController.dispose();
    super.dispose();
  }

  void _simulateScanByStudentId(String studentId) {
    final record = MockDatabase.toggleStudentAttendance(studentId);
    _showScanResult(record);
  }

  void _simulateScanByNfcUid() {
    final uid = _nfcUidController.text.trim();

    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل NFC UID أولًا')),
      );
      return;
    }

    final record = MockDatabase.toggleStudentAttendanceByNfcUid(uid);

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على طالب مرتبط بهذا UID')),
      );
      return;
    }

    _nfcUidController.clear();
    _showScanResult(record);
  }

  void _showScanResult(dynamic record) {
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
                    'مسح بطاقة الطالب',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أدخل UID تجريبيًا الآن. لاحقًا سيأتي هذا الرقم من قارئ NFC الحقيقي.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nfcUidController,
                    decoration: const InputDecoration(
                      labelText: 'NFC UID',
                      hintText: 'مثال: 04A1B2C3D4',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _simulateScanByNfcUid(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _simulateScanByNfcUid,
                    icon: const Icon(Icons.nfc),
                    label: const Text('مسح UID تجريبي'),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    'اختبار سريع بدون UID',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذا الخيار مؤقت للتجربة السريعة أثناء التطوير.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  ...students.map((student) {
                    final statusText = student.isInsideSchool
                        ? 'داخل المدرسة'
                        : 'خارج المدرسة';

                    final lastScanText = student.lastAttendanceAt == null
                        ? 'لا يوجد تسجيل بعد'
                        : 'آخر تسجيل: ${_formatTime(student.lastAttendanceAt!)}';

                    final uidText = student.nfcUid == null
                        ? 'لا يوجد UID مرتبط'
                        : 'UID: ${student.nfcUid}';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          student.isInsideSchool ? Icons.login : Icons.logout,
                        ),
                        title: Text(student.fullName),
                        subtitle: Text(
                          'الحالة: $statusText\n$uidText\n$lastScanText',
                        ),
                        isThreeLine: true,
                        trailing: FilledButton(
                          onPressed: () => _simulateScanByStudentId(student.id),
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
