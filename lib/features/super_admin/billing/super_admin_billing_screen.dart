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
  int tab = 0;
  final tabs = const ['الملخص', 'إضافة اشتراك', 'اشتراكات المدارس', 'التجارب المجانية', 'الخطط والأسعار', 'تنبيهات الفوترة'];

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
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(onBack: () => Navigator.pop(context)),
                  const SizedBox(height: 12),
                  const Text('إدارة الاشتراكات والفوترة والتجارب المجانية للمدارس فقط.', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _Tabs(tabs: tabs, selected: tab, onChanged: (i) => setState(() => tab = i)),
                  const SizedBox(height: 16),
                  if (tab == 0) _Summary(schools: schools),
                  if (tab == 1) _AddSubscription(schools: schools),
                  if (tab == 2) _ActiveSubscriptions(schools: schools),
                  if (tab == 3) const _TrialsTab(),
                  if (tab == 4) const _PlansTab(),
                  if (tab == 5) const _Empty('تنبيهات الفوترة قادمة في الخطوة التالية'),
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
  Widget build(BuildContext context) => SizedBox(
        height: 60,
        child: Stack(alignment: Alignment.center, children: [
          const Text('الاشتراكات والفوترة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Positioned(right: 0, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 30))),
        ]),
      );
}

class _Tabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.tabs, required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) => ChoiceChip(
            selected: selected == i,
            showCheckmark: false,
            label: Text(tabs[i]),
            onSelected: (_) => onChanged(i),
            selectedColor: const Color(0xFFEFF3FF),
            backgroundColor: const Color(0xFFF8F8FC),
          ),
        ),
      );
}

class _Summary extends StatelessWidget {
  final List<School> schools;
  const _Summary({required this.schools});
  @override
  Widget build(BuildContext context) {
    final active = schools.where((s) => s.status == 'active').length;
    final trial = schools.where((s) => s.status == 'trial').length;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: [
        _Metric('المدارس النشطة', '$active', Icons.verified_outlined),
        _Metric('المدارس التجريبية', '$trial', Icons.hourglass_top_rounded),
        _Metric('اشتراكات منتهية', '0', Icons.warning_amber_rounded),
        _Metric('إجمالي المدفوع', '0 د.أ', Icons.payments_outlined),
      ],
    );
  }
}

class _AddSubscription extends StatefulWidget {
  final List<School> schools;
  const _AddSubscription({required this.schools});
  @override
  State<_AddSubscription> createState() => _AddSubscriptionState();
}

class _AddSubscriptionState extends State<_AddSubscription> {
  School? school;
  DocumentSnapshot<Map<String, dynamic>>? plan;
  final annual = TextEditingController();
  final paid = TextEditingController(text: '0');
  bool saving = false;
  @override
  void dispose() { annual.dispose(); paid.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final inactive = widget.schools.where((s) => s.status != 'active' && s.status != 'trial').toList();
    if (inactive.isEmpty) return const _Empty('لا توجد مدارس غير مفعلة لإضافة اشتراك لها');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        final plans = snapshot.data?.docs ?? [];
        if (plans.isEmpty) return const _Empty('لا توجد خطط مفعلة. أضف أو فعّل خطة أولاً');
        final isTrial = plan?.data()?['type'] == 'trial';
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('إضافة اشتراك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _PickerField('المدرسة', school == null ? 'اختر المدرسة' : '${school!.name} - ${school!.code}', () {
            pick<School>(context, 'اختر المدرسة', inactive, (s) => '${s.name} - ${s.code}', school, (v) => setState(() => school = v));
          }),
          _PickerField('الخطة', plan?.data()?['name']?.toString() ?? 'اختر الخطة', () {
            pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة', plans, planLabel, plan, (v) {
              final data = v.data() ?? {};
              final amount = numFrom(data['annualPrice']);
              setState(() { plan = v; annual.text = data['type'] == 'trial' ? '0' : (amount == 0 ? '' : money(amount)); paid.text = '0'; });
            });
          }),
          if (plan != null) _PlanPreview(plan!.data() ?? {}),
          _TextFieldBox('المبلغ السنوي', annual, enabled: !isTrial, keyboardType: TextInputType.number),
          _TextFieldBox('المدفوع', paid, enabled: !isTrial, keyboardType: TextInputType.number),
          SizedBox(height: 52, child: FilledButton(onPressed: saving || school == null || plan == null ? null : save, child: saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('حفظ الاشتراك'))),
        ]);
      },
    );
  }

  Future<void> save() async {
    if (school == null || plan == null) return;
    setState(() => saving = true);
    try {
      final isTrial = plan!.data()?['type'] == 'trial';
      await applyPlan(school!.id, plan!, isTrial ? 0 : toDouble(annual.text), isTrial ? 0 : toDouble(paid.text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الاشتراك')));
      setState(() { school = null; plan = null; annual.clear(); paid.text = '0'; });
    } finally { if (mounted) setState(() => saving = false); }
  }
}

class _TrialsTab extends StatefulWidget {
  const _TrialsTab();
  @override
  State<_TrialsTab> createState() => _TrialsTabState();
}

class _TrialsTabState extends State<_TrialsTab> {
  final search = TextEditingController();
  String filter = 'all';
  @override
  void dispose() { search.dispose(); super.dispose(); }
  String stateOf(Map<String, dynamic> data) { final d = daysLeft(data); if (d <= 0) return 'expired'; if (d <= 7) return 'ending'; return 'active'; }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').where('status', isEqualTo: 'trial').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final q = search.text.trim().toLowerCase();
        final visible = docs.where((doc) {
          final data = doc.data();
          final name = data['name']?.toString().toLowerCase() ?? '';
          final code = data['code']?.toString().toLowerCase() ?? '';
          return (q.isEmpty || name.contains(q) || code.contains(q)) && (filter == 'all' || stateOf(data) == filter);
        }).toList();
        final active = docs.where((d) => stateOf(d.data()) == 'active').length;
        final ending = docs.where((d) => stateOf(d.data()) == 'ending').length;
        final expired = docs.where((d) => stateOf(d.data()) == 'expired').length;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('التجارب المجانية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _SearchBox(search, (_) => setState(() {})),
          const SizedBox(height: 10),
          _filterChips({'all': docs.length, 'active': active, 'ending': ending, 'expired': expired}),
          const SizedBox(height: 12),
          if (docs.isEmpty) const _Empty('لا توجد مدارس في التجربة المجانية') else if (visible.isEmpty) const _Empty('لا توجد نتائج مطابقة') else ...visible.map((doc) => _TrialCard(doc, stateOf(doc.data()))),
        ]);
      },
    );
  }
  Widget _filterChips(Map<String, int> counts) {
    final labels = {'all': 'الكل', 'active': 'فعال', 'ending': 'قريب الانتهاء', 'expired': 'منتهي'};
    return SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: labels.keys.map((key) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(selected: filter == key, showCheckmark: false, label: Text('${labels[key]} ${counts[key] ?? 0}'), onSelected: (_) => setState(() => filter = key)))).toList()));
  }
}

class _TrialCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String state;
  const _TrialCard(this.doc, this.state);
  @override
  Widget build(BuildContext context) {
    final data = doc.data(); final sub = subscription(data); final d = daysLeft(data);
    return panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text(data['name']?.toString() ?? 'مدرسة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), _TrialBadge(state)]),
      const SizedBox(height: 8), Text('رمز المدرسة: ${data['code'] ?? ''}'), const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [_Chip('بداية: ${formatDate(sub['startDate'])}'), _Chip('نهاية: ${formatDate(sub['endDate'])}'), _Chip('الأيام: ${d < 0 ? 0 : d}')]),
      const SizedBox(height: 12), SizedBox(height: 42, child: OutlinedButton.icon(onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _TrialDetails(doc)), icon: const Icon(Icons.visibility_outlined), label: const Text('عرض'))),
    ]));
  }
}

class _TrialDetails extends StatefulWidget { final QueryDocumentSnapshot<Map<String, dynamic>> doc; const _TrialDetails(this.doc); @override State<_TrialDetails> createState() => _TrialDetailsState(); }
class _TrialDetailsState extends State<_TrialDetails> {
  final extendDays = TextEditingController(text: '7'); bool busy = false;
  @override void dispose() { extendDays.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final data = widget.doc.data(); final sub = subscription(data); return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
    const Text('تفاصيل التجربة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
    panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(data['name']?.toString() ?? 'مدرسة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text('رمز المدرسة: ${data['code'] ?? ''}'), Text('البريد: ${data['email'] ?? 'غير محدد'}'), Text('بداية التجربة: ${formatDate(sub['startDate'])}'), Text('نهاية التجربة: ${formatDate(sub['endDate'])}'), Text('الأيام المتبقية: ${daysLeft(data) < 0 ? 0 : daysLeft(data)}') ])),
    _TextFieldBox('مدة التمديد بالأيام', extendDays, keyboardType: TextInputType.number),
    SizedBox(height: 50, child: FilledButton(onPressed: busy ? null : extend, child: const Text('تمديد التجربة'))), const SizedBox(height: 8),
    SizedBox(height: 50, child: OutlinedButton(onPressed: busy ? null : endTrial, child: const Text('إنهاء التجربة'))),
  ])))); }
  Future<void> extend() async { final count = int.tryParse(extendDays.text.trim()) ?? 0; if (count <= 0) return; setState(() => busy = true); final sub = Map<String, dynamic>.from(subscription(widget.doc.data())); final oldEnd = DateTime.tryParse(sub['endDate']?.toString() ?? '') ?? DateTime.now(); final base = oldEnd.isAfter(DateTime.now()) ? oldEnd : DateTime.now(); sub['endDate'] = base.add(Duration(days: count)).toIso8601String(); await widget.doc.reference.update({'status': 'trial', 'subscription': sub}); if (mounted) Navigator.pop(context); }
  Future<void> endTrial() async { await widget.doc.reference.update({'status': 'inactive', 'subscription.status': 'ended'}); if (mounted) Navigator.pop(context); }
}

class _PlansTab extends StatelessWidget { const _PlansTab(); @override Widget build(BuildContext context) { return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('billing_plans').snapshots(), builder: (context, snapshot) { final docs = snapshot.data?.docs ?? []; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [const Expanded(child: Text('الخطط والأسعار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), IconButton(onPressed: () => openPlanForm(context), icon: const Icon(Icons.add_circle, color: Color(0xFF2457D6), size: 32))]), if (docs.isEmpty) SizedBox(height: 50, child: FilledButton(onPressed: () => seedPlans(context), child: const Text('إنشاء الخطط الافتراضية'))) else ...docs.map((doc) => _PlanCard(doc))]); }); } }
class _PlanCard extends StatelessWidget { final DocumentSnapshot<Map<String, dynamic>> doc; const _PlanCard(this.doc); @override Widget build(BuildContext context) { final data = doc.data() ?? {}; return panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(data['name']?.toString() ?? 'خطة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Wrap(spacing: 8, children: [_Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}'), _Chip('الحد: ${data['studentLimit'] ?? 0}'), _Chip('سنويًا: ${data['annualPrice'] ?? 0}')]), Row(children: [Expanded(child: OutlinedButton(onPressed: () => openPlanForm(context, doc: doc), child: const Text('تعديل'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => doc.reference.delete(), child: const Text('حذف')))]) ])); } }
class _PlanForm extends StatefulWidget { final DocumentSnapshot<Map<String, dynamic>>? doc; const _PlanForm({this.doc}); @override State<_PlanForm> createState() => _PlanFormState(); }
class _PlanFormState extends State<_PlanForm> { final name = TextEditingController(); final duration = TextEditingController(text: '12'); final method = TextEditingController(); final price = TextEditingController(text: '0'); final limit = TextEditingController(text: '0'); final annual = TextEditingController(text: '0'); String type = 'bundle'; @override void initState() { super.initState(); final data = widget.doc?.data(); if (data != null) { name.text = '${data['name'] ?? ''}'; type = '${data['type'] ?? 'bundle'}'; duration.text = '${data['durationMonths'] ?? 12}'; method.text = '${data['pricingMethod'] ?? ''}'; price.text = '${data['pricePerStudent'] ?? 0}'; limit.text = '${data['studentLimit'] ?? 0}'; annual.text = '${data['annualPrice'] ?? 0}'; } } @override void dispose() { name.dispose(); duration.dispose(); method.dispose(); price.dispose(); limit.dispose(); annual.dispose(); super.dispose(); } @override Widget build(BuildContext context) { return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [Text(widget.doc == null ? 'إضافة خطة' : 'تعديل خطة', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), _TextFieldBox('اسم الخطة', name, keyboardType: TextInputType.text), _PickerField('نوع الخطة', typeName(type), () => pick<String>(context, 'نوع الخطة', const ['trial', 'bundle', 'custom_bundle', 'per_student'], typeName, type, (v) => setState(() => type = v))), _TextFieldBox('المدة بالأشهر', duration, keyboardType: TextInputType.number), _TextFieldBox('طريقة التسعير', method, keyboardType: TextInputType.text), _TextFieldBox('سعر الطالب', price, keyboardType: TextInputType.number), _TextFieldBox('حد الطلاب', limit, keyboardType: TextInputType.number), _TextFieldBox('السعر السنوي', annual, keyboardType: TextInputType.number), SizedBox(height: 50, child: FilledButton(onPressed: save, child: const Text('حفظ الخطة')))])))); } Future<void> save() async { final data = {'name': name.text.trim(), 'type': type, 'durationMonths': int.tryParse(duration.text) ?? 12, 'pricingMethod': method.text.trim(), 'pricePerStudent': toDouble(price.text), 'studentLimit': int.tryParse(limit.text) ?? 0, 'annualPrice': toDouble(annual.text), 'isActive': true, 'updatedAt': DateTime.now().toIso8601String()}; if (widget.doc == null) { await _db.collection('billing_plans').add({...data, 'createdAt': DateTime.now().toIso8601String()}); } else { await widget.doc!.reference.update(data); } if (mounted) Navigator.pop(context); } }
class _ActiveSubscriptions extends StatelessWidget { final List<School> schools; const _ActiveSubscriptions({required this.schools}); @override Widget build(BuildContext context) { final active = schools.where((s) => s.status == 'active').toList(); if (active.isEmpty) return const _Empty('لا توجد مدارس لديها اشتراك مفعل'); return Column(children: active.map((s) => panel(Text('${s.name} - ${s.code}', style: const TextStyle(fontWeight: FontWeight.w800)))).toList()); } }

class _Metric extends StatelessWidget { final String title; final String value; final IconData icon; const _Metric(this.title, this.value, this.icon); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: const Color(0xFF2457D6)), Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700))])); }
class _PickerField extends StatelessWidget { final String label; final String value; final VoidCallback onTap; const _PickerField(this.label, this.value, this.onTap); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: InkWell(onTap: onTap, child: InputDecorator(decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), child: Row(children: [Expanded(child: Text(value)), const Icon(Icons.keyboard_arrow_down_rounded)])))); }
class _TextFieldBox extends StatelessWidget { final String label; final TextEditingController controller; final bool enabled; final TextInputType keyboardType; const _TextFieldBox(this.label, this.controller, {this.enabled = true, this.keyboardType = TextInputType.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(controller: controller, enabled: enabled, keyboardType: keyboardType, textAlign: TextAlign.right, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))); }
class _SearchBox extends StatelessWidget { final TextEditingController controller; final ValueChanged<String> onChanged; const _SearchBox(this.controller, this.onChanged); @override Widget build(BuildContext context) => TextField(controller: controller, onChanged: onChanged, textAlign: TextAlign.right, decoration: InputDecoration(hintText: 'بحث...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))); }
class _PlanPreview extends StatelessWidget { final Map<String, dynamic> data; const _PlanPreview(this.data); @override Widget build(BuildContext context) => panel(Wrap(spacing: 8, children: [_Chip('المدة: ${data['durationMonths'] ?? 0} شهر'), _Chip('الحد: ${data['studentLimit'] ?? 0}'), _Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}') ])); }
class _TrialBadge extends StatelessWidget { final String state; const _TrialBadge(this.state); @override Widget build(BuildContext context) => _Chip(state == 'expired' ? 'منتهي' : state == 'ending' ? 'قريب الانتهاء' : 'فعال'); }
class _Chip extends StatelessWidget { final String text; const _Chip(this.text); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))); }
class _Empty extends StatelessWidget { final String text; const _Empty(this.text); @override Widget build(BuildContext context) => panel(Text(text, style: const TextStyle(fontWeight: FontWeight.w800))); }
Widget panel(Widget child) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)), child: child);
void openPlanForm(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _PlanForm(doc: doc));

void pick<T>(BuildContext context, String title, List<T> items, String Function(T) label, T? selected, ValueChanged<T> onSelect) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) {
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
                          onTap: () { onSelect(item); Navigator.pop(context); },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Row(children: [
                              Expanded(child: Text(label(item), textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                              const SizedBox(width: 14),
                              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF2457D6) : const Color(0xFF8E8E93)),
                            ]),
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

Future<void> seedPlans(BuildContext context) async { final defaults = [{'name':'تجربة مجانية','type':'trial','durationMonths':1,'pricingMethod':'مجاني','pricePerStudent':0,'studentLimit':0,'annualPrice':0,'isActive':true},{'name':'شاملة 250','type':'bundle','durationMonths':12,'pricingMethod':'باقة','pricePerStudent':15,'studentLimit':250,'annualPrice':3750,'isActive':true},{'name':'شاملة 500','type':'bundle','durationMonths':12,'pricingMethod':'باقة','pricePerStudent':10,'studentLimit':500,'annualPrice':5000,'isActive':true},{'name':'حسب الطالب','type':'per_student','durationMonths':12,'pricingMethod':'حسب حساب الطالب','pricePerStudent':20,'studentLimit':0,'annualPrice':0,'isActive':true}]; final batch = _db.batch(); for (final item in defaults) { batch.set(_db.collection('billing_plans').doc(), {...item, 'createdAt': DateTime.now().toIso8601String()}); } await batch.commit(); }
Future<void> applyPlan(String schoolId, DocumentSnapshot<Map<String, dynamic>> plan, double annualAmount, double paidAmount, {bool forceActive = false}) async { final data = plan.data() ?? {}; final isTrial = !forceActive && data['type'] == 'trial'; final now = DateTime.now(); final months = intFrom(data['durationMonths'], isTrial ? 1 : 12); await _db.collection('schools').doc(schoolId).update({'status': isTrial ? 'trial' : 'active', 'subscription': {'planId': plan.id, 'planName': data['name'] ?? '', 'planType': data['type'] ?? '', 'startDate': now.toIso8601String(), 'endDate': DateTime(now.year, now.month + months, now.day).toIso8601String(), 'annualAmount': isTrial ? 0 : annualAmount, 'paidAmount': isTrial ? 0 : paidAmount, 'remainingAmount': isTrial ? 0 : annualAmount - paidAmount}}); }
Map<String, dynamic> subscription(Map<String, dynamic> data) => data['subscription'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['subscription'] as Map<String, dynamic>) : <String, dynamic>{};
int daysLeft(Map<String, dynamic> data) { final end = DateTime.tryParse('${subscription(data)['endDate'] ?? ''}'); return end == null ? 0 : end.difference(DateTime.now()).inDays + 1; }
String formatDate(dynamic value) { final d = DateTime.tryParse('$value'); return d == null ? '—' : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'; }
double numFrom(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
double toDouble(String v) => double.tryParse(v.trim()) ?? 0;
int intFrom(dynamic v, [int fallback = 0]) => v is int ? v : v is double ? v.toInt() : int.tryParse('$v') ?? fallback;
String money(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
String planLabel(DocumentSnapshot<Map<String, dynamic>> doc) => '${doc.data()?['name'] ?? 'خطة'} - ${doc.data()?['annualPrice'] ?? 0} د.أ';
String typeName(String v) => v == 'trial' ? 'تجربة مجانية' : v == 'bundle' ? 'شاملة' : v == 'custom_bundle' ? 'شاملة مخصصة' : v == 'per_student' ? 'حسب الطالب' : v;
