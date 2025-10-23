import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'signup_page.dart';
import 'notifications.dart';
import 'theme_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  late AnimationController _fadeCtrl, _slideCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, .15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    
    // التحقق من البيانات
    if (_phone.text.isEmpty || _password.text.isEmpty) {
      NotificationsService.instance.toast(
        'يرجى إدخال رقم الجوال وكلمة المرور',
        icon: Icons.warning,
        color: Colors.orange,
      );
      return;
    }
    
    setState(() => _loading = true);
    
    final ok = await AuthState.instance.login(
      phone: _phone.text,
      password: _password.text,
    );
    
    if (mounted) {
    setState(() => _loading = false);
    }
    
    if (ok && mounted) {
      // تحديث AuthState للتطبيق بالكامل
      Provider.of<AuthState>(context, listen: false).notifyListeners();
      
      NotificationsService.instance.toast(
        'تم تسجيل الدخول بنجاح',
        icon: Icons.check_circle,
        color: const Color(0xFF059669),
      );
      
      NotificationsService.instance.add(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'تسجيل الدخول',
          body: 'أهلًا بك من جديد في الدلما',
        ),
      );
      
      Navigator.pop(context);
    } else if (mounted) {
      NotificationsService.instance.toast(
        'تحقق من الرقم أو كلمة المرور',
        icon: Icons.error_outline,
        color: const Color(0xFFDC2626),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    final headerGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [ThemeConfig.kNightDeep, ThemeConfig.kNightSoft, ThemeConfig.kNightDeep]
          : [const Color(0xFFECFDF5), ThemeConfig.kBeige, const Color(0xFFF5F9ED)],
    );

    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
    return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: Stack(
            children: [
              // خلفية عليا متدرجة
              Container(
                height: 300,
                decoration: BoxDecoration(gradient: headerGradient),
              ),
              // المحتوى
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                        // زر الرجوع
                        Row(
                          children: [
                            _TopIcon(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            _TopIcon(
                              icon: theme.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                              onTap: () async => await ThemeConfig.instance.toggleTheme(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // العنوان والوصف
                        FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: _slide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // أيقونة الدلما
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isDark
                                        ? [ThemeConfig.kGoldNight.withOpacity(0.2), ThemeConfig.kGoldNight.withOpacity(0.05)]
                                        : [ThemeConfig.kGreen.withOpacity(0.2), ThemeConfig.kGreen.withOpacity(0.05)],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.eco_outlined,
                                    size: 48,
                                    color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'أهلاً بك في الدلما',
                                  style: GoogleFonts.cairo(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textPrimaryColor,
                                  ),
                                ),
            const SizedBox(height: 8),
                                Text(
                                  'سجّل دخولك للوصول إلى جميع الخدمات',
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    color: theme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // بطاقة النموذج
                        _GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // رقم الجوال
                              Text(
                                'رقم الجوال',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimaryColor,
                                  fontSize: 14,
                                ),
                              ),
            const SizedBox(height: 8),
                              _DalmaTextField(
              controller: _phone,
                                hintText: '05xxxxxxxx',
              keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_rounded,
                              ),
                              const SizedBox(height: 20),

                              // كلمة المرور
                              Text(
                                'كلمة المرور',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimaryColor,
                                  fontSize: 14,
                                ),
                              ),
            const SizedBox(height: 8),
                              _DalmaTextField(
              controller: _password,
                                hintText: '••••••••',
              obscureText: _obscure,
                                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: theme.textSecondaryColor,
                                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                              ),
                              const SizedBox(height: 12),

                              // نسيت كلمة المرور
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    NotificationsService.instance.toast('استعادة كلمة المرور قريباً');
                                  },
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: GoogleFonts.cairo(
                                      color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // زر تسجيل الدخول
                              _PrimaryGradientButton(
                                label: _loading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول',
                                onTap: _loading ? () {} : _submit,
                                loading: _loading,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // رابط إنشاء حساب
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupPage()),
                              );
                            },
                            icon: Icon(
                              Icons.person_add_outlined,
                              color: theme.textSecondaryColor,
                            ),
                            label: Text(
                              'ليس لديك حساب؟ أنشئ حساباً جديداً',
                              style: GoogleFonts.cairo(
                                color: theme.textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ========================
// Widgets & Styles
// ========================

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(.7),
          shape: BoxShape.circle,
          border: Border.all(color: theme.borderColor.withOpacity(.6)),
          boxShadow: theme.cardShadow,
        ),
        child: Icon(icon, color: theme.textPrimaryColor, size: 18),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderColor),
            boxShadow: theme.cardShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DalmaTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  const _DalmaTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    required this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.cairo(
        color: theme.textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.cairo(
          color: theme.textSecondaryColor.withOpacity(0.5),
        ),
        filled: true,
        fillColor: isDark 
          ? ThemeConfig.kNightAccent.withOpacity(.4) 
          : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  
  const _PrimaryGradientButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.instance.isDarkMode;
    final colors = isDark
        ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(.8)]
        : [ThemeConfig.kGreen, const Color(0xFF059669)];

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: isDark ? ThemeConfig.kNightDeep : Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login_rounded,
                      color: isDark ? ThemeConfig.kNightDeep : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.cairo(
                        color: isDark ? ThemeConfig.kNightDeep : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
