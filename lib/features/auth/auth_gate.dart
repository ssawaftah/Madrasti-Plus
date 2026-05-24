import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../admin/admin_home_screen.dart';
import '../gate/gate_home_screen.dart';
import '../parent/parent_home_screen.dart';
import '../super_admin/super_admin_home_screen.dart';
import '../teacher/teacher_home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<AppUser>(
          future: authService.getOrCreateCurrentAppUser(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (userSnapshot.hasError) {
              return _AuthErrorScreen(message: userSnapshot.error.toString());
            }

            final appUser = userSnapshot.data!;
            return _NotificationInitializer(
              appUser: appUser,
              child: _RoleRouter(appUser: appUser),
            );
          },
        );
      },
    );
  }
}

class _NotificationInitializer extends StatefulWidget {
  final AppUser appUser;
  final Widget child;

  const _NotificationInitializer({
    required this.appUser,
    required this.child,
  });

  @override
  State<_NotificationInitializer> createState() => _NotificationInitializerState();
}

class _NotificationInitializerState extends State<_NotificationInitializer> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    await NotificationService().initializeForCurrentUser(widget.appUser.id);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _RoleRouter extends StatelessWidget {
  final AppUser appUser;

  const _RoleRouter({required this.appUser});

  @override
  Widget build(BuildContext context) {
    switch (appUser.role) {
      case 'super_admin':
        return const SuperAdminHomeScreen();
      case 'admin':
        return const AdminHomeScreen();
      case 'teacher':
        return const TeacherHomeScreen();
      case 'parent':
        return const ParentHomeScreen();
      case 'nfc_device':
        return const GateHomeScreen();
      default:
        return _AuthErrorScreen(
          message: 'الدور غير معروف: ${appUser.role}',
        );
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تجهيز Madrasti Plus...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final String message;

  const _AuthErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مشكلة في الحساب')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 72),
              const SizedBox(height: 16),
              const Text(
                'تعذر تحديد صلاحيات المستخدم',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => AuthService().signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
