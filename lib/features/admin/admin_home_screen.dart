import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../core/data/mock_database.dart';
import '../../core/services/nfc_uid_reader.dart';
import 'widgets/firebase_sync_button.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _sectionController = TextEditingController();
  bool _isNfcSessionActive = false;

  @override
  void dispose() {
    _stopNfcSession();
    _nameController.dispose();
    _gradeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  void _addStudent() {
    final name = _nameController.text.trim();
    final grade = _gradeController.text.trim();
    final section = _sectionController.text.trim();

    if (name.isEmpty || grade.isEmpty || section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عبّي كل الحقول يا مدير 👀')),
      );
      return;
    }

    setState(() {
      MockDatabase.addStudent(
        fullName: name,
        grade: grade,
        section: section,
      );
      _nameController.clear();
      _gradeController.clear();
      _sectionController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة الطالب بنجاح')));
  }

  void _showLinkNfcDialog(String studentId, String studentName) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text('ربط بطاقة NFC - $studentName'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'NFC UID',
                        hintText: 'مثال: 04A1B2C3D4',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isNfcSessionActive
                          ? null
                          : () => _scanNfcForStudentLink(
                                studentId: studentId,
                                controller: controller,
                                setDialogState: setDialogState,
                              ),
                      icon: const Icon(Icons.sensors),
                      label: Text(
                        _isNfcSessionActive
                            ? 'بانتظار البطاقة...'
                            : 'قراءة البطاقة الآن',
                      ),
                    ),
                    if (_isNfcSessionActive) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await _stopNfcSession();
                          setDialogState(() {});
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('إلغاء القراءة'),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      FocusScope.of(dialogContext).unfocus();
                      await _stopNfcSession();
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () => _linkNfcUid(
                      studentId: studentId,
                      uid: controller.text,
                      onSuccess: () {
                        FocusScope.of(dialogContext).unfocus();
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _stopNfcSession();
    });
  }

  Future<void> _scanNfcForStudentLink({
    required String studentId,
    required TextEditingController controller,
    required StateSetter setDialogState,
  }) async {
    final isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC غير متاح أو غير مفعّل على هذا الجهاز')),
      );
      return;
    }

    setState(() {
      _isNfcSessionActive = true;
    });
    setDialogState(() {});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قرّب بطاقة NFC من الهاتف الآن')),
    );

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        final uid = NfcUidReader.extractUid(tag);

        await _stopNfcSession();

        if (!mounted) return;
        setDialogState(() {});

        if (uid == null || uid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت قراءة البطاقة لكن لم أستطع استخراج UID')),
          );
          return;
        }

        controller.text = uid;
        _linkNfcUid(studentId: studentId, uid: uid);
      },
    );
  }

  Future<void> _stopNfcSession() async {
    if (!_isNfcSessionActive) return;

    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // Ignore stop errors during hot reload/navigation.
    }

    if (mounted) {
      setState(() {
        _isNfcSessionActive = false;
      });
    } else {
      _isNfcSessionActive = false;
    }
  }

  void _linkNfcUid({
    required String studentId,
    required String uid,
    VoidCallback? onSuccess,
  }) {
    final normalizedUid = uid.trim();

    if (normalizedUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل UID أولًا')),
      );
      return;
    }

    if (MockDatabase.isNfcUidAlreadyLinked(
      normalizedUid,
      exceptStudentId: studentId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا UID مربوط بطالب آخر بالفعل')),
      );
      return;
    }

    setState(() {
      MockDatabase.linkNfcUidToStudent(
        studentId: studentId,
        nfcUid: normalizedUid,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم ربط بطاقة NFC بنجاح')),
    );

    onSuccess?.call();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final students = MockDatabase.students;
    final records = MockDatabase.attendanceRecords;
    final insideCount = MockDatabase.insideSchoolCount;
    final outsideCount = MockDatabase.outsideSchoolCount;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإدارة'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'لوحة الإدارة',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'نظرة سريعة على الطلاب وحالة الحضور التجريبية.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'الطلاب',
                    value: students.length.toString(),
                    icon: Icons.groups,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'داخل المدرسة',
                    value: insideCount.toString(),
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'خارج المدرسة',
                    value: outsideCount.toString(),
                    icon: Icons.cancel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FirebaseSyncButton(),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'إضافة طالب',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الطالب',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'الصف',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sectionController,
              decoration: const InputDecoration(
                labelText: 'الشعبة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _addStudent,
              icon: const Icon(Icons.add),
              label: const Text('إضافة الطالب'),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'الطلاب (${students.length})',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              const Text('لا يوجد طلاب بعد. أضف أول طالب وخلينا نولّعها.')
            else
              ...students.map(
                (student) {
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
                        student.isInsideSchool
                            ? Icons.check_circle
                            : Icons.cancel,
                      ),
                      title: Text(student.fullName),
                      subtitle: Text(
                        'الصف: ${student.grade} - الشعبة: ${student.section}\nالحالة: $statusText\n$uidText\n$lastScanText',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'ربط NFC',
                        icon: const Icon(Icons.nfc),
                        onPressed: () => _showLinkNfcDialog(
                          student.id,
                          student.fullName,
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'سجل الحضور العام',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const Text('لا يوجد عمليات حضور بعد.')
            else
              ...records.map(
                (record) {
                  final typeText = record.isCheckIn ? 'دخول' : 'خروج';

                  return Card(
                    child: ListTile(
                      leading: Icon(record.isCheckIn ? Icons.login : Icons.logout),
                      title: Text('${record.studentName} - $typeText'),
                      subtitle: Text('الوقت: ${_formatTime(record.timestamp)}'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}
