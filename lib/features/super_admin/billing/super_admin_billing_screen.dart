import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/firebase_config.dart';

FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: FirebaseConfig.firestoreDatabaseId,
    );

const _blue = Color(0xFF2457D6);
const _navy = Color(0xFF123A73);
const _softBlue = Color(0xFFEFF3FF);
const _panel = Color(0xFFF8F8FC);
const _muted = Color(0xFF6B7280);
const _danger = Color(0xFFB42318);
const _success = Color(0xFF16833A);
const _warning = Color(0xFFB54708);
const _line = Color(0xFFE5E7EB);

class SuperAdminBillingScreen extends StatefulWidget {
  const SuperAdminBillingScreen({super.key});

  @override
  State<SuperAdminBillingScreen> createState() => _SuperAdminBillingScreenState();
}

class _SuperAdminBillingScreenState extends State<SuperAdminBillingScreen> {
  int tab = 0;
  final tabs = const [
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
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('schools').snapshots(),
            builder: (context, snapshot) {
              final schools = snapshot.data?.docs ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(title: 'الاشتراكات والفوترة', onBack: () => Navigator.pop(context)),
                  const SizedBox(height: 12),
                  const Text(
                    'إدارة اشتراكات المدارس، الخطط، الدفعات، التجارب، وتنبيهات الفوترة.',
                    style: TextStyle(color: _muted, fontWeight: FontWeight.w700, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  _Tabs(tabs: tabs, selected: tab, onChanged: (i) => setState(() => tab = i)),
                  const SizedBox(height: 16),
                  if (tab == 0) _SummaryTab(schools: schools),
                  if (tab == 1) _AddSubscriptionTab(schools: schools),
                  if (tab == 2) _SubscriptionsTab(schools: schools),
                  if (tab == 3) _TrialsTab(schools: schools),
                  if (tab == 4) const _PlansTab(),
                  if (tab == 5) _AlertsTab(schools: schools),
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
  final String title;
  final VoidCallback onBack;
  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Positioned(right: 0, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 30))),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.tabs, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
            side: BorderSide(color: active ? _blue : _line),
            labelStyle: TextStyle(color: active ? _blue : const Color(0xFF4B5563), fontWeight: FontWeight.w800),
          );
        },
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _SummaryTab({required this.schools});

  @override
  Widget build(BuildContext context) {
    double annual = 0;
    double paid = 0;
    double remaining = 0;
    int unpaidStudents = 0;
    for (final doc in schools) {
      final data = doc.data();
      if (isPerStudent(data)) {
        final stats = perStudentStats(data, intFrom(data['studentsCount']));
        annual += stats.total;
        paid += stats.paidAmount;
        remaining += stats.remaining;
        unpaidStudents += stats.unpaidStudents;
      } else {
        final s = sub(data);
        annual += n(s['annualAmount']);
        paid += n(s['paidAmount']);
        remaining += n(s['remainingAmount']);
      }
    }
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.12,
          children: [
            _Metric('المدارس النشطة', '${schools.where((s) => s.data()['status'] == 'active').length}', Icons.verified_outlined),
            _Metric('الموقوفة', '${schools.where((s) => s.data()['status'] == 'paused').length}', Icons.pause_circle_outline),
            _Metric('المدارس التجريبية', '${schools.where((s) => s.data()['status'] == 'trial').length}', Icons.hourglass_top_rounded),
            _Metric('تنتهي خلال 30 يوم', '${schools.where((s) => s.data()['status'] == 'active' && daysLeft(s.data()) > 0 && daysLeft(s.data()) <= 30).length}', Icons.event_busy_outlined),
            _Metric('الإيرادات السنوية', '${money(annual)} د.أ', Icons.calendar_month_outlined),
            _Metric('إجمالي المدفوع', '${money(paid)} د.أ', Icons.payments_outlined),
            _Metric('إجمالي المتبقي', '${money(remaining)} د.أ', Icons.account_balance_wallet_outlined),
            _Metric('طلاب غير مدفوعين', '$unpaidStudents', Icons.person_off_outlined),
          ],
        ),
        const SizedBox(height: 14),
        card(const Text('قاعدة خطة حسب الطالب: كل طالب داخل المدرسة محسوب ماليًا بسعر الطالب المحدد في الخطة، ولا يوجد معفى أو غير مشترك.', style: TextStyle(fontWeight: FontWeight.w800, height: 1.5))),
      ],
    );
  }
}

class _AddSubscriptionTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _AddSubscriptionTab({required this.schools});

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
    final inactive = widget.schools.where((s) => !['active', 'trial', 'paused'].contains(s.data()['status'])).toList();
    if (inactive.isEmpty) return const _Empty('لا توجد مدارس غير مفعلة. المدرسة الموقوفة لا يتم إنشاء اشتراك جديد لها، فقط استئناف.');
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        final plans = snapshot.data?.docs ?? [];
        if (plans.isEmpty) return const _Empty('لا توجد خطط مفعلة. أضف أو فعّل خطة أولاً');
        final type = plan?.data()?['type'];
        final isTrial = type == 'trial';
        final isPerStudentPlan = type == 'per_student';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إضافة اشتراك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _PickerField(
              'المدرسة',
              school == null ? 'اختر المدرسة' : '${school!.data()['name'] ?? ''} - ${school!.data()['code'] ?? ''}',
              () => pick<QueryDocumentSnapshot<Map<String, dynamic>>>(context, 'اختر المدرسة', inactive, (s) => '${s.data()['name'] ?? ''} - ${s.data()['code'] ?? ''}', school, (v) => setState(() => school = v)),
            ),
            _PickerField(
              'الخطة',
              plan?.data()?['name']?.toString() ?? 'اختر الخطة',
              () => pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة', plans, planLabel, plan, (v) {
                final p = v.data() ?? {};
                final amount = n(p['annualPrice']);
                setState(() {
                  plan = v;
                  annual.text = p['type'] == 'trial' || p['type'] == 'per_student' ? '0' : (amount == 0 ? '' : money(amount));
                  paid.text = '0';
                });
              }),
            ),
            if (plan != null) _PlanPreview(plan!.data() ?? {}),
            if (isPerStudentPlan) card(const Text('خطة حسب الطالب: السعر السنوي يحسب تلقائيًا من عدد الطلاب × سعر الطالب. أدخل المدفوع فقط إن وجد.', style: TextStyle(fontWeight: FontWeight.w800, height: 1.4))),
            _TextFieldBox('المبلغ السنوي', annual, enabled: !isTrial && !isPerStudentPlan, keyboardType: TextInputType.number),
            _TextFieldBox('المدفوع', paid, enabled: !isTrial, keyboardType: TextInputType.number),
            SizedBox(height: 52, child: FilledButton(onPressed: saving || school == null || plan == null ? null : save, child: saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('حفظ الاشتراك'))),
          ],
        );
      },
    );
  }

  Future<void> save() async {
    if (school == null || plan == null) return;
    setState(() => saving = true);
    try {
      await applyPlan(school!.id, plan!, toDouble(annual.text), toDouble(paid.text));
      if (mounted) snack(context, 'تم حفظ الاشتراك');
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
  const _SubscriptionsTab({required this.schools});

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
    final subscribed = widget.schools.where((s) => ['active', 'paused'].contains(s.data()['status'])).toList();
    final counts = {
      'all': subscribed.length,
      'active': subscribed.where((s) => s.data()['status'] == 'active').length,
      'paused': subscribed.where((s) => s.data()['status'] == 'paused').length,
      'due': subscribed.where((s) => subscriptionState(s.data()) == 'due').length,
      'bundle': subscribed.where((s) => !isPerStudent(s.data())).length,
      'per_student': subscribed.where((s) => isPerStudent(s.data())).length,
    };
    final q = search.text.trim().toLowerCase();
    final visible = subscribed.where((s) {
      final data = s.data();
      final name = '${data['name'] ?? ''}'.toLowerCase();
      final code = '${data['code'] ?? ''}'.toLowerCase();
      final status = data['status'] == 'paused' ? 'paused' : subscriptionState(data);
      final typeOk = filter == 'all' || status == filter || (filter == 'bundle' && !isPerStudent(data)) || (filter == 'per_student' && isPerStudent(data));
      return (q.isEmpty || name.contains(q) || code.contains(q)) && typeOk;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.receipt_long_outlined, color: _blue)),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('اشتراكات المدارس', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(height: 3),
            Text('عرض مختصر للمدارس. التفاصيل الكاملة داخل صفحة عرض.', style: TextStyle(color: _muted, fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 14),
        _SearchBox(search, (_) => setState(() {}), hint: 'ابحث باسم المدرسة أو رمزها...'),
        const SizedBox(height: 10),
        _SmallFilter(filter, {
          'all': 'الكل ${counts['all']}',
          'active': 'نشط ${counts['active']}',
          'paused': 'متوقف ${counts['paused']}',
          'due': 'متأخر ${counts['due']}',
          'bundle': 'شاملة ${counts['bundle']}',
          'per_student': 'حسب الطالب ${counts['per_student']}',
        }, (v) => setState(() => filter = v)),
        const SizedBox(height: 12),
        if (visible.isEmpty) const _Empty('لا توجد اشتراكات مطابقة') else ...visible.map((s) => _SimpleSubscriptionCard(doc: s)),
      ],
    );
  }
}

class _SimpleSubscriptionCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _SimpleSubscriptionCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final color = subscriptionColor(data);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [_navy, _blue.withOpacity(.85)]), borderRadius: BorderRadius.circular(18)),
              child: Icon(isPerStudent(data) ? Icons.groups_outlined : Icons.school_outlined, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${data['name'] ?? 'مدرسة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('رمز المدرسة: ${data['code'] ?? '—'}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w800)),
            ])),
            _Badge(subscriptionLabel(data), color),
          ]),
          const SizedBox(height: 14),
          SizedBox(height: 46, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailsPage(schoolId: doc.id))), icon: const Icon(Icons.visibility_outlined), label: const Text('عرض'))),
        ],
      ),
    );
  }
}

class SubscriptionDetailsPage extends StatefulWidget {
  final String schoolId;
  const SubscriptionDetailsPage({super.key, required this.schoolId});

  @override
  State<SubscriptionDetailsPage> createState() => _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> with SingleTickerProviderStateMixin {
  late final TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.collection('schools').doc(widget.schoolId).snapshots(),
            builder: (context, schoolSnap) {
              final data = schoolSnap.data?.data();
              if (data == null) return const Center(child: CircularProgressIndicator());
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.collection('schools').doc(widget.schoolId).collection('students').snapshots(),
                builder: (context, studentSnap) {
                  final students = studentSnap.data?.docs ?? [];
                  final count = students.isNotEmpty ? students.length : intFrom(data['studentsCount']);
                  return Column(
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _Header(title: 'تفاصيل الاشتراك', onBack: () => Navigator.pop(context))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _DetailsHero(data: data, studentsCount: count)),
                      const SizedBox(height: 10),
                      Container(
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
                        child: TabBar(
                          controller: controller,
                          indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12)]),
                          labelColor: _blue,
                          unselectedLabelColor: _muted,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          tabs: const [Tab(text: 'تفاصيل الاشتراك'), Tab(text: 'الطلاب'), Tab(text: 'الإعدادات')],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: controller,
                          children: [
                            _SubscriptionDashboardTab(data: data, students: students),
                            _SubscriptionStudentsTab(data: data, students: students),
                            _SubscriptionSettingsTab(schoolId: widget.schoolId, data: data, students: students),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailsHero extends StatelessWidget {
  final Map<String, dynamic> data;
  final int studentsCount;
  const _DetailsHero({required this.data, required this.studentsCount});

  @override
  Widget build(BuildContext context) {
    final s = sub(data);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, _blue]), borderRadius: BorderRadius.circular(26)),
      child: Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(18)), child: Icon(isPerStudent(data) ? Icons.groups_outlined : Icons.all_inclusive_rounded, color: Colors.white, size: 30)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${data['name'] ?? 'مدرسة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('رمز: ${data['code'] ?? '—'} • ${s['planName'] ?? 'اشتراك'} • $studentsCount طالب', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
        ])),
        _Badge(subscriptionLabel(data), Colors.white),
      ]),
    );
  }
}

class _SubscriptionDashboardTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  const _SubscriptionDashboardTab({required this.data, required this.students});

  @override
  Widget build(BuildContext context) {
    final s = sub(data);
    final count = students.isNotEmpty ? students.length : intFrom(data['studentsCount']);
    final per = isPerStudent(data);
    final stats = per ? perStudentStats(data, count) : null;
    final annual = per ? stats!.total : n(s['annualAmount']);
    final paid = per ? stats!.paidAmount : n(s['paidAmount']);
    final remaining = per ? stats!.remaining : n(s['remainingAmount']);
    final price = perStudentPrice(data);
    final paidStudents = per ? stats!.paidStudents : count;
    final unpaidStudents = per ? stats!.unpaidStudents : 0;
    final progress = annual <= 0 ? 0.0 : (paid / annual).clamp(0.0, 1.0).toDouble();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.24,
          children: [
            _Metric('نوع الخطة', per ? 'حسب الطالب' : 'شاملة', Icons.category_outlined),
            _Metric('الخطة', '${s['planName'] ?? '—'}', Icons.workspace_premium_outlined),
            _Metric('تاريخ البدء', date(s['startDate']), Icons.event_available_outlined),
            _Metric('تاريخ النهاية', date(s['endDate']), Icons.event_busy_outlined),
            _Metric('عدد الطلاب', '$count', Icons.groups_outlined),
            _Metric('سعر الطالب', per ? '${money(price)} د.أ' : '${money(n(s['pricePerStudent']))} د.أ', Icons.sell_outlined),
            _Metric('المستحق', '${money(annual)} د.أ', Icons.receipt_long_outlined),
            _Metric('مدفوعين', '$paidStudents', Icons.verified_user_outlined),
            _Metric('غير المدفوعين', '$unpaidStudents', Icons.person_off_outlined),
            _Metric('المتبقي', '${money(remaining)} د.أ', Icons.account_balance_wallet_outlined),
          ],
        ),
        const SizedBox(height: 12),
        card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _ProgressBlock(title: 'نسبة التحصيل', value: progress, text: '${(progress * 100).toStringAsFixed(0)}%'),
          const SizedBox(height: 12),
          Text(per ? 'الحسبة: عدد الطلاب × سعر الطالب، والمدفوعين = المدفوع ÷ سعر الطالب.' : 'الخطة الشاملة لا تعتمد على دفع كل طالب منفردًا، وتظهر حالة الطلاب ضمن الخطة.', style: const TextStyle(color: _muted, fontWeight: FontWeight.w800, height: 1.4)),
        ])),
      ],
    );
  }
}

class _SubscriptionStudentsTab extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  const _SubscriptionStudentsTab({required this.data, required this.students});

  @override
  State<_SubscriptionStudentsTab> createState() => _SubscriptionStudentsTabState();
}

class _SubscriptionStudentsTabState extends State<_SubscriptionStudentsTab> {
  String filter = 'all';
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final per = isPerStudent(widget.data);
    final stats = per ? perStudentStats(widget.data, widget.students.length) : null;
    final q = search.text.trim().toLowerCase();
    final rows = <_StudentRow>[];
    for (var i = 0; i < widget.students.length; i++) {
      final st = widget.students[i].data();
      final paid = per ? i < stats!.paidStudents : true;
      final row = _StudentRow(name: studentName(st), grade: studentGrade(st), section: studentSection(st), paid: paid);
      final okSearch = q.isEmpty || row.name.toLowerCase().contains(q) || row.grade.toLowerCase().contains(q) || row.section.toLowerCase().contains(q);
      final okFilter = filter == 'all' || (filter == 'paid' && paid) || (filter == 'unpaid' && !paid);
      if (okSearch && okFilter) rows.add(row);
    }
    rows.sort((a, b) => a.paid == b.paid ? a.name.compareTo(b.name) : a.paid ? 1 : -1);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SearchBox(search, (_) => setState(() {}), hint: 'ابحث باسم الطالب أو الصف أو الشعبة...'),
        const SizedBox(height: 10),
        _SmallFilter(filter, {'all': 'الكل ${widget.students.length}', 'unpaid': 'غير مدفوع ${rows.where((r) => !r.paid).length}', 'paid': 'مدفوع ${rows.where((r) => r.paid).length}'}, (v) => setState(() => filter = v)),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const _Empty('لا توجد بيانات طلاب مطابقة')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, color: _muted),
              dataTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
              columns: const [DataColumn(label: Text('الطالب')), DataColumn(label: Text('الصف')), DataColumn(label: Text('الشعبة')), DataColumn(label: Text('الحالة'))],
              rows: rows.map((r) => DataRow(cells: [DataCell(Text(r.name)), DataCell(Text(r.grade)), DataCell(Text(r.section)), DataCell(_Badge(r.paid ? 'مدفوع' : 'غير مدفوع', r.paid ? _success : _danger))])).toList(),
            ),
          ),
      ],
    );
  }
}

class _StudentRow {
  final String name;
  final String grade;
  final String section;
  final bool paid;
  const _StudentRow({required this.name, required this.grade, required this.section, required this.paid});
}

class _SubscriptionSettingsTab extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic> data;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  const _SubscriptionSettingsTab({required this.schoolId, required this.data, required this.students});

  @override
  State<_SubscriptionSettingsTab> createState() => _SubscriptionSettingsTabState();
}

class _SubscriptionSettingsTabState extends State<_SubscriptionSettingsTab> {
  final months = TextEditingController();
  DocumentSnapshot<Map<String, dynamic>>? selectedPlan;
  double planDifference = 0;
  bool saving = false;

  @override
  void dispose() {
    months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paused = widget.data['status'] == 'paused';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsBlock(title: 'تجديد الاشتراك', icon: Icons.refresh_rounded, children: [
          _TextFieldBox('مدة التجديد بالأشهر', months, keyboardType: TextInputType.number),
          SizedBox(height: 50, child: FilledButton.icon(onPressed: saving ? null : renew, icon: const Icon(Icons.refresh_rounded), label: const Text('تجديد الاشتراك'))),
        ]),
        _SettingsBlock(title: 'تغيير الخطة', icon: Icons.swap_horiz_rounded, children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('billing_plans').where('isActive', isEqualTo: true).snapshots(),
            builder: (context, snapshot) {
              final plans = (snapshot.data?.docs ?? []).where((p) => p.data()['type'] != 'trial').toList();
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _PickerField('الخطة الجديدة', selectedPlan == null ? 'اختر الخطة الجديدة' : '${selectedPlan!.data()?['name'] ?? ''}', () {
                  pick<DocumentSnapshot<Map<String, dynamic>>>(context, 'اختر الخطة الجديدة', plans, planLabel, selectedPlan, (v) => setState(() {
                        selectedPlan = v;
                        planDifference = calculatePlanDifference(widget.data, v.data() ?? {}, widget.students.length);
                      }));
                }),
                if (selectedPlan != null) card(Text(planDifference >= 0 ? 'فرق الترقية المطلوب: ${money(planDifference)} د.أ' : 'رصيد لصالح المدرسة: ${money(planDifference.abs())} د.أ', style: TextStyle(color: planDifference >= 0 ? _warning : _success, fontWeight: FontWeight.w900))),
                SizedBox(height: 50, child: OutlinedButton.icon(onPressed: selectedPlan == null || saving ? null : changePlan, icon: const Icon(Icons.swap_horiz_rounded), label: const Text('تطبيق تغيير الخطة'))),
              ]);
            },
          ),
        ]),
        _SettingsBlock(title: 'تصدير تقرير الطلاب', icon: Icons.file_download_outlined, children: [
          const Text('يتم ترتيب التقرير بحيث يظهر غير المدفوعين أولًا ثم المدفوعين.', style: TextStyle(color: _muted, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(height: 50, child: OutlinedButton.icon(onPressed: exportReport, icon: const Icon(Icons.file_download_outlined), label: const Text('تصدير / نسخ التقرير'))),
        ]),
        _SettingsBlock(title: paused ? 'استئناف الاشتراك' : 'إيقاف الاشتراك', icon: paused ? Icons.play_circle_outline : Icons.pause_circle_outline, danger: !paused, children: [
          Text(paused ? 'الاشتراك متوقف حاليًا. يمكن استئنافه بدون إنشاء اشتراك جديد.' : 'عند الإيقاف لا يمكن إنشاء اشتراك جديد للمدرسة، فقط استئناف الاشتراك الحالي.', style: const TextStyle(color: _muted, fontWeight: FontWeight.w800, height: 1.4)),
          const SizedBox(height: 10),
          SizedBox(height: 50, child: OutlinedButton.icon(onPressed: saving ? null : (paused ? resumeSubscription : pauseSubscription), icon: Icon(paused ? Icons.play_circle_outline : Icons.pause_circle_outline), label: Text(paused ? 'استئناف الاشتراك' : 'إيقاف الاشتراك'), style: OutlinedButton.styleFrom(foregroundColor: paused ? _success : _danger))),
        ]),
      ],
    );
  }

  Future<void> renew() async {
    final m = int.tryParse(months.text.trim()) ?? 0;
    if (m <= 0) return snack(context, 'أدخل مدة صحيحة بالأشهر');
    setState(() => saving = true);
    try {
      final oldSub = Map<String, dynamic>.from(sub(widget.data));
      final oldEnd = DateTime.tryParse('${oldSub['endDate'] ?? ''}') ?? DateTime.now();
      final startFrom = oldEnd.isAfter(DateTime.now()) ? oldEnd : DateTime.now();
      final newEnd = DateTime(startFrom.year, startFrom.month + m, startFrom.day);
      oldSub['endDate'] = newEnd.toIso8601String();
      oldSub['durationMonths'] = intFrom(oldSub['durationMonths'], 12) + m;
      await _db.collection('schools').doc(widget.schoolId).update({'subscription': oldSub, 'status': 'active'});
      await addBillingLog(widget.schoolId, 'تجديد الاشتراك', 'تم تجديد الاشتراك لمدة $m شهر من ${date(startFrom.toIso8601String())} إلى ${date(newEnd.toIso8601String())}');
      if (mounted) snack(context, 'تم تجديد الاشتراك');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> changePlan() async {
    if (selectedPlan == null) return;
    setState(() => saving = true);
    try {
      final p = selectedPlan!.data() ?? {};
      final oldSub = Map<String, dynamic>.from(sub(widget.data));
      final count = widget.students.length;
      final price = n(p['pricePerStudent']) == 0 ? 20 : n(p['pricePerStudent']);
      final annual = p['type'] == 'per_student' ? count * price : n(p['annualPrice']);
      oldSub['planId'] = selectedPlan!.id;
      oldSub['planName'] = p['name'] ?? '';
      oldSub['planType'] = p['type'] ?? '';
      oldSub['pricingMethod'] = p['pricingMethod'] ?? '';
      oldSub['studentLimit'] = intFrom(p['studentLimit']);
      oldSub['pricePerStudent'] = price;
      oldSub['annualAmount'] = annual;
      oldSub['remainingAmount'] = positive(annual - n(oldSub['paidAmount']));
      await _db.collection('schools').doc(widget.schoolId).update({'subscription': oldSub, 'status': 'active', 'studentsCount': count});
      await addBillingLog(widget.schoolId, 'تغيير الخطة', 'تم تغيير الخطة إلى ${p['name'] ?? ''}. فرق الخطة: ${money(planDifference)} د.أ');
      if (mounted) snack(context, 'تم تغيير الخطة');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> exportReport() async {
    final per = isPerStudent(widget.data);
    final stats = per ? perStudentStats(widget.data, widget.students.length) : null;
    final rows = <_StudentRow>[];
    for (var i = 0; i < widget.students.length; i++) {
      final st = widget.students[i].data();
      rows.add(_StudentRow(name: studentName(st), grade: studentGrade(st), section: studentSection(st), paid: per ? i < stats!.paidStudents : true));
    }
    rows.sort((a, b) => a.paid == b.paid ? a.name.compareTo(b.name) : a.paid ? 1 : -1);
    final buffer = StringBuffer('الاسم,الصف,الشعبة,الحالة\n');
    for (final r in rows) {
      buffer.writeln('${r.name},${r.grade},${r.section},${r.paid ? 'مدفوع' : 'غير مدفوع'}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) snack(context, 'تم نسخ تقرير الطلاب. غير المدفوعين بالأعلى.');
  }

  Future<void> pauseSubscription() async {
    setState(() => saving = true);
    try {
      await _db.collection('schools').doc(widget.schoolId).update({'status': 'paused', 'subscription.status': 'paused'});
      await addBillingLog(widget.schoolId, 'إيقاف الاشتراك', 'تم إيقاف الاشتراك ولا يمكن إنشاء اشتراك جديد، فقط الاستئناف.');
      if (mounted) snack(context, 'تم إيقاف الاشتراك');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> resumeSubscription() async {
    setState(() => saving = true);
    try {
      await _db.collection('schools').doc(widget.schoolId).update({'status': 'active', 'subscription.status': 'active'});
      await addBillingLog(widget.schoolId, 'استئناف الاشتراك', 'تم استئناف الاشتراك الحالي.');
      if (mounted) snack(context, 'تم استئناف الاشتراك');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _SettingsBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool danger;
  final List<Widget> children;
  const _SettingsBlock({required this.title, required this.icon, required this.children, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Icon(icon, color: danger ? _danger : _blue), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: danger ? _danger : Colors.black))]),
      const SizedBox(height: 12),
      ...children,
    ]));
  }
}

class _TrialsTab extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _TrialsTab({required this.schools});

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
    final docs = widget.schools.where((s) => s.data()['status'] == 'trial').toList();
    final q = search.text.trim().toLowerCase();
    final visible = docs.where((doc) {
      final data = doc.data();
      final name = '${data['name'] ?? ''}'.toLowerCase();
      final code = '${data['code'] ?? ''}'.toLowerCase();
      return (q.isEmpty || name.contains(q) || code.contains(q)) && (filter == 'all' || trialState(data) == filter);
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('التجارب المجانية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _SearchBox(search, (_) => setState(() {}), hint: 'ابحث باسم المدرسة أو رمزها...'),
        const SizedBox(height: 10),
        _SmallFilter(filter, {
          'all': 'الكل ${docs.length}',
          'active': 'فعال ${docs.where((x) => trialState(x.data()) == 'active').length}',
          'ending': 'قريب الانتهاء ${docs.where((x) => trialState(x.data()) == 'ending').length}',
          'expired': 'منتهي ${docs.where((x) => trialState(x.data()) == 'expired').length}',
        }, (v) => setState(() => filter = v)),
        const SizedBox(height: 12),
        if (docs.isEmpty) const _Empty('لا توجد مدارس في التجربة المجانية') else if (visible.isEmpty) const _Empty('لا توجد نتائج مطابقة') else ...visible.map((doc) => _TrialCard(doc: doc)),
      ],
    );
  }
}

class _TrialCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _TrialCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final s = sub(data);
    final left = daysLeft(data);
    return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_outlined, color: _blue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${data['name'] ?? 'مدرسة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text('رمز: ${data['code'] ?? ''}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))])),
        _Badge(trialLabel(data), trialColor(data)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [_Chip('بداية: ${date(s['startDate'])}'), _Chip('نهاية: ${date(s['endDate'])}'), _Chip('الأيام: ${left < 0 ? 0 : left}')]),
    ]));
  }
}

class _PlansTab extends StatelessWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('billing_plans').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const Expanded(child: Text('الخطط والأسعار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), IconButton(onPressed: () => openPlanForm(context), icon: const Icon(Icons.add_circle, color: _blue, size: 32))]),
          if (docs.isEmpty) Column(children: [const _Empty('لا توجد خطط بعد'), SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () => seedPlans(context), child: const Text('إنشاء الخطط الافتراضية')))]) else ...docs.map((doc) => _PlanCard(doc: doc)),
        ]);
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const _PlanCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() ?? {};
    final active = data['isActive'] != false;
    return card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('${data['name'] ?? 'خطة'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), _Badge(active ? 'مفعلة' : 'معطلة', active ? _success : _danger)]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [_Chip('النوع: ${typeName('${data['type'] ?? ''}')}'), _Chip('المدة: ${data['durationMonths'] ?? 0} شهر'), _Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}'), _Chip('الحد: ${data['studentLimit'] ?? 0}'), _Chip('سنويًا: ${data['type'] == 'per_student' ? 'تلقائي' : data['annualPrice'] ?? 0}')]),
      Row(children: [Expanded(child: OutlinedButton(onPressed: () => openPlanForm(context, doc: doc), child: const Text('تعديل'))), const SizedBox(width: 8), Expanded(child: OutlinedButton(onPressed: () => doc.reference.delete(), child: const Text('حذف')))]),
    ]));
  }
}

class _AlertsTab extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> schools;
  const _AlertsTab({required this.schools});

  @override
  Widget build(BuildContext context) {
    final alerts = <Widget>[];
    for (final doc in schools) {
      final data = doc.data();
      final name = '${data['name'] ?? 'مدرسة'}';
      final left = daysLeft(data);
      if (data['status'] == 'active' && left > 0 && left <= 30) alerts.add(_Alert('اشتراك ينتهي قريبًا', '$name ينتهي بعد $left يوم', Icons.event_busy_outlined, _blue));
      if (data['status'] == 'paused') alerts.add(_Alert('اشتراك متوقف', '$name اشتراكها متوقف ويمكن استئنافه فقط', Icons.pause_circle_outline, _warning));
      if (data['status'] == 'trial' && left > 0 && left <= 7) alerts.add(_Alert('تجربة تنتهي قريبًا', '$name تنتهي تجربتها بعد $left يوم', Icons.hourglass_bottom_rounded, _warning));
      if (isPerStudent(data)) {
        final stats = perStudentStats(data, intFrom(data['studentsCount']));
        if (stats.unpaidStudents > 0) alerts.add(_Alert('طلاب غير مدفوعين', '$name لديها ${stats.unpaidStudents} طالب غير مدفوع', Icons.person_off_outlined, _danger));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('تنبيهات الفوترة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), if (alerts.isEmpty) const _Empty('لا توجد تنبيهات حالياً') else ...alerts]);
  }
}

class _Alert extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  const _Alert(this.title, this.message, this.icon, this.color);

  @override
  Widget build(BuildContext context) => card(Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(message, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))]))]));
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
  Widget build(BuildContext context) {
    return Directionality(
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
  }

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

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _Metric(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: _blue),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        Text(title, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final String title;
  final double value;
  final String text;
  const _ProgressBlock({required this.title, required this.value, required this.text});

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(color: _muted, fontWeight: FontWeight.w800))),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: safeValue, minHeight: 8, backgroundColor: _line, color: _blue),
      ),
    ]);
  }
}

class _SmallFilter extends StatelessWidget {
  final String selected;
  final Map<String, String> items;
  final ValueChanged<String> onSelect;
  const _SmallFilter(this.selected, this.items, this.onSelect);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: items.entries.map((e) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(selected: selected == e.key, showCheckmark: false, label: Text(e.value), onSelected: (_) => onSelect(e.key), selectedColor: _softBlue),
          )).toList(),
        ),
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
  Widget build(BuildContext context) => card(Wrap(spacing: 8, runSpacing: 8, children: [_Chip('المدة: ${data['durationMonths'] ?? 0} شهر'), _Chip('الحد: ${data['studentLimit'] ?? 0}'), _Chip('سعر الطالب: ${data['pricePerStudent'] ?? 0}')]));
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color == Colors.white ? Colors.white.withOpacity(.16) : color.withOpacity(.1), borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(color: color == Colors.white ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.w900)),
      );
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
double positive(double value) => value < 0 ? 0 : value;
String money(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
String typeName(String v) => v == 'trial' ? 'تجربة مجانية' : v == 'bundle' ? 'شاملة' : v == 'custom_bundle' ? 'شاملة مخصصة' : v == 'per_student' ? 'حسب الطالب' : v;
String planLabel(DocumentSnapshot<Map<String, dynamic>> doc) => '${doc.data()?['name'] ?? 'خطة'} - ${doc.data()?['type'] == 'per_student' ? '${doc.data()?['pricePerStudent'] ?? 20} د.أ/طالب' : '${doc.data()?['annualPrice'] ?? 0} د.أ'}';
String trialState(Map<String, dynamic> data) => daysLeft(data) <= 0 ? 'expired' : daysLeft(data) <= 7 ? 'ending' : 'active';
String trialLabel(Map<String, dynamic> data) => trialState(data) == 'expired' ? 'منتهي' : trialState(data) == 'ending' ? 'قريب الانتهاء' : 'فعال';
Color trialColor(Map<String, dynamic> data) => trialState(data) == 'expired' ? _danger : trialState(data) == 'ending' ? _warning : _success;
String subscriptionState(Map<String, dynamic> data) => data['status'] == 'paused' ? 'paused' : daysLeft(data) <= 0 ? 'expired' : (isPerStudent(data) ? perStudentStats(data, intFrom(data['studentsCount'])).remaining > 0 : n(sub(data)['remainingAmount']) > 0) ? 'due' : 'active';
String subscriptionLabel(Map<String, dynamic> data) => subscriptionState(data) == 'paused' ? 'متوقف' : subscriptionState(data) == 'expired' ? 'منتهي' : subscriptionState(data) == 'due' ? 'متأخر بالدفع' : 'نشط';
Color subscriptionColor(Map<String, dynamic> data) => subscriptionState(data) == 'active' ? _success : subscriptionState(data) == 'paused' || subscriptionState(data) == 'due' ? _warning : _danger;
String studentName(Map<String, dynamic> s) => '${s['name'] ?? s['fullName'] ?? s['studentName'] ?? 'طالب'}';
String studentGrade(Map<String, dynamic> s) => '${s['gradeName'] ?? s['grade'] ?? s['className'] ?? '—'}';
String studentSection(Map<String, dynamic> s) => '${s['sectionName'] ?? s['section'] ?? s['classSection'] ?? '—'}';
void snack(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
double calculatePlanDifference(Map<String, dynamic> oldData, Map<String, dynamic> newPlan, int studentsCount) {
  final oldAnnual = isPerStudent(oldData) ? perStudentStats(oldData, studentsCount).total : n(sub(oldData)['annualAmount']);
  final newPrice = n(newPlan['pricePerStudent']) == 0 ? 20 : n(newPlan['pricePerStudent']);
  final newAnnual = newPlan['type'] == 'per_student' ? studentsCount * newPrice : n(newPlan['annualPrice']);
  return newAnnual - oldAnnual;
}
Future<void> addBillingLog(String schoolId, String action, String details) async {
  await _db.collection('schools').doc(schoolId).collection('billing_logs').add({'action': action, 'details': details, 'createdAt': DateTime.now().toIso8601String(), 'user': 'Super Admin'});
}

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
              Expanded(
                child: ListView(children: items.map((item) {
                  final isSelected = item == selected;
                  return ListTile(
                    title: Text(label(item), textAlign: TextAlign.right),
                    leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? _blue : const Color(0xFF8E8E93)),
                    onTap: () {
                      onSelect(item);
                      Navigator.pop(context);
                    },
                  );
                }).toList()),
              ),
            ]),
          ),
        ),
      ),
    ),
  );
}

void openPlanForm(BuildContext context, {DocumentSnapshot<Map<String, dynamic>>? doc}) => showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _PlanForm(doc: doc));

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
      'durationMonths': months,
      'startDate': now.toIso8601String(),
      'endDate': DateTime(now.year, now.month + months, now.day).toIso8601String(),
      'annualAmount': annual,
      'paidAmount': paid,
      'remainingAmount': positive(annual - paid),
      'status': isTrial ? 'trial' : 'active',
    }
  });
  await addBillingLog(schoolId, 'إنشاء اشتراك', 'تم إنشاء اشتراك ${p['name'] ?? ''} من ${date(now.toIso8601String())} إلى ${date(DateTime(now.year, now.month + months, now.day).toIso8601String())}');
}
