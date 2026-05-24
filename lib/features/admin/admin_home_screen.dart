import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../core/data/mock_database.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/nfc_uid_reader.dart';
import 'widgets/admin_dashboard_section.dart';
import 'widgets/admin_school_users_section.dart';
import 'widgets/admin_students_section.dart';
import 'widgets/daily_attendance_report_section.dart';

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

  void _showAddStudentSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إضافة طالب جديد',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    onPressed: () {
                      final added = _addStudent();
                      if (added && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة الطالب'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _addStudent() {
    final name = _nameController.text.trim();
    final grade = _gradeController.text.trim();
    final section = _sectionController.text.trim();

    if (name.isEmpty || grade.isEmpty || section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عبّي كل الحقول يا مدير 👀')),
      );
      return false;
    }

    MockDatabase.addStudent(
      fullName: name,
      grade: grade,
      section: section,
    );
    _nameController.clear();
    _gradeController.clear();
    _sectionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة الطالب بنجاح')),
    );
    return true;
  }

  void _showLinkNfcDialog() {
    final students = MockDatabase.students;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف طالبًا أولًا قبل ربط NFC')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'اختر طالبًا لربط بطاقة NFC',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.nfc),
                            title: Text(student.fullName),
                            subtitle: Text(
                              student.nfcUid == null
                                  ? '${student.grade} - ${student.section} | NFC غير مربوط'
                                  : '${student.grade} - ${student.section} | UID: ${student.nfcUid}',
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _showLinkNfcDialogForStudent(
                                student.id,
                                student.fullName,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLinkNfcDialogForStudent(String studentId, String studentName) {
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

    setState(() => _isNfcSessionActive = true);
    setDialogState(() {});

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
    } catch (_) {}

    if (mounted) {
      setState(() => _isNfcSessionActive = false);
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

    if (MockDatabase.isNfcUidAlreadyLinked(normalizedUid, exceptStudentId: studentId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا UID مربوط بطالب آخر بالفعل')),
      );
      return;
    }

    MockDatabase.linkNfcUidToStudent(studentId: studentId, nfcUid: normalizedUid);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم ربط بطاقة NFC بنجاح')),
    );

    onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: ValueListenableBuilder<int>(
        valueListenable: MockDatabase.revision,
        builder: (context, _, __) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('الإدارة'),
                centerTitle: true,
                actions: [
                  IconButton(
                    tooltip: 'إضافة طالب',
                    onPressed: _showAddStudentSheet,
                    icon: const Icon(Icons.person_add_alt_1),
                  ),
                  IconButton(
                    tooltip: 'ربط NFC سريع',
                    onPressed: _showLinkNfcDialog,
                    icon: const Icon(Icons.nfc),
                  ),
                  IconButton(
                    tooltip: 'تسجيل الخروج',
                    onPressed: () => AuthService().signOut(),
                    icon: const Icon(Icons.logout),
                  ),
                ],
                bottom: const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(icon: Icon(Icons.dashboard), text: 'الرئيسية'),
                    Tab(icon: Icon(Icons.analytics), text: 'التقرير'),
                    Tab(icon: Icon(Icons.groups), text: 'الطلاب'),
                    Tab(icon: Icon(Icons.manage_accounts), text: 'المستخدمون'),
                    Tab(icon: Icon(Icons.receipt_long), text: 'السجل'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  AdminDashboardSection(),
                  _ReportTab(),
                  _StudentsTab(),
                  _UsersTab(),
                  _AttendanceLogTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [DailyAttendanceReportSection()],
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [AdminStudentsSection()],
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [AdminSchoolUsersSection()],
    );
  }
}

class _AttendanceLogTab extends StatelessWidget {
  const _AttendanceLogTab();

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month';
  }

  @override
  Widget build(BuildContext context) {
    final records = MockDatabase.attendanceRecords;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'سجل الحضور العام',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('آخر 100 حركة دخول وخروج.'),
        const SizedBox(height: 14),
        if (records.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا يوجد عمليات حضور بعد.'),
            ),
          )
        else
          ...records.take(100).map((record) {
            final typeText = record.isCheckIn ? 'دخول' : 'خروج';
            final color = record.isCheckIn ? Colors.green : Colors.red;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.10),
                  child: Icon(
                    record.isCheckIn ? Icons.login : Icons.logout,
                    color: color,
                  ),
                ),
                title: Text('${record.studentName} - $typeText'),
                subtitle: Text('الوقت: ${_formatTime(record.timestamp)}'),
              ),
            );
          }),
      ],
    );
  }
}
