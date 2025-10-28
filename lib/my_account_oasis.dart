// lib/my_account_oasis.dart
// Dalma Oasis – My Account page (Luxury, Glass, Dynamic Theme)
// بيانات حقيقية من API + تكامل كامل
// by Abdulkarim ✨

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';
import 'auth.dart';
import 'request_media_page.dart';
import 'request_provider_page.dart';

class DalmaMyAccountOasis extends StatefulWidget {
  const DalmaMyAccountOasis({super.key});

  @override
  State<DalmaMyAccountOasis> createState() => _DalmaMyAccountOasisState();
}

class _DalmaMyAccountOasisState extends State<DalmaMyAccountOasis>
    with TickerProviderStateMixin {
  
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _devices = [];
  String? _token;
  final String _baseUrl = 'https://dalma-api.onrender.com';
  
  // حالة الطلبات
  Map<String, dynamic>? _mediaRequest;
  Map<String, dynamic>? _providerRequest;
  bool _loadingRequests = false;

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
    
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // تحديث البيانات عندما تتغير حالة AuthState
    final authState = Provider.of<AuthState>(context, listen: false);
    
    // إذا تم تسجيل الخروج من صفحة أخرى
    if (!authState.isLoggedIn && _token != null) {
      print('🚪 [MY_ACCOUNT_OASIS] تم اكتشاف تسجيل خروج من صفحة أخرى - تحديث الصفحة...');
      setState(() {
        _token = null;
        _userProfile = null;
        _devices = [];
        _mediaRequest = null;
        _providerRequest = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }
    
    // إذا تم تسجيل الدخول من صفحة أخرى
    if (authState.isLoggedIn && _token == null && !_isLoading) {
      print('🔄 [MY_ACCOUNT_OASIS] تم اكتشاف تسجيل دخول جديد - تحديث البيانات...');
      _loadUserProfile();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile({int retryCount = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      print('🔄 [MY_ACCOUNT_OASIS] محاولة تحميل البيانات (محاولة ${retryCount + 1}/3)...');

      // جلب بيانات المستخدم مع timeout أطول
      final response = await http.get(
        Uri.parse('$_baseUrl/api/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30), // timeout أطول للسماح لـ Render بالاستيقاظ
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال - Server قد يكون في وضع Sleep');
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        
        // الأجهزة المتصلة موجودة في userData.devices
        List<Map<String, dynamic>> devicesList = [];
        if (userData['devices'] != null) {
          devicesList = List<Map<String, dynamic>>.from(userData['devices']);
        }

        if (mounted) {
          setState(() {
            _userProfile = userData;
            _devices = devicesList;
            _isLoading = false;
            _hasError = false;
          });
          
          print('✅ [MY_ACCOUNT_OASIS] تم تحميل البيانات:');
          print('   - الاسم: ${userData['name']}');
          print('   - الصورة: ${userData['profile_image']}');
          print('   - عدد الأجهزة: ${devicesList.length}');
          
          // تشغيل الأنيميشن
          _fadeCtrl.forward();
          _slideCtrl.forward();
          
          // جلب حالة الطلبات
          _loadRequestsStatus();
        }
      } else {
        // إعادة المحاولة في حالة الخطأ
        if (retryCount < 2) {
          print('⚠️ [MY_ACCOUNT_OASIS] فشل التحميل، إعادة المحاولة بعد ${(retryCount + 1) * 2} ثانية...');
          await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
          return _loadUserProfile(retryCount: retryCount + 1);
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      
      // إعادة المحاولة في حالة الخطأ
      if (retryCount < 2) {
        print('⚠️ [MY_ACCOUNT_OASIS] فشل التحميل، إعادة المحاولة بعد ${(retryCount + 1) * 2} ثانية...');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return _loadUserProfile(retryCount: retryCount + 1);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatLastLogin(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
        return 'منذ ${diff.inMinutes} دقيقة';
      } else if (diff.inHours < 24) {
        return 'منذ ${diff.inHours} ساعة';
      } else if (diff.inDays == 1) {
        return 'أمس ${DateFormat('hh:mm a').format(date)}';
      } else if (diff.inDays < 7) {
        return 'منذ ${diff.inDays} أيام';
      } else {
        return DateFormat('dd/MM/yyyy hh:mm a').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'media':
        return 'إعلامي';
      case 'provider':
        return 'مقدم خدمة';
      default:
        return 'مستخدم';
    }
  }

  Future<void> _loadRequestsStatus() async {
    if (_token == null) return;
    
    setState(() => _loadingRequests = true);
    
    try {
      print('\n📋 [REQUESTS] جلب حالة الطلبات...');
      
      // جلب حالة طلب الإعلامي
      final mediaResponse = await http.get(
        Uri.parse('$_baseUrl/api/media-request/status'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      // جلب حالة طلب مقدم الخدمة
      final providerResponse = await http.get(
        Uri.parse('$_baseUrl/api/provider-request/status'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      if (mounted) {
        Map<String, dynamic>? mediaReq;
        Map<String, dynamic>? providerReq;
        
        if (mediaResponse.statusCode == 200) {
          final data = json.decode(mediaResponse.body);
          if (data['hasRequest'] == true) {
            mediaReq = data['request'];
            print('✅ [REQUESTS] طلب إعلامي: ${mediaReq?['status']}');
          }
        }
        
        if (providerResponse.statusCode == 200) {
          final data = json.decode(providerResponse.body);
          if (data['hasRequest'] == true) {
            providerReq = data['request'];
            print('✅ [REQUESTS] طلب مقدم خدمة: ${providerReq?['status']}');
          }
        }
        
        setState(() {
          _mediaRequest = mediaReq;
          _providerRequest = providerReq;
          _loadingRequests = false;
        });
      }
    } catch (e) {
      print('❌ [REQUESTS] خطأ في جلب الطلبات: $e');
      if (mounted) {
        setState(() => _loadingRequests = false);
      }
    }
  }

  bool _hasIdImage(Map<String, dynamic> request) {
    try {
      final experience = json.decode(request['experience'] ?? '{}');
      return experience['id_image_url'] != null && experience['id_image_url'] != '';
    } catch (e) {
      return false;
    }
  }

  bool _hasLicenseImage(Map<String, dynamic> request) {
    try {
      final extraData = json.decode(request['location_address'] ?? '{}');
      return extraData['license_image_url'] != null && extraData['license_image_url'] != '';
    } catch (e) {
      return false;
    }
  }

  Future<void> _uploadIdImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;
      
      NotificationsService.instance.toast('جاري رفع الصورة...', icon: Icons.upload);
      
      // رفع الصورة
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/upload-image'),
      )
        ..headers['Authorization'] = 'Bearer $_token'
        ..files.add(await http.MultipartFile.fromPath('image', pickedFile.path));
      
      final streamedResponse = await uploadRequest.send();
      final uploadResponse = await http.Response.fromStream(streamedResponse);
      
      if (uploadResponse.statusCode == 200) {
        final data = json.decode(uploadResponse.body);
        final imageUrl = data['url'];
        
        // تحديث الطلب بصورة الهوية
        final response = await http.post(
          Uri.parse('$_baseUrl/api/media-request/upload-id'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'id_image_url': imageUrl}),
        );
        
        if (response.statusCode == 200) {
          NotificationsService.instance.toast('تم رفع صورة الهوية بنجاح! ✅', icon: Icons.check_circle, color: Colors.green);
          _loadRequestsStatus(); // إعادة تحميل الطلبات
        } else {
          NotificationsService.instance.toast('فشل في تحديث الطلب', icon: Icons.error, color: Colors.red);
        }
      } else {
        NotificationsService.instance.toast('فشل في رفع الصورة', icon: Icons.error, color: Colors.red);
      }
    } catch (e) {
      NotificationsService.instance.toast('حدث خطأ: $e', icon: Icons.error, color: Colors.red);
    }
  }

  Future<void> _uploadLicenseImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;
      
      NotificationsService.instance.toast('جاري رفع الصورة...', icon: Icons.upload);
      
      // رفع الصورة
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/upload-image'),
      )
        ..headers['Authorization'] = 'Bearer $_token'
        ..files.add(await http.MultipartFile.fromPath('image', pickedFile.path));
      
      final streamedResponse = await uploadRequest.send();
      final uploadResponse = await http.Response.fromStream(streamedResponse);
      
      if (uploadResponse.statusCode == 200) {
        final data = json.decode(uploadResponse.body);
        final imageUrl = data['url'];
        
        // تحديث الطلب بصورة السجل
        final response = await http.post(
          Uri.parse('$_baseUrl/api/provider-request/upload-license'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'license_image_url': imageUrl}),
        );
        
        if (response.statusCode == 200) {
          NotificationsService.instance.toast('تم رفع صورة السجل بنجاح! ✅', icon: Icons.check_circle, color: Colors.green);
          _loadRequestsStatus(); // إعادة تحميل الطلبات
        } else {
          NotificationsService.instance.toast('فشل في تحديث الطلب', icon: Icons.error, color: Colors.red);
        }
      } else {
        NotificationsService.instance.toast('فشل في رفع الصورة', icon: Icons.error, color: Colors.red);
      }
    } catch (e) {
      NotificationsService.instance.toast('حدث خطأ: $e', icon: Icons.error, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    // حالة التحميل
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
              ),
              const SizedBox(height: 24),
              Text(
                'جاري تحميل البيانات...',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: theme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'قد يستغرق الأمر بضع ثوانٍ',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: theme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // حالة عدم تسجيل الدخول
    if (_token == null) {
      return _NotLoggedInScreen();
    }

    // حالة الخطأ
    if (_hasError || _userProfile == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل البيانات',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: theme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUserProfile,
                icon: const Icon(Icons.refresh),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // البيانات الحقيقية
    final name = _userProfile!['name'] ?? 'مستخدم';
    final phone = _userProfile!['phone'] ?? '';
    final role = _userProfile!['role'] ?? 'user';
    final roleLabel = _getRoleLabel(role);
    final isActive = _userProfile!['is_active'] ?? true;
    final birthDate = _formatDate(_userProfile!['birth_date']);
    final joinedAt = _formatDate(_userProfile!['created_at']);
    final avatarUrl = _userProfile!['profile_image'] ?? _userProfile!['avatar_url'];
    final devicesCount = _userProfile!['connected_devices'] ?? _devices.length;

    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
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
                height: 340,
                decoration: BoxDecoration(gradient: headerGradient),
              ),
              // المحتوى
              SafeArea(
                child: RefreshIndicator(
                  color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                  backgroundColor: theme.cardColor,
                  onRefresh: () async {
                    print('🔄 [MY_ACCOUNT_OASIS] تحديث البيانات يدوياً...');
                    await _loadUserProfile();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // شريط الأزرار العلوي
                      SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            _TopIcon(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.maybePop(context),
                            ),
                            const Spacer(),
                            _TopIcon(
                              icon: Icons.notifications_none_rounded,
                              onTap: () => NotificationsService.instance.toast('التنبيهات قريبًا 🔔'),
                            ),
                            const SizedBox(width: 8),
                            _TopIcon(
                              icon: theme.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                              onTap: () async => await ThemeConfig.instance.toggleTheme(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // الرأس: صورة، اسم، رقم، شارة الحالة
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                            child: _GlassCard(
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                              child: Column(
                                children: [
                                  // صورة شخصية + زر تغيير
                                  Stack(
                                    children: [
                                      _AvatarGlow(
                                        child: _AvatarCircle(
                                          imageUrl: avatarUrl,
                                          label: name,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: _RoundMini(
                                          icon: Icons.add_a_photo_rounded,
                                          onTap: _onChangeAvatar,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      color: theme.textPrimaryColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phone,
                                    style: GoogleFonts.cairo(
                                      color: theme.textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _RoleBadge(text: roleLabel),
                                      const SizedBox(width: 8),
                                      _StatusDot(active: isActive),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // بطاقات المعلومات الأساسية
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionCard(
                          title: 'معلومات الحساب',
                          icon: Icons.account_circle_outlined,
                          child: Column(
                            children: [
                              _InfoTile(
                                icon: Icons.phone_rounded,
                                title: 'رقم الجوال',
                                value: phone,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.cake_rounded,
                                title: 'تاريخ الميلاد',
                                value: birthDate,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.event_available_rounded,
                                title: 'تاريخ الانضمام',
                                value: joinedAt,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.devices_other_rounded,
                                title: 'الأجهزة المتصلة',
                                value: '$devicesCount ${devicesCount == 1 ? "جهاز" : "أجهزة"}',
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                onTap: _showDevicesSheet,
                              ),
                              _DividerLine(),
                              _InfoTile(
                                icon: Icons.verified_user_rounded,
                                title: 'حالة الحساب',
                                value: isActive ? 'نشط' : 'مجمّد',
                                valueColor: isActive
                                    ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                                    : Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // شريط إجراءات مصغّرة (4)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MiniAction(
                                icon: theme.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                                label: theme.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
                                onTap: () async => await ThemeConfig.instance.toggleTheme(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniAction(
                                icon: Icons.edit_rounded,
                                label: 'تعديل الملف',
                                onTap: () => NotificationsService.instance.toast('صفحة تعديل الملف قريبًا ✏️'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniAction(
                                icon: Icons.campaign_rounded,
                                label: 'طلب إعلامي',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RequestMediaPage()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _MiniAction(
                                icon: Icons.store_mall_directory_rounded,
                                label: 'مقدم خدمة',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RequestProviderPage()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // قسم حالة الطلبات
                    if (_mediaRequest != null || _providerRequest != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: _GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_rounded,
                                      color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'طلباتي',
                                      style: GoogleFonts.cairo(
                                        color: theme.textPrimaryColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_loadingRequests)
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                        ),
                                      )
                                    else
                                      IconButton(
                                        icon: Icon(Icons.refresh_rounded, size: 18),
                                        onPressed: _loadRequestsStatus,
                                        color: theme.textSecondaryColor,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_mediaRequest != null) ...[
                                  _RequestStatusTile(
                                    icon: Icons.campaign_rounded,
                                    title: 'طلب إعلامي',
                                    status: _mediaRequest!['status'],
                                    date: _formatDate(_mediaRequest!['created_at']),
                                    onUploadId: _hasIdImage(_mediaRequest!) ? null : () => _uploadIdImage(),
                                  ),
                                  if (_providerRequest != null) _DividerLine(),
                                ],
                                if (_providerRequest != null)
                                  _RequestStatusTile(
                                    icon: Icons.store_mall_directory_rounded,
                                    title: 'طلب مقدم خدمة',
                                    status: _providerRequest!['status'],
                                    date: _formatDate(_providerRequest!['created_at']),
                                    onUploadLicense: _hasLicenseImage(_providerRequest!) ? null : () => _uploadLicenseImage(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // الإجراءات السريعة
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _SectionCard(
                          title: 'إجراءات سريعة',
                          icon: Icons.bolt_rounded,
                          child: Column(
                            children: [
                              _ActionRow(
                                icon: Icons.lock_reset_rounded,
                                label: 'تغيير كلمة المرور',
                                onTap: _showChangePasswordDialog,
                              ),
                              _ActionRow(
                                icon: Icons.download_rounded,
                                label: 'تصدير بياناتي',
                                onTap: () => NotificationsService.instance.toast('سيتم تصدير بياناتك JSON'),
                              ),
                              _ActionRow(
                                icon: Icons.privacy_tip_outlined,
                                label: 'إعدادات الخصوصية',
                                onTap: () => NotificationsService.instance.toast('الخصوصية قريبًا'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // زر تسجيل الخروج
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: _PrimaryGradientButton(
                          label: 'تسجيل الخروج',
                          danger: true,
                          onTap: _confirmLogout,
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================
  // الإجراءات (Handlers)
  // ========================

  Future<void> _onChangeAvatar() async {
    final theme = ThemeConfig.instance;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _GlassSheet(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Grip(),
                const SizedBox(height: 16),
                Text(
                  'تغيير الصورة الشخصية',
                  style: GoogleFonts.cairo(
                    color: theme.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: theme.textPrimaryColor),
                  title: Text('التقاط صورة', style: GoogleFonts.cairo(color: theme.textPrimaryColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadProfilePicture(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: theme.textPrimaryColor),
                  title: Text('اختيار من المعرض', style: GoogleFonts.cairo(color: theme.textPrimaryColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadProfilePicture(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePicture(ImageSource source) async {
    try {
      print('\n📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📸 ${DateTime.now()} بدء رفع الصورة الشخصية');
      
      // 1. اختيار الصورة
      print('📸 الخطوة 1: تحديد الصورة من ${source == ImageSource.camera ? "الكاميرا" : "المعرض"}...');
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, maxWidth: 800);
      
      if (image == null) {
        print('📸 ❌ تم إلغاء اختيار الصورة');
        print('📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return;
      }
      
      print('📸 ✅ تم اختيار الصورة: ${image.path}');
      
      // عرض loader
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Center(
            child: CircularProgressIndicator(
              color: ThemeConfig.instance.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
            ),
          ),
        );
      }
      
      // 2. قراءة الصورة
      print('📸 الخطوة 2: قراءة بيانات الصورة...');
      final bytes = await image.readAsBytes();
      print('📸 ✅ حجم الصورة: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      
      // 3. رفع إلى API
      print('📸 الخطوة 3: رفع الصورة إلى الـ API...');
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$_baseUrl/api/me/avatar'),
      );
      
      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📸 الخطوة 4: استجابة الـ API: ${response.statusCode}');
      print('📸 Body: ${response.body}');
      
      if (mounted) {
        Navigator.pop(context); // إغلاق loader
      }
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileImage = data['profile_image'] ?? data['avatar_url'];
        
        print('📸 ✅ تم رفع الصورة بنجاح!');
        print('📸 URL: $profileImage');
        print('📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        // تحديث الواجهة
        setState(() {
          _userProfile!['profile_image'] = profileImage;
          _userProfile!['avatar_url'] = profileImage;
        });
        
        NotificationsService.instance.toast(
          'تم تحديث الصورة الشخصية بنجاح 📸',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      } else {
        print('📸 ❌ فشل رفع الصورة: ${response.statusCode}');
        print('📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        NotificationsService.instance.toast(
          'حدث خطأ أثناء رفع الصورة',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    } catch (e) {
      print('📸 ❌ خطأ: $e');
      print('📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      if (mounted) {
        Navigator.pop(context);
        NotificationsService.instance.toast(
          'حدث خطأ أثناء رفع الصورة',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    }
  }

  void _showDevicesSheet() {
    final theme = ThemeConfig.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _GlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Grip(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.devices_other_rounded, color: theme.textPrimaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'الأجهزة المتصلة',
                      style: GoogleFonts.cairo(
                        color: theme.textPrimaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: theme.textSecondaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'لا توجد أجهزة متصلة',
                      style: GoogleFonts.cairo(color: theme.textSecondaryColor),
                    ),
                  )
                else
                  ..._devices.map((device) {
                    // device_info يحتوي على التفاصيل
                    final deviceInfo = device['device_info'] ?? {};
                    final deviceName = deviceInfo['device_name'] ?? deviceInfo['model'] ?? 'جهاز غير معروف';
                    final city = deviceInfo['city'] ?? '';
                    final country = deviceInfo['country'] ?? '';
                    final lastLogin = _formatLastLogin(device['last_login']);
                    
                    print('📱 [DEVICE] جهاز: $deviceName, $city, $country');
                    
                    return _DeviceTile(
                      name: deviceName,
                      city: city,
                      country: country,
                      lastLogin: lastLogin,
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final theme = ThemeConfig.instance;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تغيير كلمة المرور',
          style: GoogleFonts.cairo(
            color: theme.textPrimaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Field(label: 'كلمة المرور الحالية', obscure: true, controller: oldCtrl),
            const SizedBox(height: 10),
            _Field(label: 'كلمة المرور الجديدة', obscure: true, controller: newCtrl),
            const SizedBox(height: 10),
            _Field(label: 'تأكيد كلمة المرور', obscure: true, controller: confirmCtrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: theme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newCtrl.text.isEmpty || newCtrl.text != confirmCtrl.text) {
                NotificationsService.instance.toast('تأكد من إدخال كلمة مرور مطابقة');
                return;
              }
              
              Navigator.pop(context);
              
              // إرسال الطلب إلى API
              try {
                final response = await http.post(
                  Uri.parse('$_baseUrl/api/change-password'),
                  headers: {
                    'Authorization': 'Bearer $_token',
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'old_password': oldCtrl.text,
                    'new_password': newCtrl.text,
                  }),
                );
                
                if (response.statusCode == 200) {
                  NotificationsService.instance.toast('تم تغيير كلمة المرور بنجاح 🔒');
                } else {
                  NotificationsService.instance.toast('فشل تغيير كلمة المرور');
                }
              } catch (e) {
                NotificationsService.instance.toast('حدث خطأ أثناء تغيير كلمة المرور');
              }
            },
            child: Text(
              'حفظ',
              style: GoogleFonts.cairo(
                color: theme.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    final theme = ThemeConfig.instance;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'هل تريد تسجيل الخروج؟',
          style: GoogleFonts.cairo(
            color: theme.textPrimaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'سيتم إنهاء جلستك الحالية.',
          style: GoogleFonts.cairo(color: theme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'رجوع',
              style: GoogleFonts.cairo(color: theme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // مسح البيانات المحلية
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('user_name');
              await prefs.remove('user_phone');
              await prefs.remove('user_role');
              
              // تحديث AuthState
              if (mounted) {
                await Provider.of<AuthState>(context, listen: false).logout();
              }
              
              // تحديث الصفحة الحالية
              if (mounted) {
                setState(() {
                  _token = null;
                  _userProfile = null;
                  _devices = [];
                  _isLoading = false;
                  _hasError = false;
                });
              }
              
              NotificationsService.instance.toast('تم تسجيل الخروج بنجاح 👋');
            },
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================
// شاشة عدم تسجيل الدخول
// ========================

class _NotLoggedInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // أيقونة أنيقة
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                        ? [ThemeConfig.kGoldNight.withOpacity(0.2), ThemeConfig.kGoldNight.withOpacity(0.05)]
                        : [ThemeConfig.kGreen.withOpacity(0.2), ThemeConfig.kGreen.withOpacity(0.05)],
                    ),
                  ),
                  child: Icon(
                    Icons.account_circle_outlined,
                    size: 80,
                    color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                  ),
                ),
                const SizedBox(height: 32),
                // العنوان
                Text(
                  'سجّل دخول لإدارة حسابك',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // الوصف
                Text(
                  'سجّل الدخول للوصول إلى:\n✨ معلومات حسابك الشخصية\n📱 الأجهزة المتصلة\n🎨 إعدادات الثيم والمظهر\n📍 العناوين المحفوظة',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: theme.textSecondaryColor,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // زر تسجيل الدخول
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                        ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(0.8)]
                        : [ThemeConfig.kGreen, const Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    icon: const Icon(Icons.login_rounded, size: 24),
                    label: Text(
                      'تسجيل الدخول',
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: isDark ? ThemeConfig.kNightDeep : Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // زر إنشاء حساب
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  icon: Icon(Icons.person_add_outlined, color: theme.textSecondaryColor),
                  label: Text(
                    'ليس لديك حساب؟ أنشئ حساباً جديداً',
                    style: GoogleFonts.cairo(
                      color: theme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

class _AvatarCircle extends StatelessWidget {
  final String? imageUrl;
  final String? label;
  const _AvatarCircle({this.imageUrl, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final initial = (label?.isNotEmpty ?? false) ? label!.characters.first : 'د';
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.cardShadow,
        image: (imageUrl != null && imageUrl!.isNotEmpty)
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Center(
              child: Text(
                initial,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  color: theme.textPrimaryColor,
                ),
              ),
            )
          : null,
    );
  }
}

class _AvatarGlow extends StatelessWidget {
  final Widget child;
  const _AvatarGlow({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.instance.isDarkMode;
    final glowColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: glowColor.withOpacity(.28), blurRadius: 24, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}

class _RoundMini extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundMini({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: theme.cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: theme.borderColor),
        ),
        child: Icon(icon, size: 16, color: theme.textPrimaryColor),
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

class _GlassSheet extends StatelessWidget {
  final Widget child;
  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: theme.cardColor.withOpacity(.92),
          child: child,
        ),
      ),
    );
  }
}

class _Grip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: theme.borderColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, color: theme.textPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: theme.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
    this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.textSecondaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.cairo(
                color: valueColor ?? theme.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    return Container(
      height: 1,
      color: theme.borderColor.withOpacity(.7),
    );
  }
}

class _RequestStatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final String date;
  final VoidCallback? onUploadId;
  final VoidCallback? onUploadLicense;
  
  const _RequestStatusTile({
    required this.icon,
    required this.title,
    required this.status,
    required this.date,
    this.onUploadId,
    this.onUploadLicense,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    // تحديد اللون والنص حسب الحالة
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'قيد المراجعة';
        statusIcon = Icons.pending_rounded;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'تمت الموافقة';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.info_rounded;
    }
    
    final hasUploadButton = onUploadId != null || onUploadLicense != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              // أيقونة نوع الطلب
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // معلومات الطلب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: theme.textPrimaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'تاريخ التقديم: $date',
                      style: GoogleFonts.cairo(
                        color: theme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // حالة الطلب
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.cairo(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasUploadButton) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onUploadId ?? onUploadLicense,
                icon: Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(
                  onUploadId != null ? 'رفع صورة الهوية للتوثيق 📸' : 'رفع صورة السجل التجاري 📸',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                  backgroundColor: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: (isDark ? ThemeConfig.kNightSoft : ThemeConfig.kBeige).withOpacity(.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.textPrimaryColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final colors = isDark
        ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(.75)]
        : [ThemeConfig.kGreen, const Color(0xFF059669)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: isDark ? ThemeConfig.kNightDeep : Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: isDark ? ThemeConfig.kNightDeep : Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: isDark ? ThemeConfig.kNightDeep : Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _PrimaryGradientButton({required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.instance.isDarkMode;
    final green = [ThemeConfig.kGreen, const Color(0xFF059669)];
    final gold = [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(.8)];
    final red = [const Color(0xFFEF4444), const Color(0xFFF97316)];
    final colors = danger ? red : (isDark ? gold : green);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              color: isDark && !danger ? ThemeConfig.kNightDeep : Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.instance.isDarkMode;
    final color = active
        ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
        : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.verified_rounded : Icons.block, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            active ? 'نشط' : 'مجمّد',
            style: GoogleFonts.cairo(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String text;
  const _RoleBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.instance.isDarkMode;
    final color = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.cairo(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final String name;
  final String city;
  final String country;
  final String lastLogin;
  const _DeviceTile({
    required this.name,
    required this.city,
    required this.country,
    required this.lastLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final location = (city.isNotEmpty && country.isNotEmpty)
        ? '$city، $country'
        : (city.isNotEmpty ? city : (country.isNotEmpty ? country : 'غير محدد'));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.devices, color: theme.textPrimaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    color: theme.textPrimaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$location • آخر دخول: $lastLogin',
                  style: GoogleFonts.cairo(
                    color: theme.textSecondaryColor,
                    fontSize: 12,
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.cairo(color: theme.textPrimaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
        filled: true,
        fillColor: isDark ? ThemeConfig.kNightAccent.withOpacity(.35) : Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

