import 'package:flutter/material.dart';

class SuperAdminSchoolDetailsScreen extends StatelessWidget {
  final String schoolId;
  const SuperAdminSchoolDetailsScreen({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Text('عرض المدرسة: $schoolId'),
          ),
        ),
      ),
    );
  }
}
