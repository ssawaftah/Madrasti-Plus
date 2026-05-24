import 'package:flutter/material.dart';

import '../../../core/data/mock_database.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/user_management_service.dart';

class AdminUsersSection extends StatelessWidget {
  const AdminUsersSection({super.key});

  static const _roles = [
    'admin',
    'teacher',
    'parent',
    'nfc_device',
  ];

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'الإدارة';
      case 'teacher':
        return 'المعلم';
      case 'parent':
        return 'ولي الأمر';
      case 'nfc_device':
        return 'جهاز البوابة';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = UserManagementService();

    return StreamBuilder<List<AppUser>>(
      stream: service.watchUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <AppUser>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'المستخدمون والصلاحيات',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'غيّر دور الحسابات واربط أولياء الأمور بالطلاب وعيّن صفوف المعلمين.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (snapshot.hasError)
              Text('تعذر تحميل المستخدمين: ${snapshot.error}')
            else if (users.isEmpty)
              const Text('لا يوجد مستخدمون بعد. سجّل دخول حساب جديد مرة واحدة أولًا.')
            else
              ...users.map((user) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.account_circle, size: 34),
                          title: Text(user.fullName),
                          subtitle: Text(user.email),
                        ),
                        DropdownButtonFormField<String>(
                          value: _roles.contains(user.role) ? user.role : 'parent',
                          decoration: const InputDecoration(
                            labelText: 'الدور',
                            border: OutlineInputBorder(),
                          ),
                          items: _roles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(_roleLabel(role)),
                            );
                          }).toList(),
                          onChanged: (role) {
                            if (role == null) return;
                            service.updateUserRole(userId: user.id, role: role);
                          },
                        ),
                        if (user.role == 'parent') ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showLinkStudentsDialog(
                              context: context,
                              user: user,
                              service: service,
                            ),
                            icon: const Icon(Icons.family_restroom),
                            label: Text(
                              user.linkedStudentIds.isEmpty
                                  ? 'ربط ولي الأمر بطلاب'
                                  : 'الطلاب المرتبطون: ${user.linkedStudentIds.length}',
                            ),
                          ),
                        ],
                        if (user.role == 'teacher') ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showTeacherAssignmentsDialog(
                              context: context,
                              user: user,
                              service: service,
                            ),
                            icon: const Icon(Icons.class_),
                            label: Text(
                              user.assignedGrades.isEmpty &&
                                      user.assignedSections.isEmpty
                                  ? 'تعيين الصفوف والشعب'
                                  : 'الصفوف: ${user.assignedGrades.length} | الشعب: ${user.assignedSections.length}',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showLinkStudentsDialog({
    required BuildContext context,
    required AppUser user,
    required UserManagementService service,
  }) {
    final selectedIds = user.linkedStudentIds.toSet();
    final students = MockDatabase.students;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text('ربط طلاب - ${user.email}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: students.isEmpty
                      ? const Text('لا يوجد طلاب بعد.')
                      : ListView(
                          shrinkWrap: true,
                          children: students.map((student) {
                            final isSelected = selectedIds.contains(student.id);
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(student.fullName),
                              subtitle: Text('${student.grade} - ${student.section}'),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedIds.add(student.id);
                                  } else {
                                    selectedIds.remove(student.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await service.updateLinkedStudentIds(
                        userId: user.id,
                        linkedStudentIds: selectedIds.toList(),
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTeacherAssignmentsDialog({
    required BuildContext context,
    required AppUser user,
    required UserManagementService service,
  }) {
    final selectedGrades = user.assignedGrades.toSet();
    final selectedSections = user.assignedSections.toSet();
    final grades = MockDatabase.students.map((student) => student.grade).toSet().toList()
      ..sort();
    final sections = MockDatabase.students.map((student) => student.section).toSet().toList()
      ..sort();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text('تعيين المعلم - ${user.email}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'الصفوف المسموحة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (grades.isEmpty)
                          const Text('لا توجد صفوف بعد. أضف طلابًا أولًا.')
                        else
                          ...grades.map((grade) {
                            return CheckboxListTile(
                              value: selectedGrades.contains(grade),
                              title: Text(grade),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedGrades.add(grade);
                                  } else {
                                    selectedGrades.remove(grade);
                                  }
                                });
                              },
                            );
                          }),
                        const Divider(height: 24),
                        const Text(
                          'الشُعب المسموحة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (sections.isEmpty)
                          const Text('لا توجد شعب بعد. أضف طلابًا أولًا.')
                        else
                          ...sections.map((section) {
                            return CheckboxListTile(
                              value: selectedSections.contains(section),
                              title: Text(section),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedSections.add(section);
                                  } else {
                                    selectedSections.remove(section);
                                  }
                                });
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await service.updateTeacherAssignments(
                        userId: user.id,
                        assignedGrades: selectedGrades.toList()..sort(),
                        assignedSections: selectedSections.toList()..sort(),
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
