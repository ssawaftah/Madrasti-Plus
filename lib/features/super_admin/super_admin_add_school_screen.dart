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
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _schoolType;
  String? _educationStage;
  String? _studentGender;

  int _stepIndex = 0;
  bool _isSaving = false;
  bool _obscurePassword = true;

  static const _blue = Color(0xFF2457D6);
  static const _border = Color(0xFFD8D8DD);
  static const _hint = Color(0xFF8E8E93);

  static const _schoolTypes = ['حكومية', 'خاصة', 'دولية'];
  static const _educationStages = ['أساسي', 'ثانوي', 'أساسي + ثانوي'];
  static const _studentGenders = ['ذكور', 'إناث', 'مختلط'];

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _managerNameController.dispose();
    _schoolCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _stepTitle {
    switch (_stepIndex) {
      case 0:
        return 'المعلومات الأساسية';
      case 1:
        return 'المعلومات التفصيلية';
      default:
        return 'بيانات الدخول';
    }
  }

  void _goBack() {
    if (_stepIndex == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _stepIndex--);
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    setState(() => _stepIndex++);
  }

  bool _validateCurrentStep() {
    if (_stepIndex == 0) {
      if (_schoolNameController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        _showMessage('أكمل المعلومات الأساسية أولًا');
        return false;
      }
      return true;
    }

    if (_stepIndex == 1) {
      if (_schoolType == null ||
          _educationStage == null ||
          _studentGender == null ||
          _managerNameController.text.trim().isEmpty) {
        _showMessage('أكمل المعلومات التفصيلية أولًا');
        return false;
      }
      return true;
    }

    final code = _schoolCodeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (code.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('أكمل بيانات الدخول أولًا');
      return false;
    }
    if (code.length < 3) {
      _showMessage('رمز المدرسة يجب أن يكون 3 أحرف على الأقل');
      return false;
    }
    if (!email.contains('@')) {
      _showMessage('البريد الإلكتروني غير صحيح');
      return false;
    }
    if (password.length < 6) {
      _showMessage('كلمة السر يجب أن تكون 6 أحرف على الأقل');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSaving || !_validateCurrentStep()) return;

    setState(() => _isSaving = true);

    try {
      final school = await SuperAdminService().createSchool(
        name: _schoolNameController.text.trim(),
        code: _schoolCodeController.text.trim().toUpperCase(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        type: _schoolType ?? '',
        educationStage: _educationStage ?? '',
        studentGender: _studentGender ?? '',
        managerName: _managerNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ المدرسة. الرمز: ${school.code}')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      _showMessage(_authError(error));
    } catch (error) {
      _showMessage('تعذر حفظ المدرسة: $error');
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
    final isLastStep = _stepIndex == 2;

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
                onBack: _goBack,
                onClose: () => Navigator.of(context).pop(),
              ),
              _ProgressLine(currentStep: _stepIndex),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                  children: [
                    Text(
                      _stepTitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 22),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _buildStepContent(),
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
                    onPressed: _isSaving ? null : (isLastStep ? _submit : _nextStep),
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
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(isLastStep ? 'حفظ المدرسة' : 'التالي'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_stepIndex) {
      case 0:
        return Column(
          key: const ValueKey('basic-info'),
          children: [
            _LabeledField(label: 'اسم المدرسة *', hint: 'اسم المدرسة', controller: _schoolNameController),
            _LabeledField(label: 'عنوان المدرسة *', hint: 'عنوان المدرسة', controller: _addressController),
            _LabeledField(
              label: 'رقم هاتف المدرسة *',
              hint: 'رقم الهاتف',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey('details-info'),
          children: [
            _LabeledDropdown(
              label: 'نوع المدرسة *',
              hint: 'اختر نوع المدرسة',
              value: _schoolType,
              items: _schoolTypes,
              onChanged: (value) => setState(() => _schoolType = value),
            ),
            _LabeledDropdown(
              label: 'المرحلة الدراسية *',
              hint: 'اختر المرحلة الدراسية',
              value: _educationStage,
              items: _educationStages,
              onChanged: (value) => setState(() => _educationStage = value),
            ),
            _LabeledDropdown(
              label: 'جنس الطلاب *',
              hint: 'اختر جنس الطلاب',
              value: _studentGender,
              items: _studentGenders,
              onChanged: (value) => setState(() => _studentGender = value),
            ),
            _LabeledField(label: 'اسم مدير المدرسة *', hint: 'اسم مدير المدرسة', controller: _managerNameController),
          ],
        );
      default:
        return Column(
          key: const ValueKey('login-info'),
          children: [
            _LabeledField(
              label: 'رمز المدرسة *',
              hint: 'مثال: MAD-001',
              controller: _schoolCodeController,
              textCapitalization: TextCapitalization.characters,
            ),
            _LabeledField(
              label: 'البريد الإلكتروني للمدرسة *',
              hint: 'school@email.com',
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
        );
    }
  }
}

class _FormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _FormHeader({required this.title, required this.onBack, required this.onClose});

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
              style: const TextStyle(color: Color(0xFF111827), fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          Positioned(right: 8, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 31))),
          Positioned(left: 8, child: IconButton(onPressed: onClose, icon: const Icon(Icons.close, size: 31))),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final int currentStep;

  const _ProgressLine({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 4),
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? _SuperAdminAddSchoolScreenState._blue : const Color(0xFFEDEDF2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
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
    return _FormFieldShell(
      label: label,
      child: SizedBox(
        height: 58,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 18, color: Color(0xFF111827)),
          decoration: _inputDecoration(hint: hint, suffixIcon: suffixIcon),
        ),
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FormFieldShell(
      label: label,
      child: SizedBox(
        height: 58,
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _SuperAdminAddSchoolScreenState._hint, size: 30),
          decoration: _inputDecoration(hint: hint),
          hint: Align(
            alignment: Alignment.centerRight,
            child: Text(hint, style: const TextStyle(color: _SuperAdminAddSchoolScreenState._hint, fontSize: 17, fontWeight: FontWeight.w500)),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Align(alignment: Alignment.centerRight, child: Text(item)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FormFieldShell extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormFieldShell({required this.label, required this.child});

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
                style: const TextStyle(color: Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
                children: [
                  TextSpan(text: cleanLabel),
                  if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626))),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _SuperAdminAddSchoolScreenState._hint, fontSize: 17, fontWeight: FontWeight.w500),
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
  );
}
