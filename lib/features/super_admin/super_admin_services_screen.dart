import 'package:flutter/material.dart';

import 'billing/super_admin_billing_screen.dart';
import 'super_admin_school_wizard_screen.dart';
import 'super_admin_schools_screen.dart';

class SuperAdminServicesScreen extends StatelessWidget {
  const SuperAdminServicesScreen({super.key});

  void _openAddSchool(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SuperAdminSchoolWizardScreen()),
    );
  }

  void _openSchools(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SuperAdminSchoolsScreen()),
    );
  }

  void _openBilling(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SuperAdminBillingScreen()),
    );
  }

  void _showSoon(BuildContext context, String feature) {
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: 22),
              const Text('الخدمات', textAlign: TextAlign.right, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _ServiceCard(icon: Icons.school_outlined, title: 'إدارة المدارس', onTap: () => _openSchools(context)),
                  _ServiceCard(icon: Icons.add_business_outlined, title: 'إضافة مدرسة', onTap: () => _openAddSchool(context)),
                  _ServiceCard(icon: Icons.admin_panel_settings_outlined, title: 'إدارة المدراء', onTap: () => _showSoon(context, 'إدارة المدراء')),
                  _ServiceCard(icon: Icons.receipt_long_outlined, title: 'الاشتراكات والفوترة', onTap: () => _openBilling(context)),
                  _ServiceCard(icon: Icons.campaign_outlined, title: 'الإشعارات العامة', onTap: () => _showSoon(context, 'الإشعارات العامة')),
                  _ServiceCard(icon: Icons.settings_outlined, title: 'إعدادات المنصة', onTap: () => _showSoon(context, 'إعدادات المنصة')),
                ],
              ),
            ],
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
          const Center(child: Text('الخدمات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
          Positioned(right: 0, child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, size: 30))),
        ],
      ),
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
        decoration: BoxDecoration(color: const Color(0xFFF8F8FC), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: const Color(0xFF2457D6), size: 27),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
