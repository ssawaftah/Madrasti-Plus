import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/config/firebase_config.dart';
import 'billing/super_admin_billing_screen.dart';

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

class SuperAdminSchoolDetailsScreen extends StatefulWidget {
  final String schoolId;
  const SuperAdminSchoolDetailsScreen({super.key, required this.schoolId});

  @override
  State<SuperAdminSchoolDetailsScreen> createState() => _SuperAdminSchoolDetailsScreenState();
}

class _SuperAdminSchoolDetailsScreenState extends State<SuperAdminSchoolDetailsScreen> {
  int tab = 0;
  final tabs = const ['الملخص', 'الطلاب', 'المعلمين', 'أولياء الأمور', 'الإداريين', 'الاشتراك', 'الإعدادات', 'السجل'];

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
              final school = schoolSnap.data?.data();
              if (school == null) return const Center(child: CircularProgressIndicator());
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db.collection('schools').doc(widget.schoolId).collection('students').snapshots(),
                builder: (context, stSnap) {
                  final students = stSnap.data?.docs ?? [];
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db.collection('schools').doc(widget.schoolId).collection('teachers').snapshots(),
                    builder: (context, tSnap) {
                      final teachers = tSnap.data?.docs ?? [];
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        children: [
                          _Header(title: 'عرض المدرسة', onBack: () => Navigator.pop(context)),
                          const SizedBox(height: 12),
                          _Hero(schoolId: widget.schoolId, school: school, studentCount: students.length),
                          const SizedBox(height: 14),
                          _Tabs(tabs: tabs, selected: tab, onChanged: (i) => setState(() => tab = i)),
                          const SizedBox(height: 14),
                          if (tab == 0) _Summary(school: school, students: students, teachers: teachers),
                          if (tab == 1) _Students(school: school, students: students),
                          if (tab == 2) _Teachers(teachers: teachers),
                          if (tab == 3) _ParentsTab(schoolId: widget.schoolId, students: students),
                          if (tab == 4) _AdminsTab(schoolId: widget.schoolId),
                          if (tab == 5) _SubscriptionTab(schoolId: widget.schoolId, school: school),
                          if (tab == 6) _SchoolSettingsTab(schoolId: widget.schoolId, school: school),
                          if (tab == 7) _SchoolLogTab(schoolId: widget.schoolId),
                        ],
                      );
                    },
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

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: Row(children: [
          SizedBox(width: 48, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 30))),
          Expanded(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          const SizedBox(width: 48),
        ]),
      );
}

class _Hero extends StatelessWidget {
  final String schoolId;
  final Map<String, dynamic> school;
  final int studentCount;
  const _Hero({required this.schoolId, required this.school, required this.studentCount});

  @override
  Widget build(BuildContext context) {
    final s = sub(school);
    final status = statusText('${school['status'] ?? ''}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_navy, _blue]), borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.school_outlined, color: Colors.white, size: 32)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${school['name'] ?? 'مدرسة'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            Text('رمز المدرسة: ${school['code'] ?? '—'}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
          ])),
          _HeroBadge(status),
        ]),
        const SizedBox(height: 12),
        Text([school['governorate'], school['address']].where((e) => e != null && '$e'.trim().isNotEmpty).join(' - '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroInfo(Icons.workspace_premium_outlined, 'الخطة: ${s['planName'] ?? 'غير محددة'}'),
          _HeroInfo(Icons.groups_outlined, '$studentCount طالب'),
          _HeroInfo(Icons.event_busy_outlined, 'النهاية: ${date(s['endDate'])}'),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: 48, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailsPage(schoolId: schoolId))), icon: const Icon(Icons.receipt_long_outlined), label: const Text('فتح الاشتراك'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _blue, elevation: 0, textStyle: const TextStyle(fontWeight: FontWeight.w900))))
      ]),
    );
  }
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
          itemBuilder: (_, i) => ChoiceChip(
            selected: selected == i,
            showCheckmark: false,
            label: Text(tabs[i]),
            onSelected: (_) => onChanged(i),
            selectedColor: _softBlue,
            backgroundColor: _panel,
            side: BorderSide(color: selected == i ? _blue : _line),
            labelStyle: TextStyle(color: selected == i ? _blue : _muted, fontWeight: FontWeight.w900),
          ),
        ),
      );
}

class _Summary extends StatelessWidget {
  final Map<String, dynamic> school;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers;
  const _Summary({required this.school, required this.students, required this.teachers});

  @override
  Widget build(BuildContext context) {
    final s = sub(school);
    final grades = students.map((e) => grade(e.data())).where((e) => e != '—').toSet().length;
    final sections = students.map((e) => '${grade(e.data())}-${section(e.data())}').where((e) => !e.endsWith('-—')).toSet().length;
    final limit = intFrom(s['studentLimit']);
    final use = limit <= 0 ? 0.0 : (students.length / limit).clamp(0.0, 1.0).toDouble();
    final unpaid = isPerStudent(school) ? unpaidCount(school, students) : 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.15, children: [
        _Metric('عدد الطلاب', '${students.length}', Icons.groups_outlined),
        _Metric('عدد المعلمين', '${teachers.length}', Icons.person_outline),
        _Metric('عدد الصفوف', '$grades', Icons.layers_outlined),
        _Metric('عدد الشعب', '$sections', Icons.account_tree_outlined),
        _Metric('حالة الاشتراك', statusText('${school['status'] ?? ''}'), Icons.verified_outlined),
        _Metric('نهاية الاشتراك', date(s['endDate']), Icons.event_busy_outlined),
      ]),
      const SizedBox(height: 12),
      _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('نسبة استخدام الخطة ${limit <= 0 ? 'غير محددة' : '${(use * 100).toStringAsFixed(0)}%'}', style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: use, minHeight: 9, backgroundColor: _line, color: _blue)),
      ])),
      const Text('تنبيهات ذكية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      ...alerts(school, use, unpaid).map((x) => _Panel(child: Text(x, style: const TextStyle(fontWeight: FontWeight.w900)))),
      if (alerts(school, use, unpaid).isEmpty) const _Empty('لا توجد تنبيهات مهمة حاليًا'),
    ]);
  }
}

class _Students extends StatefulWidget {
  final Map<String, dynamic> school;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  const _Students({required this.school, required this.students});

  @override
  State<_Students> createState() => _StudentsState();
}

class _StudentsState extends State<_Students> {
  String? selectedGrade;
  String? selectedSection;
  String filter = 'all';
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grades = widget.students.map((e) => grade(e.data())).where((e) => e != '—').toSet().toList()..sort();
    final gradeStudents = selectedGrade == null ? widget.students : widget.students.where((s) => grade(s.data()) == selectedGrade).toList();
    final sections = gradeStudents.map((s) => section(s.data())).where((e) => e != '—').toSet().toList()..sort();
    final visible = gradeStudents.where((doc) {
      final d = doc.data();
      final paid = paidStudent(widget.school, widget.students, doc);
      final active = activeAccount(d);
      final q = search.text.trim().toLowerCase();
      return (selectedSection == null || section(d) == selectedSection) &&
          (q.isEmpty || name(d).toLowerCase().contains(q) || parent(d).toLowerCase().contains(q)) &&
          (filter == 'all' || (filter == 'paid' && paid) || (filter == 'unpaid' && !paid) || (filter == 'active' && active) || (filter == 'inactive' && !active));
    }).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .98, children: [
        _MiniMetric('الطلاب', '${widget.students.length}', Icons.groups_outlined),
        _MiniMetric('الصفوف', '${grades.length}', Icons.layers_outlined),
        _MiniMetric('الشعب', '${sections.length}', Icons.account_tree_outlined),
        _MiniMetric('غير مدفوع', '${unpaidCount(widget.school, widget.students)}', Icons.person_off_outlined),
        _MiniMetric('مدفوع', '${widget.students.length - unpaidCount(widget.school, widget.students)}', Icons.verified_user_outlined),
        _MiniMetric('الحالي', '${visible.length}', Icons.filter_alt_outlined),
      ]),
      const SizedBox(height: 12),
      TextField(controller: search, onChanged: (_) => setState(() {}), textAlign: TextAlign.right, decoration: InputDecoration(hintText: 'ابحث باسم الطالب أو ولي الأمر...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
      const SizedBox(height: 10),
      _Filter(selected: filter, items: const {'all': 'الكل', 'paid': 'مدفوع', 'unpaid': 'غير مدفوع', 'active': 'نشط', 'inactive': 'غير نشط'}, onChanged: (v) => setState(() => filter = v)),
      const SizedBox(height: 12),
      if (selectedGrade == null) ...grades.map((g) => _Nav(title: g, subtitle: '${widget.students.where((s) => grade(s.data()) == g).length} طالب', icon: Icons.layers_outlined, onTap: () => setState(() { selectedGrade = g; selectedSection = null; })))
      else if (selectedSection == null) ...[
        _Back(text: 'الصف: $selectedGrade', onTap: () => setState(() { selectedGrade = null; selectedSection = null; })),
        ...sections.map((s) => _Nav(title: 'شعبة $s', subtitle: '${gradeStudents.where((x) => section(x.data()) == s).length} طالب', icon: Icons.account_tree_outlined, onTap: () => setState(() => selectedSection = s)))
      ] else ...[
        _Back(text: '$selectedGrade / شعبة $selectedSection', onTap: () => setState(() => selectedSection = null)),
        if (visible.isEmpty) const _Empty('لا توجد بيانات طلاب مطابقة') else ...visible.map((s) => _StudentCard(school: widget.school, all: widget.students, doc: s)),
      ],
    ]);
  }
}

class _Teachers extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers;
  const _Teachers({required this.teachers});

  @override
  State<_Teachers> createState() => _TeachersState();
}

class _TeachersState extends State<_Teachers> {
  String? subject;

  @override
  Widget build(BuildContext context) {
    final subjects = widget.teachers.expand((t) => subjectsOf(t.data())).toSet().toList()..sort();
    final selected = subject == null ? <QueryDocumentSnapshot<Map<String, dynamic>>>[] : widget.teachers.where((t) => subjectsOf(t.data()).contains(subject)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .98, children: [
        _MiniMetric('المعلمين', '${widget.teachers.length}', Icons.person_outline),
        _MiniMetric('المواد', '${subjects.length}', Icons.menu_book_outlined),
        _MiniMetric('التكليفات', '${widget.teachers.expand((t) => classesOf(t.data())).toSet().length}', Icons.account_tree_outlined),
      ]),
      const SizedBox(height: 12),
      if (subject == null) ...subjects.map((s) => _Nav(title: s, subtitle: '${widget.teachers.where((t) => subjectsOf(t.data()).contains(s)).length} معلم', icon: Icons.menu_book_outlined, onTap: () => setState(() => subject = s)))
      else ...[_Back(text: 'المادة: $subject', onTap: () => setState(() => subject = null)), if (selected.isEmpty) const _Empty('لا يوجد معلمون لهذه المادة') else ...selected.map((t) => _TeacherCard(t.data()))],
    ]);
  }
}

class _ParentsTab extends StatefulWidget {
  final String schoolId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  const _ParentsTab({required this.schoolId, required this.students});

  @override
  State<_ParentsTab> createState() => _ParentsTabState();
}

class _ParentsTabState extends State<_ParentsTab> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').doc(widget.schoolId).collection('parents').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final q = search.text.trim().toLowerCase();
        final visible = docs.where((d) {
          final p = d.data();
          return q.isEmpty || personName(p).toLowerCase().contains(q) || personPhone(p).contains(q) || personEmail(p).toLowerCase().contains(q);
        }).toList();
        final linkedChildren = widget.students.where((s) => '${s.data()['parentId'] ?? s.data()['guardianId'] ?? ''}'.trim().isNotEmpty).length;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .98, children: [
            _MiniMetric('أولياء الأمور', '${docs.length}', Icons.family_restroom_outlined),
            _MiniMetric('طلاب مرتبطين', '$linkedChildren', Icons.link_outlined),
            _MiniMetric('غير مرتبط', '${widget.students.length - linkedChildren}', Icons.link_off_outlined),
          ]),
          const SizedBox(height: 12),
          TextField(controller: search, onChanged: (_) => setState(() {}), textAlign: TextAlign.right, decoration: InputDecoration(hintText: 'ابحث باسم ولي الأمر أو الهاتف أو البريد...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          if (docs.isEmpty) const _Empty('لا يوجد أولياء أمور مسجلون بعد') else if (visible.isEmpty) const _Empty('لا توجد نتائج مطابقة') else ...visible.map((doc) => _PersonCard(data: doc.data(), icon: Icons.family_restroom_outlined, type: 'ولي أمر')),
        ]);
      },
    );
  }
}

class _AdminsTab extends StatefulWidget {
  final String schoolId;
  const _AdminsTab({required this.schoolId});

  @override
  State<_AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends State<_AdminsTab> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').doc(widget.schoolId).collection('admins').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final q = search.text.trim().toLowerCase();
        final visible = docs.where((d) {
          final a = d.data();
          return q.isEmpty || personName(a).toLowerCase().contains(q) || personEmail(a).toLowerCase().contains(q) || adminRole(a).toLowerCase().contains(q);
        }).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .98, children: [
            _MiniMetric('الإداريين', '${docs.length}', Icons.admin_panel_settings_outlined),
            _MiniMetric('مدراء', '${docs.where((d) => adminRole(d.data()).contains('مدير') || adminRole(d.data()).toLowerCase().contains('admin')).length}', Icons.shield_outlined),
            _MiniMetric('الحالي', '${visible.length}', Icons.filter_alt_outlined),
          ]),
          const SizedBox(height: 12),
          TextField(controller: search, onChanged: (_) => setState(() {}), textAlign: TextAlign.right, decoration: InputDecoration(hintText: 'ابحث باسم الإداري أو البريد أو الدور...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: _panel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          if (docs.isEmpty) const _Empty('لا يوجد إداريون مسجلون بعد') else if (visible.isEmpty) const _Empty('لا توجد نتائج مطابقة') else ...visible.map((doc) => _PersonCard(data: doc.data(), icon: Icons.admin_panel_settings_outlined, type: adminRole(doc.data()))),
        ]);
      },
    );
  }
}

class _SubscriptionTab extends StatelessWidget {
  final String schoolId;
  final Map<String, dynamic> school;
  const _SubscriptionTab({required this.schoolId, required this.school});

  @override
  Widget build(BuildContext context) {
    final s = sub(school);
    return _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('ملخص الاشتراك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      _Line('الخطة', '${s['planName'] ?? 'غير محددة'}'),
      _Line('نوع الخطة', '${s['planType'] ?? 'غير محدد'}'),
      _Line('تاريخ النهاية', date(s['endDate'])),
      _Line('المتبقي', '${money(n(s['remainingAmount']))} د.أ'),
      const SizedBox(height: 12),
      SizedBox(height: 50, child: FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionDetailsPage(schoolId: schoolId))), icon: const Icon(Icons.receipt_long_outlined), label: const Text('إدارة الاشتراك'))),
    ]));
  }
}

class _SchoolSettingsTab extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic> school;
  const _SchoolSettingsTab({required this.schoolId, required this.school});

  @override
  State<_SchoolSettingsTab> createState() => _SchoolSettingsTabState();
}

class _SchoolSettingsTabState extends State<_SchoolSettingsTab> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController governorateController;
  late final TextEditingController addressController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: '${widget.school['name'] ?? ''}');
    phoneController = TextEditingController(text: '${widget.school['phone'] ?? widget.school['schoolPhone'] ?? ''}');
    governorateController = TextEditingController(text: '${widget.school['governorate'] ?? ''}');
    addressController = TextEditingController(text: '${widget.school['address'] ?? ''}');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    governorateController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = '${widget.school['status'] ?? 'inactive'}';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('بيانات المدرسة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        _Input('اسم المدرسة', nameController),
        _Input('رقم الهاتف', phoneController, keyboardType: TextInputType.phone),
        _Input('المحافظة', governorateController),
        _Input('العنوان', addressController),
        SizedBox(height: 50, child: FilledButton.icon(onPressed: saving ? null : saveInfo, icon: const Icon(Icons.save_outlined), label: const Text('حفظ البيانات'))),
      ])),
      _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('حالة المدرسة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('الحالة الحالية: ${statusText(st)}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _StatusAction('تفعيل', Icons.play_circle_outline, _success, () => updateStatus('active')),
          _StatusAction('إيقاف', Icons.pause_circle_outline, _warning, () => updateStatus('paused')),
          _StatusAction('تعطيل', Icons.block_outlined, _danger, () => updateStatus('inactive')),
        ]),
      ])),
      _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: const [
        Text('تنبيه أمان', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text('هذا القسم للسوبر أدمن فقط. مدير المدرسة لا يجب أن يمتلك صلاحية رؤية حساب السوبر أدمن أو تغيير دوره.', style: TextStyle(color: _muted, fontWeight: FontWeight.w800, height: 1.45)),
      ])),
    ]);
  }

  Future<void> saveInfo() async {
    setState(() => saving = true);
    try {
      await _db.collection('schools').doc(widget.schoolId).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'governorate': governorateController.text.trim(),
        'address': addressController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await addSchoolLog(widget.schoolId, 'تعديل بيانات المدرسة', 'تم تعديل البيانات الأساسية للمدرسة');
      if (mounted) snack(context, 'تم حفظ البيانات');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> updateStatus(String status) async {
    setState(() => saving = true);
    try {
      await _db.collection('schools').doc(widget.schoolId).update({'status': status, 'updatedAt': DateTime.now().toIso8601String()});
      await addSchoolLog(widget.schoolId, 'تغيير حالة المدرسة', 'تم تغيير حالة المدرسة إلى ${statusText(status)}');
      if (mounted) snack(context, 'تم تغيير الحالة إلى ${statusText(status)}');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _SchoolLogTab extends StatelessWidget {
  final String schoolId;
  const _SchoolLogTab({required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('schools').doc(schoolId).collection('billing_logs').snapshots(),
      builder: (context, billingSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('schools').doc(schoolId).collection('activity_logs').snapshots(),
          builder: (context, activitySnap) {
            final items = <Map<String, dynamic>>[];
            for (final doc in billingSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
              items.add({...doc.data(), '_source': 'الفوترة'});
            }
            for (final doc in activitySnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
              items.add({...doc.data(), '_source': 'النظام'});
            }
            items.sort((a, b) => '${b['createdAt'] ?? b['date'] ?? ''}'.compareTo('${a['createdAt'] ?? a['date'] ?? ''}'));
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .98, children: [
                _MiniMetric('العمليات', '${items.length}', Icons.history_rounded),
                _MiniMetric('فوترة', '${items.where((e) => e['_source'] == 'الفوترة').length}', Icons.receipt_long_outlined),
                _MiniMetric('نظام', '${items.where((e) => e['_source'] == 'النظام').length}', Icons.settings_suggest_outlined),
              ]),
              const SizedBox(height: 12),
              if (items.isEmpty) const _Empty('لا يوجد سجل عمليات بعد') else ...items.map((e) => _LogCard(e)),
            ]);
          },
        );
      },
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final IconData icon;
  final String type;
  const _PersonCard({required this.data, required this.icon, required this.type});

  @override
  Widget build(BuildContext context) {
    return _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: _blue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(personName(data), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          Text(type, style: const TextStyle(color: _muted, fontWeight: FontWeight.w800)),
        ])),
        _Badge(personStatus(data), activeAccount(data) ? _success : _danger),
      ]),
      const SizedBox(height: 10),
      _Line('الهاتف', personPhone(data)),
      _Line('البريد', personEmail(data)),
    ]));
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LogCard(this.data);

  @override
  Widget build(BuildContext context) {
    return _Panel(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.history_rounded, color: _blue)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${data['action'] ?? data['title'] ?? 'عملية'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${data['details'] ?? data['description'] ?? data['message'] ?? ''}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700, height: 1.35)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _Badge('${data['_source'] ?? 'سجل'}', _blue),
          _Badge(date(data['createdAt'] ?? data['date']), _muted),
          if ('${data['user'] ?? ''}'.trim().isNotEmpty) _Badge('${data['user']}', _success),
        ]),
      ])),
    ]));
  }
}

class _StatusAction extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatusAction(this.text, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(text), style: OutlinedButton.styleFrom(foregroundColor: color));
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  const _Input(this.label, this.controller, {this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: controller, keyboardType: keyboardType, textAlign: TextAlign.right, decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      );
}

class _HeroBadge extends StatelessWidget { final String text; const _HeroBadge(this.text); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(99)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))); }
class _HeroInfo extends StatelessWidget { final IconData icon; final String text; const _HeroInfo(this.icon, this.text); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))])); }
class _Metric extends StatelessWidget { final String title; final String value; final IconData icon; const _Metric(this.title, this.value, this.icon); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: _blue), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: _muted, fontWeight: FontWeight.w800))])); }
class _MiniMetric extends StatelessWidget { final String title; final String value; final IconData icon; const _MiniMetric(this.title, this.value, this.icon); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: _blue, size: 21), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w800))])); }
class _Panel extends StatelessWidget { final Widget child; const _Panel({required this.child}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0F0F5))), child: child); }
class _Nav extends StatelessWidget { final String title; final String subtitle; final IconData icon; final VoidCallback onTap; const _Nav({required this.title, required this.subtitle, required this.icon, required this.onTap}); @override Widget build(BuildContext context) => InkWell(onTap: onTap, child: _Panel(child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: _blue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: _muted, fontWeight: FontWeight.w700))])), const Icon(Icons.chevron_left_rounded, color: _muted)]))); }
class _Filter extends StatelessWidget { final String selected; final Map<String, String> items; final ValueChanged<String> onChanged; const _Filter({required this.selected, required this.items, required this.onChanged}); @override Widget build(BuildContext context) => SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: items.entries.map((e) => Padding(padding: const EdgeInsets.only(left: 8), child: ChoiceChip(selected: selected == e.key, showCheckmark: false, label: Text(e.value), selectedColor: _softBlue, onSelected: (_) => onChanged(e.key)))).toList())); }
class _Back extends StatelessWidget { final String text; final VoidCallback onTap; const _Back({required this.text, required this.onTap}); @override Widget build(BuildContext context) => Row(children: [IconButton(onPressed: onTap, icon: const Icon(Icons.arrow_back, color: _blue)), Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))]); }
class _Empty extends StatelessWidget { final String text; const _Empty(this.text); @override Widget build(BuildContext context) => _Panel(child: Center(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)))); }
class _Line extends StatelessWidget { final String label; final String value; const _Line(this.label, this.value); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: _muted, fontWeight: FontWeight.w800))), Flexible(child: Text(value, textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w900)))])); }

class _StudentCard extends StatelessWidget { final Map<String, dynamic> school; final List<QueryDocumentSnapshot<Map<String, dynamic>>> all; final QueryDocumentSnapshot<Map<String, dynamic>> doc; const _StudentCard({required this.school, required this.all, required this.doc}); @override Widget build(BuildContext context) { final d = doc.data(); final paid = paidStudent(school, all, doc); return _Panel(child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: paid ? _success.withOpacity(.1) : _softBlue, borderRadius: BorderRadius.circular(16)), child: Icon(paid ? Icons.verified_user_outlined : Icons.person_outline, color: paid ? _success : _blue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name(d), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text('${grade(d)} • شعبة ${section(d)}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12)), Text('ولي الأمر: ${parent(d)}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700, fontSize: 12))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [_Badge(activeAccount(d) ? 'نشط' : 'غير نشط', activeAccount(d) ? _success : _danger), if (isPerStudent(school)) ...[const SizedBox(height: 6), _Badge(paid ? 'مدفوع' : 'غير مدفوع', paid ? _success : _danger)]]) ])); }}

class _TeacherCard extends StatelessWidget {
  final Map<String, dynamic> t;
  const _TeacherCard(this.t);

  @override
  Widget build(BuildContext context) {
    return _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: _softBlue, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.person_outline, color: _blue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(teacherName(t), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          Text('الهاتف: ${teacherPhone(t)}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w700)),
        ])),
      ]),
      const SizedBox(height: 10),
      Text('الشعب والصفوف: ${classesOf(t).isEmpty ? 'غير محدد' : classesOf(t).join('، ')}', style: const TextStyle(color: _muted, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      SizedBox(height: 42, child: OutlinedButton.icon(onPressed: () => showModalBottomSheet<void>(context: context, showDragHandle: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))), builder: (_) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(teacherName(t), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 12), _Line('الهاتف', teacherPhone(t)), _Line('المواد', subjectsOf(t).join('، ')), _Line('الصفوف والشعب', classesOf(t).isEmpty ? 'غير محدد' : classesOf(t).join('، ')), _Line('معلومات عامة', '${t['notes'] ?? t['generalInfo'] ?? t['bio'] ?? 'غير محدد'}')])))), icon: const Icon(Icons.visibility_outlined), label: const Text('عرض التفاصيل'))),
    ]));
  }
}

class _Badge extends StatelessWidget { final String text; final Color color; const _Badge(this.text, this.color); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))); }

Map<String, dynamic> sub(Map<String, dynamic> d) => d['subscription'] is Map<String, dynamic> ? Map<String, dynamic>.from(d['subscription'] as Map<String, dynamic>) : <String, dynamic>{};
bool isPerStudent(Map<String, dynamic> school) => sub(school)['planType'] == 'per_student';
double n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int intFrom(dynamic v) => v is int ? v : v is double ? v.toInt() : int.tryParse('$v') ?? 0;
String money(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
String date(dynamic v) { final x = DateTime.tryParse('$v'); return x == null ? '—' : '${x.year}/${x.month.toString().padLeft(2, '0')}/${x.day.toString().padLeft(2, '0')}'; }
String statusText(String s) { final v = s.toLowerCase().trim(); if (v == 'active') return 'مفعلة'; if (v == 'paused' || v == 'stopped' || v == 'suspended') return 'موقوفة'; if (v == 'trial') return 'تجريبية'; return 'غير مفعلة'; }
String name(Map<String, dynamic> s) => '${s['name'] ?? s['fullName'] ?? s['studentName'] ?? 'طالب'}';
String grade(Map<String, dynamic> s) => '${s['gradeName'] ?? s['grade'] ?? s['className'] ?? '—'}';
String section(Map<String, dynamic> s) => '${s['sectionName'] ?? s['section'] ?? s['classSection'] ?? '—'}';
String parent(Map<String, dynamic> s) => '${s['parentName'] ?? s['guardianName'] ?? s['parent'] ?? 'غير محدد'}';
bool activeAccount(Map<String, dynamic> s) { final v = '${s['status'] ?? s['accountStatus'] ?? 'active'}'.toLowerCase(); return v != 'inactive' && v != 'disabled' && v != 'stopped'; }
bool paidStudent(Map<String, dynamic> school, List<QueryDocumentSnapshot<Map<String, dynamic>>> all, QueryDocumentSnapshot<Map<String, dynamic>> doc) { if (!isPerStudent(school)) return true; final d = doc.data(); final raw = '${d['billingStatus'] ?? d['paymentStatus'] ?? d['billing_status'] ?? ''}'.toLowerCase(); if (raw == 'paid' || raw == 'مدفوع') return true; if (raw == 'unpaid' || raw == 'غير مدفوع') return false; final price = n(sub(school)['pricePerStudent']) == 0 ? 20 : n(sub(school)['pricePerStudent']); final paidCount = price <= 0 ? 0 : (n(sub(school)['paidAmount']) / price).floor(); final index = all.indexWhere((x) => x.id == doc.id); return index >= 0 && index < paidCount; }
int unpaidCount(Map<String, dynamic> school, List<QueryDocumentSnapshot<Map<String, dynamic>>> students) => !isPerStudent(school) ? 0 : students.where((s) => !paidStudent(school, students, s)).length;
List<String> alerts(Map<String, dynamic> school, double usage, int unpaid) { final out = <String>[]; final st = '${school['status'] ?? ''}'.toLowerCase(); final end = DateTime.tryParse('${sub(school)['endDate'] ?? ''}'); final left = end == null ? 0 : end.difference(DateTime.now()).inDays + 1; if (st == 'paused') out.add('المدرسة موقوفة حاليًا'); if (left > 0 && left <= 30) out.add('الاشتراك ينتهي بعد $left يوم'); if (usage >= .9) out.add('المدرسة وصلت ${(usage * 100).toStringAsFixed(0)}% من حد الطلاب'); if (unpaid > 0) out.add('يوجد $unpaid طالب غير مدفوع'); return out; }
String teacherName(Map<String, dynamic> t) => '${t['name'] ?? t['fullName'] ?? t['teacherName'] ?? 'معلم'}';
String teacherPhone(Map<String, dynamic> t) => '${t['phone'] ?? t['mobile'] ?? t['phoneNumber'] ?? 'غير محدد'}';
List<String> subjectsOf(Map<String, dynamic> t) { final raw = t['subjects'] ?? t['subjectNames'] ?? t['subject']; if (raw is List) return raw.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList(); if (raw is String && raw.trim().isNotEmpty) return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(); return ['غير محدد']; }
List<String> classesOf(Map<String, dynamic> t) { final raw = t['assignedClasses'] ?? t['classes'] ?? t['sections']; if (raw is List) return raw.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList(); if (raw is String && raw.trim().isNotEmpty) return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(); return const []; }
String personName(Map<String, dynamic> p) => '${p['name'] ?? p['fullName'] ?? p['displayName'] ?? p['parentName'] ?? p['guardianName'] ?? 'غير محدد'}';
String personPhone(Map<String, dynamic> p) => '${p['phone'] ?? p['mobile'] ?? p['phoneNumber'] ?? 'غير محدد'}';
String personEmail(Map<String, dynamic> p) => '${p['email'] ?? p['mail'] ?? 'غير محدد'}';
String personStatus(Map<String, dynamic> p) => activeAccount(p) ? 'نشط' : 'غير نشط';
String adminRole(Map<String, dynamic> a) => '${a['roleLabel'] ?? a['role'] ?? a['jobTitle'] ?? 'إداري'}';
void snack(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
Future<void> addSchoolLog(String schoolId, String action, String details) async { await _db.collection('schools').doc(schoolId).collection('activity_logs').add({'action': action, 'details': details, 'createdAt': DateTime.now().toIso8601String(), 'user': 'Super Admin'}); }
