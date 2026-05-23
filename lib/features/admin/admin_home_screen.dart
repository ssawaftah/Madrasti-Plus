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

  @override
  Widget build(BuildContext context) {
    final students = MockDatabase.students;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإدارة'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                (student) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(student.fullName),
                    subtitle: Text(
                      'الصف: ${student.grade} - الشعبة: ${student.section}',
                    ),
                    trailing: Icon(
                      student.isInsideSchool
                          ? Icons.check_circle
                          : Icons.cancel,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
