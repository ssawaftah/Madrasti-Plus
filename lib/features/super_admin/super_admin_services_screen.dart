import 'package:flutter/material.dart';

import '../../core/models/school.dart';
import '../../core/services/super_admin_service.dart';
import 'super_admin_add_school_screen.dart';

class SuperAdminServicesScreen extends StatefulWidget {
  const SuperAdminServicesScreen({super.key});

  @override
  State<SuperAdminServicesScreen> createState() => _SuperAdminServicesScreenState();
}

class _SuperAdminServicesScreenState extends State<SuperAdminServicesScreen> {
  final _searchController = TextEditingController();

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

  void _openAddSchool() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SuperAdminAddSchoolScreen()),
    );
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature في الخطوة القادمة')),
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
              final filteredSchools = _filterSchools(schools);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  _Header(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 18),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 22),
                  const _Title('الخدمات'),
                  const SizedBox(height: 12),
                  _ServiceCards(
                    onManageSchools: () {},
                    onAddSchool: _openAddSchool,
                    onSoon: _showSoon,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(child: _Title('إدارة المدارس')),
                      Text(
                        '${filteredSchools.length}',
                        style: const TextStyle(color: Color(0xFF747985), fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (schools.isEmpty)
                    _EmptySchools(onAddSchool: _openAddSchool)
                  else if (filteredSchools.isEmpty)
                    const _EmptySearch()
                  else
                    ...filteredSchools.map(
                      (school) => _SchoolManagementCard(
                        school: school,
                        onDetails: () => _showSchoolDetails(school),
                        onEdit: () => _showSoon('تعديل المدرسة'),
                        onToggleStatus: () => _showSoon('تفعيل وإيقاف المدرسة'),
                        onCopyCode: () => _showCopyCodeMessage(school.code),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCopyCodeMessage(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('رمز المدرسة: $code')),
    );
  }

  void _showSchoolDetails(School school) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    school.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(label: 'رمز المدرسة', value: school.code),
                  _DetailRow(label: 'مدير المدرسة', value: school.managerName),
                  _DetailRow(label: 'بريد المدير', value: school.email),
                  _DetailRow(label: 'العنوان', value: school.address),
                  _DetailRow(label: 'تاريخ الإنشاء', value: _formatDate(school.createdAt)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
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
          const Center(
            child: Text(
              'الخدمات',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        decoration: const InputDecoration(
          hintText: 'ابحث في المدارس...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          suffixIcon: Icon(Icons.search_rounded, size: 28),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;

  const _Title(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
    );
  }
}

class _ServiceCards extends StatelessWidget {
  final VoidCallback onManageSchools;
  final VoidCallback onAddSchool;
  final void Function(String feature) onSoon;

  const _ServiceCards({
    required this.onManageSchools,
    required this.onAddSchool,
    required this.onSoon,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _ServiceCard(icon: Icons.school_outlined, title: 'إدارة المدارس', onTap: onManageSchools),
        _ServiceCard(icon: Icons.add_business_outlined, title: 'إضافة مدرسة', onTap: onAddSchool),
        _ServiceCard(icon: Icons.admin_panel_settings_outlined, title: 'إدارة المدراء', onTap: () => onSoon('إدارة المدراء')),
        _ServiceCard(icon: Icons.workspace_premium_outlined, title: 'الاشتراكات والخطط', onTap: () => onSoon('الاشتراكات والخطط')),
        _ServiceCard(icon: Icons.campaign_outlined, title: 'الإشعارات العامة', onTap: () => onSoon('الإشعارات العامة')),
        _ServiceCard(icon: Icons.settings_outlined, title: 'إعدادات المنصة', onTap: () => onSoon('إعدادات المنصة')),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ServiceCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: const Color(0xFF2457D6), size: 27),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolManagementCard extends StatelessWidget {
  final School school;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onCopyCode;

  const _SchoolManagementCard({
    required this.school,
    required this.onDetails,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    const isActive = true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEFF3FF),
                child: Text(
                  school.name.trim().isEmpty ? 'M+' : school.name.trim().characters.take(2).join(),
                  style: const TextStyle(color: Color(0xFF2457D6), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'الرمز: ${school.code}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _StatusChip(isActive: isActive),
            ],
          ),
          const SizedBox(height: 12),
          Text('المدير: ${school.managerName}', maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(school.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(icon: Icons.visibility_outlined, label: 'تفاصيل', onTap: onDetails),
              _ActionButton(icon: Icons.edit_outlined, label: 'تعديل', onTap: onEdit),
              _ActionButton(icon: Icons.pause_circle_outline, label: 'إيقاف', onTap: onToggleStatus),
              _ActionButton(icon: Icons.copy_outlined, label: 'نسخ الرمز', onTap: onCopyCode),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE9F8EF) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'مفعلة' : 'موقوفة',
        style: TextStyle(
          color: isActive ? const Color(0xFF16833A) : const Color(0xFFB42318),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2457D6),
        side: const BorderSide(color: Color(0xFFD9E1FF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _EmptySchools extends StatelessWidget {
  final VoidCallback onAddSchool;

  const _EmptySchools({required this.onAddSchool});

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
          FilledButton.icon(onPressed: onAddSchool, icon: const Icon(Icons.add), label: const Text('إضافة مدرسة')),
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
