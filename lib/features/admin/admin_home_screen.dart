import 'package:flutter/material.dart';

import '../../core/data/mock_database.dart';
import '../../core/models/student.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _sectionController = TextEditingController();

  @override
  void dispose() {
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

    final student = Student(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: name,
      grade: grade,
      section: section,
    );

    setState(() {
      MockDatabase.students.add(student);
      _nameController.clear();
      _gradeController.clear();
      _sectionController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة الطالب بنجاح')));
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
    final insideCount = students.where((student) => student.isInsideSchool).length;
    final outsideCount = students.length - insideCount;

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
