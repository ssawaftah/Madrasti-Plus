import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/school.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/super_admin_service.dart';

class SuperAdminHomeScreenV2 extends StatefulWidget {
  const SuperAdminHomeScreenV2({super.key});

  @override
  State<SuperAdminHomeScreenV2> createState() => _SuperAdminHomeScreenV2State();
}

class _SuperAdminHomeScreenV2State extends State<SuperAdminHomeScreenV2> {
  final _schoolNameController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolCodeController.dispose();
    _addressController.dispose();
    _managerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (_isSaving) return;

    final schoolName = _schoolNameController.text.trim();
    final schoolCode = _schoolCodeController.text.trim().toUpperCase();
    final address = _addressController.text.trim();
    final managerName = _managerNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final validationMessage = _validateForm(
      schoolName: schoolName,
      schoolCode: schoolCode,
      address: address,
      managerName: managerName,
      email: email,
      password: password,
    );

    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final school = await SuperAdminService().createSchool(
        name: schoolName,
        code: schoolCode,
        address: address,
        managerName: managerName,
        email: email,
        password: password,
      );

      _schoolNameController.clear();
      _schoolCodeController.clear();
      _addressController.clear();
      _managerNameController.clear();
      _emailController.clear();
      _passwordController.clear();

      _showMessage('تم إنشاء المدرسة بنجاح. الرمز: ${school.code}');
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error) {
      _showMessage('تعذر إنشاء المدرسة: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateForm({
    required String schoolName,
    required String schoolCode,
    required String address,
    required String managerName,
    required String email,
    required String password,
  }) {
    if (schoolName.isEmpty ||
        schoolCode.isEmpty ||
        address.isEmpty ||
        managerName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      return 'كل الحقول مطلوبة';
    }

    if (schoolCode.length < 3) return 'رمز المدرسة يجب أن يكون 3 أحرف على الأقل';
    if (!email.contains('@')) return 'البريد الإلكتروني غير صحيح';
    if (password.length < 6) return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل لحساب آخر';
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Super Admin'),
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: StreamBuilder<List<School>>(
          stream: SuperAdminService().watchSchools(),
          builder: (context, snapshot) {
            final schools = snapshot.data ?? const <School>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(totalSchools: schools.length),
                const SizedBox(height: 16),
                _CreateSchoolCard(
                  schoolNameController: _schoolNameController,
                  schoolCodeController: _schoolCodeController,
                  addressController: _addressController,
                  managerNameController: _managerNameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isSaving: _isSaving,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onSubmit: _createSchool,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'المدارس',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('${schools.length}'),
                  ],
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (schools.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد مدارس بعد.'),
                    ),
                  )
                else
                  ...schools.map((school) => _SchoolCard(school: school)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int totalSchools;

  const _HeaderCard({required this.totalSchools});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white, size: 42),
          const SizedBox(height: 16),
          const Text(
            'Madrasti Plus Cloud',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'إدارة المدارس ورموز الدخول من مكان واحد. المدارس المفعلة: $totalSchools',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CreateSchoolCard extends StatelessWidget {
  final TextEditingController schoolNameController;
  final TextEditingController schoolCodeController;
  final TextEditingController addressController;
  final TextEditingController managerNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSaving;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _CreateSchoolCard({
    required this.schoolNameController,
    required this.schoolCodeController,
    required this.addressController,
    required this.managerNameController,
    required this.emailController,
    required this.passwordController,
    required this.isSaving,
    required this.obscurePassword,
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
            const Text(
              'إضافة مدرسة جديدة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('رمز المدرسة هنا إجباري وتحدده أنت.'),
            const SizedBox(height: 14),
            _Field(
              controller: schoolNameController,
              label: 'اسم المدرسة',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 10),
            _Field(
              controller: schoolCodeController,
              label: 'رمز المدرسة',
              hint: 'مثال: MAD-001',
              icon: Icons.qr_code_2,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 10),
            _Field(
              controller: addressController,
              label: 'العنوان',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 10),
            _Field(
              controller: managerNameController,
              label: 'اسم مدير المدرسة',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 10),
            _Field(
              controller: emailController,
              label: 'بريد المدير',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة السر',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isSaving ? null : onSubmit,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(isSaving ? 'جاري الإنشاء...' : 'إنشاء المدرسة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final School school;

  const _SchoolCard({required this.school});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: const Icon(Icons.school),
        title: Text(school.name),
        subtitle: Text(
          'الرمز: ${school.code}\nالمدير: ${school.managerName}\n${school.email}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
