import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/school.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/super_admin_service.dart';

class SuperAdminHomeScreenV2 extends StatefulWidget {
  const SuperAdminHomeScreenV2({super.key});

  @override
  State<SuperAdminHomeScreenV2> createState() => _SuperAdminHomeScreenV2State();
}

class _SuperAdminHomeScreenV2State extends State<SuperAdminHomeScreenV2> {
  final _schoolNameController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isSaving = false;
  bool _obscurePassword = true;
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolCodeController.dispose();
    _addressController.dispose();
    _managerNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createSchool() async {
    if (_isSaving) return;

    final schoolName = _schoolNameController.text.trim();
    final schoolCode = _schoolCodeController.text.trim().toUpperCase();
    final address = _addressController.text.trim();
    final managerName = _managerNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final validationMessage = _validateForm(
      schoolName: schoolName,
      schoolCode: schoolCode,
      address: address,
      managerName: managerName,
      email: email,
      password: password,
    );

    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final school = await SuperAdminService().createSchool(
        name: schoolName,
        code: schoolCode,
        address: address,
        managerName: managerName,
        email: email,
        password: password,
      );

      _schoolNameController.clear();
      _schoolCodeController.clear();
      _addressController.clear();
      _managerNameController.clear();
      _emailController.clear();
      _passwordController.clear();

      if (mounted) Navigator.of(context).pop();
      _showMessage('تم إنشاء المدرسة بنجاح. الرمز: ${school.code}');
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error) {
      _showMessage('تعذر إنشاء المدرسة: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateForm({
    required String schoolName,
    required String schoolCode,
    required String address,
    required String managerName,
    required String email,
    required String password,
  }) {
    if (schoolName.isEmpty ||
        schoolCode.isEmpty ||
        address.isEmpty ||
        managerName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      return 'كل الحقول مطلوبة';
    }

    if (schoolCode.length < 3) return 'رمز المدرسة يجب أن يكون 3 أحرف على الأقل';
    if (!email.contains('@')) return 'البريد الإلكتروني غير صحيح';
    if (password.length < 6) return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل لحساب آخر';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة السر ضعيفة';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'فشل إنشاء الحساب: ${error.message ?? error.code}';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddSchoolSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 4,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: _CreateSchoolForm(
              schoolNameController: _schoolNameController,
              schoolCodeController: _schoolCodeController,
              addressController: _addressController,
              managerNameController: _managerNameController,
              emailController: _emailController,
              passwordController: _passwordController,
              isSaving: _isSaving,
              obscurePassword: _obscurePassword,
              onTogglePassword: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              onSubmit: _createSchool,
            ),
          ),
        );
      },
    );
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  _TopSearchBar(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onNotificationTap: () => _showMessage('لا توجد تنبيهات جديدة'),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle(title: 'الوصول السريع'),
                  const SizedBox(height: 12),
                  _QuickAccessGrid(
                    totalSchools: schools.length,
                    onAddSchoolTap: _showAddSchoolSheet,
                    onSchoolsTap: () => _showMessage('قائمة المدارس أمامك في الأسفل'),
                    onReportsTap: () => _showMessage('التقارير التفصيلية في الخطوة القادمة'),
                    onSubscriptionsTap: () => _showMessage('الاشتراكات قريبًا'),
                  ),
                  const SizedBox(height: 22),
                  _ToolsHeader(onCustomizeTap: () => _showMessage('التخصيص لاحقًا')),
                  const SizedBox(height: 10),
                  _PlatformStatusCard(totalSchools: schools.length),
                  const SizedBox(height: 22),
                  const _SectionTitle(title: 'المدارس المختارة'),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
                  else if (schools.isEmpty)
                    _EmptySchoolsCard(onAddSchoolTap: _showAddSchoolSheet)
                  else if (filteredSchools.isEmpty)
                    const _EmptySearchCard()
                  else
                    _SelectedSchoolsStrip(schools: filteredSchools.take(6).toList()),
                  const SizedBox(height: 70),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: _SuperAdminBottomNav(
            selectedIndex: _selectedTabIndex,
            onTap: (index) {
              setState(() => _selectedTabIndex = index);
              if (index == 1) _showMessage('المستندات قريبًا');
              if (index == 2) _showMessage('الخدمات قريبًا');
              if (index == 3) _showMessage('الحساب والإعدادات قريبًا');
            },
          ),
        ),
      ),
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onNotificationTap;

  const _TopSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_none_rounded, size: 31),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
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

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final int totalSchools;
  final VoidCallback onAddSchoolTap;
  final VoidCallback onSchoolsTap;
  final VoidCallback onReportsTap;
  final VoidCallback onSubscriptionsTap;

  const _QuickAccessGrid({
    required this.totalSchools,
    required this.onAddSchoolTap,
    required this.onSchoolsTap,
    required this.onReportsTap,
    required this.onSubscriptionsTap,
  });

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
        _QuickAccessTile(icon: Icons.add_business_outlined, label: 'إضافة\nمدرسة', onTap: onAddSchoolTap),
        _QuickAccessTile(icon: Icons.school_outlined, label: 'المدارس\n$totalSchools', onTap: onSchoolsTap),
        _QuickAccessTile(icon: Icons.admin_panel_settings_outlined, label: 'إدارة\nالمدراء', onTap: onSchoolsTap),
        _QuickAccessTile(icon: Icons.analytics_outlined, label: 'تقارير\nالمنصة', onTap: onReportsTap),
        _QuickAccessTile(icon: Icons.workspace_premium_outlined, label: 'الاشتراكات\nوالخطط', onTap: onSubscriptionsTap),
        _QuickAccessTile(icon: Icons.security_outlined, label: 'الأمان\nوالصلاحيات', onTap: onReportsTap),
      ],
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FC),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2457D6), size: 31),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolsHeader extends StatelessWidget {
  final VoidCallback onCustomizeTap;

  const _ToolsHeader({required this.onCustomizeTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onCustomizeTap,
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, color: Color(0xFF2457D6), size: 23),
              SizedBox(width: 7),
              Text(
                'تخصيص',
                style: TextStyle(color: Color(0xFF2457D6), fontSize: 19, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Text('أدواتي', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _PlatformStatusCard extends StatelessWidget {
  final int totalSchools;

  const _PlatformStatusCard({required this.totalSchools});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF123A73), Color(0xFF0B1F3B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Madrasti Plus Cloud',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 7),
                Text(
                  '$totalSchools مدرسة مسجلة على المنصة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 9),
                const Text(
                  'النظام يعمل بشكل طبيعي',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_done_outlined, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

class _SelectedSchoolsStrip extends StatelessWidget {
  final List<School> schools;

  const _SelectedSchoolsStrip({required this.schools});

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
              child: Text(
                initials,
                style: const TextStyle(color: Color(0xFF2457D6), fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            school.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            school.code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EmptySchoolsCard extends StatelessWidget {
  final VoidCallback onAddSchoolTap;

  const _EmptySchoolsCard({required this.onAddSchoolTap});

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

class _EmptySearchCard extends StatelessWidget {
  const _EmptySearchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(22)),
      child: const Text('لا توجد نتائج مطابقة للبحث.'),
    );
  }
}

class _CreateSchoolForm extends StatelessWidget {
  final TextEditingController schoolNameController;
  final TextEditingController schoolCodeController;
  final TextEditingController addressController;
  final TextEditingController managerNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSaving;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  const _CreateSchoolForm({
    required this.schoolNameController,
    required this.schoolCodeController,
    required this.addressController,
    required this.managerNameController,
    required this.emailController,
    required this.passwordController,
    required this.isSaving,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إضافة مدرسة جديدة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('أدخل بيانات المدرسة ومديرها. رمز المدرسة إجباري وتحدده أنت.'),
            const SizedBox(height: 16),
            _Field(controller: schoolNameController, label: 'اسم المدرسة', icon: Icons.school_outlined),
            const SizedBox(height: 10),
            _Field(
              controller: schoolCodeController,
              label: 'رمز المدرسة',
              hint: 'مثال: MAD-001',
              icon: Icons.qr_code_2,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 10),
            _Field(controller: addressController, label: 'العنوان', icon: Icons.location_on_outlined),
            const SizedBox(height: 10),
            _Field(controller: managerNameController, label: 'اسم مدير المدرسة', icon: Icons.person_outline),
            const SizedBox(height: 10),
            _Field(
              controller: emailController,
              label: 'بريد المدير',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة السر',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isSaving ? null : onSubmit,
              icon: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: Text(isSaving ? 'جاري الإنشاء...' : 'إنشاء المدرسة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SuperAdminBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _SuperAdminBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.person_outline, label: 'الحساب', selected: selectedIndex == 3, onTap: () => onTap(3)),
          _NavItem(icon: Icons.inventory_2_outlined, label: 'الخدمات', selected: selectedIndex == 2, onTap: () => onTap(2)),
          _NavItem(icon: Icons.article_outlined, label: 'المستندات', selected: selectedIndex == 1, onTap: () => onTap(1)),
          _NavItem(icon: Icons.home_outlined, label: 'الرئيسية', selected: selectedIndex == 0, onTap: () => onTap(0)),
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
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEFF3FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                color: selected ? const Color(0xFF2457D6) : const Color(0xFF747985),
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? const Color(0xFF2457D6) : const Color(0xFF747985),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
