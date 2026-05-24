import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/school.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/super_admin_service.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  State<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _managerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final school = await SuperAdminService().createSchool(
        name: _schoolNameController.text,
        address: _addressController.text,
        managerName: _managerNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      _schoolNameController.clear();
      _addressController.clear();
      _managerNameController.clear();
      _emailController.clear();
      _passwordController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء المدرسة بنجاح. رمز المدرسة: ${school.code}'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(error))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إنشاء المدرسة: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل لحساب آخر.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح.';
      case 'weak-password':
        return 'كلمة السر ضعيفة. استخدم 6 أحرف على الأقل.';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت.';
      default:
        return 'فشل إنشاء الحساب: ${error.message ?? error.code}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
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
                _HeroTile(totalSchools: schools.length),
                const SizedBox(height: 18),
                _CreateSchoolCard(
                  formKey: _formKey,
                  schoolNameController: _schoolNameController,
                  addressController: _addressController,
                  managerNameController: _managerNameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  isSaving: _isSaving,
                  onTogglePassword: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onSubmit: _createSchool,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'المدارس',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.28,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                    Text(
                      schools.length.toString(),
                      style: const TextStyle(
                        color: Color(0xFF7A7A7A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (schools.isEmpty)
                  const _EmptySchoolsCard()
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

class _HeroTile extends StatelessWidget {
  final int totalSchools;

  const _HeroTile({required this.totalSchools});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          const Text(
            'Madrasti Plus Cloud',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              height: 1.1,
              letterSpacing: -0.37,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'إدارة المدارس والحسابات من لوحة مركزية واحدة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.47,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0066CC),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$totalSchools مدرسة مفعّلة',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateSchoolCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController schoolNameController;
  final TextEditingController addressController;
  final TextEditingController managerNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSaving;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _CreateSchoolCard({
    required this.formKey,
    required this.schoolNameController,
    required this.addressController,
    required this.managerNameController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSaving,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إضافة مدرسة جديدة',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.28,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'سيتم إنشاء حساب مدير المدرسة في Authentication وربطه برمز مدرسة خاص.',
                style: TextStyle(fontSize: 15, height: 1.45),
              ),
              const SizedBox(height: 18),
              _AppleTextField(
                controller: schoolNameController,
                label: 'اسم المدرسة',
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),
              _AppleTextField(
                controller: addressController,
                label: 'عنوان المدرسة',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _AppleTextField(
                controller: managerNameController,
                label: 'اسم مدير المدرسة',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _AppleTextField(
                controller: emailController,
                label: 'البريد الإلكتروني للمدرسة',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _AppleTextField(
                controller: passwordController,
                label: 'كلمة السر',
                icon: Icons.lock_outline,
                obscureText: obscurePassword,
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: isSaving ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(isSaving ? 'جاري إنشاء المدرسة...' : 'إنشاء المدرسة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _AppleTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (keyboardType == TextInputType.emailAddress && !value.contains('@')) {
          return 'البريد الإلكتروني غير صحيح';
        }
        if (obscureText && value.length < 6) {
          return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
        }
        return null;
      },
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
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0066CC).withOpacity(0.10),
          child: const Icon(Icons.school, color: Color(0xFF0066CC)),
        ),
        title: Text(
          school.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'الرمز: ${school.code}\nالمدير: ${school.managerName}\n${school.email}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _EmptySchoolsCard extends StatelessWidget {
  const _EmptySchoolsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('لا توجد مدارس بعد. أضف أول مدرسة وخلينا نفتح الفرنشايز 😄'),
      ),
    );
  }
}
