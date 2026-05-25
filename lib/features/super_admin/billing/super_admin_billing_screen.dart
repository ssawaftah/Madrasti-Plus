import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/models/school.dart';
import '../../../core/services/super_admin_service.dart';

class SuperAdminBillingScreen extends StatefulWidget {
  const SuperAdminBillingScreen({super.key});

  @override
  State<SuperAdminBillingScreen> createState() => _SuperAdminBillingScreenState();
}

class _SuperAdminBillingScreenState extends State<SuperAdminBillingScreen> {
  int _selectedTab = 0;
  static const _muted = Color(0xFF6B7280);

  final _tabs = const [
    'الملخص',
    'إضافة اشتراك',
    'اشتراكات المدارس',
    'التجارب المجانية',
    'الخطط والأسعار',
    'تنبيهات الفوترة',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<List<School>>(
            stream: SuperAdminService().watchSchools(),
            builder: (context, snapshot) {
              final schools = snapshot.data ?? const <School>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 18),
                  const Text(
                    'إدارة الاشتراكات، الفواتير، الدفعات، والتجارب المجانية للمدارس فقط.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: _muted, fontSize: 15, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 18),
                  _TabsBar(tabs: _tabs, selectedIndex: _selectedTab, onChanged: (i) => setState(() => _selectedTab = i)),
                  const SizedBox(height: 18),
                  if (_selectedTab == 0)
                    _BillingSummary(schools: schools)
                  else if (_selectedTab == 1)
                    _AddSubscriptionView(schools: schools)
                  else if (_selectedTab == 2)
                    _SchoolSubscriptions(schools: schools)
                  else if (_selectedTab == 3)
                    const _FreeTrialsView()
                  else if (_selectedTab == 4)
                    const _PlansPricingView()
                  else
                    const _BillingAlertsView(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(child: Text('الاشتراكات والفوترة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          Positioned(right: 0, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 30))),
        ],
      ),
    );
  }
}

class _TabsBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _TabsBar({required this.tabs, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Text(tabs[index]),
            onSelected: (_) => onChanged(index),
            selectedColor: const Color(0xFFEFF3FF),
            backgroundColor: const Color(0xFFF8F8FC),
            side: BorderSide(color: selected ? const Color(0xFF2457D6) : const Color(0xFFE5E7EB)),
            labelStyle: TextStyle(color: selected ? const Color(0xFF2457D6) : const Color(0xFF4B5563), fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          );
        },
      ),
    );
  }
}

class _BillingSummary extends StatelessWidget {
  final List<School> schools;
  const _BillingSummary({required this.schools});

  @override
  Widget build(BuildContext context) {
    final activeSchools = schools.where((s) => s.status == 'active').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.08,
          children: [
            _MetricCard(icon: Icons.verified_outlined, title: 'المدارس النشطة', value: activeSchools.toString()),
            const _MetricCard(icon: Icons.hourglass_top_rounded, title: 'المدارس التجريبية', value: '0'),
            const _MetricCard(icon: Icons.event_busy_outlined, title: 'تنتهي خلال 30 يوم', value: '0'),
            const _MetricCard(icon: Icons.warning_amber_rounded, title: 'الاشتراكات المنتهية', value: '0'),
            const _MetricCard(icon: Icons.payments_outlined, title: 'إجمالي المدفوع', value: '0 د.أ'),
            const _MetricCard(icon: Icons.account_balance_wallet_outlined, title: 'إجمالي المتبقي', value: '0 د.أ'),
            const _MetricCard(icon: Icons.calendar_month_outlined, title: 'الإيرادات السنوية', value: '0 د.أ'),
            const _MetricCard(icon: Icons.person_off_outlined, title: 'طلاب غير مدفوعين', value: '0'),
          ],
        ),
        const SizedBox(height: 18),
        const _RuleCard(),
      ],
    );
  }
}

class _AddSubscriptionView extends StatefulWidget {
  final List<School> schools;
  const _AddSubscriptionView({required this.schools});

  @override
  State<_AddSubscriptionView> createState() => _AddSubscriptionViewState();
}

class _AddSubscriptionViewState extends State<_AddSubscriptionView> {
  final _annualAmount = TextEditingController();
  final _paidAmount = TextEditingController(text: '0');
  School? _school;
  String? _planType;
  String? _packageName;
  bool _saving = false;

  static const _blue = Color(0xFF2457D6);
  static const _hint = Color(0xFF8E8E93);
  static const _border = Color(0xFFCFCFD4);

  @override
  void dispose() {
    _annualAmount.dispose();
    _paidAmount.dispose();
    super.dispose();
  }

  List<School> get inactiveSchools {
    return widget.schools.where((s) => s.status != 'active').toList();
  }

  bool get canSave => _school != null && _planType != null && (_planType == 'تجربة مجانية' || _annualAmount.text.trim().isNotEmpty);

  Future<void> _save() async {
    if (!canSave || _saving || _school == null || _planType == null) return;
    setState(() => _saving = true);
    try {
      final start = DateTime.now();
      final isTrial = _planType == 'تجربة مجانية';
      final end = DateTime(start.year + (isTrial ? 0 : 1), start.month + (isTrial ? 1 : 0), start.day);
      final annual = isTrial ? 0.0 : double.tryParse(_annualAmount.text.trim()) ?? 0.0;
      final paid = double.tryParse(_paidAmount.text.trim()) ?? 0.0;
      final remaining = annual - paid;

      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: FirebaseConfig.firestoreDatabaseId)
          .collection('schools')
          .doc(_school!.id)
          .update({
        'status': 'active',
        'subscription': {
          'planType': _planType,
          'packageName': _packageName ?? '',
          'status': isTrial ? 'trial' : 'active',
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
          'annualAmount': annual,
          'paidAmount': paid,
          'remainingAmount': remaining < 0 ? 0 : remaining,
          'createdAt': DateTime.now().toIso8601String(),
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الاشتراك وتفعيل المدرسة')));
      setState(() {
        _school = null;
        _planType = null;
        _packageName = null;
        _annualAmount.clear();
        _paidAmount.text = '0';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إضافة الاشتراك: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickSchool() {
    _openPicker<School>(
      title: 'اختر المدرسة',
      items: inactiveSchools,
      label: (s) => '${s.name} - ${s.code}',
      selected: _school,
      onSelect: (s) => setState(() => _school = s),
    );
  }

  void _pickPlan() {
    _openPicker<String>(
      title: 'اختر نوع الخطة',
      items: const ['تجربة مجانية', 'شاملة', 'حسب الطالب'],
      label: (v) => v,
      selected: _planType,
      onSelect: (v) {
        setState(() {
          _planType = v;
          _packageName = null;
          if (v == 'تجربة مجانية') {
            _annualAmount.text = '0';
            _paidAmount.text = '0';
          }
        });
      },
    );
  }

  void _pickPackage() {
    _openPicker<String>(
      title: 'اختر الباقة',
      items: const ['شاملة 250', 'شاملة 500', 'شاملة 750', 'شاملة 1000+'],
      label: (v) => v,
      selected: _packageName,
      onSelect: (v) {
        setState(() {
          _packageName = v;
          if (v == 'شاملة 250') _annualAmount.text = '3750';
          if (v == 'شاملة 500') _annualAmount.text = '5000';
          if (v == 'شاملة 750') _annualAmount.text = '7500';
          if (v == 'شاملة 1000+') _annualAmount.text = '';
        });
      },
    );
  }

  void _openPicker<T>({required String title, required List<T> items, required String Function(T) label, required T? selected, required ValueChanged<T> onSelect}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.62,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: items.map((item) {
                          final isSelected = item == selected;
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
                                  Expanded(child: Text(label(item), textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                                  const SizedBox(width: 14),
                                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? _blue : _hint),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inactiveSchools.isEmpty) {
      return const _EmptyState(text: 'لا توجد مدارس غير مفعلة لإضافة اشتراك لها');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('إضافة اشتراك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _PickerField(label: 'المدرسة *', value: _school == null ? 'اختر المدرسة' : '${_school!.name} - ${_school!.code}', onTap: _pickSchool),
        _PickerField(label: 'نوع الخطة *', value: _planType ?? 'اختر نوع الخطة', onTap: _pickPlan),
        if (_planType == 'شاملة') _PickerField(label: 'الباقة *', value: _packageName ?? 'اختر الباقة', onTap: _pickPackage),
        _SmallField(label: 'المبلغ السنوي', controller: _annualAmount, enabled: _planType != 'تجربة مجانية'),
        _SmallField(label: 'المدفوع', controller: _paidAmount, enabled: _planType != 'تجربة مجانية'),
        const SizedBox(height: 8),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _saving || !canSave ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: _blue, disabledBackgroundColor: const Color(0xFFF1F1F4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('حفظ الاشتراك وتفعيل المدرسة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCFCFD4)), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)))), const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E8E93))]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  const _SmallField({required this.label, required this.controller, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _MetricCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF2457D6), size: 23)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, height: 1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5, height: 1.15, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF123A73), Color(0xFF0B1F3B)]), borderRadius: BorderRadius.circular(22)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('قاعدة مالية أساسية', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('المدرسة هي العميل المالي الوحيد. لا يوجد أي تعامل مالي مباشر مع أولياء الأمور داخل النظام.', textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _SchoolSubscriptions extends StatelessWidget {
  final List<School> schools;
  const _SchoolSubscriptions({required this.schools});

  @override
  Widget build(BuildContext context) {
    final activeSchools = schools.where((s) => s.status == 'active').toList();
    if (activeSchools.isEmpty) return const _EmptyState(text: 'لا توجد مدارس لديها اشتراك مفعل');
    return Column(children: activeSchools.map((s) => _SubscriptionSchoolCard(school: s)).toList());
  }
}

class _SubscriptionSchoolCard extends StatelessWidget {
  final School school;
  const _SubscriptionSchoolCard({required this.school});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: Text(school.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), const _StatusBadge(text: 'نشط', active: true)]),
        const SizedBox(height: 8),
        Text('رمز المدرسة: ${school.code}', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Wrap(spacing: 8, runSpacing: 8, children: [_MiniChip(text: 'نوع الخطة: محفوظ'), _MiniChip(text: 'المدفوع: محفوظ'), _MiniChip(text: 'المتبقي: محفوظ')]),
        const SizedBox(height: 12),
        SizedBox(height: 42, child: OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تفاصيل الاشتراك في المرحلة القادمة'))), icon: const Icon(Icons.visibility_outlined, size: 19), label: const Text('عرض'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2457D6), side: const BorderSide(color: Color(0xFFD9E1FF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ]),
    );
  }
}

class _FreeTrialsView extends StatelessWidget { const _FreeTrialsView(); @override Widget build(BuildContext context) => const _PlaceholderList(title: 'التجارب المجانية', items: ['إنشاء تجربة مجانية', 'تمديد التجربة', 'إنهاء التجربة', 'تحويل إلى خطة مدفوعة']); }
class _PlansPricingView extends StatelessWidget { const _PlansPricingView(); @override Widget build(BuildContext context) => const Column(children: [_PlanCard(title: 'تجربة مجانية', subtitle: 'شهر واحد - مجاني'), _PlanCard(title: 'شاملة 250', subtitle: '250 طالب × 15 د.أ = 3,750 د.أ سنويًا'), _PlanCard(title: 'شاملة 500', subtitle: '500 طالب × 10 د.أ = 5,000 د.أ سنويًا'), _PlanCard(title: 'شاملة 750', subtitle: '750 طالب × 10 د.أ = 7,500 د.أ سنويًا'), _PlanCard(title: 'شاملة 1000+', subtitle: 'عدد مخصص × 10 د.أ سنويًا'), _PlanCard(title: 'حسب الطالب', subtitle: '20 د.أ سنويًا لكل حساب طالب')]); }
class _BillingAlertsView extends StatelessWidget { const _BillingAlertsView(); @override Widget build(BuildContext context) => const _PlaceholderList(title: 'تنبيهات الفوترة', items: ['اشتراك ينتهي قريبًا', 'تجربة تنتهي قريبًا', 'حسابات غير مدفوعة', 'مدرسة وصلت حد الخطة', 'دفعة متأخرة']); }

class _PlaceholderList extends StatelessWidget {
  final String title; final List<String> items; const _PlaceholderList({required this.title, required this.items});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), ...items.map((i) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.circle, color: Color(0xFF2457D6), size: 10), const SizedBox(width: 10), Expanded(child: Text(i, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))])))]);
}

class _PlanCard extends StatelessWidget {
  final String title; final String subtitle; const _PlanCard({required this.title, required this.subtitle});
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF2457D6))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600))]))]));
}

class _MiniChip extends StatelessWidget { final String text; const _MiniChip({required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4B5563)))); }
class _StatusBadge extends StatelessWidget { final String text; final bool active; const _StatusBadge({required this.text, required this.active}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: active ? const Color(0xFFE9F8EF) : const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: active ? const Color(0xFF16833A) : const Color(0xFFB42318), fontSize: 12, fontWeight: FontWeight.w900))); }
class _EmptyState extends StatelessWidget { final String text; const _EmptyState({required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(22)), child: Column(children: [const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF2457D6)), const SizedBox(height: 10), Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))])); }
