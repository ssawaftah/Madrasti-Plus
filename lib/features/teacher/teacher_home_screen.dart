import 'package:flutter/material.dart';

import '../../core/data/mock_database.dart';
import '../../core/models/app_user.dart';
import '../../core/models/attendance_record.dart';
import '../../core/models/student.dart';
import '../../core/services/auth_service.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _searchController = TextEditingController();
  String _gradeFilter = 'all';
  String _sectionFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Student> _assignedStudents(List<Student> students, AppUser teacher) {
    if (teacher.assignedGrades.isEmpty || teacher.assignedSections.isEmpty) {
      return [];
    }

    return students.where((student) {
      return teacher.assignedGrades.contains(student.grade) &&
          teacher.assignedSections.contains(student.section);
    }).toList();
  }

  List<Student> _filteredStudents(List<Student> students) {
    final query = _searchController.text.trim().toLowerCase();

    return students.where((student) {
      final matchesSearch = query.isEmpty ||
          student.fullName.toLowerCase().contains(query) ||
          student.grade.toLowerCase().contains(query) ||
          student.section.toLowerCase().contains(query);
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

  List<AttendanceRecord> _todayRecordsForStudents(List<Student> students) {
    final studentIds = students.map((student) => student.id).toSet();
    return MockDatabase.attendanceRecords.where((record) {
      return studentIds.contains(record.studentId) && _isToday(record.timestamp);
    }).toList();
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<AppUser?>(
      stream: authService.watchCurrentAppUser(),
      builder: (context, userSnapshot) {
        final teacher = userSnapshot.data;

        return ValueListenableBuilder<int>(
          valueListenable: MockDatabase.revision,
          builder: (context, _, __) {
            final allStudents = MockDatabase.students;
            final assignedStudents = teacher == null
                ? <Student>[]
                : _assignedStudents(allStudents, teacher);
            final filteredStudents = _filteredStudents(assignedStudents);
            final todayRecords = _todayRecordsForStudents(filteredStudents);
            final attendedStudentIds =
                todayRecords.map((record) => record.studentId).toSet();
            final insideCount = filteredStudents
                .where((student) => student.isInsideSchool)
                .length;
            final outsideCount = filteredStudents.length - insideCount;
            final absentTodayCount = filteredStudents
                .where((student) => !attendedStudentIds.contains(student.id))
                .length;
            final grades = _uniqueGrades(assignedStudents);
            final sections = _uniqueSections(assignedStudents);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                appBar: AppBar(
                  title: const Text('المعلم'),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      tooltip: 'تسجيل الخروج',
                      onPressed: () => AuthService().signOut(),
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                body: userSnapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : teacher == null
                        ? const _EmptyCard(
                            icon: Icons.person_off,
                            title: 'تعذر تحميل حساب المعلم',
                            message: 'سجّل الخروج ثم ادخل مرة أخرى.',
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              MockDatabase.startRealtimeSync();
                              await Future<void>.delayed(
                                const Duration(milliseconds: 350),
                              );
                            },
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                _TeacherHeaderCard(teacher: teacher),
                                const SizedBox(height: 16),
                                if (teacher.assignedGrades.isEmpty ||
                                    teacher.assignedSections.isEmpty)
                                  const _EmptyCard(
                                    icon: Icons.assignment_ind,
                                    title: 'لم يتم تعيين صفوف لك بعد',
                                    message:
                                        'اطلب من الإدارة تعيين الصفوف والشُعب الخاصة بك من قسم المستخدمين.',
                                  )
                                else ...[
                                  GridView.count(
                                    crossAxisCount: 2,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.35,
                                    children: [
                                      _MetricCard(
                                        title: 'ضمن الفلتر',
                                        value: filteredStudents.length.toString(),
                                        icon: Icons.groups,
                                        color: const Color(0xFF2563EB),
                                      ),
                                      _MetricCard(
                                        title: 'داخل المدرسة',
                                        value: insideCount.toString(),
                                        icon: Icons.check_circle,
                                        color: const Color(0xFF16A34A),
                                      ),
                                      _MetricCard(
                                        title: 'خارج المدرسة',
                                        value: outsideCount.toString(),
                                        icon: Icons.cancel,
                                        color: const Color(0xFFDC2626),
                                      ),
                                      _MetricCard(
                                        title: 'لم يحضروا اليوم',
                                        value: absentTodayCount.toString(),
                                        icon: Icons.person_off,
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  _FiltersCard(
                                    searchController: _searchController,
                                    grades: grades,
                                    sections: sections,
                                    gradeFilter: _gradeFilter,
                                    sectionFilter: _sectionFilter,
                                    onSearchChanged: () => setState(() {}),
                                    onGradeChanged: (value) =>
                                        setState(() => _gradeFilter = value),
                                    onSectionChanged: (value) =>
                                        setState(() => _sectionFilter = value),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'الطلاب',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${filteredStudents.length}/${assignedStudents.length}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (assignedStudents.isEmpty)
                                    const _EmptyCard(
                                      icon: Icons.groups_outlined,
                                      title: 'لا يوجد طلاب ضمن التعيين',
                                      message:
                                          'تأكد أن الصفوف والشُعب المعينة تحتوي طلابًا.',
                                    )
                                  else if (filteredStudents.isEmpty)
                                    const _EmptyCard(
                                      icon: Icons.search_off,
                                      title: 'لا توجد نتائج',
                                      message: 'جرّب تغيير البحث أو الفلاتر.',
                                    )
                                  else
                                    ...filteredStudents.map((student) {
                                      final records = MockDatabase
                                          .attendanceRecords
                                          .where((record) =>
                                              record.studentId == student.id)
                                          .take(3)
                                          .toList();
                                      return _TeacherStudentCard(
                                        student: student,
                                        records: records,
                                      );
                                    }),
                                ],
                              ],
                            ),
                          ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TeacherHeaderCard extends StatelessWidget {
  final AppUser teacher;

  const _TeacherHeaderCard({required this.teacher});

  @override
  Widget build(BuildContext context) {
    final assignedText = teacher.assignedGrades.isEmpty ||
            teacher.assignedSections.isEmpty
        ? 'لم يتم تعيين صفوف وشُعب بعد.'
        : 'الصفوف: ${teacher.assignedGrades.join(', ')} | الشعب: ${teacher.assignedSections.join(', ')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0F766E), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.co_present, color: Colors.white, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوحة المعلم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  assignedText,
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> grades;
  final List<String> sections;
  final String gradeFilter;
  final String sectionFilter;
  final VoidCallback onSearchChanged;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onSectionChanged;

  const _FiltersCard({
    required this.searchController,
    required this.grades,
    required this.sections,
    required this.gradeFilter,
    required this.sectionFilter,
    required this.onSearchChanged,
    required this.onGradeChanged,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'بحث عن طالب',
                hintText: 'الاسم، الصف، الشعبة',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged();
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => onSearchChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: gradeFilter,
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
                      if (value != null) onGradeChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: sectionFilter,
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
                      if (value != null) onSectionChanged(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherStudentCard extends StatelessWidget {
  final Student student;
  final List<AttendanceRecord> records;

  const _TeacherStudentCard({required this.student, required this.records});

  @override
  Widget build(BuildContext context) {
    final color = student.isInsideSchool
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final statusText = student.isInsideSchool ? 'داخل المدرسة' : 'خارج المدرسة';
    final lastScanText = student.lastAttendanceAt == null
        ? 'لا يوجد تسجيل بعد'
        : _formatDateTime(student.lastAttendanceAt!);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.10),
          child: Icon(
            student.isInsideSchool ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
        ),
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${student.grade} - ${student.section} | $statusText'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Row(
            children: [
              Expanded(
                child: _SmallInfoBox(title: 'الحالة', value: statusText, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallInfoBox(
                  title: 'آخر تسجيل',
                  value: lastScanText,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'آخر الحركات',
              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          if (records.isEmpty)
            const Align(
              alignment: Alignment.centerRight,
              child: Text('لا توجد حركات لهذا الطالب بعد.'),
            )
          else
            ...records.map((record) => _RecordRow(record: record)),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AttendanceRecord record;

  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final isCheckIn = record.isCheckIn;
    final color = isCheckIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final label = isCheckIn ? 'دخول' : 'خروج';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(isCheckIn ? Icons.login : Icons.logout, color: color),
      title: Text(label),
      subtitle: Text(_formatDateTime(record.timestamp)),
    );
  }
}

class _SmallInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SmallInfoBox({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
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
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCard({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$hour:$minute - $day/$month';
}
