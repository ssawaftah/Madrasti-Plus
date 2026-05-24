import 'package:flutter/material.dart';

import '../../../core/data/mock_database.dart';
import '../../../core/models/attendance_record.dart';
import '../../../core/models/student.dart';

class DailyAttendanceReportSection extends StatefulWidget {
  const DailyAttendanceReportSection({super.key});

  @override
  State<DailyAttendanceReportSection> createState() =>
      _DailyAttendanceReportSectionState();
}

class _DailyAttendanceReportSectionState
    extends State<DailyAttendanceReportSection> {
  String _gradeFilter = 'all';
  String _sectionFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents(MockDatabase.students);
    final todayRecords = _todayRecordsForStudents(students);
    final checkInsToday = todayRecords.where((record) => record.isCheckIn).length;
    final checkOutsToday = todayRecords.where((record) => !record.isCheckIn).length;
    final insideNow = students.where((student) => student.isInsideSchool).toList();
    final attendedStudentIds = todayRecords.map((record) => record.studentId).toSet();
    final notAttendedToday = students
        .where((student) => !attendedStudentIds.contains(student.id))
        .toList();
    final grades = _uniqueGrades(MockDatabase.students);
    final sections = _uniqueSections(MockDatabase.students);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تقرير اليوم',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _todayLabel(),
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(height: 14),
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _ReportMetricCard(
              title: 'دخول اليوم',
              value: checkInsToday.toString(),
              icon: Icons.login,
              color: const Color(0xFF16A34A),
            ),
            _ReportMetricCard(
              title: 'خروج اليوم',
              value: checkOutsToday.toString(),
              icon: Icons.logout,
              color: const Color(0xFFDC2626),
            ),
            _ReportMetricCard(
              title: 'داخل المدرسة الآن',
              value: insideNow.length.toString(),
              icon: Icons.school,
              color: const Color(0xFF2563EB),
            ),
            _ReportMetricCard(
              title: 'لم يحضروا اليوم',
              value: notAttendedToday.length.toString(),
              icon: Icons.person_off,
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ExpandableReportList(
          title: 'الطلاب داخل المدرسة الآن',
          emptyText: 'لا يوجد طلاب داخل المدرسة حاليًا ضمن الفلتر المحدد.',
          icon: Icons.check_circle,
          color: const Color(0xFF16A34A),
          students: insideNow,
        ),
        const SizedBox(height: 10),
        _ExpandableReportList(
          title: 'الطلاب الذين لم يحضروا اليوم',
          emptyText: 'كل الطلاب ضمن الفلتر لديهم حركة حضور اليوم. ممتاز، بس لا نتحمس كثير 😄',
          icon: Icons.person_off,
          color: const Color(0xFFF59E0B),
          students: notAttendedToday,
        ),
        const SizedBox(height: 10),
        _TodayRecordsList(records: todayRecords),
      ],
    );
  }

  List<Student> _filteredStudents(List<Student> students) {
    return students.where((student) {
      final matchesGrade = _gradeFilter == 'all' || student.grade == _gradeFilter;
      final matchesSection =
          _sectionFilter == 'all' || student.section == _sectionFilter;
      return matchesGrade && matchesSection;
    }).toList();
  }

  List<AttendanceRecord> _todayRecordsForStudents(List<Student> students) {
    final studentIds = students.map((student) => student.id).toSet();

    return MockDatabase.attendanceRecords.where((record) {
      return studentIds.contains(record.studentId) && _isToday(record.timestamp);
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

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  String _todayLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return 'ملخص عمليات الحضور والخروج لهذا اليوم $day/$month/$year';
  }
}

class _ReportMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportMetricCard({
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableReportList extends StatelessWidget {
  final String title;
  final String emptyText;
  final IconData icon;
  final Color color;
  final List<Student> students;

  const _ExpandableReportList({
    required this.title,
    required this.emptyText,
    required this.icon,
    required this.color,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.10),
          child: Icon(icon, color: color),
        ),
        title: Text(
          '$title (${students.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(emptyText),
            )
          else
            ...students.map((student) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.person),
                title: Text(student.fullName),
                subtitle: Text('الصف: ${student.grade} - الشعبة: ${student.section}'),
              );
            }),
        ],
      ),
    );
  }
}

class _TodayRecordsList extends StatelessWidget {
  final List<AttendanceRecord> records;

  const _TodayRecordsList({required this.records});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text(
          'سجل اليوم (${records.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('لا توجد عمليات حضور أو خروج اليوم ضمن الفلتر المحدد.'),
            )
          else
            ...records.take(30).map((record) {
              final color = record.isCheckIn
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626);
              final label = record.isCheckIn ? 'دخول' : 'خروج';

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.10),
                  child: Icon(
                    record.isCheckIn ? Icons.login : Icons.logout,
                    color: color,
                    size: 18,
                  ),
                ),
                title: Text('${record.studentName} - $label'),
                subtitle: Text('الوقت: ${_formatTime(record.timestamp)}'),
              );
            }),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
