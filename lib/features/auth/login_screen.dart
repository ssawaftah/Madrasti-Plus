import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _schoolCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _selectedTabIndex = 1;

  static const _blue = Color(0xFF2457D6);
  static const _dark = Color(0xFF505050);
  static const _softBlue = Color(0xFFF3F6FF);

  @override
  void dispose() {
    _schoolCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('أدخل البريد الإلكتروني وكلمة السر');
      return;
    }

    if (!email.contains('@')) {
      _showMessage('البريد الإلكتروني غير صحيح');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().signIn(
        schoolCode: _schoolCodeController.text,
        email: email,
        password: password,
      );
    } on SchoolCodeException catch (error) {
      _showMessage(error.message);
    } on FirebaseAuthException catch (error) {
      _showMessage(_friendlyAuthError(error));
    } catch (error) {
      _showMessage('فشل تسجيل الدخول: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-disabled':
        return 'هذا الحساب معطل';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'فشل تسجيل الدخول: ${error.message ?? error.code}';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLanguageSheet() {
    _showInfoSheet(
      title: 'اختر اللغة',
      icon: Icons.language,
      children: const [
        _InfoTile(icon: Icons.check_circle_outline, title: 'العربية', subtitle: 'اللغة الحالية'),
        _InfoTile(icon: Icons.translate, title: 'English', subtitle: 'قريبًا'),
      ],
    );
  }

  void _showHelpSheet() {
    setState(() => _selectedTabIndex = 0);
    _showInfoSheet(
      title: 'المساعدة',
      icon: Icons.help_outline,
      children: const [
        _InfoTile(
          icon: Icons.key,
          title: 'كيف أحصل على رمز المدرسة؟',
          subtitle: 'رمز المدرسة يزوّدك به مدير النظام أو إدارة المدرسة.',
        ),
        _InfoTile(
          icon: Icons.lock_outline,
          title: 'نسيت كلمة السر؟',
          subtitle: 'تواصل مع إدارة المدرسة لإعادة تعيينها.',
        ),
        _InfoTile(
          icon: Icons.nfc,
          title: 'هل يعمل النظام مع NFC؟',
          subtitle: 'نعم، يدعم تسجيل دخول وخروج الطلاب عبر بطاقات NFC.',
        ),
      ],
    );
  }

  void _showContactSheet() {
    setState(() => _selectedTabIndex = 2);
    _showInfoSheet(
      title: 'تواصل معنا',
      icon: Icons.support_agent,
      children: const [
        _InfoTile(icon: Icons.email_outlined, title: 'البريد الإلكتروني', subtitle: 'iisawaftah@gmail.com'),
        _InfoTile(icon: Icons.phone_outlined, title: 'رقم الهاتف', subtitle: '0781002373'),
      ],
    );
  }

  void _showInfoSheet({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 30),
                      const SizedBox(width: 10),
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _selectedTabIndex = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _TopBar(onLanguageTap: _showLanguageSheet),
                        SizedBox(height: constraints.maxHeight < 720 ? 76 : 120),
                        const _MadrastiLogo(),
                        SizedBox(height: constraints.maxHeight < 720 ? 84 : 140),
                        _LoginForm(
                          schoolCodeController: _schoolCodeController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          isLoading: _isLoading,
                          onTogglePassword: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          onLogin: _login,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.notifications_active_outlined,
                                title: 'تنبيهات\nفورية',
                              ),
                            ),
                            SizedBox(width: 18),
                            Expanded(
                              child: _FeatureCard(
                                icon: Icons.analytics_outlined,
                                title: 'تقارير\nذكية',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        _BottomTabs(
                          selectedIndex: _selectedTabIndex,
                          onHelpTap: _showHelpSheet,
                          onLoginTap: () => setState(() => _selectedTabIndex = 1),
                          onContactTap: _showContactSheet,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onLanguageTap;

  const _TopBar({required this.onLanguageTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: onLanguageTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('اختر اللغة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
              SizedBox(width: 10),
              Icon(Icons.language, size: 28),
            ],
          ),
        ),
      ],
    );
  }
}

class _MadrastiLogo extends StatelessWidget {
  const _MadrastiLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.school_rounded, color: Color(0xFF56B47B), size: 70),
        SizedBox(height: 6),
        Text(
          'مدرستي +',
          style: TextStyle(
            color: Color(0xFF56B47B),
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Madrasti Plus',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController schoolCodeController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  const _LoginForm({
    required this.schoolCodeController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SanadLikeField(
          controller: schoolCodeController,
          hint: 'رمز المدرسة',
          icon: Icons.qr_code_2,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 10),
        _SanadLikeField(
          controller: emailController,
          hint: 'البريد الإلكتروني',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _SanadLikeField(
          controller: passwordController,
          hint: 'كلمة السر',
          icon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          ),
          onSubmitted: (_) => onLogin(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 62,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _LoginScreenState._blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            onPressed: isLoading ? null : onLogin,
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('تسجيل دخول'),
          ),
        ),
      ],
    );
  }
}

class _SanadLikeField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _SanadLikeField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
        onSubmitted: onSubmitted,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 20, color: Color(0xFF565656), fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Color(0xFF565656), size: 30),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: _LoginScreenState._dark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _LoginScreenState._softBlue,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: _LoginScreenState._blue, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _LoginScreenState._blue,
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback onHelpTap;
  final VoidCallback onLoginTap;
  final VoidCallback onContactTap;

  const _BottomTabs({
    required this.selectedIndex,
    required this.onHelpTap,
    required this.onLoginTap,
    required this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _BottomTab(
          icon: Icons.help_outline,
          label: 'المساعدة',
          selected: selectedIndex == 0,
          onTap: onHelpTap,
        ),
        _BottomTab(
          icon: Icons.account_circle_outlined,
          label: 'الدخول',
          selected: selectedIndex == 1,
          onTap: onLoginTap,
        ),
        _BottomTab(
          icon: Icons.support_agent,
          label: 'تواصل معنا',
          selected: selectedIndex == 2,
          onTap: onContactTap,
        ),
      ],
    );
  }
}

class _BottomTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 105,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: selected ? const EdgeInsets.symmetric(horizontal: 22, vertical: 8) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEFF3FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                icon,
                color: selected ? _LoginScreenState._blue : const Color(0xFF747985),
                size: 34,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? _LoginScreenState._blue : const Color(0xFF747985),
                fontSize: 17,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _LoginScreenState._blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF666666), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
