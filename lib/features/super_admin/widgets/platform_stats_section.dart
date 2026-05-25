import 'package:flutter/material.dart';

import '../../../core/models/school.dart';
import '../../../core/services/super_admin_service.dart';

class PlatformStatsSection extends StatelessWidget {
  final List<School> schools;

  const PlatformStatsSection({super.key, required this.schools});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformStats>(
      future: SuperAdminService().fetchPlatformStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? PlatformStats.fromSchoolsOnly(schools);

        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Container(
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _StatCard(icon: Icons.school_outlined, title: 'عدد المدارس', value: stats.totalSchools.toString()),
            _StatCard(icon: Icons.groups_outlined, title: 'عدد الطلاب الكلي', value: stats.totalStudents.toString()),
            _StatCard(icon: Icons.people_alt_outlined, title: 'عدد المستخدمين', value: stats.totalUsers.toString()),
            _StatCard(icon: Icons.check_circle_outline, title: 'مدارس مفعلة', value: stats.activeSchools.toString()),
            _StatCard(icon: Icons.pause_circle_outline, title: 'مدارس موقوفة', value: stats.suspendedSchools.toString()),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2457D6), size: 25),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
