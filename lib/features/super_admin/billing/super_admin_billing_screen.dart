import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/config/firebase_config.dart';
import '../../../core/models/school.dart';
import '../../../core/services/super_admin_service.dart';

FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: FirebaseConfig.firestoreDatabaseId,
    );

class SuperAdminBillingScreen extends StatefulWidget {
  const SuperAdminBillingScreen({super.key});

  @override
  State<SuperAdminBillingScreen> createState() => _SuperAdminBillingScreenState();
}

class _SuperAdminBillingScreenState extends State<SuperAdminBillingScreen> {
  int _selectedTab = 0;

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
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 15, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 18),
                  _TabsBar(
                    tabs: _tabs,
                    selectedIndex: _selectedTab,
                    onChanged: (i) => setState(() => _selectedTab = i),
                  ),
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
                    const _PlansManagerView()
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
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF2457D6) : const Color(0xFF4B5563),
              fontWeight: FontWeight.w800,
            ),
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
    final trialSchools = schools.where((s) => s.status == 'trial').length;
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
            _MetricCard(icon: Icons.hourglass_top_rounded, title: 'المدارس التجريبية', value: trialSchools.toString()),
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
  DocumentSnapshot<Map<String, dynamic>>? _plan;
  bool _saving = false;

  static const _blue = Color(0xFF2457D6);
  static const _hint = Color(0xFF8E8E93);

  @override
  void dispose() {
    _annualAmount.dispose();
    _paidAmount.dispose();
    super.dispose();
  }

  List<School> get inactiveSchools => widget.schools.where((s) => s.status != 'active' && s.status != 'trial').toList();

  Map<String, dynamic> get _planData => _plan?.data() ?? const <String, dynamic>{};
  bool get _isTrial => _planData['type'] == 'trial';
  bool get canSave => _school != null && _plan != null && (_isTrial || _annualAmount.text.trim().isNotEmpty);

  double _numberFrom(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _intFrom(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _save() async {
    if (!canSave || _saving || _school == null || _plan == null) return;
    setState(() => _saving = true);
    try {
      final planData = _plan!.data() ?? {};
      final start = DateTime.now();
      final durationMonths = _intFrom(planData['durationMonths'], _isTrial ? 1 : 12);
      final end = DateTime(start.year, start.month + durationMonths, start.day);
      final annual = _isTrial ? 0.0 : double.tryParse(_annualAmount.text.trim()) ?? _numberFrom(planData['annualPrice']);
      final paid = _isTrial ? 0.0 : double.tryParse(_paidAmount.text.trim()) ?? 0.0;

      await _db.collection('schools').doc(_school!.id).update({
        'status': _isTrial ? 'trial' : 'active',
        'subscription': {
          'planId': _plan!.id,
          'planName': planData['name']?.toString() ?? '',
          'planType': planData['type']?.toString() ?? '',
          'pricingMethod': planData['pricingMethod']?.toString() ?? '',
          'durationMonths': durationMonths,
          'studentLimit': _intFrom(planData['studentLimit']),
          'pricePerStudent': _numberFrom(planData['pricePerStudent']),
          'status': _isTrial ? 'trial' : 'active',
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String(),
          'annualAmount': annual,
          'paidAmount': paid,
          'remainingAmount': (annual - paid) < 0 ? 0 : annual - paid,
          'createdAt': DateTime.now().toIso8601String(),
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isTrial ? 'تم إنشاء التجربة المجانية' : 'تم إضافة الاشتراك وتفعيل المدرسة')));
      setState(() {
        _school = null;
        _plan = null;
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

  void _pickSchool() => _openPicker<School>(
        title: 'اختر المدرسة',
        items: inactiveSchools,
        label: (s) => '${s.name} - ${s.code}',
        selected: _school,
        onSelect: (s) => setState(() => _school = s),
      );

  void _pickPlan(List<DocumentSnapshot<Map<String, dynamic>>> plans) => _openPicker<DocumentSnapshot<Map<String, dynamic>>>(
        title: 'اختر الخطة',
        items: plans,
        label: (doc) {
          final data = doc.data() ?? {};
          final name = data['name']?.toString() ?? 'خطة';
          final annual = data['annualPrice']?.toString() ?? '0';
          return '$name - $annual د.أ';
        },
        selected: _plan,
        onSelect: (doc) {
          final data = doc.data() ?? {};
          setState(() {
            _plan = doc;
            final annual = _numberFrom(data['annualPrice']);
            _annualAmount.text = annual == 0 ? '' : annual.toStringAsFixed(annual.truncateToDouble() == annual ? 0 : 2);
            _paidAmount.text = '0';
            if (data['type'] == 'trial') {
              _annualAmount.text = '0';
              _paidAmount.text = '0';
            }
          });
        },
      );

  void _openPicker<T>({required String title, required List<T> items, required String Function(T) label, required T? selected, required ValueChanged<T> onSelect}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.62,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                          child: Row(children: [
                            Expanded(child: Text(label(item), textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                            const SizedBox(width: 14),
                            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? _blue : _hint),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (inactiveSchools.isEmpty) return const _EmptyState(text: 'لا توجد مدارس غير مفعلة لإضافة اشتراك لها');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        final plans = snapshot.data?.docs ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator()));
        }
        if (plans.isEmpty) {
          return const _EmptyState(text: 'لا توجد خطط مفعلة. أضف أو فعّل خطة من تبويب الخطط والأسعار أولًا');
        }
        final planName = _plan?.data()?['name']?.toString() ?? 'اختر الخطة';
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('إضافة اشتراك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _PickerField(label: 'المدرسة *', value: _school == null ? 'اختر المدرسة' : '${_school!.name} - ${_school!.code}', onTap: _pickSchool),
          _PickerField(label: 'الخطة *', value: planName, onTap: () => _pickPlan(plans)),
          if (_plan != null) _PlanPreview(data: _planData),
          _SmallField(label: 'المبلغ السنوي', controller: _annualAmount, enabled: !_isTrial, keyboardType: TextInputType.number),
          _SmallField(label: 'المدفوع', controller: _paidAmount, enabled: !_isTrial, keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _saving || !canSave ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: _blue, disabledBackgroundColor: const Color(0xFFF1F1F4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('حفظ الاشتراك', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ),
          ),
        ]);
      },
    );
  }
}

class _FreeTrialsView extends StatelessWidget {
  const _FreeTrialsView();

  int _daysLeft(Map<String, dynamic> data) {
    final subscription = data['subscription'] is Map<String, dynamic> ? data['subscription'] as Map<String, dynamic> : <String, dynamic>{};
    final endText = subscription['endDate']?.toString();
    final end = endText == null ? null : DateTime.tryParse(endText);
    if (end == null) return 0;
    return end.difference(DateTime.now()).inDays + 1;
  }

  Future<void> _extend(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data() ?? {};
    final subscription = data['subscription'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['subscription'] as Map<String, dynamic>) : <String, dynamic>{};
    final oldEnd = DateTime.tryParse(subscription['endDate']?.toString() ?? '') ?? DateTime.now();
    final newEnd = DateTime(oldEnd.year, oldEnd.month + 1, oldEnd.day);
    subscription['endDate'] = newEnd.toIso8601String();
    await doc.reference.update({'subscription': subscription});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تمديد التجربة شهرًا إضافيًا')));
  }

  Future<void> _endTrial(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.update({'status': 'inactive', 'subscription.status': 'ended'});
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء التجربة')));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').where('status', isEqualTo: 'trial').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator()));
        }
        if (docs.isEmpty) return const _EmptyState(text: 'لا توجد مدارس في التجربة المجانية');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('التجارب المجانية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data();
              final subscription = data['subscription'] is Map<String, dynamic> ? data['subscription'] as Map<String, dynamic> : <String, dynamic>{};
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(data['name']?.toString() ?? 'مدرسة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
                    const _StatusBadge(text: 'تجريبية', active: true),
                  ]),
                  const SizedBox(height: 8),
                  Text('رمز المدرسة: ${data['code'] ?? ''}', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _MiniChip(text: 'بداية: ${_formatDate(subscription['startDate'])}'),
                    _MiniChip(text: 'نهاية: ${_formatDate(subscription['endDate'])}'),
                    _MiniChip(text: 'الأيام المتبقية: ${_daysLeft(data)}'),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => _extend(context, doc), icon: const Icon(Icons.add, size: 18), label: const Text('تمديد'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(onPressed: () => _endTrial(context, doc), icon: const Icon(Icons.stop_circle_outlined, size: 18), label: const Text('إنهاء'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB42318)))),
                  ]),
                ]),
              );
            }),
          ],
        );
      },
    );
  }
}

String _formatDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '—';
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

class _PlanPreview extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PlanPreview({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(16)),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        _MiniChip(text: 'المدة: ${data['durationMonths'] ?? 0} شهر'),
        _MiniChip(text: 'الحد: ${(data['studentLimit'] ?? 0).toString() == '0' ? 'بدون' : data['studentLimit']}'),
        _MiniChip(text: 'سعر الطالب: ${data['pricePerStudent'] ?? 0} د.أ'),
      ]),
    );
  }
}

class _PlansManagerView extends StatelessWidget {
  const _PlansManagerView();

  static const _defaults = [
    {'name': 'تجربة مجانية', 'type': 'trial', 'durationMonths': 1, 'pricingMethod': 'مجاني', 'pricePerStudent': 0, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
    {'name': 'شاملة 250', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 15, 'studentLimit': 250, 'annualPrice': 3750, 'isActive': true},
    {'name': 'شاملة 500', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 500, 'annualPrice': 5000, 'isActive': true},
    {'name': 'شاملة 750', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 750, 'annualPrice': 7500, 'isActive': true},
    {'name': 'شاملة 1000+', 'type': 'custom_bundle', 'durationMonths': 12, 'pricingMethod': 'مخصص', 'pricePerStudent': 10, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
    {'name': 'حسب الطالب', 'type': 'per_student', 'durationMonths': 12, 'pricingMethod': 'حسب حساب الطالب', 'pricePerStudent': 20, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
  ];

  Future<void> _seedDefaults(BuildContext context) async {
    try {
      final batch = _db.batch();
      for (final plan in _defaults) {
        final ref = _db.collection('billing_plans').doc();
        batch.set(ref, {...plan, 'createdAt': DateTime.now().toIso8601String(), 'updatedAt': DateTime.now().toIso8601String()});
      }
      await batch.commit();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الخطط الافتراضية')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل إنشاء الخطط: $e')));
    }
  }

  void _openForm(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _PlanForm(doc: doc),
    );
  }

  Future<void> _delete(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      await doc.reference.delete();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الخطة')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حذف الخطة: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('billing_plans').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Expanded(child: Text('الخطط والأسعار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
            IconButton(onPressed: () => _openForm(context), icon: const Icon(Icons.add_circle, color: Color(0xFF2457D6), size: 32)),
          ]),
          const SizedBox(height: 8),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (docs.isEmpty)
            Column(children: [
              const _EmptyState(text: 'لا توجد خطط بعد'),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: () => _seedDefaults(context), icon: const Icon(Icons.auto_fix_high), label: const Text('إنشاء الخطط الافتراضية'))),
            ])
          else
            ...docs.map((doc) => _PlanManagementCard(doc: doc, onEdit: () => _openForm(context, doc: doc), onDelete: () => _delete(context, doc))),
        ]);
      },
    );
  }
}

class _PlanForm extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>>? doc;
  const _PlanForm({this.doc});

  @override
  State<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<_PlanForm> {
  final name = TextEditingController();
  final duration = TextEditingController(text: '12');
  final method = TextEditingController();
  final price = TextEditingController(text: '0');
  final limit = TextEditingController(text: '0');
  final annual = TextEditingController(text: '0');
  String type = 'bundle';
  bool active = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data();
    if (data != null) {
      name.text = data['name']?.toString() ?? '';
      type = data['type']?.toString() ?? 'bundle';
      duration.text = data['durationMonths']?.toString() ?? '12';
      method.text = data['pricingMethod']?.toString() ?? '';
      price.text = data['pricePerStudent']?.toString() ?? '0';
      limit.text = data['studentLimit']?.toString() ?? '0';
      annual.text = data['annualPrice']?.toString() ?? '0';
      active = data['isActive'] != false;
    }
  }

  @override
  void dispose() {
    name.dispose();
    duration.dispose();
    method.dispose();
    price.dispose();
    limit.dispose();
    annual.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    final data = {
      'name': name.text.trim(),
      'type': type,
      'durationMonths': int.tryParse(duration.text.trim()) ?? 12,
      'pricingMethod': method.text.trim(),
      'pricePerStudent': double.tryParse(price.text.trim()) ?? 0,
      'studentLimit': int.tryParse(limit.text.trim()) ?? 0,
      'annualPrice': double.tryParse(annual.text.trim()) ?? 0,
      'isActive': active,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    try {
      if (widget.doc == null) {
        await _db.collection('billing_plans').add({...data, 'createdAt': DateTime.now().toIso8601String()});
      } else {
        await widget.doc!.reference.update(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.doc == null ? 'تمت إضافة الخطة' : 'تم تعديل الخطة')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر حفظ الخطة: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.doc == null ? 'إضافة خطة' : 'تعديل خطة', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            _SmallField(label: 'اسم الخطة', controller: name, keyboardType: TextInputType.text),
            _PickerField(label: 'نوع الخطة', value: _typeLabel(type), onTap: pickType),
            _SmallField(label: 'المدة بالأشهر', controller: duration, keyboardType: TextInputType.number),
            _SmallField(label: 'طريقة التسعير', controller: method, keyboardType: TextInputType.text),
            _SmallField(label: 'سعر الطالب', controller: price, keyboardType: TextInputType.number),
            _SmallField(label: 'حد الطلاب / 0 بدون حد', controller: limit, keyboardType: TextInputType.number),
            _SmallField(label: 'السعر السنوي', controller: annual, keyboardType: TextInputType.number),
            SwitchListTile(
              value: active,
              onChanged: (v) => setState(() => active = v),
              title: const Text('الخطة مفعلة', style: TextStyle(fontWeight: FontWeight.w800)),
              activeColor: const Color(0xFF2457D6),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SizedBox(height: 52, child: FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'جاري الحفظ...' : 'حفظ الخطة'))),
          ]),
        ),
      ),
    );
  }

  String _typeLabel(String value) {
    if (value == 'trial') return 'تجربة مجانية';
    if (value == 'bundle') return 'شاملة';
    if (value == 'custom_bundle') return 'شاملة مخصصة';
    if (value == 'per_student') return 'حسب الطالب';
    return value;
  }

  void pickType() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('اختر نوع الخطة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              _TypeOption(label: 'تجربة مجانية', value: 'trial', selected: type, onSelect: setType),
              _TypeOption(label: 'شاملة', value: 'bundle', selected: type, onSelect: setType),
              _TypeOption(label: 'شاملة مخصصة', value: 'custom_bundle', selected: type, onSelect: setType),
              _TypeOption(label: 'حسب الطالب', value: 'per_student', selected: type, onSelect: setType),
            ]),
          ),
        ),
      ),
    );
  }

  void setType(String value) {
    setState(() => type = value);
    Navigator.of(context).pop();
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelect;
  const _TypeOption({required this.label, required this.value, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ListTile(
      onTap: () => onSelect(value),
      title: Text(label, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
      leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF2457D6) : const Color(0xFF8E8E93)),
    );
  }
}

class _PlanManagementCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlanManagementCard({required this.doc, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final active = data['isActive'] != false;
    final name = data['name']?.toString() ?? 'خطة';
    final pricePerStudent = data['pricePerStudent']?.toString() ?? '0';
    final limit = data['studentLimit']?.toString() ?? '0';
    final annual = data['annualPrice']?.toString() ?? '0';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF2457D6))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          _StatusBadge(text: active ? 'مفعلة' : 'معطلة', active: active),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _MiniChip(text: 'سعر الطالب: $pricePerStudent د.أ'),
          _MiniChip(text: limit == '0' ? 'بدون حد' : 'الحد: $limit'),
          _MiniChip(text: 'سنويًا: $annual د.أ'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('تعديل'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('حذف'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB42318)))),
        ]),
      ]),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
        ]),
      );
}

class _SmallField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType keyboardType;
  const _SmallField({required this.label, required this.controller, this.enabled = true, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          SizedBox(
            height: 52,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _MetricCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Container(
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
  Widget build(BuildContext context) => Container(
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

class _BillingAlertsView extends StatelessWidget {
  const _BillingAlertsView();
  @override
  Widget build(BuildContext context) => const _PlaceholderList(title: 'تنبيهات الفوترة', items: ['اشتراك ينتهي قريبًا', 'تجربة تنتهي قريبًا', 'حسابات غير مدفوعة', 'مدرسة وصلت حد الخطة', 'دفعة متأخرة']);
}

class _PlaceholderList extends StatelessWidget {
  final String title;
  final List<String> items;
  const _PlaceholderList({required this.title, required this.items});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), ...items.map((i) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.circle, color: Color(0xFF2457D6), size: 10), const SizedBox(width: 10), Expanded(child: Text(i, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))])))]);
}

class _MiniChip extends StatelessWidget {
  final String text;
  const _MiniChip({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4B5563))));
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final bool active;
  const _StatusBadge({required this.text, required this.active});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: active ? const Color(0xFFE9F8EF) : const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: active ? const Color(0xFF16833A) : const Color(0xFFB42318), fontSize: 12, fontWeight: FontWeight.w900)));
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(22)), child: Column(children: [const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF2457D6)), const SizedBox(height: 10), Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]));
}
