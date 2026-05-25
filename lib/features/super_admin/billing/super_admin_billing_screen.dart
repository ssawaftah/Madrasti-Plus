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
  static const tabs = ['الملخص', 'إضافة اشتراك', 'اشتراكات المدارس', 'التجارب المجانية', 'الخطط والأسعار', 'تنبيهات الفوترة'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<List<School>>(
            stream: SuperAdminService().watchSchools(),
            builder: (context, snap) {
              final schools = snap.data ?? const <School>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _Header(onBack: () => Navigator.pop(context)),
                  const SizedBox(height: 18),
                  const Text('إدارة الاشتراكات، الفواتير، الدفعات، والتجارب المجانية للمدارس فقط.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 15, height: 1.4, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 18),
                  _TabStrip(tabs: tabs, selected: tab, onSelect: (i) => setState(() => tab = i)),
                  const SizedBox(height: 18),
                  if (tab == 0) _Summary(schools: schools),
                  if (tab == 1) _AddSubscription(schools: schools),
                  if (tab == 2) _ActiveSubscriptions(schools: schools),
                  if (tab == 3) const _FreeTrials(),
                  if (tab == 4) const _PlansManager(),
                  if (tab == 5) const _Bullets(title: 'تنبيهات الفوترة', items: ['اشتراك ينتهي قريبًا', 'تجربة تنتهي قريبًا', 'حسابات غير مدفوعة', 'مدرسة وصلت حد الخطة', 'دفعة متأخرة']),
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
        height: 64,
        child: Stack(alignment: Alignment.center, children: [
          const Center(child: Text('الاشتراكات والفوترة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          Positioned(right: 0, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 30))),
        ]),
      );
}

class _TabStrip extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  const _TabStrip({required this.tabs, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ChoiceChip(
            selected: selected == i,
            showCheckmark: false,
            label: Text(tabs[i]),
            onSelected: (_) => onSelect(i),
            selectedColor: const Color(0xFFEFF3FF),
            backgroundColor: const Color(0xFFF8F8FC),
            side: BorderSide(color: selected == i ? const Color(0xFF2457D6) : const Color(0xFFE5E7EB)),
            labelStyle: TextStyle(color: selected == i ? const Color(0xFF2457D6) : const Color(0xFF4B5563), fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.08,
        children: [
          _Metric(icon: Icons.verified_outlined, title: 'المدارس النشطة', value: '$active'),
          _Metric(icon: Icons.hourglass_top_rounded, title: 'المدارس التجريبية', value: '$trial'),
          const _Metric(icon: Icons.event_busy_outlined, title: 'تنتهي خلال 30 يوم', value: '0'),
          const _Metric(icon: Icons.warning_amber_rounded, title: 'الاشتراكات المنتهية', value: '0'),
          const _Metric(icon: Icons.payments_outlined, title: 'إجمالي المدفوع', value: '0 د.أ'),
          const _Metric(icon: Icons.account_balance_wallet_outlined, title: 'إجمالي المتبقي', value: '0 د.أ'),
          const _Metric(icon: Icons.calendar_month_outlined, title: 'الإيرادات السنوية', value: '0 د.أ'),
          const _Metric(icon: Icons.person_off_outlined, title: 'طلاب غير مدفوعين', value: '0'),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF123A73), Color(0xFF0B1F3B)]), borderRadius: BorderRadius.circular(22)),
        child: const Text('المدرسة هي العميل المالي الوحيد. لا يوجد أي تعامل مالي مباشر مع أولياء الأمور داخل النظام.', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

class _AddSubscription extends StatefulWidget {
  final List<School> schools;
  const _AddSubscription({required this.schools});
  @override
  State<_AddSubscription> createState() => _AddSubscriptionState();
}

class _AddSubscriptionState extends State<_AddSubscription> {
  final annual = TextEditingController();
  final paid = TextEditingController(text: '0');
  School? school;
  DocumentSnapshot<Map<String, dynamic>>? plan;
  bool saving = false;

  @override
  void dispose() {
    annual.dispose();
    paid.dispose();
    super.dispose();
  }

  List<School> get schools => widget.schools.where((s) => s.status != 'active' && s.status != 'trial').toList();
  bool get isTrial => plan?.data()?['type'] == 'trial';
  bool get canSave => school != null && plan != null && (isTrial || annual.text.trim().isNotEmpty);

  Future<void> save() async {
    if (!canSave || saving || school == null || plan == null) return;
    setState(() => saving = true);
    try {
      await applyPlan(school!.id, plan!, isTrial ? 0 : toDouble(annual.text), isTrial ? 0 : toDouble(paid.text));
      if (!mounted) return;
      snack(context, isTrial ? 'تم إنشاء التجربة المجانية' : 'تم إضافة الاشتراك وتفعيل المدرسة');
      setState(() { school = null; plan = null; annual.clear(); paid.text = '0'; });
    } catch (e) {
      if (mounted) snack(context, 'تعذر حفظ الاشتراك: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (schools.isEmpty) return const _Empty(text: 'لا توجد مدارس غير مفعلة لإضافة اشتراك لها');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(),
      builder: (_, snap) {
        final plans = snap.data?.docs ?? [];
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator()));
        if (plans.isEmpty) return const _Empty(text: 'لا توجد خطط مفعلة. أضف أو فعّل خطة من تبويب الخطط والأسعار أولًا');
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('إضافة اشتراك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Picker(label: 'المدرسة *', value: school == null ? 'اختر المدرسة' : '${school!.name} - ${school!.code}', onTap: () => pick<School>(context, 'اختر المدرسة', schools, (s) => '${s.name} - ${s.code}', school, (v) => setState(() => school = v))),
          _Picker(label: 'الخطة *', value: plan?.data()?['name']?.toString() ?? 'اختر الخطة', onTap: () => pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة', plans, planLabel, plan, (v) { final p = v.data() ?? {}; final a = numFrom(p['annualPrice']); setState(() { plan = v; annual.text = p['type'] == 'trial' ? '0' : (a == 0 ? '' : money(a)); paid.text = '0'; }); })),
          if (plan != null) _PlanInfo(data: plan!.data() ?? {}),
          _Field(label: 'المبلغ السنوي', controller: annual, enabled: !isTrial, keyboardType: TextInputType.number),
          _Field(label: 'المدفوع', controller: paid, enabled: !isTrial, keyboardType: TextInputType.number),
          SizedBox(height: 54, child: FilledButton(onPressed: saving || !canSave ? null : save, style: blueButton(), child: saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('حفظ الاشتراك'))),
        ]);
      },
    );
  }
}

class _FreeTrials extends StatefulWidget {
  const _FreeTrials();
  @override
  State<_FreeTrials> createState() => _FreeTrialsState();
}

class _FreeTrialsState extends State<_FreeTrials> {
  final search = TextEditingController();
  String filter = 'all';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String stateOf(Map<String, dynamic> data) {
    final d = daysLeft(data);
    if (d <= 0) return 'expired';
    if (d <= 7) return 'ending';
    return 'active';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> visible(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final q = search.text.trim().toLowerCase();
    return docs.where((doc) {
      final data = doc.data();
      final name = data['name']?.toString().toLowerCase() ?? '';
      final code = data['code']?.toString().toLowerCase() ?? '';
      final okSearch = q.isEmpty || name.contains(q) || code.contains(q);
      final okFilter = filter == 'all' || stateOf(data) == filter;
      return okSearch && okFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').where('status', isEqualTo: 'trial').snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final list = visible(docs);
        final active = docs.where((d) => stateOf(d.data()) == 'active').length;
        final ending = docs.where((d) => stateOf(d.data()) == 'ending').length;
        final expired = docs.where((d) => stateOf(d.data()) == 'expired').length;
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator()));
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('التجارب المجانية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _Search(controller: search, onChanged: (_) => setState(() {})),
          const SizedBox(height: 10),
          _TrialFilters(selected: filter, all: docs.length, active: active, ending: ending, expired: expired, onChanged: (v) => setState(() => filter = v)),
          const SizedBox(height: 14),
          if (docs.isEmpty) const _Empty(text: 'لا توجد مدارس في التجربة المجانية') else if (list.isEmpty) const _Empty(text: 'لا توجد نتائج مطابقة') else ...list.map((doc) => _TrialCard(doc: doc, state: stateOf(doc.data()), days: daysLeft(doc.data()))),
        ]);
      },
    );
  }
}

class _TrialFilters extends StatelessWidget {
  final String selected;
  final int all, active, ending, expired;
  final ValueChanged<String> onChanged;
  const _TrialFilters({required this.selected, required this.all, required this.active, required this.ending, required this.expired, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final data = [
      ['all', 'الكل', all],
      ['active', 'فعال', active],
      ['ending', 'قريب الانتهاء', ending],
      ['expired', 'منتهي', expired],
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final key = data[i][0] as String;
          final sel = key == selected;
          return ChoiceChip(
            selected: sel,
            showCheckmark: false,
            label: Text('${data[i][1]} ${data[i][2]}'),
            onSelected: (_) => onChanged(key),
            selectedColor: const Color(0xFFEFF3FF),
            backgroundColor: const Color(0xFFF8F8FC),
            side: BorderSide(color: sel ? const Color(0xFF2457D6) : const Color(0xFFE5E7EB)),
            labelStyle: TextStyle(color: sel ? const Color(0xFF2457D6) : const Color(0xFF4B5563), fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          );
        },
      ),
    );
  }
}

class _TrialCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String state;
  final int days;
  const _TrialCard({required this.doc, required this.state, required this.days});
  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final sub = subscription(data);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: Text(data['name']?.toString() ?? 'مدرسة', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), _StateBadge(state: state)]),
        const SizedBox(height: 8),
        Text('رمز المدرسة: ${data['code'] ?? ''}', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [_Chip(text: 'بداية: ${fmtDate(sub['startDate'])}'), _Chip(text: 'نهاية: ${fmtDate(sub['endDate'])}'), _Chip(text: 'الأيام: ${days < 0 ? 0 : days}')]),
        const SizedBox(height: 12),
        SizedBox(height: 42, child: OutlinedButton.icon(onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _TrialDetails(doc: doc)), icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('عرض'), style: outlineBlue())),
      ]),
    );
  }
}

class _TrialDetails extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _TrialDetails({required this.doc});
  @override
  State<_TrialDetails> createState() => _TrialDetailsState();
}

class _TrialDetailsState extends State<_TrialDetails> {
  final days = TextEditingController(text: '7');
  bool busy = false;
  @override
  void dispose() { days.dispose(); super.dispose(); }

  Future<void> extend() async {
    final count = int.tryParse(days.text.trim()) ?? 0;
    if (count <= 0 || busy) return;
    setState(() => busy = true);
    try {
      final data = widget.doc.data();
      final sub = Map<String, dynamic>.from(subscription(data));
      final oldEnd = DateTime.tryParse(sub['endDate']?.toString() ?? '') ?? DateTime.now();
      final base = oldEnd.isAfter(DateTime.now()) ? oldEnd : DateTime.now();
      sub['endDate'] = base.add(Duration(days: count)).toIso8601String();
      sub['status'] = 'trial';
      await widget.doc.reference.update({'status': 'trial', 'subscription': sub});
      if (!mounted) return;
      Navigator.pop(context);
      snack(context, 'تم تمديد التجربة $count يوم');
    } catch (e) { if (mounted) snack(context, 'فشل التمديد: $e'); } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> endTrial() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.doc.reference.update({'status': 'inactive', 'subscription.status': 'ended'});
      if (!mounted) return;
      Navigator.pop(context);
      snack(context, 'تم إنهاء التجربة');
    } catch (e) { if (mounted) snack(context, 'فشل إنهاء التجربة: $e'); } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final sub = subscription(data);
    return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      const Text('تفاصيل التجربة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      _Info(title: data['name']?.toString() ?? 'مدرسة', lines: ['رمز المدرسة: ${data['code'] ?? ''}', 'البريد: ${data['email'] ?? 'غير محدد'}', 'العنوان: ${[data['governorate'], data['address']].where((e) => e != null && e.toString().trim().isNotEmpty).join(' - ')}', 'بداية التجربة: ${fmtDate(sub['startDate'])}', 'نهاية التجربة: ${fmtDate(sub['endDate'])}', 'الأيام المتبقية: ${daysLeft(data) < 0 ? 0 : daysLeft(data)}']),
      const SizedBox(height: 14),
      _Field(label: 'مدة التمديد بالأيام', controller: days, keyboardType: TextInputType.number),
      SizedBox(height: 52, child: FilledButton.icon(onPressed: busy ? null : extend, icon: const Icon(Icons.add), label: const Text('تمديد التجربة'), style: blueButton())),
      const SizedBox(height: 10),
      SizedBox(height: 52, child: OutlinedButton.icon(onPressed: busy ? null : () => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _ConvertTrial(doc: widget.doc)), icon: const Icon(Icons.workspace_premium_outlined), label: const Text('تحويل إلى اشتراك فعّال'), style: outlineBlue())),
      const SizedBox(height: 10),
      SizedBox(height: 52, child: OutlinedButton.icon(onPressed: busy ? null : endTrial, icon: const Icon(Icons.stop_circle_outlined), label: const Text('إنهاء التجربة'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB42318), side: const BorderSide(color: Color(0xFFFFDAD6)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
    ]))));
  }
}

class _ConvertTrial extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ConvertTrial({required this.doc});
  @override
  State<_ConvertTrial> createState() => _ConvertTrialState();
}

class _ConvertTrialState extends State<_ConvertTrial> {
  final annual = TextEditingController();
  final paid = TextEditingController(text: '0');
  DocumentSnapshot<Map<String, dynamic>>? plan;
  bool saving = false;
  @override
  void dispose() { annual.dispose(); paid.dispose(); super.dispose(); }
  bool get canSave => plan != null && annual.text.trim().isNotEmpty;

  Future<void> save() async {
    if (!canSave || saving || plan == null) return;
    setState(() => saving = true);
    try {
      await applyPlan(widget.doc.id, plan!, toDouble(annual.text), toDouble(paid.text), forceActive: true);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      snack(context, 'تم تحويل التجربة إلى اشتراك فعّال');
    } catch (e) { if (mounted) snack(context, 'تعذر التحويل: $e'); } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(), builder: (_, snap) {
      final plans = (snap.data?.docs ?? []).where((p) => p.data()['type'] != 'trial').toList();
      if (snap.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
      return SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        const Text('تحويل إلى اشتراك فعّال', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        if (plans.isEmpty) const _Empty(text: 'لا توجد خطط مدفوعة مفعلة') else ...[
          _Picker(label: 'الخطة *', value: plan?.data()?['name']?.toString() ?? 'اختر الخطة', onTap: () => pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة', plans, planLabel, plan, (v) { final a = numFrom(v.data()?['annualPrice']); setState(() { plan = v; annual.text = a == 0 ? '' : money(a); paid.text = '0'; }); })),
          if (plan != null) _PlanInfo(data: plan!.data() ?? {}),
          _Field(label: 'المبلغ السنوي', controller: annual, keyboardType: TextInputType.number),
          _Field(label: 'المدفوع', controller: paid, keyboardType: TextInputType.number),
          SizedBox(height: 52, child: FilledButton(onPressed: saving || !canSave ? null : save, style: blueButton(), child: saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('حفظ الاشتراك وتفعيل المدرسة'))),
        ],
      ]));
    })));
  }
}

class _PlansManager extends StatelessWidget {
  const _PlansManager();
  static const defaults = [
    {'name': 'تجربة مجانية', 'type': 'trial', 'durationMonths': 1, 'pricingMethod': 'مجاني', 'pricePerStudent': 0, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
    {'name': 'شاملة 250', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 15, 'studentLimit': 250, 'annualPrice': 3750, 'isActive': true},
    {'name': 'شاملة 500', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 500, 'annualPrice': 5000, 'isActive': true},
    {'name': 'شاملة 750', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 750, 'annualPrice': 7500, 'isActive': true},
    {'name': 'شاملة 1000+', 'type': 'custom_bundle', 'durationMonths': 12, 'pricingMethod': 'مخصص', 'pricePerStudent': 10, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
    {'name': 'حسب الطالب', 'type': 'per_student', 'durationMonths': 12, 'pricingMethod': 'حسب حساب الطالب', 'pricePerStudent': 20, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
  ];

  Future<void> seed(BuildContext context) async {
    try {
      final batch = _db.batch();
      for (final p in defaults) { batch.set(_db.collection('billing_plans').doc(), {...p, 'createdAt': DateTime.now().toIso8601String(), 'updatedAt': DateTime.now().toIso8601String()}); }
      await batch.commit();
      if (context.mounted) snack(context, 'تم إنشاء الخطط الافتراضية');
    } catch (e) { if (context.mounted) snack(context, 'فشل إنشاء الخطط: $e'); }
  }

  void form(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _PlanForm(doc: doc));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('billing_plans').snapshots(), builder: (_, snap) {
      final docs = snap.data?.docs ?? [];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [const Expanded(child: Text('الخطط والأسعار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), IconButton(onPressed: () => form(context), icon: const Icon(Icons.add_circle, color: Color(0xFF2457D6), size: 32))]),
        const SizedBox(height: 8),
        if (snap.connectionState == ConnectionState.waiting) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())) else if (docs.isEmpty) Column(children: [const _Empty(text: 'لا توجد خطط بعد'), const SizedBox(height: 12), SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: () => seed(context), icon: const Icon(Icons.auto_fix_high), label: const Text('إنشاء الخطط الافتراضية')))]) else ...docs.map((doc) => _PlanCard(doc: doc, onEdit: () => form(context, doc: doc), onDelete: () async { await doc.reference.delete(); if (context.mounted) snack(context, 'تم حذف الخطة'); })),
      ]);
    });
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
  bool active = true, saving = false;

  @override
  void initState() { super.initState(); final d = widget.doc?.data(); if (d != null) { name.text = '${d['name'] ?? ''}'; type = '${d['type'] ?? 'bundle'}'; duration.text = '${d['durationMonths'] ?? 12}'; method.text = '${d['pricingMethod'] ?? ''}'; price.text = '${d['pricePerStudent'] ?? 0}'; limit.text = '${d['studentLimit'] ?? 0}'; annual.text = '${d['annualPrice'] ?? 0}'; active = d['isActive'] != false; } }
  @override
  void dispose() { name.dispose(); duration.dispose(); method.dispose(); price.dispose(); limit.dispose(); annual.dispose(); super.dispose(); }

  Future<void> save() async {
    if (name.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    final data = {'name': name.text.trim(), 'type': type, 'durationMonths': int.tryParse(duration.text) ?? 12, 'pricingMethod': method.text.trim(), 'pricePerStudent': toDouble(price.text), 'studentLimit': int.tryParse(limit.text) ?? 0, 'annualPrice': toDouble(annual.text), 'isActive': active, 'updatedAt': DateTime.now().toIso8601String()};
    try {
      if (widget.doc == null) { await _db.collection('billing_plans').add({...data, 'createdAt': DateTime.now().toIso8601String()}); } else { await widget.doc!.reference.update(data); }
      if (!mounted) return;
      Navigator.pop(context);
      snack(context, widget.doc == null ? 'تمت إضافة الخطة' : 'تم تعديل الخطة');
    } catch (e) { if (mounted) snack(context, 'تعذر حفظ الخطة: $e'); } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Text(widget.doc == null ? 'إضافة خطة' : 'تعديل خطة', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      _Field(label: 'اسم الخطة', controller: name, keyboardType: TextInputType.text),
      _Picker(label: 'نوع الخطة', value: typeName(type), onTap: () => pick<String>(context, 'اختر نوع الخطة', const ['trial', 'bundle', 'custom_bundle', 'per_student'], typeName, type, (v) => setState(() => type = v))),
      _Field(label: 'المدة بالأشهر', controller: duration, keyboardType: TextInputType.number),
      _Field(label: 'طريقة التسعير', controller: method, keyboardType: TextInputType.text),
      _Field(label: 'سعر الطالب', controller: price, keyboardType: TextInputType.number),
      _Field(label: 'حد الطلاب / 0 بدون حد', controller: limit, keyboardType: TextInputType.number),
      _Field(label: 'السعر السنوي', controller: annual, keyboardType: TextInputType.number),
      SwitchListTile(value: active, onChanged: (v) => setState(() => active = v), title: const Text('الخطة مفعلة', style: TextStyle(fontWeight: FontWeight.w800)), activeColor: const Color(0xFF2457D6), contentPadding: EdgeInsets.zero),
      SizedBox(height: 52, child: FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'جاري الحفظ...' : 'حفظ الخطة'))),
    ]))));
  }
}

class _PlanCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlanCard({required this.doc, required this.onEdit, required this.onDelete});
  @override
  Widget build(BuildContext context) { final d = doc.data() ?? {}; final active = d['isActive'] != false; return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF2457D6))), const SizedBox(width: 12), Expanded(child: Text('${d['name'] ?? 'خطة'}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), _Status(text: active ? 'مفعلة' : 'معطلة', active: active)]),
    const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [_Chip(text: 'سعر الطالب: ${d['pricePerStudent'] ?? 0} د.أ'), _Chip(text: '${d['studentLimit'] ?? 0}' == '0' ? 'بدون حد' : 'الحد: ${d['studentLimit']}'), _Chip(text: 'سنويًا: ${d['annualPrice'] ?? 0} د.أ')]),
    const SizedBox(height: 12), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('تعديل'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('حذف'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB42318))))]),
  ])); }
}

class _ActiveSubscriptions extends StatelessWidget {
  final List<School> schools;
  const _ActiveSubscriptions({required this.schools});
  @override
  Widget build(BuildContext context) { final active = schools.where((s) => s.status == 'active').toList(); if (active.isEmpty) return const _Empty(text: 'لا توجد مدارس لديها اشتراك مفعل'); return Column(children: active.map((s) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), const _Status(text: 'نشط', active: true)]), const SizedBox(height: 8), Text('رمز المدرسة: ${s.code}', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Wrap(spacing: 8, runSpacing: 8, children: [_Chip(text: 'نوع الخطة: محفوظ'), _Chip(text: 'المدفوع: محفوظ'), _Chip(text: 'المتبقي: محفوظ')])]))).toList()); }
}

class _Metric extends StatelessWidget { final IconData icon; final String title; final String value; const _Metric({required this.icon, required this.title, required this.value}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF2457D6), size: 23)), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, height: 1, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5, height: 1.15, fontWeight: FontWeight.w700))])])) ; }
class _Picker extends StatelessWidget { final String label, value; final VoidCallback onTap; const _Picker({required this.label, required this.value, required this.onTap}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: 7), InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: Container(height: 52, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCFCFD4)), borderRadius: BorderRadius.circular(12)), child: Row(children: [Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)))), const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E8E93))])))])); }
class _Field extends StatelessWidget { final String label; final TextEditingController controller; final bool enabled; final TextInputType keyboardType; const _Field({required this.label, required this.controller, this.enabled = true, this.keyboardType = TextInputType.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: 7), SizedBox(height: 52, child: TextField(controller: controller, enabled: enabled, keyboardType: keyboardType, textAlign: TextAlign.right, decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))])); }
class _Search extends StatelessWidget { final TextEditingController controller; final ValueChanged<String> onChanged; const _Search({required this.controller, required this.onChanged}); @override Widget build(BuildContext context) => Container(height: 52, decoration: BoxDecoration(color: const Color(0xFFF4F4F7), borderRadius: BorderRadius.circular(26)), child: TextField(controller: controller, onChanged: onChanged, textAlign: TextAlign.right, decoration: const InputDecoration(hintText: 'ابحث باسم المدرسة أو رمزها...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12), suffixIcon: Icon(Icons.search_rounded, size: 26)))); }
class _PlanInfo extends StatelessWidget { final Map<String, dynamic> data; const _PlanInfo({required this.data}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(16)), child: Wrap(spacing: 8, runSpacing: 8, children: [_Chip(text: 'المدة: ${data['durationMonths'] ?? 0} شهر'), _Chip(text: '${data['studentLimit'] ?? 0}' == '0' ? 'الحد: بدون' : 'الحد: ${data['studentLimit']}'), _Chip(text: 'سعر الطالب: ${data['pricePerStudent'] ?? 0} د.أ')])); }
class _Info extends StatelessWidget { final String title; final List<String> lines; const _Info({required this.title, required this.lines}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 10), ...lines.map((l) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(l, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, fontWeight: FontWeight.w700))))])); }
class _StateBadge extends StatelessWidget { final String state; const _StateBadge({required this.state}); @override Widget build(BuildContext context) { final expired = state == 'expired'; final ending = state == 'ending'; final text = expired ? 'منتهية' : ending ? 'قريب الانتهاء' : 'فعالة'; final color = expired ? const Color(0xFFB42318) : ending ? const Color(0xFFB54708) : const Color(0xFF16833A); final bg = expired ? const Color(0xFFFFF0F0) : ending ? const Color(0xFFFFF7E6) : const Color(0xFFE9F8EF); return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900))); } }
class _Status extends StatelessWidget { final String text; final bool active; const _Status({required this.text, required this.active}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: active ? const Color(0xFFE9F8EF) : const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: active ? const Color(0xFF16833A) : const Color(0xFFB42318), fontSize: 12, fontWeight: FontWeight.w900))); }
class _Chip extends StatelessWidget { final String text; const _Chip({required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4B5563)))); }
class _Empty extends StatelessWidget { final String text; const _Empty({required this.text}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(22)), child: Column(children: [const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF2457D6)), const SizedBox(height: 10), Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))])); }
class _Bullets extends StatelessWidget { final String title; final List<String> items; const _Bullets({required this.title, required this.items}); @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), ...items.map((i) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.circle, color: Color(0xFF2457D6), size: 10), const SizedBox(width: 10), Expanded(child: Text(i, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))])))]) ; }

void snack(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
ButtonStyle blueButton() => FilledButton.styleFrom(backgroundColor: const Color(0xFF2457D6), disabledBackgroundColor: const Color(0xFFF1F1F4), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
ButtonStyle outlineBlue() => OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2457D6), side: const BorderSide(color: Color(0xFFD9E1FF)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
Map<String, dynamic> subscription(Map<String, dynamic> data) => data['subscription'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['subscription'] as Map<String, dynamic>) : <String, dynamic>{};
int daysLeft(Map<String, dynamic> data) { final end = DateTime.tryParse(subscription(data)['endDate']?.toString() ?? ''); if (end == null) return 0; return end.difference(DateTime.now()).inDays + 1; }
String fmtDate(dynamic value) { final d = DateTime.tryParse(value?.toString() ?? ''); if (d == null) return '—'; return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}'; }
double numFrom(dynamic v) => v is int ? v.toDouble() : v is double ? v : double.tryParse(v?.toString() ?? '') ?? 0;
double toDouble(String v) => double.tryParse(v.trim()) ?? 0;
int intFrom(dynamic v, [int fallback = 0]) => v is int ? v : v is double ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;
String money(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
String planLabel(DocumentSnapshot<Map<String, dynamic>> doc) { final d = doc.data() ?? {}; return '${d['name'] ?? 'خطة'} - ${d['annualPrice'] ?? 0} د.أ'; }
String typeName(String v) { if (v == 'trial') return 'تجربة مجانية'; if (v == 'bundle') return 'شاملة'; if (v == 'custom_bundle') return 'شاملة مخصصة'; if (v == 'per_student') return 'حسب الطالب'; return v; }

void pick<T>(BuildContext context, String title, List<T> items, String Function(T) label, T? selected, ValueChanged<T> onSelect) {
  showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: FractionallySizedBox(heightFactor: 0.62, child: Padding(padding: const EdgeInsets.fromLTRB(22, 8, 22, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), Expanded(child: ListView(children: items.map((item) { final sel = item == selected; return InkWell(borderRadius: BorderRadius.circular(14), onTap: () { onSelect(item); Navigator.pop(context); }, child: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Row(children: [Expanded(child: Text(label(item), textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))), const SizedBox(width: 14), Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off, color: sel ? const Color(0xFF2457D6) : const Color(0xFF8E8E93))]))); }).toList()))])))));
}

Future<void> applyPlan(String schoolId, DocumentSnapshot<Map<String, dynamic>> plan, double annualAmount, double paidAmount, {bool forceActive = false}) async {
  final d = plan.data() ?? {};
  final trial = !forceActive && d['type'] == 'trial';
  final start = DateTime.now();
  final months = intFrom(d['durationMonths'], trial ? 1 : 12);
  final end = DateTime(start.year, start.month + months, start.day);
  final annual = trial ? 0.0 : annualAmount;
  final paid = trial ? 0.0 : paidAmount;
  await _db.collection('schools').doc(schoolId).update({'status': trial ? 'trial' : 'active', 'subscription': {'planId': plan.id, 'planName': d['name']?.toString() ?? '', 'planType': d['type']?.toString() ?? '', 'pricingMethod': d['pricingMethod']?.toString() ?? '', 'durationMonths': months, 'studentLimit': intFrom(d['studentLimit']), 'pricePerStudent': numFrom(d['pricePerStudent']), 'status': trial ? 'trial' : 'active', 'startDate': start.toIso8601String(), 'endDate': end.toIso8601String(), 'annualAmount': annual, 'paidAmount': paid, 'remainingAmount': (annual - paid) < 0 ? 0 : annual - paid, 'createdAt': DateTime.now().toIso8601String()}});
}
