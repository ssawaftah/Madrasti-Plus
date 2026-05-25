import 'package:flutter/material.dart';

import '../../core/models/school.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/super_admin_service.dart';
import 'super_admin_add_school_screen.dart';
import 'widgets/platform_stats_section.dart';

class SuperAdminHomeScreenV3 extends StatefulWidget {
  const SuperAdminHomeScreenV3({super.key});

  @override
  State<SuperAdminHomeScreenV3> createState() => _SuperAdminHomeScreenV3State();
}

class _SuperAdminHomeScreenV3State extends State<SuperAdminHomeScreenV3> {
  final _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<School> _filterSchools(List<School> schools) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return schools;

    return schools.where((school) {
      return school.name.toLowerCase().contains(query) ||
          school.code.toLowerCase().contains(query) ||
          school.email.toLowerCase().contains(query) ||
          school.managerName.toLowerCase().contains(query);
    }).toList();
  }

  void _showSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الميزة في الخطوة القادمة')),
    );
  }

  void _openAddSchoolScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SuperAdminAddSchoolScreen()),
    );
  }

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
              final filtered = _filterSchools(schools);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onBellTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا توجد تنبيهات جديدة')),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('الوصول السريع'),
                  const SizedBox(height: 12),
                  _QuickGrid(
                    totalSchools: schools.length,
                    onAddSchoolTap: _openAddSchoolScreen,
                    onTapSoon: _showSoon,
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('إحصائيات المنصة'),
                  const SizedBox(height: 10),
                  PlatformStatsSection(schools: schools),
                  const SizedBox(height: 22),
                  const _SectionTitle('المدارس المختارة'),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (schools.isEmpty)
                    _EmptySchools(onAddSchoolTap: _openAddSchoolScreen)
                  else if (filtered.isEmpty)
                    const _EmptySearch()
                  else
                    _SchoolsStrip(schools: filtered.take(6).toList()),
                  const SizedBox(height: 70),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: _BottomNav(
            selectedIndex: _selectedIndex,
            onTap: (index) {
              setState(() => _selectedIndex = index);
              if (index == 3) AuthService().signOut();
              if (index != 0 && index != 3) _showSoon();
            },
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onBellTap;

  const _SearchBar({required this.controller, required this.onChanged, required this.onBellTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onBellTap, icon: const Icon(Icons.notifications_none_rounded, size: 31)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(color: const Color(0xFFF4F4F7), borderRadius: BorderRadius.circular(28)),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'ابحث في المدارس والقيود...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                suffixIcon: Icon(Icons.search_rounded, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800));
  }
}

class _QuickGrid extends StatelessWidget {
  final int totalSchools;
  final VoidCallback onAddSchoolTap;
  final VoidCallback onTapSoon;

  const _QuickGrid({required this.totalSchools, required this.onAddSchoolTap, required this.onTapSoon});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        _QuickTile(icon: Icons.add_business_outlined, label: 'إضافة\nمدرسة', onTap: onAddSchoolTap),
        _QuickTile(icon: Icons.school_outlined, label: 'المدارس\n$totalSchools', onTap: onTapSoon),
        _QuickTile(icon: Icons.admin_panel_settings_outlined, label: 'إدارة\nالمدراء', onTap: onTapSoon),
        _QuickTile(icon: Icons.analytics_outlined, label: 'تقارير\nالمنصة', onTap: onTapSoon),
        _QuickTile(icon: Icons.workspace_premium_outlined, label: 'الاشتراكات\nوالخطط', onTap: onTapSoon),
        _QuickTile(icon: Icons.security_outlined, label: 'الأمان\nوالصلاحيات', onTap: onTapSoon),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2457D6), size: 31),
            const SizedBox(height: 8),
            Flexible(
              child: Text(label, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.12, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolsStrip extends StatelessWidget {
  final List<School> schools;

  const _SchoolsStrip({required this.schools});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          reverse: true,
          itemCount: schools.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) => _SchoolBubble(school: schools[index]),
        ),
      ),
    );
  }
}

class _SchoolBubble extends StatelessWidget {
  final School school;

  const _SchoolBubble({required this.school});

  @override
  Widget build(BuildContext context) {
    final initials = school.name.trim().isEmpty ? 'M+' : school.name.trim().characters.take(2).join();

    return SizedBox(
      width: 104,
      child: Column(
        children: [
          CircleAvatar(
            radius: 33,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 29,
              backgroundColor: const Color(0xFFEFF3FF),
              child: Text(initials, style: const TextStyle(color: Color(0xFF2457D6), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Text(school.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(school.code, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptySchools extends StatelessWidget {
  final VoidCallback onAddSchoolTap;

  const _EmptySchools({required this.onAddSchoolTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 46, color: Color(0xFF2457D6)),
          const SizedBox(height: 10),
          const Text('لا توجد مدارس بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('ابدأ بإضافة أول مدرسة على المنصة.'),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onAddSchoolTap, icon: const Icon(Icons.add), label: const Text('إضافة مدرسة')),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(22)),
      child: const Text('لا توجد نتائج مطابقة للبحث.'),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      color: Colors.white,
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.home_outlined, label: 'الرئيسية', selected: selectedIndex == 0, onTap: () => onTap(0)),
          _NavItem(icon: Icons.article_outlined, label: 'المستندات', selected: selectedIndex == 1, onTap: () => onTap(1)),
          _NavItem(icon: Icons.inventory_2_outlined, label: 'الخدمات', selected: selectedIndex == 2, onTap: () => onTap(2)),
          _NavItem(icon: Icons.logout, label: 'خروج', selected: selectedIndex == 3, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: selected ? const EdgeInsets.symmetric(horizontal: 18, vertical: 6) : EdgeInsets.zero,
              decoration: BoxDecoration(color: selected ? const Color(0xFFEFF3FF) : Colors.transparent, borderRadius: BorderRadius.circular(999)),
              child: Icon(icon, color: selected ? const Color(0xFF2457D6) : const Color(0xFF747985), size: 28),
            ),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? const Color(0xFF2457D6) : const Color(0xFF747985), fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
