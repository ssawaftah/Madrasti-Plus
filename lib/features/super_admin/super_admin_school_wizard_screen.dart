import 'package:flutter/material.dart';

import '../../core/services/super_admin_service.dart';

class SuperAdminSchoolWizardScreen extends StatefulWidget {
  const SuperAdminSchoolWizardScreen({super.key});

  @override
  State<SuperAdminSchoolWizardScreen> createState() => _SuperAdminSchoolWizardScreenState();
}

class _SuperAdminSchoolWizardScreenState extends State<SuperAdminSchoolWizardScreen> {
  final name = TextEditingController();
  final address = TextEditingController();
  final phone = TextEditingController();
  final manager = TextEditingController();
  final code = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();

  String? schoolType;
  String? stage;
  String? studentsType;
  int step = 0;
  bool saving = false;
  bool hidePass = true;

  static const blue = Color(0xFF2457D6);
  static const border = Color(0xFFD8D8DD);
  static const hint = Color(0xFF8E8E93);

  @override
  void dispose() {
    name.dispose(); address.dispose(); phone.dispose(); manager.dispose();
    code.dispose(); email.dispose(); pass.dispose();
    super.dispose();
  }

  String get title => step == 0
      ? 'المعلومات الأساسية'
      : step == 1
          ? 'المعلومات التفصيلية للمدرسة'
          : 'بيانات الدخول';

  void toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool valid() {
    if (step == 0) {
      if (name.text.trim().isEmpty || address.text.trim().isEmpty || phone.text.trim().isEmpty) {
        toast('أكمل المعلومات الأساسية');
        return false;
      }
      return true;
    }
    if (step == 1) {
      if (schoolType == null || stage == null || studentsType == null || manager.text.trim().isEmpty) {
        toast('أكمل المعلومات التفصيلية');
        return false;
      }
      return true;
    }
    if (code.text.trim().length < 3) { toast('رمز المدرسة قصير'); return false; }
    if (!email.text.trim().contains('@')) { toast('البريد الإلكتروني غير صحيح'); return false; }
    if (pass.text.length < 6) { toast('كلمة السر قصيرة'); return false; }
    return true;
  }

  void next() { if (valid()) setState(() => step++); }
  void back() { step == 0 ? Navigator.of(context).pop() : setState(() => step--); }

  Future<void> save() async {
    if (saving || !valid()) return;
    setState(() => saving = true);
    try {
      final school = await SuperAdminService().createSchool(
        name: name.text.trim(),
        address: address.text.trim(),
        phone: phone.text.trim(),
        type: schoolType ?? '',
        educationStage: stage ?? '',
        studentGender: studentsType ?? '',
        managerName: manager.text.trim(),
        code: code.text.trim().toUpperCase(),
        email: email.text.trim(),
        password: pass.text,
      );
      if (!mounted) return;
      toast('تم حفظ المدرسة. الرمز: ${school.code}');
      Navigator.of(context).pop();
    } catch (e) {
      toast('تعذر حفظ المدرسة: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('إضافة مدرسة جديدة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    Positioned(right: 8, child: IconButton(onPressed: back, icon: const Icon(Icons.arrow_back, size: 31))),
                    Positioned(left: 8, child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 31))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: List.generate(3, (i) => Expanded(child: Container(
                  margin: EdgeInsets.only(left: i == 2 ? 0 : 4), height: 7,
                  decoration: BoxDecoration(color: i <= step ? blue : const Color(0xFFEDEDF2), borderRadius: BorderRadius.circular(99)),
                )))),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    if (step == 0) ...[
                      field('اسم المدرسة *', 'اسم المدرسة', name),
                      field('عنوان المدرسة *', 'عنوان المدرسة', address),
                      field('رقم هاتف المدرسة *', 'رقم هاتف المدرسة', phone, type: TextInputType.phone),
                    ] else if (step == 1) ...[
                      select('نوع المدرسة *', 'اختر نوع المدرسة', schoolType, const ['حكومية', 'خاصة', 'دولية'], (v) => setState(() => schoolType = v)),
                      select('المرحلة الدراسية *', 'اختر المرحلة الدراسية', stage, const ['أساسي', 'ثانوي', 'أساسي + ثانوي'], (v) => setState(() => stage = v)),
                      select('فئة الطلاب *', 'اختر فئة الطلاب', studentsType, const ['بنين', 'بنات', 'مختلط'], (v) => setState(() => studentsType = v)),
                      field('اسم مدير المدرسة *', 'اسم مدير المدرسة', manager),
                    ] else ...[
                      field('رمز المدرسة *', 'مثال: MAD-001', code, caps: TextCapitalization.characters),
                      field('البريد الإلكتروني للمدرسة *', 'school@email.com', email, type: TextInputType.emailAddress),
                      field('كلمة السر *', 'كلمة السر', pass, obscure: hidePass, suffix: IconButton(onPressed: () => setState(() => hidePass = !hidePass), icon: Icon(hidePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: hint))),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: SizedBox(
                  height: 58, width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : (step == 2 ? save : next),
                    style: FilledButton.styleFrom(backgroundColor: blue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(step == 2 ? 'حفظ المدرسة' : 'التالي', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(String label, String hintText, TextEditingController c, {bool obscure = false, TextInputType? type, TextCapitalization caps = TextCapitalization.none, Widget? suffix}) {
    return shell(label, TextField(controller: c, obscureText: obscure, keyboardType: type, textCapitalization: caps, textAlign: TextAlign.right, decoration: deco(hintText, suffix)));
  }

  Widget select(String label, String hintText, String? val, List<String> list, ValueChanged<String?> change) {
    return shell(label, DropdownButtonFormField<String>(value: val, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: hint), decoration: deco(hintText, null), hint: Text(hintText, style: const TextStyle(color: hint)), items: list.map((e) => DropdownMenuItem(value: e, alignment: Alignment.centerRight, child: Text(e))).toList(), onChanged: change));
  }

  Widget shell(String label, Widget child) {
    final clean = label.replaceAll('*', '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.only(bottom: 9), child: RichText(textAlign: TextAlign.right, text: TextSpan(style: const TextStyle(color: Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Roboto'), children: [TextSpan(text: clean), if (label.contains('*')) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))]))),
        SizedBox(height: 58, child: child),
      ]),
    );
  }

  InputDecoration deco(String hintText, Widget? suffix) => InputDecoration(
    hintText: hintText, suffixIcon: suffix,
    hintStyle: const TextStyle(color: hint, fontSize: 17, fontWeight: FontWeight.w500),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border, width: 1.3)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border, width: 1.3)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: blue, width: 1.5)),
  );
}
