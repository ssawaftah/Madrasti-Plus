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
  static const border = Color(0xFFCFCFD4);
  static const hint = Color(0xFF8E8E93);

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    phone.dispose();
    manager.dispose();
    code.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  String get title => step == 0
      ? 'المعلومات الأساسية'
      : step == 1
          ? 'المعلومات التفصيلية للمدرسة'
          : 'بيانات الدخول';

  bool get canContinue {
    if (step == 0) {
      return name.text.trim().isNotEmpty && address.text.trim().isNotEmpty && phone.text.trim().isNotEmpty;
    }
    if (step == 1) {
      return schoolType != null && stage != null && studentsType != null && manager.text.trim().isNotEmpty;
    }
    return code.text.trim().length >= 3 && email.text.trim().contains('@') && pass.text.length >= 6;
  }

  void toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool valid() {
    if (step == 0) {
      if (!canContinue) {
        toast('أكمل المعلومات الأساسية');
        return false;
      }
      return true;
    }
    if (step == 1) {
      if (!canContinue) {
        toast('أكمل المعلومات التفصيلية');
        return false;
      }
      return true;
    }
    if (code.text.trim().length < 3) {
      toast('رمز المدرسة قصير');
      return false;
    }
    if (!email.text.trim().contains('@')) {
      toast('البريد الإلكتروني غير صحيح');
      return false;
    }
    if (pass.text.length < 6) {
      toast('كلمة السر قصيرة');
      return false;
    }
    return true;
  }

  void next() {
    if (valid()) setState(() => step++);
  }

  void back() {
    step == 0 ? Navigator.of(context).pop() : setState(() => step--);
  }

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

  void openPicker({
    required String title,
    required List<String> items,
    required String? value,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  ...items.map((item) {
                    final selected = item == value;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        onSelect(item);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          children: [
                            Expanded(child: Text(item, textAlign: TextAlign.right, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
                            const SizedBox(width: 14),
                            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? blue : hint, size: 26),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 64),
                        child: Center(
                          child: Text('إضافة مدرسة جديدة', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ),
                    Positioned(right: 2, child: IconButton(onPressed: back, icon: const Icon(Icons.arrow_back, size: 31))),
                    Positioned(left: 2, child: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 31))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: i == 2 ? 0 : 4),
                      height: 6,
                      decoration: BoxDecoration(color: i <= step ? blue : const Color(0xFFEDEDF2), borderRadius: BorderRadius.circular(99)),
                    ),
                  )),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    if (step == 0) ...[
                      field('اسم المدرسة *', 'اسم المدرسة', name),
                      field('عنوان المدرسة *', 'عنوان المدرسة', address),
                      field('رقم هاتف المدرسة *', 'رقم هاتف المدرسة', phone, type: TextInputType.phone),
                    ] else if (step == 1) ...[
                      select('نوع المدرسة *', 'اختر نوع المدرسة', schoolType, const ['حكومية', 'خاصة', 'دولية'], (v) => setState(() => schoolType = v)),
                      select('المرحلة الدراسية *', 'اختر المرحلة الدراسية', stage, const ['أساسي', 'ثانوي', 'أساسي + ثانوي'], (v) => setState(() => stage = v)),
                      select('جنس الطلاب *', 'اختر جنس الطلاب', studentsType, const ['ذكور', 'إناث', 'مختلط'], (v) => setState(() => studentsType = v)),
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
                  height: 56,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving || !canContinue ? null : (step == 2 ? save : next),
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFF1F1F4),
                      disabledForegroundColor: const Color(0xFF777777),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
    return shell(label, TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      textCapitalization: caps,
      textAlign: TextAlign.right,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 17, color: Color(0xFF111827)),
      decoration: deco(hintText, suffix),
    ));
  }

  Widget select(String label, String hintText, String? val, List<String> list, ValueChanged<String?> change) {
    return shell(label, InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => openPicker(
        title: label.replaceAll('*', '').trim(),
        items: list,
        value: val,
        onSelect: (v) => change(v),
      ),
      child: InputDecorator(
        decoration: deco(hintText, null),
        child: Row(
          children: [
            Expanded(
              child: Text(
                val ?? hintText,
                textAlign: TextAlign.right,
                style: TextStyle(color: val == null ? hint : const Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: hint, size: 30),
          ],
        ),
      ),
    ));
  }

  Widget shell(String label, Widget child) {
    final clean = label.replaceAll('*', '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF111827), fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Roboto'),
              children: [TextSpan(text: clean), if (label.contains('*')) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))],
            ),
          ),
        ),
        SizedBox(height: 54, child: child),
      ]),
    );
  }

  InputDecoration deco(String hintText, Widget? suffix) => InputDecoration(
    hintText: hintText,
    suffixIcon: suffix,
    hintStyle: const TextStyle(color: hint, fontSize: 16, fontWeight: FontWeight.w500),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border, width: 1.2)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border, width: 1.2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: blue, width: 1.4)),
  );
}
