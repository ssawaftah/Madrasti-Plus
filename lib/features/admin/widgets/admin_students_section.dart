import 'package:flutter/material.dart';

import '../../../core/data/mock_database.dart';
import '../../../core/models/student.dart';

class AdminStudentsSection extends StatefulWidget {
  const AdminStudentsSection({super.key});

  @override
  State<AdminStudentsSection> createState() => _AdminStudentsSectionState();
}

class _AdminStudentsSectionState extends State<AdminStudentsSection> {
  final _searchController = TextEditingController();
  String _gradeFilter = 'all';
  String _sectionFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> _filteredStudents(List<Student> students) {
    final query = _searchController.text.trim().toLowerCase();

    return students.where((student) {
      final matchesSearch = query.isEmpty ||
          student.fullName.toLowerCase().contains(query) ||
          student.grade.toLowerCase().contains(query) ||
          student.section.toLowerCase().contains(query) ||
          (student.nfcUid ?? '').toLowerCase().contains(query);

      final matchesGrade = _gradeFilter == 'all' || student.grade == _gradeFilter;
      final matchesSection = _sectionFilter == 'all' || student.section == _sectionFilter;

      return matchesSearch && matchesGrade && matchesSection;
    }).toList();
  }

  List<String> _uniqueGrades(List<Student> students) {
    final values = students.map((student) => student.grade).toSet().toList()..sort();
    return values;
  }

  List<String> _uniqueSections(List<Student> students) {
    final values = students.map((student) => student.section).toSet().toList()..sort();
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final students = MockDatabase.students;
    final filteredStudents = _filteredStudents(students);
    final grades = _uniqueGrades(students);
    final sections = _uniqueSections(students);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'إدارة الطلاب',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${filteredStudents.length}/${students.length}',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'ابحث، فلتر، عدّل، احذف، أو أعد ضبط بطاقة NFC.',
          style: TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'بحث عن طالب',
            hintText: 'الاسم، الصف، الشعبة، UID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      setState(() => _searchController.clear());
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gradeFilter,
                decoration: const InputDecoration(
                  labelText: 'الصف',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('كل الصفوف')),
                  ...grades.map(
                    (grade) => DropdownMenuItem(value: grade, child: Text(grade)),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _gradeFilter = value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sectionFilter,
                decoration: const InputDecoration(
                  labelText: 'الشعبة',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('كل الشعب')),
                  ...sections.map(
                    (section) => DropdownMenuItem(value: section, child: Text(section)),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _sectionFilter = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (students.isEmpty)
          const _EmptyStudentsCard()
        else if (filteredStudents.isEmpty)
          const _NoResultsCard()
        else
          ...filteredStudents.map(
            (student) => _StudentManagementCard(
              student: student,
              onEdit: () => _showEditStudentDialog(context, student),
              onClearNfc: student.nfcUid == null
                  ? null
                  : () => _confirmClearNfc(context, student),
              onDelete: () => _confirmDeleteStudent(context, student),
            ),
          ),
      ],
    );
  }

  void _showEditStudentDialog(BuildContext context, Student student) {
    final nameController = TextEditingController(text: student.fullName);
    final gradeController = TextEditingController(text: student.grade);
    final sectionController = TextEditingController(text: student.section);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعديل ${student.fullName}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الطالب',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gradeController,
                    decoration: const InputDecoration(
                      labelText: 'الصف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sectionController,
                    decoration: const InputDecoration(
                      labelText: 'الشعبة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final grade = gradeController.text.trim();
                  final section = sectionController.text.trim();

                  if (name.isEmpty || grade.isEmpty || section.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('كل الحقول مطلوبة')),
                    );
                    return;
                  }

                  MockDatabase.updateStudent(
                    studentId: student.id,
                    fullName: name,
                    grade: grade,
                    section: section,
                  );
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClearNfc(BuildContext context, Student student) async {
    final confirmed = await _confirm(
      context: context,
      title: 'إزالة بطاقة NFC؟',
      message: 'سيتم إزالة UID المرتبط بالطالب ${student.fullName}.',
      confirmText: 'إزالة',
    );

    if (confirmed == true) {
      MockDatabase.clearStudentNfcUid(student.id);
    }
  }

  Future<void> _confirmDeleteStudent(BuildContext context, Student student) async {
    final confirmed = await _confirm(
      context: context,
      title: 'حذف الطالب؟',
      message:
          'سيتم حذف ${student.fullName} من قائمة الطلاب. سجلات الحضور السابقة ستبقى محفوظة كأرشيف.',
      confirmText: 'حذف',
      destructive: true,
    );

    if (confirmed == true) {
      await MockDatabase.deleteStudent(student.id);
    }
  }

  Future<bool?> _confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmText),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentManagementCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback? onClearNfc;
  final VoidCallback onDelete;

  const _StudentManagementCard({
    required this.student,
    required this.onEdit,
    required this.onClearNfc,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = student.isInsideSchool ? Colors.green : Colors.red;
    final statusText = student.isInsideSchool ? 'داخل المدرسة' : 'خارج المدرسة';
    final lastScan = student.lastAttendanceAt == null
        ? 'لا يوجد تسجيل'
        : _formatTime(student.lastAttendanceAt!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(
                    student.isInsideSchool ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('الصف: ${student.grade} - الشعبة: ${student.section}'),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'clear_nfc':
                        onClearNfc?.call();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
                    PopupMenuItem(
                      value: 'clear_nfc',
                      enabled: onClearNfc != null,
                      child: const Text('إزالة NFC'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('حذف الطالب'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.location_on,
                  label: statusText,
                  color: statusColor,
                ),
                _InfoChip(
                  icon: Icons.schedule,
                  label: lastScan,
                  color: Colors.blueGrey,
                ),
                _InfoChip(
                  icon: Icons.nfc,
                  label: student.nfcUid == null ? 'NFC غير مربوط' : student.nfcUid!,
                  color: student.nfcUid == null ? Colors.orange : Colors.indigo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17, color: color),
      label: Text(label),
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.18)),
    );
  }
}

class _EmptyStudentsCard extends StatelessWidget {
  const _EmptyStudentsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('لا يوجد طلاب بعد. أضف أول طالب من قسم إضافة طالب.'),
      ),
    );
  }
}

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('لا توجد نتائج مطابقة للبحث أو الفلاتر.'),
      ),
    );
  }
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$hour:$minute - $day/$month';
}
