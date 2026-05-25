import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/super_admin_service.dart';

class SuperAdminAddSchoolScreen extends StatefulWidget {
  const SuperAdminAddSchoolScreen({super.key});

  @override
  State<SuperAdminAddSchoolScreen> createState() => _SuperAdminAddSchoolScreenState();
}

class _SuperAdminAddSchoolScreenState extends State<SuperAdminAddSchoolScreen> {
  final _schoolNameController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSaving = false;
  bool _obscurePassword = true;

  static const _blue = Color(0xFF2457D6);
  static const _border = Color(0xFFD8D8DD);
  static const _hint = Color(0xFF8E8E93);

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

  Future<void> _submit() async {
    if (_isSaving) return;

    final name = _schoolNameController.text.trim();
    final code = _schoolCodeController.text.trim().toUpperCase();
    final address = _addressController.text.trim();
    final managerName = _managerNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || code.isEmpty || address.isEmpty || managerName.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('كل الحقول مطلوبة');
      return;
    }

    if (code.length < 3) {
      _showMessage('رمز المدرسة يجب أن يكون 3 أحرف على الأقل');
      return;
    }

    if (!email.contains('@')) {
      _showMessage('البريد الإلكتروني غير صحيح');
      return;
    }

    if (password.length < 6) {
      _showMessage('كلمة السر يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final school = await SuperAdminService().createSchool(
        name: name,
        code: code,
        address: address,
        managerName: managerName,
        email: email,
        password: password,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء المدرسة. الرمز: ${school.code}')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      _showMessage(_authError(error));
    } catch (error) {
      _showMessage('تعذر إنشاء المدرسة: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _authError(FirebaseAuthException error) {
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _FormHeader(
                title: 'إضافة مدرسة جديدة',
                onClose: () => Navigator.of(context).pop(),
              ),
              const _ProgressLine(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
                  children: [
                    _LabeledField(
                      label: 'اسم المدرسة *',
                      hint: 'اسم المدرسة',
                      controller: _schoolNameController,
                    ),
                    _LabeledField(
                      label: 'رمز المدرسة *',
                      hint: 'مثال: MAD-001',
                      controller: _schoolCodeController,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    _LabeledField(
                      label: 'العنوان *',
                      hint: 'عنوان المدرسة',
                      controller: _addressController,
                    ),
                    _LabeledField(
                      label: 'اسم مدير المدرسة *',
                      hint: 'اسم المدير',
                      controller: _managerNameController,
                    ),
                    _LabeledField(
                      label: 'البريد الإلكتروني للمدير *',
                      hint: 'example@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _LabeledField(
                      label: 'كلمة السر *',
                      hint: 'كلمة السر',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: _hint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: const Color(0xFFF1F1F4),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: _hint,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('إنشاء المدرسة'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _FormHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: 8,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back, size: 31),
            ),
          ),
          Positioned(
            left: 8,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 31),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: _SuperAdminAddSchoolScreenState._blue,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: _SuperAdminAddSchoolScreenState._blue,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isRequired = label.contains('*');
    final cleanLabel = label.replaceAll('*', '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                ),
                children: [
                  TextSpan(text: cleanLabel),
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: _SuperAdminAddSchoolScreenState._hint,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
                suffixIcon: suffixIcon,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _SuperAdminAddSchoolScreenState._border, width: 1.3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _SuperAdminAddSchoolScreenState._border, width: 1.3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _SuperAdminAddSchoolScreenState._blue, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
