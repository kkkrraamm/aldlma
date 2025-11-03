import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'theme_config.dart';
import 'notifications.dart';
import 'secure_api_service.dart';

class RequestMediaPage extends StatefulWidget {
  const RequestMediaPage({Key? key}) : super(key: key);

  @override
  _RequestMediaPageState createState() => _RequestMediaPageState();
}

class _RequestMediaPageState extends State<RequestMediaPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _socialMediaController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  
  late AnimationController _fadeCtrl, _slideCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  
  bool _isLoading = false;
  bool _wantsVerification = false;
  File? _idImage;
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedContentType;
  final List<String> _contentTypes = [
    'فيديوهات تعليمية',
    'صور فوتوغرافية',
    'مقاطع كوميدية',
    'محتوى طهي',
    'رياضة ولياقة',
    'تقنية وبرمجة',
    'فنون وتصميم',
    'سفر وسياحة',
    'أخرى',
  ];

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
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    if (phone != null && mounted) {
      setState(() => _whatsappController.text = phone);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _bioController.dispose();
    _socialMediaController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickIdImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _idImage = File(pickedFile.path);
        });
        NotificationsService.instance.toast('تم اختيار الصورة بنجاح ✅');
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل اختيار الصورة', icon: Icons.error, color: Colors.red);
    }
  }

  Future<void> _submitRequest() async {
    print('\n📺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📺 ${DateTime.now()} بدء عملية إرسال طلب إعلامي');
    print('📺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // التحقق من الحقول
    print('📺 الخطوة 1: التحقق من الحقول...');
    if (!_formKey.currentState!.validate()) {
      print('❌ [MEDIA REQUEST] فشل التحقق: حقول ناقصة');
      NotificationsService.instance.toast('يرجى ملء جميع الحقول المطلوبة', icon: Icons.warning, color: Colors.orange);
      return;
    }
    print('✅ [MEDIA REQUEST] التحقق من الحقول نجح\n');

    // التحقق من نوع المحتوى
    if (_selectedContentType == null || _selectedContentType!.isEmpty) {
      print('❌ [MEDIA REQUEST] فشل: نوع المحتوى غير محدد');
      NotificationsService.instance.toast('يرجى اختيار نوع المحتوى', icon: Icons.warning, color: Colors.orange);
      return;
    }

    // التحقق من صورة الهوية
    if (_wantsVerification && _idImage == null) {
      print('❌ [MEDIA REQUEST] فشل: صورة الهوية مطلوبة للتوثيق');
      NotificationsService.instance.toast('يرجى إرفاق صورة الهوية للتوثيق', icon: Icons.warning, color: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // جلب التوكن
      print('📺 الخطوة 2: جلب Token...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('❌ [MEDIA REQUEST] فشل: المستخدم غير مسجل الدخول');
        NotificationsService.instance.toast('يجب تسجيل الدخول أولاً', icon: Icons.error, color: Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      print('✅ [MEDIA REQUEST] Token موجود\n');

      // رفع صورة الهوية عبر Backend API (إذا كانت موجودة)
      String? idImageUrl;
      if (_idImage != null) {
        print('📺 الخطوة 3: رفع صورة الهوية عبر Backend API...');
        print('   📂 حجم الملف: ${(_idImage!.lengthSync() / 1024).toStringAsFixed(2)} KB');
        print('   📂 المسار: ${_idImage!.path}');
        
        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse('https://dalma-api.onrender.com/api/upload-image'),
        )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(await http.MultipartFile.fromPath('image', _idImage!.path));
        
        print('   📤 إرسال إلى Backend API...');
        final streamedResponse = await uploadRequest.send();
        final uploadResponse = await http.Response.fromStream(streamedResponse);
        
        print('   📊 استجابة Upload API: ${uploadResponse.statusCode}');
        
        if (uploadResponse.statusCode == 200) {
          final data = json.decode(uploadResponse.body);
          idImageUrl = data['url'];
          print('   ✅ تم رفع الصورة بنجاح!');
          print('   🔗 URL: $idImageUrl\n');
        } else {
          print('   ❌ فشل رفع الصورة: ${uploadResponse.statusCode}');
          print('   📄 Response: ${uploadResponse.body}\n');
        }
      } else {
        print('📺 الخطوة 3: تخطي رفع صورة الهوية (غير مطلوبة)\n');
      }

      // إعداد البيانات
      print('📺 الخطوة 4: إعداد بيانات الطلب...');
      final requestData = {
        'bio': _bioController.text,
        'social_media': _socialMediaController.text,
        'content_type': _selectedContentType ?? 'أخرى',
        'whatsapp': _whatsappController.text,
        'email': _emailController.text,
        'wants_verification': _wantsVerification,
        'id_image_url': idImageUrl,
      };
      print('   📋 البيانات:');
      print('      - نبذة عنك: "${_bioController.text}" (طول: ${_bioController.text.length})');
      print('      - حسابات التواصل: "${_socialMediaController.text}"');
      print('      - نوع المحتوى: "$_selectedContentType"');
      print('      - واتساب: "${_whatsappController.text}"');
      print('      - البريد: "${_emailController.text}"');
      print('      - التوثيق: $_wantsVerification');
      print('      - صورة الهوية: ${idImageUrl != null ? "✅ موجودة" : "❌ غير موجودة"}\n');

      // إرسال الطلب إلى API
      print('📺 الخطوة 5: إرسال الطلب إلى API...');
      print('   🌐 URL: https://dalma-api.onrender.com/api/media-request');
      print('   📤 إرسال...');
      
      final response = await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/media-request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('   📊 استجابة API: ${response.statusCode}');
      print('   📄 Response Body: ${response.body}\n');

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ نجح! تم إرسال طلب الإعلامي بنجاح!');
        print('   📋 رقم الطلب: ${responseData['request']?['id']}');
        print('   ⏳ الحالة: ${responseData['request']?['status']}');
        print('   📅 تاريخ الإنشاء: ${responseData['request']?['created_at']}');
        print('✅━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        NotificationsService.instance.toast('تم إرسال طلبك بنجاح! 🎉', icon: Icons.check_circle, color: Colors.green);
        Navigator.pop(context, true); // إرجاع true للإشارة إلى نجاح الإرسال
      } else {
        print('❌━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ فشل إرسال الطلب!');
        print('   📊 Status Code: ${response.statusCode}');
        print('   📄 Response: ${response.body}');
        print('❌━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        NotificationsService.instance.toast('حدث خطأ، حاول مرة أخرى', icon: Icons.error, color: Colors.red);
      }
    } catch (e, stackTrace) {
      print('❌━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ خطأ في إرسال الطلب!');
      print('   🔴 Error: $e');
      print('   📍 Stack Trace: $stackTrace');
      print('❌━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      NotificationsService.instance.toast('حدث خطأ: $e', icon: Icons.error, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final theme = ThemeConfig.instance;
        final isDark = theme.isDarkMode;

        final headerGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [ThemeConfig.kNightDeep, ThemeConfig.kNightSoft, ThemeConfig.kNightDeep]
              : [const Color(0xFFECFDF5), ThemeConfig.kBeige, const Color(0xFFF5F9ED)],
        );

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: Stack(
            children: [
              // خلفية عليا متدرجة
              Container(
                height: 280,
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
                                    Icons.campaign_rounded,
                                    size: 48,
                                    color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'طلب أن تكون إعلامياً',
                                  style: GoogleFonts.cairo(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'انضم إلى مجتمع الإعلاميين في الدلما وشارك محتواك',
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // نبذة عنك
                                _FieldLabel('نبذة عنك * (على الأقل 50 حرف)'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _bioController,
                                  hintText: 'أخبرنا عن نفسك وخبراتك بالتفصيل...',
                                  maxLines: 3,
                                  prefixIcon: Icons.description_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'النبذة مطلوبة';
                                    }
                                    if (v.trim().length < 50) {
                                      return 'النبذة قصيرة جداً (${v.trim().length}/50 حرف)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // حسابات التواصل الاجتماعي
                                _FieldLabel('حسابات التواصل الاجتماعي *'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _socialMediaController,
                                  hintText: '@username أو https://...',
                                  prefixIcon: Icons.share_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'حساب التواصل مطلوب';
                                    }
                                    final trimmed = v.trim();
                                    // يجب أن يبدأ بـ @ أو http أو يحتوي على نقطة (مثل instagram.com/username)
                                    if (!trimmed.startsWith('@') && 
                                        !trimmed.startsWith('http') && 
                                        !trimmed.contains('.')) {
                                      return 'أدخل @username أو رابط صحيح';
                                    }
                                    if (trimmed.length < 5) {
                                      return 'الحساب قصير جداً';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // نوع المحتوى
                                _FieldLabel('نوع المحتوى *'),
                                const SizedBox(height: 8),
                                _DalmaDropdown(
                                  value: _selectedContentType,
                                  items: _contentTypes,
                                  hint: 'اختر نوع المحتوى',
                                  onChanged: (v) => setState(() => _selectedContentType = v),
                                ),
                                const SizedBox(height: 20),

                                // واتساب
                                _FieldLabel('رقم واتساب * (سعودي)'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _whatsappController,
                                  hintText: '05xxxxxxxx',
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: Icons.phone_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'رقم الواتساب مطلوب';
                                    }
                                    final phone = v.trim().replaceAll(' ', '').replaceAll('-', '');
                                    // رقم سعودي: يبدأ بـ 05 ويتكون من 10 أرقام
                                    if (!RegExp(r'^05\d{8}$').hasMatch(phone)) {
                                      return 'أدخل رقم سعودي صحيح (05xxxxxxxx)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // البريد الإلكتروني
                                _FieldLabel('البريد الإلكتروني (اختياري)'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _emailController,
                                  hintText: 'example@email.com',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_rounded,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return null; // اختياري
                                    }
                                    // التحقق من صيغة البريد الإلكتروني
                                    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(v.trim())) {
                                      return 'أدخل بريد إلكتروني صحيح';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // التوثيق
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'التوثيق',
                                                  style: GoogleFonts.cairo(
                                                    color: theme.textPrimaryColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'احصل على شارة التوثيق الرسمية',
                                                  style: GoogleFonts.cairo(
                                                    color: theme.textSecondaryColor,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: _wantsVerification,
                                            activeColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                            onChanged: (v) => setState(() => _wantsVerification = v),
                                          ),
                                        ],
                                      ),
                                      if (_wantsVerification) ...[
                                        const SizedBox(height: 16),
                                        _ImageUploadBox(
                                          image: _idImage,
                                          onTap: _pickIdImage,
                                          label: 'إرفاق صورة الهوية',
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // زر الإرسال
                                _PrimaryGradientButton(
                                  label: _isLoading ? 'جاري الإرسال...' : 'إرسال الطلب',
                                  onTap: _isLoading ? () {} : _submitRequest,
                                  loading: _isLoading,
                                  icon: Icons.send_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.w700,
        color: ThemeConfig.instance.textPrimaryColor,
        fontSize: 14,
      ),
    );
  }
}

class _DalmaTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData prefixIcon;
  final String? Function(String?)? validator;

  const _DalmaTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    required this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _DalmaDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _DalmaDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark 
          ? ThemeConfig.kNightAccent.withOpacity(.4) 
          : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.cairo(
              color: theme.textSecondaryColor.withOpacity(0.5),
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
          ),
          dropdownColor: theme.cardColor,
          style: GoogleFonts.cairo(
            color: theme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final String label;

  const _ImageUploadBox({
    required this.image,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark 
            ? ThemeConfig.kNightAccent.withOpacity(.4) 
            : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: image != null
              ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
              : theme.borderColor.withOpacity(0.3),
            width: image != null ? 2 : 1,
          ),
        ),
        child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                image!,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_rounded,
                  size: 40,
                  color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: theme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
