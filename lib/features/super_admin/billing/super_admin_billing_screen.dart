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
const _warning = Color(0xFFB54708);

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
    double annual = 0;
    double paid = 0;
    double remaining = 0;
    int unpaidStudents = 0;

    for (final school in schools) {
      final data = d(school);
      final s = sub(data);
      if (isPerStudent(data)) {
        final stats = perStudentStats(data, intFrom(data['studentsCount']));
        annual += stats.total;
        paid += stats.paidAmount;
        remaining += stats.remaining;
        unpaidStudents += stats.unpaidStudents;
      } else {
        annual += n(s['annualAmount']);
        paid += n(s['paidAmount']);
        remaining += n(s['remainingAmount']);
      }
    }

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
          _Metric('طلاب غير مدفوعين', '$unpaidStudents', Icons.person_off_outlined),
        ],
      ),
      const SizedBox(height: 14),
      card(const Text('قاعدة النظام: كل طالب موجود داخل مدرسة على خطة حسب الطالب يُحسب ماليًا. لا يوجد معفى ولا غير مشترك في هذه الخطة.', style: TextStyle(fontWeight: FontWeight.w800, height: 1.5))),
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
  void dispose() {
    annual.dispose();
    paid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inactive = widget.schools.where((s) => !['active', 'trial'].contains(d(s)['status'])).toList();
    if (inactive.isEmpty) return const _Empty('لا توجد مدارس غير مفعلة لإضافة اشتراك لها');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        final plans = snapshot.data?.docs ?? [];
        if (plans.isEmpty) return const _Empty('لا توجد خطط مفعلة. أضف أو فعّل خطة أولاً');
        final type = plan?.data()?['type'];
        final isTrial = type == 'trial';
        final isPerStudentPlan = type == 'per_student';
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
              setState(() {
                plan = v;
                annual.text = p['type'] == 'trial' || p['type'] == 'per_student' ? '0' : (amount == 0 ? '' : money(amount));
                paid.text = '0';
              });
            });
          }),
          if (plan != null) _PlanPreview(plan!.data() ?? {}),
          if (isPerStudentPlan) card(const Text('خطة حسب الطالب: السعر السنوي يحسب تلقائيًا من عدد الطلاب × سعر الطالب. أدخل المدفوع فقط إن وجد.', style: TextStyle(fontWeight: FontWeight.w800, height: 1.4))),
          _TextFieldBox('المبلغ السنوي', annual, enabled: !isTrial && !isPerStudentPlan, keyboardType: TextInputType.number),
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
      await applyPlan(school!.id, plan!, toDouble(annual.text), toDouble(paid.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الاشتراك')));
      setState(() {
        school = null;
        plan = null;
        annual.clear();
        paid.text = '0';
      });
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _SubscriptionsTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _SubscriptionsTab(this.schools);

  @override
  State<_SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<_SubscriptionsTab> {
  final search = TextEditingController();
  String filter = 'all';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscribed = widget.schools.where((s) => d(s)['status'] == 'active').toList();
    final counts = {
      'all': subscribed.length,
      'active': subscribed.where((s) => subscriptionState(d(s)) == 'active').length,
      'due': subscribed.where((s) => subscriptionState(d(s)) == 'due').length,
      'expired': subscribed.where((s) => subscriptionState(d(s)) == 'expired').length,
      'bundle': subscribed.where((s) => !isPerStudent(d(s))).length,
      'per_student': subscribed.where((s) => isPerStudent(d(s))).length,
    };
    final q = search.text.trim().toLowerCase();
    final visible = subscribed.where((s) {
      final data = d(s);
      final name = '${data['name'] ?? ''}'.toLowerCase();
      final code = '${data['code'] ?? ''}'.toLowerCase();
      final planName = '${sub(data)['planName'] ?? ''}'.toLowerCase();
      final status = subscriptionState(data);
      final typeOk = filter == 'all' || status == filter || (filter == 'bundle' && !isPerStudent(data)) || (filter == 'per_student' && isPerStudent(data));
      return (q.isEmpty || name.contains(q) || code.contains(q) || planName.contains(q)) && typeOk;
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.receipt_long_outlined, color: _blue)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('اشتراكات المدارس', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          SizedBox(height: 3),
          Text('متابعة الخطط، الدفع، الحدود، وحالة كل مدرسة', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        ])),
      ]),
      const SizedBox(height: 14),
      _SubscriptionsOverview(schools: subscribed),
      const SizedBox(height: 14),
      _SearchBox(search, (_) => setState(() {}), hint: 'ابحث باسم المدرسة أو الرمز أو الخطة...'),
      const SizedBox(height: 10),
      _SmallFilter(filter, {
        'all': 'الكل ${counts['all']}',
        'active': 'نشط ${counts['active']}',
        'due': 'متأخر ${counts['due']}',
        'expired': 'منتهي ${counts['expired']}',
        'bundle': 'شاملة ${counts['bundle']}',
        'per_student': 'حسب الطالب ${counts['per_student']}',
      }, (v) => setState(() => filter = v)),
      const SizedBox(height: 12),
      if (visible.isEmpty) const _Empty('لا توجد اشتراكات مطابقة') else ...visible.map((s) => _SubscriptionCard(s)),
    ]);
  }
}

class _SubscriptionsOverview extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _SubscriptionsOverview({required this.schools});

  @override
  Widget build(BuildContext context) {
    double annual = 0;
    double paid = 0;
    double remaining = 0;
    int perStudent = 0;
    int bundle = 0;
    for (final doc in schools) {
      final data = d(doc);
      final s = sub(data);
      if (isPerStudent(data)) {
        perStudent++;
        final stats = perStudentStats(data, intFrom(data['studentsCount']));
        annual += stats.total;
        paid += stats.paidAmount;
        remaining += stats.remaining;
      } else {
        bundle++;
        annual += n(s['annualAmount']);
        paid += n(s['paidAmount']);
        remaining += n(s['remainingAmount']);
      }
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _MiniSummary('اشتراكات', '${schools.length}', Icons.apartment_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _MiniSummary('شاملة', '$bundle', Icons.all_inclusive_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _MiniSummary('حسب الطالب', '$perStudent', Icons.groups_outlined)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _MiniSummary('سنويًا', '${money(annual)} د.أ', Icons.calendar_month_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _MiniSummary('مدفوع', '${money(paid)} د.أ', Icons.payments_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _MiniSummary('متبقي', '${money(remaining)} د.أ', Icons.account_balance_wallet_outlined)),
      ]),
    ]);
  }
}

class _MiniSummary extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _MiniSummary(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _blue, size: 20),
          const SizedBox(height: 8),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _SubscriptionCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _SubscriptionCard(this.doc);

  @override
  Widget build(BuildContext context) {
    final data = d(doc);
    final s = sub(data);
    final per = isPerStudent(data);
    final limit = intFrom(s['studentLimit']);
    final students = intFrom(data['studentsCount']);
    final annual = per ? perStudentStats(data, students).total : n(s['annualAmount']);
    final paid = n(s['paidAmount']);
    final remaining = per ? perStudentStats(data, students).remaining : n(s['remainingAmount']);
    final progress = annual <= 0 ? 0.0 : (paid / annual).clamp(0.0, 1.0).toDouble();

    return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(16)), child: Icon(per ? Icons.groups_outlined : Icons.all_inclusive_rounded, color: _blue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${data['name'] ?? 'مدرسة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text('رمز المدرسة: ${data['code'] ?? '—'}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        ])),
        _Badge(subscriptionLabel(data), subscriptionColor(data)),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: _LineInfo('نوع الخطة', per ? 'حسب الطالب' : 'شاملة')),
            Expanded(child: _LineInfo('الخطة', '${s['planName'] ?? '—'}')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _LineInfo('البداية', date(s['startDate']))),
            Expanded(child: _LineInfo('النهاية', date(s['endDate']))),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      if (per)
        _PerStudentBillingPreview(doc: doc)
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          _DataPill('عدد الطلاب', '$students'),
          _DataPill('حد الطلاب', limit == 0 ? 'غير محدد' : '$limit'),
          if (limit > 0) _DataPill('المقاعد المتبقية', '${positiveInt(limit - students)}'),
          _DataPill('المدفوع', '${money(paid)} د.أ'),
          _DataPill('المتبقي', '${money(remaining)} د.أ'),
        ]),
      const SizedBox(height: 12),
      _ProgressBlock(title: 'نسبة التحصيل', value: progress, text: '${(progress * 100).toStringAsFixed(0)}%'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => openSubscriptionDetails(context, doc), icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('عرض'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: () => openSubscriptionDetails(context, doc), icon: const Icon(Icons.payments_outlined, size: 18), label: const Text('دفعة'))),
      ]),
    ]));
  }
}

class _PerStudentBillingPreview extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _PerStudentBillingPreview({required this.doc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').doc(doc.id).collection('students').snapshots(),
      builder: (context, snapshot) {
        final stats = perStudentStats(d(doc), snapshot.data?.docs.length ?? intFrom(d(doc)['studentsCount']));
        return Wrap(spacing: 8, runSpacing: 8, children: [
          _DataPill('عدد الطلاب', '${stats.count}'),
          _DataPill('سعر الطالب', '${money(stats.price)} د.أ'),
          _DataPill('المستحق', '${money(stats.total)} د.أ'),
          _DataPill('مدفوعين', '${stats.paidStudents}'),
          _DataPill('غير مدفوعين', '${stats.unpaidStudents}'),
          _DataPill('المتبقي', '${money(stats.remaining)} د.أ'),
        ]);
      },
    );
  }
}

class _LineInfo extends StatelessWidget {
  final String title;
  final String value;
  const _LineInfo(this.title, this.value);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
      ]);
}

class _DataPill extends StatelessWidget {
  final String title;
  final String value;
  const _DataPill(this.title, this.value);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _ProgressBlock extends StatelessWidget {
  final String title;
  final double value;
  final String text;
  const _ProgressBlock({required this.title, required this.value, required this.text});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Expanded(child: Text(title, style: const TextStyle(color: _muted, fontWeight: FontWeight.w800))), Text(text, style: const TextStyle(fontWeight: FontWeight.w900))]),
        const SizedBox(height: 7),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: const Color(0xFFE5E7EB), color: _blue)),
      ]);
}

class _TrialsTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _TrialsTab(this.schools);

  @override
  State<_TrialsTab> createState() => _TrialsTabState();
}

class _TrialsTabState extends State<_TrialsTab> {
  final search = TextEditingController();
  String filter = 'all';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.schools.where((s) => d(s)['status'] == 'trial').toList();
    final q = search.text.trim().toLowerCase();
    final visible = docs.where((doc) {
      final data = d(doc);
      final name = '${data['name'] ?? ''}'.toLowerCase();
      final code = '${data['code'] ?? ''}'.toLowerCase();
      return (q.isEmpty || name.contains(q) || code.contains(q)) && (filter == 'all' || trialState(data) == filter);
    }).toList();
    final active = docs.where((x) => trialState(d(x)) == 'active').length;
    final ending = docs.where((x) => trialState(d(x)) == 'ending').length;
    final expired = docs.where((x) => trialState(d(x)) == 'expired').length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('التجارب المجانية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      _SearchBox(search, (_) => setState(() {}), hint: 'ابحث باسم المدرسة أو رمزها...'),
      const SizedBox(height: 10),
      _SmallFilter(filter, {'all': 'الكل ${docs.length}', 'active': 'فعال $active', 'ending': 'قريب الانتهاء $ending', 'expired': 'منتهي $expired'}, (v) => setState(() => filter = v)),
      const SizedBox(height: 12),
      if (docs.isEmpty) const _Empty('لا توجد مدارس في التجربة المجانية') else if (visible.isEmpty) const _Empty('لا توجد نتائج مطابقة') else ...visible.map((doc) => _TrialCard(doc)),
    ]);
  }
}

class _TrialCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _TrialCard(this.doc);

  @override
  Widget build(BuildContext context) {
    final data = d(doc);
    final s = sub(data);
    final left = daysLeft(data);
    return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_outlined, color: _blue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${data['name'] ?? 'مدرسة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          Text('رمز: ${data['code'] ?? ''}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        ])),
        _Badge(trialLabel(data), trialColor(data)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [_Chip('بداية: ${date(s['startDate'])}'), _Chip('نهاية: ${date(s['endDate'])}'), _Chip('الأيام: ${left < 0 ? 0 : left}')]),
      const SizedBox(height: 12),
      SizedBox(height: 42, child: OutlinedButton.icon(onPressed: () => openTrialDetails(context, doc), icon: const Icon(Icons.visibility_outlined), label: const Text('عرض'))),
    ]));
  }
}

class _PlansTab extends StatelessWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('billing_plans').snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const Expanded(child: Text('الخطط والأسعار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
              IconButton(onPressed: () => openPlanForm(context), icon: const Icon(Icons.add_circle, color: _blue, size: 32)),
            ]),
            if (docs.isEmpty)
              Column(children: [
                const _Empty('لا توجد خطط بعد'),
                SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () => seedPlans(context), child: const Text('إنشاء الخطط الافتراضية'))),
              ])
            else
              ...docs.map((doc) => _PlanCard(doc)),
          ]);
        },
      );
}

class _PlanCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const _PlanCard(this.doc);

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final active = data['isActive'] != false;
    return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text('${data['name'] ?? 'خطة'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        _Badge(active ? 'مفعلة' : 'معطلة', active ? _success : _danger),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Chip('النوع: ${typeName('${data['type'] ?? ''}')}'),
        _Chip('المدة: ${data['durationMonths'] ?? 0} شهر'),
        _Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}'),
        _Chip('الحد: ${data['studentLimit'] ?? 0}'),
        _Chip('سنويًا: ${data['type'] == 'per_student' ? 'تلقائي' : data['annualPrice'] ?? 0}'),
      ]),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => openPlanForm(context, doc: doc), child: const Text('تعديل'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () => doc.reference.delete(), child: const Text('حذف'))),
      ]),
    ]));
  }
}

class _AlertsTab extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _AlertsTab(this.schools);

  @override
  Widget build(BuildContext context) {
    final alerts = <Widget>[];
    for (final doc in schools) {
      final data = d(doc);
      final s = sub(data);
      final name = '${data['name'] ?? 'مدرسة'}';
      final left = daysLeft(data);
      if (data['status'] == 'active' && left > 0 && left <= 30) alerts.add(_Alert('اشتراك ينتهي قريبًا', '$name ينتهي بعد $left يوم', Icons.event_busy_outlined, _blue));
      if (data['status'] == 'active' && left <= 0) alerts.add(_Alert('اشتراك منتهي', '$name انتهى اشتراكها', Icons.warning_amber_rounded, _danger));
      if (data['status'] == 'trial' && left > 0 && left <= 7) alerts.add(_Alert('تجربة تنتهي قريبًا', '$name تنتهي تجربتها بعد $left يوم', Icons.hourglass_bottom_rounded, _warning));
      if (isPerStudent(data)) {
        final stats = perStudentStats(data, intFrom(data['studentsCount']));
        if (stats.unpaidStudents > 0) alerts.add(_Alert('طلاب غير مدفوعين', '$name لديها ${stats.unpaidStudents} طالب غير مدفوع', Icons.person_off_outlined, _danger));
      } else if (n(s['remainingAmount']) > 0) {
        alerts.add(_Alert('مبلغ متبقي', '$name عليها ${money(n(s['remainingAmount']))} د.أ', Icons.account_balance_wallet_outlined, _danger));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('تنبيهات الفوترة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      if (alerts.isEmpty) const _Empty('لا توجد تنبيهات حالياً') else ...alerts,
    ]);
  }
}

class _Alert extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  const _Alert(this.title, this.message, this.icon, this.color);

  @override
  Widget build(BuildContext context) => card(Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(message, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        ])),
      ]));
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

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data();
    if (data != null) {
      name.text = '${data['name'] ?? ''}';
      type = '${data['type'] ?? 'bundle'}';
      duration.text = '${data['durationMonths'] ?? 12}';
      method.text = '${data['pricingMethod'] ?? ''}';
      price.text = '${data['pricePerStudent'] ?? 0}';
      limit.text = '${data['studentLimit'] ?? 0}';
      annual.text = '${data['annualPrice'] ?? 0}';
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

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text(widget.doc == null ? 'إضافة خطة' : 'تعديل خطة', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _TextFieldBox('اسم الخطة', name, keyboardType: TextInputType.text),
              _PickerField('نوع الخطة', typeName(type), () => pick<String>(context, 'نوع الخطة', const ['trial', 'bundle', 'custom_bundle', 'per_student'], typeName, type, (v) => setState(() => type = v))),
              _TextFieldBox('المدة بالأشهر', duration, keyboardType: TextInputType.number),
              _TextFieldBox('طريقة التسعير', method, keyboardType: TextInputType.text),
              _TextFieldBox('سعر الطالب', price, keyboardType: TextInputType.number),
              _TextFieldBox('حد الطلاب', limit, keyboardType: TextInputType.number),
              _TextFieldBox('السعر السنوي', annual, enabled: type != 'per_student', keyboardType: TextInputType.number),
              SwitchListTile(value: active, onChanged: (v) => setState(() => active = v), title: const Text('الخطة مفعلة', style: TextStyle(fontWeight: FontWeight.w800)), activeColor: _blue, contentPadding: EdgeInsets.zero),
              SizedBox(height: 50, child: FilledButton(onPressed: save, child: const Text('حفظ الخطة'))),
            ]),
          ),
        ),
      );

  Future<void> save() async {
    final data = {
      'name': name.text.trim(),
      'type': type,
      'durationMonths': int.tryParse(duration.text) ?? 12,
      'pricingMethod': method.text.trim(),
      'pricePerStudent': toDouble(price.text),
      'studentLimit': int.tryParse(limit.text) ?? 0,
      'annualPrice': type == 'per_student' ? 0 : toDouble(annual.text),
      'isActive': active,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (widget.doc == null) {
      await _db.collection('billing_plans').add({...data, 'createdAt': DateTime.now().toIso8601String()});
    } else {
      await widget.doc!.reference.update(data);
    }
    if (mounted) Navigator.pop(context);
  }
}

class _TrialDetailsSheet extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _TrialDetailsSheet(this.doc);

  @override
  State<_TrialDetailsSheet> createState() => _TrialDetailsSheetState();
}

class _TrialDetailsSheetState extends State<_TrialDetailsSheet> {
  final extendDays = TextEditingController(text: '7');

  @override
  void dispose() {
    extendDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = d(widget.doc);
    final s = sub(data);
    final left = daysLeft(data);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            const Text('تفاصيل التجربة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF123A73), _blue]), borderRadius: BorderRadius.circular(24)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${data['name'] ?? 'مدرسة'}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('متبقي ${left < 0 ? 0 : left} يوم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                Text('من ${date(s['startDate'])} إلى ${date(s['endDate'])}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 14),
            card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('رمز المدرسة: ${data['code'] ?? ''}'),
              Text('البريد: ${data['email'] ?? 'غير محدد'}'),
              Text('العنوان: ${[data['governorate'], data['address']].where((e) => e != null && '$e'.trim().isNotEmpty).join(' - ')}'),
            ])),
            _TextFieldBox('مدة التمديد بالأيام', extendDays, keyboardType: TextInputType.number),
            SizedBox(height: 52, child: FilledButton.icon(onPressed: extend, icon: const Icon(Icons.add), label: const Text('تمديد التجربة'))),
            const SizedBox(height: 10),
            SizedBox(height: 52, child: OutlinedButton.icon(onPressed: openConvert, icon: const Icon(Icons.workspace_premium_outlined), label: const Text('تحويل إلى اشتراك فعّال'))),
            const SizedBox(height: 10),
            SizedBox(height: 52, child: OutlinedButton.icon(onPressed: endTrial, icon: const Icon(Icons.stop_circle_outlined), label: const Text('إنهاء التجربة'), style: OutlinedButton.styleFrom(foregroundColor: _danger))),
          ]),
        ),
      ),
    );
  }

  Future<void> extend() async {
    final count = int.tryParse(extendDays.text.trim()) ?? 0;
    if (count <= 0) return;
    final s = Map<String, dynamic>.from(sub(d(widget.doc)));
    final oldEnd = DateTime.tryParse('${s['endDate'] ?? ''}') ?? DateTime.now();
    final base = oldEnd.isAfter(DateTime.now()) ? oldEnd : DateTime.now();
    s['endDate'] = base.add(Duration(days: count)).toIso8601String();
    s['status'] = 'trial';
    await widget.doc.reference.update({'status': 'trial', 'subscription': s});
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تمديد التجربة $count يوم')));
    }
  }

  Future<void> endTrial() async {
    await widget.doc.reference.update({'status': 'inactive', 'subscription.status': 'ended'});
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء التجربة')));
    }
  }

  void openConvert() => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _ConvertTrialSheet(widget.doc));
}

class _ConvertTrialSheet extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ConvertTrialSheet(this.doc);

  @override
  State<_ConvertTrialSheet> createState() => _ConvertTrialSheetState();
}

class _ConvertTrialSheetState extends State<_ConvertTrialSheet> {
  DocumentSnapshot<Map<String, dynamic>>? plan;
  final annual = TextEditingController();
  final paid = TextEditingController(text: '0');

  @override
  void dispose() {
    annual.dispose();
    paid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              final plans = (snapshot.data?.docs ?? []).where((p) => p.data()['type'] != 'trial').toList();
              final isPerStudentPlan = plan?.data()?['type'] == 'per_student';
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                  const Text('تحويل إلى اشتراك فعّال', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  if (plans.isEmpty)
                    const _Empty('لا توجد خطط مدفوعة مفعلة')
                  else ...[
                    _PickerField('الخطة', plan?.data()?['name']?.toString() ?? 'اختر الخطة', () => pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة', plans, planLabel, plan, (v) {
                          final amount = n(v.data()?['annualPrice']);
                          setState(() {
                            plan = v;
                            annual.text = v.data()?['type'] == 'per_student' ? '0' : (amount == 0 ? '' : money(amount));
                            paid.text = '0';
                          });
                        })),
                    if (plan != null) _PlanPreview(plan!.data() ?? {}),
                    if (isPerStudentPlan) card(const Text('سيتم احتساب إجمالي المستحق تلقائيًا من عدد طلاب المدرسة × سعر الطالب.', style: TextStyle(fontWeight: FontWeight.w800))),
                    _TextFieldBox('المبلغ السنوي', annual, enabled: !isPerStudentPlan, keyboardType: TextInputType.number),
                    _TextFieldBox('المدفوع', paid, keyboardType: TextInputType.number),
                    SizedBox(height: 52, child: FilledButton(onPressed: plan == null || (!isPerStudentPlan && annual.text.trim().isEmpty) ? null : save, child: const Text('حفظ الاشتراك وتفعيل المدرسة'))),
                  ],
                ]),
              );
            },
          ),
        ),
      );

  Future<void> save() async {
    if (plan == null) return;
    await applyPlan(widget.doc.id, plan!, toDouble(annual.text), toDouble(paid.text), forceActive: true);
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحويل التجربة إلى اشتراك فعّال')));
    }
  }
}

class _SubscriptionDetailsSheet extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _SubscriptionDetailsSheet(this.doc);

  @override
  State<_SubscriptionDetailsSheet> createState() => _SubscriptionDetailsSheetState();
}

class _SubscriptionDetailsSheetState extends State<_SubscriptionDetailsSheet> {
  final payment = TextEditingController();

  @override
  void dispose() {
    payment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = d(widget.doc);
    final s = sub(data);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            const Text('تفاصيل الاشتراك', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('المدرسة: ${data['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('الخطة: ${s['planName'] ?? ''}'),
              Text('البداية: ${date(s['startDate'])}'),
              Text('النهاية: ${date(s['endDate'])}'),
            ])),
            if (isPerStudent(data)) _PerStudentBillingDetails(doc: widget.doc) else _BundleBillingDetails(data: data),
            _TextFieldBox('تسجيل دفعة جديدة', payment, keyboardType: TextInputType.number),
            SizedBox(height: 52, child: FilledButton.icon(onPressed: recordPayment, icon: const Icon(Icons.payments_outlined), label: const Text('تسجيل دفعة'))),
          ]),
        ),
      ),
    );
  }

  Future<void> recordPayment() async {
    final amount = toDouble(payment.text);
    if (amount <= 0) return;
    final data = d(widget.doc);
    final s = Map<String, dynamic>.from(sub(data));
    double annual = n(s['annualAmount']);
    if (isPerStudent(data)) {
      final count = await getStudentsCount(widget.doc.id);
      annual = count * perStudentPrice(data);
    }
    final paid = n(s['paidAmount']) + amount;
    s['annualAmount'] = annual;
    s['paidAmount'] = paid;
    s['remainingAmount'] = positive(annual - paid);
    await widget.doc.reference.update({'subscription': s, if (isPerStudent(data)) 'studentsCount': await getStudentsCount(widget.doc.id)});
    await widget.doc.reference.collection('payments').add({'amount': amount, 'date': DateTime.now().toIso8601String(), 'status': 'confirmed'});
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة')));
    }
  }
}

class _BundleBillingDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BundleBillingDetails({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = sub(data);
    final limit = intFrom(s['studentLimit']);
    final current = intFrom(data['studentsCount']);
    return card(Wrap(spacing: 8, runSpacing: 8, children: [
      _DataPill('حد الطلاب', limit == 0 ? 'غير محدد' : '$limit'),
      _DataPill('عدد الطلاب', '$current'),
      if (limit > 0) _DataPill('المقاعد المتبقية', '${positiveInt(limit - current)}'),
      _DataPill('المبلغ السنوي', '${money(n(s['annualAmount']))} د.أ'),
      _DataPill('المدفوع', '${money(n(s['paidAmount']))} د.أ'),
      _DataPill('المتبقي', '${money(n(s['remainingAmount']))} د.أ'),
    ]));
  }
}

class _PerStudentBillingDetails extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _PerStudentBillingDetails({required this.doc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').doc(doc.id).collection('students').snapshots(),
      builder: (context, snapshot) {
        final stats = perStudentStats(d(doc), snapshot.data?.docs.length ?? intFrom(d(doc)['studentsCount']));
        return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('فوترة حسب الطالب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _DataPill('عدد الطلاب', '${stats.count}'),
            _DataPill('سعر الطالب', '${money(stats.price)} د.أ'),
            _DataPill('إجمالي المستحق', '${money(stats.total)} د.أ'),
            _DataPill('المدفوع', '${money(stats.paidAmount)} د.أ'),
            _DataPill('المتبقي', '${money(stats.remaining)} د.أ'),
            _DataPill('طلاب مدفوعين', '${stats.paidStudents}'),
            _DataPill('طلاب غير مدفوعين', '${stats.unpaidStudents}'),
          ]),
        ]));
      },
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _Metric(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: _blue),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(title, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _SmallFilter extends StatelessWidget {
  final String selected;
  final Map<String, String> items;
  final ValueChanged<String> onSelect;
  const _SmallFilter(this.selected, this.items, this.onSelect);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView(scrollDirection: Axis.horizontal, children: items.entries.map((e) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(selected: selected == e.key, showCheckmark: false, label: Text(e.value), onSelected: (_) => onSelect(e.key), selectedColor: _softBlue))).toList()),
      );
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerField(this.label, this.value, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            child: Row(children: [Expanded(child: Text(value)), const Icon(Icons.keyboard_arrow_down_rounded)]),
          ),
        ),
      );
}

class _TextFieldBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType keyboardType;
  const _TextFieldBox(this.label, this.controller, {this.enabled = true, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(controller: controller, enabled: enabled, keyboardType: keyboardType, textAlign: TextAlign.right, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      );
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  const _SearchBox(this.controller, this.onChanged, {this.hint = 'بحث...'});

  @override
  Widget build(BuildContext context) => TextField(controller: controller, onChanged: onChanged, textAlign: TextAlign.right, decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
}

class _PlanPreview extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PlanPreview(this.data);

  @override
  Widget build(BuildContext context) => card(Wrap(spacing: 8, runSpacing: 8, children: [
        _Chip('المدة: ${data['durationMonths'] ?? 0} شهر'),
        _Chip('الحد: ${data['studentLimit'] ?? 0}'),
        _Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}'),
      ]));
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(99)), child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)));
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)));
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => card(Text(text, style: const TextStyle(fontWeight: FontWeight.w800)));
}

class PerStudentStats {
  final int count;
  final double price;
  final double total;
  final double paidAmount;
  final double remaining;
  final int paidStudents;
  final int unpaidStudents;
  const PerStudentStats(this.count, this.price, this.total, this.paidAmount, this.remaining, this.paidStudents, this.unpaidStudents);
}

Widget card(Widget child) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)), child: child);
Map<String, dynamic> d(QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.data();
Map<String, dynamic> sub(Map<String, dynamic> data) => data['subscription'] is Map<String, dynamic> ? Map<String, dynamic>.from(data['subscription'] as Map<String, dynamic>) : <String, dynamic>{};
bool isPerStudent(Map<String, dynamic> data) => sub(data)['planType'] == 'per_student';
double perStudentPrice(Map<String, dynamic> data) => n(sub(data)['pricePerStudent']) == 0 ? 20 : n(sub(data)['pricePerStudent']);
PerStudentStats perStudentStats(Map<String, dynamic> data, int count) {
  final price = perStudentPrice(data);
  final total = count * price;
  final paidAmount = n(sub(data)['paidAmount']);
  final paidStudents = clampInt(price <= 0 ? 0 : (paidAmount / price).floor(), 0, count);
  final unpaidStudents = count - paidStudents;
  return PerStudentStats(count, price, total, paidAmount, positive(total - paidAmount), paidStudents, unpaidStudents);
}
int daysLeft(Map<String, dynamic> data) {
  final end = DateTime.tryParse('${sub(data)['endDate'] ?? ''}');
  return end == null ? 0 : end.difference(DateTime.now()).inDays + 1;
}
String date(dynamic value) {
  final x = DateTime.tryParse('$value');
  return x == null ? '—' : '${x.year}/${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}';
}
double n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
double toDouble(String v) => double.tryParse(v.trim()) ?? 0;
int intFrom(dynamic v, [int fallback = 0]) => v is int ? v : v is double ? v.toInt() : int.tryParse('$v') ?? fallback;
int clampInt(int value, int min, int max) => value < min ? min : value > max ? max : value;
int positiveInt(int value) => value < 0 ? 0 : value;
double positive(double value) => value < 0 ? 0 : value;
String money(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
String typeName(String v) => v == 'trial' ? 'تجربة مجانية' : v == 'bundle' ? 'شاملة' : v == 'custom_bundle' ? 'شاملة مخصصة' : v == 'per_student' ? 'حسب الطالب' : v;
String planLabel(DocumentSnapshot<Map<String, dynamic>> doc) => '${doc.data()?['name'] ?? 'خطة'} - ${doc.data()?['annualPrice'] ?? 0} د.أ';
String trialState(Map<String, dynamic> data) => daysLeft(data) <= 0 ? 'expired' : daysLeft(data) <= 7 ? 'ending' : 'active';
String trialLabel(Map<String, dynamic> data) => trialState(data) == 'expired' ? 'منتهي' : trialState(data) == 'ending' ? 'قريب الانتهاء' : 'فعال';
Color trialColor(Map<String, dynamic> data) => trialState(data) == 'expired' ? _danger : trialState(data) == 'ending' ? _warning : _success;
String subscriptionState(Map<String, dynamic> data) => daysLeft(data) <= 0 ? 'expired' : (isPerStudent(data) ? perStudentStats(data, intFrom(data['studentsCount'])).remaining > 0 : n(sub(data)['remainingAmount']) > 0) ? 'due' : 'active';
String subscriptionLabel(Map<String, dynamic> data) => subscriptionState(data) == 'expired' ? 'منتهي' : subscriptionState(data) == 'due' ? 'متأخر بالدفع' : 'نشط';
Color subscriptionColor(Map<String, dynamic> data) => subscriptionState(data) == 'active' ? _success : subscriptionState(data) == 'due' ? _warning : _danger;

void pick<T>(BuildContext context, String title, List<T> items, String Function(T) label, T? selected, ValueChanged<T> onSelect) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: FractionallySizedBox(
          heightFactor: .62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Expanded(child: ListView(children: items.map((item) {
                final isSelected = item == selected;
                return ListTile(title: Text(label(item), textAlign: TextAlign.right), leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? _blue : const Color(0xFF8E8E93)), onTap: () { onSelect(item); Navigator.pop(context); });
              }).toList())),
            ]),
          ),
        ),
      ),
    ),
  );
}

void openPlanForm(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _PlanForm(doc: doc));
void openTrialDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _TrialDetailsSheet(doc));
void openSubscriptionDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _SubscriptionDetailsSheet(doc));

Future<int> getStudentsCount(String schoolId) async {
  final snap = await _db.collection('schools').doc(schoolId).collection('students').get();
  return snap.docs.length;
}

Future<void> seedPlans(BuildContext context) async {
  final defaults = [
    {'name': 'تجربة مجانية', 'type': 'trial', 'durationMonths': 1, 'pricingMethod': 'مجاني', 'pricePerStudent': 0, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
    {'name': 'شاملة 250', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 15, 'studentLimit': 250, 'annualPrice': 3750, 'isActive': true},
    {'name': 'شاملة 500', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 500, 'annualPrice': 5000, 'isActive': true},
    {'name': 'شاملة 750', 'type': 'bundle', 'durationMonths': 12, 'pricingMethod': 'باقة', 'pricePerStudent': 10, 'studentLimit': 750, 'annualPrice': 7500, 'isActive': true},
    {'name': 'حسب الطالب', 'type': 'per_student', 'durationMonths': 12, 'pricingMethod': 'حسب كل طالب داخل المدرسة', 'pricePerStudent': 20, 'studentLimit': 0, 'annualPrice': 0, 'isActive': true},
  ];
  final batch = _db.batch();
  for (final item in defaults) {
    batch.set(_db.collection('billing_plans').doc(), {...item, 'createdAt': DateTime.now().toIso8601String()});
  }
  await batch.commit();
}

Future<void> applyPlan(String schoolId, DocumentSnapshot<Map<String, dynamic>> plan, double annualAmount, double paidAmount, {bool forceActive = false}) async {
  final p = plan.data() ?? {};
  final isTrial = !forceActive && p['type'] == 'trial';
  final perStudent = p['type'] == 'per_student';
  final now = DateTime.now();
  final months = intFrom(p['durationMonths'], isTrial ? 1 : 12);
  final studentsCount = perStudent ? await getStudentsCount(schoolId) : 0;
  final price = n(p['pricePerStudent']) == 0 ? 20 : n(p['pricePerStudent']);
  final annual = isTrial ? 0.0 : perStudent ? studentsCount * price : annualAmount;
  final paid = isTrial ? 0.0 : paidAmount;
  await _db.collection('schools').doc(schoolId).update({
    'status': isTrial ? 'trial' : 'active',
    if (perStudent) 'studentsCount': studentsCount,
    'subscription': {
      'planId': plan.id,
      'planName': p['name'] ?? '',
      'planType': p['type'] ?? '',
      'pricingMethod': p['pricingMethod'] ?? '',
      'studentLimit': intFrom(p['studentLimit']),
      'pricePerStudent': price,
      'startDate': now.toIso8601String(),
      'endDate': DateTime(now.year, now.month + months, now.day).toIso8601String(),
      'annualAmount': annual,
      'paidAmount': paid,
      'remainingAmount': positive(annual - paid),
      'status': isTrial ? 'trial' : 'active',
    }
  });
}
