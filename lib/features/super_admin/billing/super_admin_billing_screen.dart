import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/config/firebase_config.dart';

FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: FirebaseConfig.firestoreDatabaseId,
    );

const _blue = Color(0xFF2457D6);
const _softBlue = Color(0xFFEFF3FF);
const _panel = Color(0xFFF8F8FC);
const _muted = Color(0xFF6B7280);
const _danger = Color(0xFFB42318);
const _success = Color(0xFF16833A);

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
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('schools').snapshots(),
            builder: (context, snapshot) {
              final schools = snapshot.data?.docs ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(onBack: () => Navigator.pop(context)),
                  const SizedBox(height: 12),
                  const Text('إدارة الاشتراكات والفوترة والتجارب المجانية للمدارس فقط.', style: TextStyle(color: _muted, fontWeight: FontWeight.w600, height: 1.5)),
                  const SizedBox(height: 16),
                  _Tabs(tabs, tab, (i) => setState(() => tab = i)),
                  const SizedBox(height: 16),
                  if (tab == 0) _SummaryTab(schools),
                  if (tab == 1) _AddSubscriptionTab(schools),
                  if (tab == 2) _SubscriptionsTab(schools),
                  if (tab == 3) _TrialsTab(schools),
                  if (tab == 4) const _PlansTab(),
                  if (tab == 5) _AlertsTab(schools),
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
  const _Tabs(this.tabs, this.selected, this.onChanged);
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final active = selected == i;
            return ChoiceChip(
              selected: active,
              showCheckmark: false,
              label: Text(tabs[i]),
              onSelected: (_) => onChanged(i),
              selectedColor: _softBlue,
              backgroundColor: _panel,
              side: BorderSide(color: active ? _blue : const Color(0xFFE5E7EB)),
              labelStyle: TextStyle(color: active ? _blue : const Color(0xFF4B5563), fontWeight: FontWeight.w800),
            );
          },
        ),
      );
}

class _SummaryTab extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _SummaryTab(this.schools);
  @override
  Widget build(BuildContext context) {
    final active = schools.where((s) => d(s)['status'] == 'active').length;
    final trial = schools.where((s) => d(s)['status'] == 'trial').length;
    final expiring = schools.where((s) => d(s)['status'] == 'active' && daysLeft(d(s)) > 0 && daysLeft(d(s)) <= 30).length;
    final expired = schools.where((s) => d(s)['status'] == 'active' && daysLeft(d(s)) <= 0).length;
    final annual = schools.fold<double>(0, (sum, s) => sum + n(sub(d(s))['annualAmount']));
    final paid = schools.fold<double>(0, (sum, s) => sum + n(sub(d(s))['paidAmount']));
    final remaining = schools.fold<double>(0, (sum, s) => sum + n(sub(d(s))['remainingAmount']));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.12,
        children: [
          _Metric('المدارس النشطة', '$active', Icons.verified_outlined),
          _Metric('المدارس التجريبية', '$trial', Icons.hourglass_top_rounded),
          _Metric('تنتهي خلال 30 يوم', '$expiring', Icons.event_busy_outlined),
          _Metric('اشتراكات منتهية', '$expired', Icons.warning_amber_rounded),
          _Metric('الإيرادات السنوية', '${money(annual)} د.أ', Icons.calendar_month_outlined),
          _Metric('إجمالي المدفوع', '${money(paid)} د.أ', Icons.payments_outlined),
          _Metric('إجمالي المتبقي', '${money(remaining)} د.أ', Icons.account_balance_wallet_outlined),
          _Metric('طلاب غير مدفوعين', '0', Icons.person_off_outlined),
        ],
      ),
      const SizedBox(height: 14),
      card(const Text('قاعدة النظام: المدرسة هي العميل المالي الوحيد. لا يوجد دفع مباشر من ولي الأمر داخل المنصة.', style: TextStyle(fontWeight: FontWeight.w800, height: 1.5))),
    ]);
  }
}

class _AddSubscriptionTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _AddSubscriptionTab(this.schools);
  @override
  State<_AddSubscriptionTab> createState() => _AddSubscriptionTabState();
}

class _AddSubscriptionTabState extends State<_AddSubscriptionTab> {
  QueryDocumentSnapshot<Map<String, dynamic>>? school;
  DocumentSnapshot<Map<String, dynamic>>? plan;
  final annual = TextEditingController();
  final paid = TextEditingController(text: '0');
  bool saving = false;
  @override
  void dispose() { annual.dispose(); paid.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final inactive = widget.schools.where((s) => !['active', 'trial'].contains(d(s)['status'])).toList();
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
          _PickerField('المدرسة', school == null ? 'اختر المدرسة' : '${d(school!)['name'] ?? ''} - ${d(school!)['code'] ?? ''}', () {
            pick<QueryDocumentSnapshot<Map<String, dynamic>>>(context, 'اختر المدرسة', inactive, (s) => '${d(s)['name'] ?? ''} - ${d(s)['code'] ?? ''}', school, (v) => setState(() => school = v));
          }),
          _PickerField('الخطة', plan?.data()?['name']?.toString() ?? 'اختر الخطة', () {
            pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة', plans, planLabel, plan, (v) {
              final p = v.data() ?? {};
              final amount = n(p['annualPrice']);
              setState(() { plan = v; annual.text = p['type'] == 'trial' ? '0' : (amount == 0 ? '' : money(amount)); paid.text = '0'; });
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
    try { await applyPlan(school!.id, plan!, toDouble(annual.text), toDouble(paid.text)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الاشتراك'))); setState(() { school = null; plan = null; annual.clear(); paid.text = '0'; }); } finally { if (mounted) setState(() => saving = false); }
  }
}

class _SubscriptionsTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _SubscriptionsTab(this.schools);
  @override
  State<_SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<_SubscriptionsTab> {
  final search = TextEditingController(); String filter = 'all';
  @override void dispose() { search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final subscribed = widget.schools.where((s) => d(s)['status'] == 'active').toList();
    final q = search.text.trim().toLowerCase();
    final visible = subscribed.where((s) { final data = d(s); final name = '${data['name'] ?? ''}'.toLowerCase(); final code = '${data['code'] ?? ''}'.toLowerCase(); final st = subscriptionState(data); return (q.isEmpty || name.contains(q) || code.contains(q)) && (filter == 'all' || st == filter); }).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('اشتراكات المدارس', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
      _SearchBox(search, (_) => setState(() {}), hint: 'ابحث باسم المدرسة أو رمزها...'), const SizedBox(height: 10),
      _SmallFilter(filter, const {'all': 'الكل', 'active': 'نشط', 'expired': 'منتهي', 'due': 'متأخر بالدفع'}, (v) => setState(() => filter = v)), const SizedBox(height: 12),
      if (visible.isEmpty) const _Empty('لا توجد اشتراكات مطابقة') else ...visible.map((s) => _SubscriptionCard(s)),
    ]);
  }
}

class _SubscriptionCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _SubscriptionCard(this.doc);
  @override Widget build(BuildContext context) { final data = d(doc); final s = sub(data); return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [Expanded(child: Text('${data['name'] ?? 'مدرسة'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), _Badge(subscriptionLabel(data), subscriptionColor(data))]),
    const SizedBox(height: 8), Text('رمز المدرسة: ${data['code'] ?? ''}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)), const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: [_Chip('الخطة: ${s['planName'] ?? '—'}'), _Chip('النهاية: ${date(s['endDate'])}'), _Chip('المدفوع: ${money(n(s['paidAmount']))} د.أ'), _Chip('المتبقي: ${money(n(s['remainingAmount']))} د.أ')]), const SizedBox(height: 12),
    SizedBox(height: 42, child: OutlinedButton.icon(onPressed: () => openSubscriptionDetails(context, doc), icon: const Icon(Icons.visibility_outlined), label: const Text('عرض'))),
  ])); }
}

class _TrialsTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _TrialsTab(this.schools);
  @override State<_TrialsTab> createState() => _TrialsTabState();
}
class _TrialsTabState extends State<_TrialsTab> { final search = TextEditingController(); String filter = 'all'; @override void dispose() { search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final docs = widget.schools.where((s) => d(s)['status'] == 'trial').toList(); final q = search.text.trim().toLowerCase(); final visible = docs.where((doc) { final data = d(doc); final name = '${data['name'] ?? ''}'.toLowerCase(); final code = '${data['code'] ?? ''}'.toLowerCase(); return (q.isEmpty || name.contains(q) || code.contains(q)) && (filter == 'all' || trialState(data) == filter); }).toList(); final active = docs.where((x) => trialState(d(x)) == 'active').length; final ending = docs.where((x) => trialState(d(x)) == 'ending').length; final expired = docs.where((x) => trialState(d(x)) == 'expired').length; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('التجارب المجانية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), _SearchBox(search, (_) => setState(() {}), hint: 'ابحث باسم المدرسة أو رمزها...'), const SizedBox(height: 10), _SmallFilter(filter, {'all': 'الكل ${docs.length}', 'active': 'فعال $active', 'ending': 'قريب الانتهاء $ending', 'expired': 'منتهي $expired'}, (v) => setState(() => filter = v)), const SizedBox(height: 12), if (docs.isEmpty) const _Empty('لا توجد مدارس في التجربة المجانية') else if (visible.isEmpty) const _Empty('لا توجد نتائج مطابقة') else ...visible.map((doc) => _TrialCard(doc))]); }
}
class _TrialCard extends StatelessWidget { final QueryDocumentSnapshot<Map<String, dynamic>> doc; const _TrialCard(this.doc); @override Widget build(BuildContext context) { final data = d(doc); final s = sub(data); final left = daysLeft(data); return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_outlined, color: _blue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${data['name'] ?? 'مدرسة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text('رمز: ${data['code'] ?? ''}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))])), _Badge(trialLabel(data), trialColor(data))]), const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: [_Chip('بداية: ${date(s['startDate'])}'), _Chip('نهاية: ${date(s['endDate'])}'), _Chip('الأيام: ${left < 0 ? 0 : left}')]), const SizedBox(height: 12), SizedBox(height: 42, child: OutlinedButton.icon(onPressed: () => openTrialDetails(context, doc), icon: const Icon(Icons.visibility_outlined), label: const Text('عرض')))])); } }

class _PlansTab extends StatelessWidget { const _PlansTab(); @override Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('billing_plans').snapshots(), builder: (context, snapshot) { final docs = snapshot.data?.docs ?? []; return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [const Expanded(child: Text('الخطط والأسعار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), IconButton(onPressed: () => openPlanForm(context), icon: const Icon(Icons.add_circle, color: _blue, size: 32))]), if (docs.isEmpty) Column(children: [const _Empty('لا توجد خطط بعد'), SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () => seedPlans(context), child: const Text('إنشاء الخطط الافتراضية')))]) else ...docs.map((doc) => _PlanCard(doc))]); }); }
class _PlanCard extends StatelessWidget { final DocumentSnapshot<Map<String, dynamic>> doc; const _PlanCard(this.doc); @override Widget build(BuildContext context) { final data = doc.data() ?? {}; final active = data['isActive'] != false; return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('${data['name'] ?? 'خطة'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), _Badge(active ? 'مفعلة' : 'معطلة', active ? _success : _danger)]), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: [_Chip('النوع: ${typeName('${data['type'] ?? ''}')}'), _Chip('المدة: ${data['durationMonths'] ?? 0} شهر'), _Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}'), _Chip('الحد: ${data['studentLimit'] ?? 0}'), _Chip('سنويًا: ${data['annualPrice'] ?? 0}')]), Row(children: [Expanded(child: OutlinedButton(onPressed: () => openPlanForm(context, doc: doc), child: const Text('تعديل'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => doc.reference.delete(), child: const Text('حذف')))]) ])); } }

class _AlertsTab extends StatelessWidget { final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools; const _AlertsTab(this.schools); @override Widget build(BuildContext context) { final alerts = <Widget>[]; for (final doc in schools) { final data = d(doc); final s = sub(data); final name = '${data['name'] ?? 'مدرسة'}'; final left = daysLeft(data); if (data['status'] == 'active' && left > 0 && left <= 30) alerts.add(_Alert('اشتراك ينتهي قريبًا', '$name ينتهي بعد $left يوم', Icons.event_busy_outlined, _blue)); if (data['status'] == 'active' && left <= 0) alerts.add(_Alert('اشتراك منتهي', '$name انتهى اشتراكها', Icons.warning_amber_rounded, _danger)); if (data['status'] == 'trial' && left > 0 && left <= 7) alerts.add(_Alert('تجربة تنتهي قريبًا', '$name تنتهي تجربتها بعد $left يوم', Icons.hourglass_bottom_rounded, const Color(0xFFB54708))); if (n(s['remainingAmount']) > 0) alerts.add(_Alert('مبلغ متبقي', '$name عليها ${money(n(s['remainingAmount']))} د.أ', Icons.account_balance_wallet_outlined, _danger)); } return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('تنبيهات الفوترة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), if (alerts.isEmpty) const _Empty('لا توجد تنبيهات حالياً') else ...alerts]); } }
class _Alert extends StatelessWidget { final String title, message; final IconData icon; final Color color; const _Alert(this.title, this.message, this.icon, this.color); @override Widget build(BuildContext context) => card(Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(message, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))]))])); }

class _PlanForm extends StatefulWidget { final DocumentSnapshot<Map<String, dynamic>>? doc; const _PlanForm({this.doc}); @override State<_PlanForm> createState() => _PlanFormState(); }
class _PlanFormState extends State<_PlanForm> { final name = TextEditingController(); final duration = TextEditingController(text: '12'); final method = TextEditingController(); final price = TextEditingController(text: '0'); final limit = TextEditingController(text: '0'); final annual = TextEditingController(text: '0'); String type = 'bundle'; bool active = true; @override void initState() { super.initState(); final data = widget.doc?.data(); if (data != null) { name.text = '${data['name'] ?? ''}'; type = '${data['type'] ?? 'bundle'}'; duration.text = '${data['durationMonths'] ?? 12}'; method.text = '${data['pricingMethod'] ?? ''}'; price.text = '${data['pricePerStudent'] ?? 0}'; limit.text = '${data['studentLimit'] ?? 0}'; annual.text = '${data['annualPrice'] ?? 0}'; active = data['isActive'] != false; } } @override void dispose() { name.dispose(); duration.dispose(); method.dispose(); price.dispose(); limit.dispose(); annual.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [Text(widget.doc == null ? 'إضافة خطة' : 'تعديل خطة', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), _TextFieldBox('اسم الخطة', name, keyboardType: TextInputType.text), _PickerField('نوع الخطة', typeName(type), () => pick<String>(context, 'نوع الخطة', const ['trial', 'bundle', 'custom_bundle', 'per_student'], typeName, type, (v) => setState(() => type = v))), _TextFieldBox('المدة بالأشهر', duration, keyboardType: TextInputType.number), _TextFieldBox('طريقة التسعير', method, keyboardType: TextInputType.text), _TextFieldBox('سعر الطالب', price, keyboardType: TextInputType.number), _TextFieldBox('حد الطلاب', limit, keyboardType: TextInputType.number), _TextFieldBox('السعر السنوي', annual, keyboardType: TextInputType.number), SwitchListTile(value: active, onChanged: (v) => setState(() => active = v), title: const Text('الخطة مفعلة', style: TextStyle(fontWeight: FontWeight.w800)), activeColor: _blue, contentPadding: EdgeInsets.zero), SizedBox(height: 50, child: FilledButton(onPressed: save, child: const Text('حفظ الخطة')))])))); Future<void> save() async { final data = {'name': name.text.trim(), 'type': type, 'durationMonths': int.tryParse(duration.text) ?? 12, 'pricingMethod': method.text.trim(), 'pricePerStudent': toDouble(price.text), 'studentLimit': int.tryParse(limit.text) ?? 0, 'annualPrice': toDouble(annual.text), 'isActive': active, 'updatedAt': DateTime.now().toIso8601String()}; if (widget.doc == null) { await _db.collection('billing_plans').add({...data, 'createdAt': DateTime.now().toIso8601String()}); } else { await widget.doc!.reference.update(data); } if (mounted) Navigator.pop(context); } }

class _Metric extends StatelessWidget { final String title, value; final IconData icon; const _Metric(this.title, this.value, this.icon); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: _blue), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))])); }
class _SmallFilter extends StatelessWidget { final String selected; final Map<String, String> items; final ValueChanged<String> onSelect; const _SmallFilter(this.selected, this.items, this.onSelect); @override Widget build(BuildContext context) => SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: items.entries.map((e) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(selected: selected == e.key, showCheckmark: false, label: Text(e.value), onSelected: (_) => onSelect(e.key), selectedColor: _softBlue))).toList())); }
class _PickerField extends StatelessWidget { final String label, value; final VoidCallback onTap; const _PickerField(this.label, this.value, this.onTap); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: InkWell(onTap: onTap, child: InputDecorator(decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), child: Row(children: [Expanded(child: Text(value)), const Icon(Icons.keyboard_arrow_down_rounded)])))); }
class _TextFieldBox extends StatelessWidget { final String label; final TextEditingController controller; final bool enabled; final TextInputType keyboardType; const _TextFieldBox(this.label, this.controller, {this.enabled = true, this.keyboardType = TextInputType.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextField(controller: controller, enabled: enabled, keyboardType: keyboardType, textAlign: TextAlign.right, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))); }
class _SearchBox extends StatelessWidget { final TextEditingController controller; final ValueChanged<String> onChanged; final String hint; const _SearchBox(this.controller, this.onChanged, {this.hint = 'بحث...'}); @override Widget build(BuildContext context) => TextField(controller: controller, onChanged: onChanged, textAlign: TextAlign.right, decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))); }
class _PlanPreview extends StatelessWidget { final Map<String, dynamic> data; const _PlanPreview(this.data); @override Widget build(BuildContext context) => card(Wrap(spacing: 8, runSpacing: 8, children: [_Chip('المدة: ${data['durationMonths'] ?? 0} شهر'), _Chip('الحد: ${data['studentLimit'] ?? 0}'), _Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}')])); }
class _Badge extends StatelessWidget { final String text; final Color color; const _Badge(this.text, this.color); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(99)), child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900))); }
class _Chip extends StatelessWidget { final String text; const _Chip(this.text); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))); }
class _Empty extends StatelessWidget { final String text; const _Empty(this.text); @override Widget build(BuildContext context) => card(Text(text, style: const TextStyle(fontWeight: FontWeight.w800))); }
Widget card(Widget child) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)), child: child);

Map<String, dynamic> d(QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data(); Map<String, dynamic> sub(Map<String, dynamic> data) => data['subscription'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['subscription'] as Map<String, dynamic>) : <String, dynamic>{}; int daysLeft(Map<String, dynamic> data) { final end = DateTime.tryParse('${sub(data)['endDate'] ?? ''}'); return end == null ? 0 : end.difference(DateTime.now()).inDays + 1; } String date(dynamic value) { final x = DateTime.tryParse('$value'); return x == null ? '—' : '${x.year}/${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}'; } double n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0; double toDouble(String v) => double.tryParse(v.trim()) ?? 0; int intFrom(dynamic v, [int fallback = 0]) => v is int ? v : v is double ? v.toInt() : int.tryParse('$v') ?? fallback; String money(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2); String typeName(String v) => v == 'trial' ? 'تجربة مجانية' : v == 'bundle' ? 'شاملة' : v == 'custom_bundle' ? 'شاملة مخصصة' : v == 'per_student' ? 'حسب الطالب' : v; String planLabel(DocumentSnapshot<Map<String, dynamic>> doc) => '${doc.data()?['name'] ?? 'خطة'} - ${doc.data()?['annualPrice'] ?? 0} د.أ'; String trialState(Map<String, dynamic> data) => daysLeft(data) <= 0 ? 'expired' : daysLeft(data) <= 7 ? 'ending' : 'active'; String trialLabel(Map<String, dynamic> data) => trialState(data) == 'expired' ? 'منتهي' : trialState(data) == 'ending' ? 'قريب الانتهاء' : 'فعال'; Color trialColor(Map<String, dynamic> data) => trialState(data) == 'expired' ? _danger : trialState(data) == 'ending' ? const Color(0xFFB54708) : _success; String subscriptionState(Map<String, dynamic> data) => daysLeft(data) <= 0 ? 'expired' : n(sub(data)['remainingAmount']) > 0 ? 'due' : 'active'; String subscriptionLabel(Map<String, dynamic> data) => subscriptionState(data) == 'expired' ? 'منتهي' : subscriptionState(data) == 'due' ? 'متأخر بالدفع' : 'نشط'; Color subscriptionColor(Map<String, dynamic> data) => subscriptionState(data) == 'active' ? _success : _danger;

void pick<T>(BuildContext context, String title, List<T> items, String Function(T) label, T? selected, ValueChanged<T> onSelect) { showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: FractionallySizedBox(heightFactor: .62, child: Padding(padding: const EdgeInsets.fromLTRB(22, 8, 22, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), Expanded(child: ListView(children: items.map((item) { final isSelected = item == selected; return ListTile(title: Text(label(item), textAlign: TextAlign.right), leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? _blue : const Color(0xFF8E8E93)), onTap: () { onSelect(item); Navigator.pop(context); }); }).toList()))])))))); }
void openPlanForm(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _PlanForm(doc: doc));
void openTrialDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _TrialDetailsSheet(doc));
void openSubscriptionDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _SubscriptionDetailsSheet(doc));

class _TrialDetailsSheet extends StatefulWidget { final QueryDocumentSnapshot<Map<String, dynamic>> doc; const _TrialDetailsSheet(this.doc); @override State<_TrialDetailsSheet> createState() => _TrialDetailsSheetState(); }
class _TrialDetailsSheetState extends State<_TrialDetailsSheet> { final extendDays = TextEditingController(text: '7'); @override void dispose() { extendDays.dispose(); super.dispose(); } @override Widget build(BuildContext context) { final data = d(widget.doc); final s = sub(data); final left = daysLeft(data); return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [const Text('تفاصيل التجربة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 14), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF123A73), _blue]), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('${data['name'] ?? 'مدرسة'}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), Text('متبقي ${left < 0 ? 0 : left} يوم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text('من ${date(s['startDate'])} إلى ${date(s['endDate'])}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))])), const SizedBox(height: 14), card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('رمز المدرسة: ${data['code'] ?? ''}'), Text('البريد: ${data['email'] ?? 'غير محدد'}'), Text('العنوان: ${[data['governorate'], data['address']].where((e) => e != null && '$e'.trim().isNotEmpty).join(' - ')}')])), _TextFieldBox('مدة التمديد بالأيام', extendDays, keyboardType: TextInputType.number), SizedBox(height: 52, child: FilledButton.icon(onPressed: extend, icon: const Icon(Icons.add), label: const Text('تمديد التجربة'))), const SizedBox(height: 10), SizedBox(height: 52, child: OutlinedButton.icon(onPressed: openConvert, icon: const Icon(Icons.workspace_premium_outlined), label: const Text('تحويل إلى اشتراك فعّال'))), const SizedBox(height: 10), SizedBox(height: 52, child: OutlinedButton.icon(onPressed: endTrial, icon: const Icon(Icons.stop_circle_outlined), label: const Text('إنهاء التجربة'), style: OutlinedButton.styleFrom(foregroundColor: _danger)))])))); } Future<void> extend() async { final count = int.tryParse(extendDays.text.trim()) ?? 0; if (count <= 0) return; final s = Map<String, dynamic>.from(sub(d(widget.doc))); final oldEnd = DateTime.tryParse('${s['endDate'] ?? ''}') ?? DateTime.now(); final base = oldEnd.isAfter(DateTime.now()) ? oldEnd : DateTime.now(); s['endDate'] = base.add(Duration(days: count)).toIso8601String(); s['status'] = 'trial'; await widget.doc.reference.update({'status': 'trial', 'subscription': s}); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تمديد التجربة $count يوم'))); } } Future<void> endTrial() async { await widget.doc.reference.update({'status': 'inactive', 'subscription.status': 'ended'}); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء التجربة'))); } } void openConvert() => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _ConvertTrialSheet(widget.doc)); }
class _ConvertTrialSheet extends StatefulWidget { final QueryDocumentSnapshot<Map<String, dynamic>> doc; const _ConvertTrialSheet(this.doc); @override State<_ConvertTrialSheet> createState() => _ConvertTrialSheetState(); }
class _ConvertTrialSheetState extends State<_ConvertTrialSheet> { DocumentSnapshot<Map<String, dynamic>>? plan; final annual = TextEditingController(); final paid = TextEditingController(text: '0'); @override void dispose() { annual.dispose(); paid.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(), builder: (context, snapshot) { final plans = (snapshot.data?.docs ?? []).where((p) => p.data()['type'] != 'trial').toList(); return SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [const Text('تحويل إلى اشتراك فعّال', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 12), if (plans.isEmpty) const _Empty('لا توجد خطط مدفوعة مفعلة') else ...[_PickerField('الخطة', plan?.data()?['name']?.toString() ?? 'اختر الخطة', () => pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة', plans, planLabel, plan, (v) { final amount = n(v.data()?['annualPrice']); setState(() { plan = v; annual.text = amount == 0 ? '' : money(amount); paid.text = '0'; }); })), if (plan != null) _PlanPreview(plan!.data() ?? {}), _TextFieldBox('المبلغ السنوي', annual, keyboardType: TextInputType.number), _TextFieldBox('المدفوع', paid, keyboardType: TextInputType.number), SizedBox(height: 52, child: FilledButton(onPressed: plan == null || annual.text.trim().isEmpty ? null : save, child: const Text('حفظ الاشتراك وتفعيل المدرسة')))] ])); }))); Future<void> save() async { if (plan == null) return; await applyPlan(widget.doc.id, plan!, toDouble(annual.text), toDouble(paid.text), forceActive: true); if (mounted) { Navigator.pop(context); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحويل التجربة إلى اشتراك فعّال'))); } } }
class _SubscriptionDetailsSheet extends StatefulWidget { final QueryDocumentSnapshot<Map<String, dynamic>> doc; const _SubscriptionDetailsSheet(this.doc); @override State<_SubscriptionDetailsSheet> createState() => _SubscriptionDetailsSheetState(); }
class _SubscriptionDetailsSheetState extends State<_SubscriptionDetailsSheet> { final payment = TextEditingController(); @override void dispose() { payment.dispose(); super.dispose(); } @override Widget build(BuildContext context) { final data = d(widget.doc); final s = sub(data); return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [const Text('تفاصيل الاشتراك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 12), card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('المدرسة: ${data['name'] ?? ''}'), Text('الخطة: ${s['planName'] ?? ''}'), Text('البداية: ${date(s['startDate'])}'), Text('النهاية: ${date(s['endDate'])}'), Text('المدفوع: ${money(n(s['paidAmount']))} د.أ'), Text('المتبقي: ${money(n(s['remainingAmount']))} د.أ')])), _TextFieldBox('تسجيل دفعة جديدة', payment, keyboardType: TextInputType.number), SizedBox(height: 52, child: FilledButton.icon(onPressed: recordPayment, icon: const Icon(Icons.payments_outlined), label: const Text('تسجيل دفعة')))])))); } Future<void> recordPayment() async { final amount = toDouble(payment.text); if (amount <= 0) return; final data = d(widget.doc); final s = Map<String, dynamic>.from(sub(data)); final paid = n(s['paidAmount']) + amount; final annual = n(s['annualAmount']); s['paidAmount'] = paid; s['remainingAmount'] = (annual - paid) < 0 ? 0 : annual - paid; await widget.doc.reference.update({'subscription': s}); await widget.doc.reference.collection('payments').add({'amount': amount, 'date': DateTime.now().toIso8601String(), 'status': 'confirmed'}); if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة'))); } } }

Future<void> seedPlans(BuildContext context) async { final defaults = [{'name': 'تجربة مجانية', 'type': 'trial', 'durationMonths': 1, 'pricingMethod': 'مجاني', 'pricePerStudent': 0, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true}, {'name': 'شاملة 250', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 15, 'studentLimit': 250, 'annualPrice': 3750, 'isActive': true}, {'name': 'شاملة 500', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 500, 'annualPrice': 5000, 'isActive': true}, {'name': 'شاملة 750', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 750, 'annualPrice': 7500, 'isActive': true}, {'name': 'حسب الطالب', 'type': 'per_student', 'durationMonths': 12, 'pricingMethod': 'حسب حساب الطالب', 'pricePerStudent': 20, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true}]; final batch = _db.batch(); for (final item in defaults) { batch.set(_db.collection('billing_plans').doc(), {...item, 'createdAt': DateTime.now().toIso8601String()}); } await batch.commit(); }
Future<void> applyPlan(String schoolId, DocumentSnapshot<Map<String, dynamic>> plan, double annualAmount, double paidAmount, {bool forceActive = false}) async { final p = plan.data() ?? {}; final isTrial = !forceActive && p['type'] == 'trial'; final now = DateTime.now(); final months = intFrom(p['durationMonths'], isTrial ? 1 : 12); final annual = isTrial ? 0.0 : annualAmount; final paid = isTrial ? 0.0 : paidAmount; await _db.collection('schools').doc(schoolId).update({'status': isTrial ? 'trial' : 'active', 'subscription': {'planId': plan.id, 'planName': p['name'] ?? '', 'planType': p['type'] ?? '', 'pricingMethod': p['pricingMethod'] ?? '', 'studentLimit': intFrom(p['studentLimit']), 'pricePerStudent': n(p['pricePerStudent']), 'startDate': now.toIso8601String(), 'endDate': DateTime(now.year, now.month + months, now.day).toIso8601String(), 'annualAmount': annual, 'paidAmount': paid, 'remainingAmount': (annual - paid) < 0 ? 0 : annual - paid, 'status': isTrial ? 'trial' : 'active'}}); }
