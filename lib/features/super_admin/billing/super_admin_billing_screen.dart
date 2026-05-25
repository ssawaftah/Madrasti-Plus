import 'package:flutter/material.dart';

import '../../../core/models/school.dart';
import '../../../core/services/super_admin_service.dart';

class SuperAdminBillingScreen extends StatefulWidget {
  const SuperAdminBillingScreen({super.key});

  @override
  State<SuperAdminBillingScreen> createState() => _SuperAdminBillingScreenState();
}

class _SuperAdminBillingScreenState extends State<SuperAdminBillingScreen> {
  int _selectedTab = 0;

  static const _blue = Color(0xFF2457D6);
  static const _bg = Color(0xFFF8F8FC);
  static const _muted = Color(0xFF6B7280);

  final _tabs = const [
    'الملخص',
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
                  _TabsBar(
                    tabs: _tabs,
                    selectedIndex: _selectedTab,
                    onChanged: (index) => setState(() => _selectedTab = index),
                  ),
                  const SizedBox(height: 18),
                  if (_selectedTab == 0)
                    _BillingSummary(schools: schools)
                  else if (_selectedTab == 1)
                    _SchoolSubscriptions(schools: schools)
                  else if (_selectedTab == 2)
                    const _FreeTrialsView()
                  else if (_selectedTab == 3)
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
        reverse: true,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _MetricCard(icon: Icons.verified_outlined, title: 'المدارس النشطة', value: schools.length.toString()),
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

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: const Color(0xFF2457D6), size: 24),
          ),
          const SizedBox(height: 10),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF123A73), Color(0xFF0B1F3B)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('قاعدة مالية أساسية', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('المدرسة هي العميل المالي الوحيد. لا يوجد أي تعامل مالي مباشر مع أولياء الأمور داخل النظام.', textAlign: TextAlign.right, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SchoolSubscriptions extends StatelessWidget {
  final List<School> schools;

  const _SchoolSubscriptions({required this.schools});

  @override
  Widget build(BuildContext context) {
    if (schools.isEmpty) return const _EmptyState(text: 'لا توجد مدارس بعد');

    return Column(
      children: schools.map((school) => _SubscriptionSchoolCard(school: school)).toList(),
    );
  }
}

class _SubscriptionSchoolCard extends StatelessWidget {
  final School school;

  const _SubscriptionSchoolCard({required this.school});

  @override
  Widget build(BuildContext context) {
    final active = school.status != 'suspended' && school.status != 'inactive' && school.status != 'stopped';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(school.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              _StatusBadge(text: active ? 'نشط' : 'موقوف', active: active),
            ],
          ),
          const SizedBox(height: 8),
          Text('رمز المدرسة: ${school.code}', style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(text: 'نوع الخطة: غير محدد'),
              _MiniChip(text: 'المدفوع: 0 د.أ'),
              _MiniChip(text: 'المتبقي: 0 د.أ'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تفاصيل الاشتراك في المرحلة القادمة'))),
              icon: const Icon(Icons.visibility_outlined, size: 19),
              label: const Text('عرض'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2457D6),
                side: const BorderSide(color: Color(0xFFD9E1FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeTrialsView extends StatelessWidget {
  const _FreeTrialsView();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderList(
      title: 'التجارب المجانية',
      items: ['إنشاء تجربة مجانية', 'تمديد التجربة', 'إنهاء التجربة', 'تحويل إلى خطة مدفوعة'],
    );
  }
}

class _PlansPricingView extends StatelessWidget {
  const _PlansPricingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PlanCard(title: 'تجربة مجانية', subtitle: 'شهر واحد - مجاني'),
        _PlanCard(title: 'شاملة 250', subtitle: '250 طالب × 15 د.أ = 3,750 د.أ سنويًا'),
        _PlanCard(title: 'شاملة 500', subtitle: '500 طالب × 10 د.أ = 5,000 د.أ سنويًا'),
        _PlanCard(title: 'شاملة 750', subtitle: '750 طالب × 10 د.أ = 7,500 د.أ سنويًا'),
        _PlanCard(title: 'شاملة 1000+', subtitle: 'عدد مخصص × 10 د.أ سنويًا'),
        _PlanCard(title: 'حسب الطالب', subtitle: '20 د.أ سنويًا لكل حساب طالب'),
      ],
    );
  }
}

class _BillingAlertsView extends StatelessWidget {
  const _BillingAlertsView();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderList(
      title: 'تنبيهات الفوترة',
      items: ['اشتراك ينتهي قريبًا', 'تجربة تنتهي قريبًا', 'حسابات غير مدفوعة', 'مدرسة وصلت حد الخطة', 'دفعة متأخرة'],
    );
  }
}

class _PlaceholderList extends StatelessWidget {
  final String title;
  final List<String> items;

  const _PlaceholderList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF2457D6), size: 10),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                ],
              ),
            )),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlanCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF2457D6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;

  const _MiniChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4B5563))),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final bool active;

  const _StatusBadge({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F8EF) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: active ? const Color(0xFF16833A) : const Color(0xFFB42318), fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF2457D6)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
