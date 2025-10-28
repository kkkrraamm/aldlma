import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'notifications.dart';
import 'theme_config.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  DateTime? _dob;
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
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final now = DateTime.now();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      helpText: 'اختر تاريخ الميلاد',
      confirmText: 'تم',
      cancelText: 'إلغاء',
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
              onPrimary: Colors.white,
              surface: theme.cardColor,
              onSurface: theme.textPrimaryColor,
            ),
            dialogBackgroundColor: theme.cardColor,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    
    // التحقق من البيانات
    if (_name.text.isEmpty) {
      NotificationsService.instance.toast(
        'يرجى إدخال الاسم',
        icon: Icons.warning,
        color: Colors.orange,
      );
      return;
    }
    
    if (_phone.text.isEmpty) {
      NotificationsService.instance.toast(
        'يرجى إدخال رقم الجوال',
        icon: Icons.warning,
        color: Colors.orange,
      );
      return;
    }
    
    if (_password.text.isEmpty) {
      NotificationsService.instance.toast(
        'يرجى إدخال كلمة المرور',
        icon: Icons.warning,
        color: Colors.orange,
      );
      return;
    }
    
    if (_dob == null) {
      NotificationsService.instance.toast(
        'يرجى اختيار تاريخ الميلاد',
        icon: Icons.warning,
        color: Colors.orange,
      );
      return;
    }
    
    setState(() => _loading = true);
    
    final ok = await AuthState.instance.signup(
      name: _name.text,
      dob: _dob!,
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
        'تم إنشاء الحساب وتسجيل الدخول بنجاح',
        icon: Icons.check_circle,
        color: const Color(0xFF059669),
      );
      
      NotificationsService.instance.add(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'حساب جديد',
          body: 'مرحبًا ${_name.text} في الدلما',
        ),
      );
      
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      NotificationsService.instance.toast(
        'تحقق من المدخلات أو الرقم مستخدم بالفعل',
        icon: Icons.error_outline,
        color: const Color(0xFFDC2626),
      );
    }
  }

  String _formatDob() {
    if (_dob == null) return 'اختر تاريخ الميلاد';
    return '${_dob!.day}/${_dob!.month}/${_dob!.year}';
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
                                    Icons.person_add_alt_1_rounded,
                                    size: 48,
                                    color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'مرحباً بك في الدلما',
                                  style: GoogleFonts.cairo(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textPrimaryColor,
                                  ),
                                ),
            const SizedBox(height: 8),
                                Text(
                                  'أنشئ حسابك لتستفيد من كامل الخدمات',
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
                              // الاسم
                              Text(
                                'الاسم الكامل',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimaryColor,
                                  fontSize: 14,
                                ),
                              ),
            const SizedBox(height: 8),
                              _DalmaTextField(
              controller: _name,
                                hintText: 'أحمد محمد',
                                keyboardType: TextInputType.name,
                                prefixIcon: Icons.person_rounded,
                              ),
                              const SizedBox(height: 20),

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
                              const SizedBox(height: 20),

                              // تاريخ الميلاد
                              Text(
                                'تاريخ الميلاد',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: theme.textPrimaryColor,
                                  fontSize: 14,
                                ),
                              ),
            const SizedBox(height: 8),
                              InkWell(
              onTap: _pickDob,
                                borderRadius: BorderRadius.circular(14),
              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                                    color: isDark 
                                      ? ThemeConfig.kNightAccent.withOpacity(.4) 
                                      : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _dob != null
                                        ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                                        : theme.borderColor.withOpacity(0.3),
                                      width: _dob != null ? 2 : 1,
                                    ),
                                  ),
                child: Row(
                  children: [
                                      Icon(
                                        Icons.cake_rounded,
                                        color: _dob != null
                                          ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                                          : theme.textSecondaryColor,
                                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                                          _formatDob(),
                                          style: GoogleFonts.cairo(
                                            color: _dob != null
                                              ? theme.textPrimaryColor
                                              : theme.textSecondaryColor.withOpacity(0.5),
                                            fontWeight: _dob != null ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: theme.textSecondaryColor,
                                      ),
                  ],
                ),
              ),
            ),
                              const SizedBox(height: 32),

                              // زر إنشاء الحساب
                              _PrimaryGradientButton(
                                label: _loading ? 'جاري إنشاء الحساب...' : 'إنشاء الحساب',
                                onTap: _loading ? () {} : _submit,
                                loading: _loading,
                                icon: Icons.person_add_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // رابط تسجيل الدخول
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.login_rounded,
                              color: theme.textSecondaryColor,
                            ),
                            label: Text(
                              'لديك حساب بالفعل؟ سجّل دخولك',
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
  final IconData icon;
  
  const _PrimaryGradientButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    required this.icon,
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
                      icon,
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
