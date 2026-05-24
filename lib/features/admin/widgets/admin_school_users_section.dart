import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/data/mock_database.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/school_user_creation_service.dart';
import '../../../core/services/user_management_service.dart';

class AdminSchoolUsersSection extends StatefulWidget {
  const AdminSchoolUsersSection({super.key});

  @override
  State<AdminSchoolUsersSection> createState() => _AdminSchoolUsersSectionState();
}

class _AdminSchoolUsersSectionState extends State<AdminSchoolUsersSection> {
  final _teacherNameController = TextEditingController();
  final _teacherEmailController = TextEditingController();
  final _teacherPasswordController = TextEditingController();

  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPasswordController = TextEditingController();

  bool _isCreatingTeacher = false;
  bool _isCreatingParent = false;
  bool _obscureTeacherPassword = true;
  bool _obscureParentPassword = true;

  @override
  void dispose() {
    _teacherNameController.dispose();
    _teacherEmailController.dispose();
    _teacherPasswordController.dispose();
    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createTeacher() async {
    if (_isCreatingTeacher) return;
    final name = _teacherNameController.text.trim();
    final email = _teacherEmailController.text.trim();
    final password = _teacherPasswordController.text;

    final validation = _validateUserForm(name: name, email: email, password: password);
    if (validation != null) {
      _showMessage(validation);
      return;
    }

    setState(() => _isCreatingTeacher = true);
    try {
      await SchoolUserCreationService().createTeacher(
        fullName: name,
        email: email,
        password: password,
      );
      _teacherNameController.clear();
      _teacherEmailController.clear();
      _teacherPasswordController.clear();
      _showMessage('تم إنشاء حساب المعلم بنجاح');
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error) {
      _showMessage('تعذر إنشاء المعلم: $error');
    } finally {
      if (mounted) setState(() => _isCreatingTeacher = false);
    }
  }

  Future<void> _createParent() async {
    if (_isCreatingParent) return;
    final name = _parentNameController.text.trim();
    final email = _parentEmailController.text.trim();
    final password = _parentPasswordController.text;

    final validation = _validateUserForm(name: name, email: email, password: password);
    if (validation != null) {
      _showMessage(validation);
      return;
    }

    setState(() => _isCreatingParent = true);
    try {
      await SchoolUserCreationService().createParent(
        fullName: name,
        email: email,
        password: password,
      );
      _parentNameController.clear();
      _parentEmailController.clear();
      _parentPasswordController.clear();
      _showMessage('تم إنشاء حساب ولي الأمر بنجاح');
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error) {
      _showMessage('تعذر إنشاء ولي الأمر: $error');
    } finally {
      if (mounted) setState(() => _isCreatingParent = false);
    }
  }

  String? _validateUserForm({
    required String name,
    required String email,
    required String password,
  }) {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'الاسم والبريد وكلمة السر مطلوبة';
    }
    if (!email.contains('@')) return 'البريد الإلكتروني غير صحيح';
    if (password.length < 6) return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة السر ضعيفة';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'فشل إنشاء الحساب: ${error.message ?? error.code}';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: AuthService().getCurrentAppUserOrThrow(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (adminSnapshot.hasError || !adminSnapshot.hasData) {
          return Text('تعذر تحميل حساب المدير: ${adminSnapshot.error}');
        }

        final admin = adminSnapshot.data!;
        final service = UserManagementService();

        return StreamBuilder<List<AppUser>>(
          stream: service.watchUsers(),
          builder: (context, snapshot) {
            final users = (snapshot.data ?? const <AppUser>[])
                .where((user) => user.schoolId == admin.schoolId)
                .where((user) => user.role == 'teacher' || user.role == 'parent')
                .toList();
            final teachers = users.where((user) => user.role == 'teacher').toList();
            final parents = users.where((user) => user.role == 'parent').toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'المستخدمون',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أنشئ حسابات المعلمين وأولياء الأمور ضمن مدرستك فقط.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                _CreateUserCard(
                  title: 'إضافة معلم',
                  icon: Icons.co_present,
                  nameController: _teacherNameController,
                  emailController: _teacherEmailController,
                  passwordController: _teacherPasswordController,
                  obscurePassword: _obscureTeacherPassword,
                  isSaving: _isCreatingTeacher,
                  submitLabel: 'إنشاء معلم',
                  onTogglePassword: () {
                    setState(() => _obscureTeacherPassword = !_obscureTeacherPassword);
                  },
                  onSubmit: _createTeacher,
                ),
                const SizedBox(height: 14),
                _CreateUserCard(
                  title: 'إضافة ولي أمر',
                  icon: Icons.family_restroom,
                  nameController: _parentNameController,
                  emailController: _parentEmailController,
                  passwordController: _parentPasswordController,
                  obscurePassword: _obscureParentPassword,
                  isSaving: _isCreatingParent,
                  submitLabel: 'إنشاء ولي أمر',
                  onTogglePassword: () {
                    setState(() => _obscureParentPassword = !_obscureParentPassword);
                  },
                  onSubmit: _createParent,
                ),
                const SizedBox(height: 22),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  Text('تعذر تحميل المستخدمين: ${snapshot.error}')
                else ...[
                  _UsersListCard(
                    title: 'المعلمون',
                    emptyText: 'لا يوجد معلمون بعد.',
                    users: teachers,
                    trailingBuilder: (teacher) => OutlinedButton.icon(
                      onPressed: () => _showTeacherAssignmentsDialog(
                        context: context,
                        user: teacher,
                        service: service,
                      ),
                      icon: const Icon(Icons.class_),
                      label: Text(
                        teacher.assignedGrades.isEmpty && teacher.assignedSections.isEmpty
                            ? 'تعيين الصفوف'
                            : '${teacher.assignedGrades.length} صف | ${teacher.assignedSections.length} شعبة',
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _UsersListCard(
                    title: 'أولياء الأمور',
                    emptyText: 'لا يوجد أولياء أمور بعد.',
                    users: parents,
                    trailingBuilder: (parent) => OutlinedButton.icon(
                      onPressed: () => _showLinkStudentsDialog(
                        context: context,
                        user: parent,
                        service: service,
                      ),
                      icon: const Icon(Icons.link),
                      label: Text(
                        parent.linkedStudentIds.isEmpty
                            ? 'ربط الطلاب'
                            : '${parent.linkedStudentIds.length} طالب',
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
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
                title: Text('ربط الطلاب - ${user.fullName}'),
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
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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
    final grades = MockDatabase.students.map((student) => student.grade).toSet().toList()..sort();
    final sections = MockDatabase.students.map((student) => student.section).toSet().toList()..sort();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text('تعيين المعلم - ${user.fullName}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('الصفوف', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (grades.isEmpty)
                          const Text('لا توجد صفوف بعد.')
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
                        const Divider(),
                        const Text('الشعب', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (sections.isEmpty)
                          const Text('لا توجد شعب بعد.')
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
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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

class _CreateUserCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSaving;
  final String submitLabel;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _CreateUserCard({
    required this.title,
    required this.icon,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSaving,
    required this.submitLabel,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة السر',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isSaving ? null : onSubmit,
              icon: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: Text(isSaving ? 'جاري الإنشاء...' : submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersListCard extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<AppUser> users;
  final Widget Function(AppUser user) trailingBuilder;

  const _UsersListCard({
    required this.title,
    required this.emptyText,
    required this.users,
    required this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('$title (${users.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (users.isEmpty)
              Text(emptyText)
            else
              ...users.map((user) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_circle),
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  trailing: trailingBuilder(user),
                );
              }),
          ],
        ),
      ),
    );
  }
}
