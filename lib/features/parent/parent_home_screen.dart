import 'package:flutter/material.dart';

import '../../core/data/mock_database.dart';
import '../../core/models/app_user.dart';
import '../../core/models/attendance_record.dart';
import '../../core/models/student.dart';
import '../../core/services/auth_service.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('ولي الأمر'),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: authService.signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: StreamBuilder<AppUser?>(
          stream: authService.watchCurrentAppUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline,
                title: 'تعذر تحميل الحساب',
                message: snapshot.error.toString(),
              );
            }

            final appUser = snapshot.data;

            if (appUser == null) {
              return const _EmptyState(
                icon: Icons.person_off_outlined,
                title: 'لا يوجد حساب نشط',
                message: 'سجّل الدخول مرة أخرى للوصول للوحة ولي الأمر.',
              );
            }

            final linkedStudents = MockDatabase.students
                .where((student) => appUser.linkedStudentIds.contains(student.id))
                .toList();

            if (linkedStudents.isEmpty) {
              return const _EmptyState(
                icon: Icons.family_restroom,
                title: 'لم يتم ربط طلاب بعد',
                message:
                    'اطلب من الإدارة ربط حسابك بطلابك من لوحة المستخدمين والصلاحيات.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeaderCard(
                    parentName: appUser.fullName,
                    childrenCount: linkedStudents.length,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'أبنائي',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...linkedStudents.map((student) {
                    final records = _recordsForStudent(student.id);
                    return _StudentStatusCard(
                      student: student,
                      records: records,
                    );
                  }),
                  const SizedBox(height: 18),
                  const Text(
                    'آخر الحركات',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _RecentActivityList(
                    records: _recordsForStudents(
                      linkedStudents.map((student) => student.id).toSet(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static List<AttendanceRecord> _recordsForStudent(String studentId) {
    return MockDatabase.attendanceRecords
        .where((record) => record.studentId == studentId)
        .take(5)
        .toList();
  }

  static List<AttendanceRecord> _recordsForStudents(Set<String> studentIds) {
    return MockDatabase.attendanceRecords
        .where((record) => studentIds.contains(record.studentId))
        .take(8)
        .toList();
  }
}

class _HeaderCard extends StatelessWidget {
  final String parentName;
  final int childrenCount;

  const _HeaderCard({
    required this.parentName,
    required this.childrenCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1D4ED8), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.family_restroom, color: Colors.white, size: 34),
          const SizedBox(height: 18),
          Text(
            'مرحبًا، $parentName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تتابع الآن $childrenCount من الأبناء المرتبطين بحسابك.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentStatusCard extends StatelessWidget {
  final Student student;
  final List<AttendanceRecord> records;

  const _StudentStatusCard({
    required this.student,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = student.isInsideSchool
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    final statusText = student.isInsideSchool ? 'داخل المدرسة' : 'خارج المدرسة';
    final lastScanText = student.lastAttendanceAt == null
        ? 'لا يوجد تسجيل بعد'
        : _formatDateTime(student.lastAttendanceAt!);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(
                    student.isInsideSchool
                        ? Icons.check_circle
                        : Icons.cancel_rounded,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الصف: ${student.grade} - الشعبة: ${student.section}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    lastScanText,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'آخر السجلات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...records.take(3).map((record) => _RecordTile(record: record)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final List<AttendanceRecord> records;

  const _RecentActivityList({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('لا توجد حركات حضور بعد.'),
        ),
      );
    }

    return Column(
      children: records.map((record) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: _RecordTile(record: record),
        );
      }).toList(),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;

  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isCheckIn = record.isCheckIn;
    final color = isCheckIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final label = isCheckIn ? 'دخول' : 'خروج';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.10),
        child: Icon(isCheckIn ? Icons.login : Icons.logout, color: color),
      ),
      title: Text('${record.studentName} - $label'),
      subtitle: Text(_formatDateTime(record.timestamp)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 78, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
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
