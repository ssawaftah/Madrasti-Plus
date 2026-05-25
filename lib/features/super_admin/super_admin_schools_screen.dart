import 'package:flutter/material.dart';

import '../../core/models/school.dart';
import '../../core/services/super_admin_service.dart';

class SuperAdminSchoolsScreen extends StatefulWidget {
  const SuperAdminSchoolsScreen({super.key});

  @override
  State<SuperAdminSchoolsScreen> createState() => _SuperAdminSchoolsScreenState();
}

class _SuperAdminSchoolsScreenState extends State<SuperAdminSchoolsScreen> {
  final _searchController = TextEditingController();
  String? _selectedGovernorate;

  static const _blue = Color(0xFF2457D6);
  static const _muted = Color(0xFF6B7280);
  static const _governorates = [
    'عمّان',
    'إربد',
    'الزرقاء',
    'البلقاء',
    'مأدبا',
    'الكرك',
    'الطفيلة',
    'معان',
    'العقبة',
    'جرش',
    'عجلون',
    'المفرق',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<School> _filter(List<School> schools) {
    final q = _searchController.text.trim().toLowerCase();
    return schools.where((school) {
      final matchesSearch = q.isEmpty ||
          school.name.toLowerCase().contains(q) ||
          school.code.toLowerCase().contains(q) ||
          school.governorate.toLowerCase().contains(q);
      final matchesGovernorate = _selectedGovernorate == null || school.governorate == _selectedGovernorate;
      return matchesSearch && matchesGovernorate;
    }).toList();
  }

  void _showSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('صفحة عرض المدرسة في المرحلة القادمة')),
    );
  }

  void _openGovernoratePicker() {
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
              heightFactor: 0.72,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('اختر المحافظة', textAlign: TextAlign.right, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          _GovernorateOption(
                            title: 'كل المحافظات',
                            selected: _selectedGovernorate == null,
                            onTap: () {
                              setState(() => _selectedGovernorate = null);
                              Navigator.of(context).pop();
                            },
                          ),
                          ..._governorates.map((g) => _GovernorateOption(
                                title: g,
                                selected: _selectedGovernorate == g,
                                onTap: () {
                                  setState(() => _selectedGovernorate = g);
                                  Navigator.of(context).pop();
                                },
                              )),
                        ],
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: StreamBuilder<List<School>>(
            stream: SuperAdminService().watchSchools(),
            builder: (context, snapshot) {
              final schools = snapshot.data ?? const <School>[];
              final filtered = _filter(schools);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 18),
                  _SearchBox(controller: _searchController, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 10),
                  _GovernorateFilter(
                    value: _selectedGovernorate ?? 'كل المحافظات',
                    onTap: _openGovernoratePicker,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(child: Text('المدارس', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
                      Text('${filtered.length}', style: const TextStyle(color: _muted, fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else if (schools.isEmpty)
                    const _EmptyState(text: 'لا توجد مدارس بعد')
                  else if (filtered.isEmpty)
                    const _EmptyState(text: 'لا توجد مدارس مطابقة للبحث')
                  else
                    ...filtered.map((school) => _SchoolCard(school: school, onView: _showSoon)),
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
          const Center(child: Text('إدارة المدارس', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          Positioned(right: 0, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 30))),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(color: const Color(0xFFF4F4F7), borderRadius: BorderRadius.circular(28)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(
          hintText: 'ابحث باسم المدرسة أو رمزها أو المحافظة...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          suffixIcon: Icon(Icons.search_rounded, size: 28),
        ),
      ),
    );
  }
}

class _GovernorateFilter extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _GovernorateFilter({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF2457D6), size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E8E93), size: 28),
          ],
        ),
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final School school;
  final VoidCallback onView;

  const _SchoolCard({required this.school, required this.onView});

  @override
  Widget build(BuildContext context) {
    final active = _schoolIsActive(school.status);
    final initials = school.name.trim().isEmpty ? 'M+' : school.name.trim().characters.take(2).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEFF3FF),
                child: Text(initials, style: const TextStyle(color: Color(0xFF2457D6), fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(school.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('رمز المدرسة: ${school.code}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _StatusBadge(active: active),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.email_outlined, text: school.email),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on_outlined, text: [school.governorate, school.address].where((e) => e.trim().isNotEmpty).join(' - ')),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined, size: 20),
              label: const Text('عرض'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2457D6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _schoolIsActive(String status) {
    final normalized = status.toLowerCase().trim();
    return normalized != 'inactive' &&
        normalized != 'suspended' &&
        normalized != 'stopped' &&
        normalized != 'paused';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2457D6), size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text.isEmpty ? 'غير محدد' : text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF4B5563), fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F8EF) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(active ? 'مفعلة' : 'موقوفة', style: TextStyle(color: active ? const Color(0xFF16833A) : const Color(0xFFB42318), fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }
}

class _GovernorateOption extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _GovernorateOption({required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(title, textAlign: TextAlign.right, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            const SizedBox(width: 12),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? const Color(0xFF2457D6) : const Color(0xFF8E8E93)),
          ],
        ),
      ),
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
          const Icon(Icons.school_outlined, size: 44, color: Color(0xFF2457D6)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
