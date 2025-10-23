import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'theme_config.dart';
import 'notifications.dart';
import 'secure_api_service.dart';

class RequestProviderPage extends StatefulWidget {
  const RequestProviderPage({Key? key}) : super(key: key);

  @override
  _RequestProviderPageState createState() => _RequestProviderPageState();
}

class _RequestProviderPageState extends State<RequestProviderPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  
  late AnimationController _fadeCtrl, _slideCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  
  bool _isLoading = false;
  bool _hasCommercialLicense = false;
  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedCategory;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'مطاعم', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'صيانة', 'icon': Icons.build, 'color': Colors.blue},
    {'name': 'تنظيف', 'icon': Icons.cleaning_services, 'color': Colors.green},
    {'name': 'تصميم', 'icon': Icons.palette, 'color': Colors.purple},
    {'name': 'نقل', 'icon': Icons.local_shipping, 'color': Colors.brown},
    {'name': 'تعليم', 'icon': Icons.school, 'color': Colors.indigo},
    {'name': 'صحة ورياضة', 'icon': Icons.fitness_center, 'color': Colors.red},
    {'name': 'تجميل', 'icon': Icons.face, 'color': Colors.pink},
    {'name': 'تقنية', 'icon': Icons.computer, 'color': Colors.teal},
    {'name': 'أخرى', 'icon': Icons.more_horiz, 'color': Colors.grey},
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
    _businessNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _licenseImage = File(pickedFile.path);
        });
        NotificationsService.instance.toast('تم اختيار الصورة بنجاح ✅');
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل اختيار الصورة', icon: Icons.error, color: Colors.red);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        NotificationsService.instance.toast('خدمة الموقع غير مفعلة', icon: Icons.warning, color: Colors.orange);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          NotificationsService.instance.toast('تم رفض إذن الموقع', icon: Icons.error, color: Colors.red);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationController.text = '${position.latitude}, ${position.longitude}';
      });
      NotificationsService.instance.toast('تم تحديد الموقع بنجاح 📍');
    } catch (e) {
      NotificationsService.instance.toast('فشل تحديد الموقع', icon: Icons.error, color: Colors.red);
    }
  }

  Future<void> _submitRequest() async {
    print('\n🏪━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏪 ${DateTime.now()} بدء عملية إرسال طلب مقدم خدمة');
    print('🏪━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // التحقق من الحقول
    print('🏪 الخطوة 1: التحقق من الحقول...');
    if (!_formKey.currentState!.validate()) {
      print('❌ [PROVIDER REQUEST] فشل التحقق: حقول ناقصة');
      NotificationsService.instance.toast('يرجى ملء جميع الحقول المطلوبة', icon: Icons.warning, color: Colors.orange);
      return;
    }
    print('✅ [PROVIDER REQUEST] التحقق من الحقول نجح');

    if (_selectedCategory == null) {
      print('❌ [PROVIDER REQUEST] فشل: الفئة غير محددة');
      NotificationsService.instance.toast('يرجى اختيار الفئة', icon: Icons.warning, color: Colors.orange);
      return;
    }
    print('✅ [PROVIDER REQUEST] الفئة محددة: $_selectedCategory\n');

    if (_hasCommercialLicense && _licenseImage == null) {
      print('❌ [PROVIDER REQUEST] فشل: صورة السجل التجاري مطلوبة');
      NotificationsService.instance.toast('يرجى إرفاق صورة السجل التجاري', icon: Icons.warning, color: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // جلب التوكن
      print('🏪 الخطوة 2: جلب Token...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('❌ [PROVIDER REQUEST] فشل: المستخدم غير مسجل الدخول');
        NotificationsService.instance.toast('يجب تسجيل الدخول أولاً', icon: Icons.error, color: Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      print('✅ [PROVIDER REQUEST] Token موجود\n');

      // رفع صورة السجل عبر Backend API (إذا كانت موجودة)
      String? licenseImageUrl;
      if (_licenseImage != null) {
        print('🏪 الخطوة 3: رفع صورة السجل التجاري عبر Backend API...');
        print('   📂 حجم الملف: ${(_licenseImage!.lengthSync() / 1024).toStringAsFixed(2)} KB');
        print('   📂 المسار: ${_licenseImage!.path}');
        
        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse('https://dalma-api.onrender.com/api/upload-image'),
        )
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(await http.MultipartFile.fromPath('image', _licenseImage!.path));
        
        print('   📤 إرسال إلى Backend API...');
        final streamedResponse = await uploadRequest.send();
        final uploadResponse = await http.Response.fromStream(streamedResponse);
        
        print('   📊 استجابة Upload API: ${uploadResponse.statusCode}');
        
        if (uploadResponse.statusCode == 200) {
          final data = json.decode(uploadResponse.body);
          licenseImageUrl = data['url'];
          print('   ✅ تم رفع الصورة بنجاح!');
          print('   🔗 URL: $licenseImageUrl\n');
        } else {
          print('   ❌ فشل رفع الصورة: ${uploadResponse.statusCode}');
          print('   📄 Response: ${uploadResponse.body}\n');
        }
      } else {
        print('🏪 الخطوة 3: تخطي رفع صورة السجل (غير موجودة)\n');
      }

      // إعداد البيانات
      print('🏪 الخطوة 4: إعداد بيانات الطلب...');
      final requestData = {
        'business_name': _businessNameController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'location': _locationController.text,
        'whatsapp': _whatsappController.text,
        'email': _emailController.text,
        'has_commercial_license': _hasCommercialLicense,
        'license_number': _licenseNumberController.text,
        'license_image_url': licenseImageUrl,
      };
      print('   📋 البيانات:');
      print('      - اسم النشاط: ${_businessNameController.text}');
      print('      - الوصف: ${_descriptionController.text.substring(0, _descriptionController.text.length > 30 ? 30 : _descriptionController.text.length)}...');
      print('      - الفئة: $_selectedCategory');
      print('      - الموقع: ${_locationController.text}');
      print('      - واتساب: ${_whatsappController.text}');
      print('      - سجل تجاري: $_hasCommercialLicense');
      print('      - رقم السجل: ${_licenseNumberController.text}');
      print('      - صورة السجل: ${licenseImageUrl != null ? "✅ موجودة" : "❌ غير موجودة"}\n');

      // إرسال الطلب إلى API
      print('🏪 الخطوة 5: إرسال الطلب إلى API...');
      print('   🌐 URL: https://dalma-api.onrender.com/api/provider-request');
      print('   📤 إرسال...');
      
      final response = await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/provider-request'),
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
        print('✅ نجح! تم إرسال طلب مقدم الخدمة بنجاح!');
        print('   📋 رقم الطلب: ${responseData['request']?['id']}');
        print('   ⏳ الحالة: ${responseData['request']?['status']}');
        print('   📅 تاريخ الإنشاء: ${responseData['request']?['created_at']}');
        print('✅━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        NotificationsService.instance.toast('تم إرسال طلبك بنجاح! 🎉', icon: Icons.check_circle, color: Colors.green);
        Navigator.pop(context);
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
                                    Icons.store_mall_directory_rounded,
                                    size: 48,
                                    color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'طلب مقدم خدمة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: theme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'انضم إلى شبكة مقدمي الخدمات واعرض خدماتك',
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
                                // اسم النشاط
                                _FieldLabel('اسم النشاط التجاري *'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _businessNameController,
                                  hintText: 'مثال: مطعم الدلما',
                                  prefixIcon: Icons.business_rounded,
                                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 20),

                                // الوصف
                                _FieldLabel('وصف الخدمة *'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _descriptionController,
                                  hintText: 'اكتب وصفاً تفصيلياً للخدمات التي تقدمها...',
                                  maxLines: 3,
                                  prefixIcon: Icons.description_rounded,
                                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 20),

                                // الفئة
                                _FieldLabel('الفئة *'),
                                const SizedBox(height: 8),
                                _CategoryGrid(
                                  categories: _categories,
                                  selectedCategory: _selectedCategory,
                                  onSelect: (v) => setState(() => _selectedCategory = v),
                                ),
                                const SizedBox(height: 20),

                                // الموقع
                                _FieldLabel('الموقع *'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DalmaTextField(
                                        controller: _locationController,
                                        hintText: 'عرعر، شارع...',
                                        prefixIcon: Icons.location_on_rounded,
                                        validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _IconButton(
                                      icon: Icons.my_location_rounded,
                                      onTap: _getCurrentLocation,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // واتساب
                                _FieldLabel('رقم واتساب *'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _whatsappController,
                                  hintText: '05xxxxxxxx',
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: Icons.phone_rounded,
                                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                                ),
                                const SizedBox(height: 20),

                                // البريد الإلكتروني
                                _FieldLabel('البريد الإلكتروني'),
                                const SizedBox(height: 8),
                                _DalmaTextField(
                                  controller: _emailController,
                                  hintText: 'example@email.com',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_rounded,
                                ),
                                const SizedBox(height: 24),

                                // السجل التجاري
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
                                            Icons.assignment_rounded,
                                            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'السجل التجاري',
                                                  style: GoogleFonts.cairo(
                                                    color: theme.textPrimaryColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  'لدي سجل تجاري رسمي',
                                                  style: GoogleFonts.cairo(
                                                    color: theme.textSecondaryColor,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Switch(
                                            value: _hasCommercialLicense,
                                            activeColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                            onChanged: (v) => setState(() => _hasCommercialLicense = v),
                                          ),
                                        ],
                                      ),
                                      if (_hasCommercialLicense) ...[
                                        const SizedBox(height: 16),
                                        _DalmaTextField(
                                          controller: _licenseNumberController,
                                          hintText: 'رقم السجل التجاري',
                                          prefixIcon: Icons.numbers_rounded,
                                        ),
                                        const SizedBox(height: 12),
                                        _ImageUploadBox(
                                          image: _licenseImage,
                                          onTap: _pickLicenseImage,
                                          label: 'إرفاق صورة السجل التجاري',
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
        ),
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

class _CategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategory;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selectedCategory == cat['name'];
        return InkWell(
          onTap: () => onSelect(cat['name']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.15)
                : (isDark ? ThemeConfig.kNightAccent : Colors.grey[50]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                  ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                  : theme.borderColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat['icon'],
                  size: 18,
                  color: isSelected
                    ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                    : theme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  cat['name'],
                  style: GoogleFonts.cairo(
                    color: isSelected ? theme.textPrimaryColor : theme.textSecondaryColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
