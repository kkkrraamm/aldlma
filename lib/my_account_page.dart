import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'auth.dart';
import 'request_media_page.dart';
import 'request_provider_page.dart';
import 'notifications.dart';
import 'api_config.dart';
import 'package:intl/intl.dart';
import 'theme_config.dart';
import 'theme_toggle_widget.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({Key? key}) : super(key: key);

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _userProfile;
  String? _token;
  final String _baseUrl = 'https://dalma-api.onrender.com';

  // استخدام ألوان الثيم الديناميكي
  Color get kBeige => ThemeConfig.instance.isDarkMode ? ThemeConfig.kNightSoft : ThemeConfig.kBeige;
  Color get kMint => ThemeConfig.instance.isDarkMode ? ThemeConfig.kNightDeep : ThemeConfig.kMint;
  Color get kGreen => ThemeConfig.instance.primaryColor;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
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

      final response = await http.get(
        Uri.parse('$_baseUrl/api/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _userProfile = userData;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy - hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showDevicesDialog() {
    final devices = _userProfile?['devices'] as List<dynamic>? ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.devices, color: kGreen),
                  const SizedBox(width: 12),
                  Text(
                    'الأجهزة المتصلة (${devices.length})',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            // Devices list
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices_other, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('لا توجد أجهزة متصلة', style: GoogleFonts.cairo(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final deviceInfo = device['device_info'] as Map<String, dynamic>? ?? {};
                        final platform = deviceInfo['platform'] ?? 'unknown';
                        final ip = deviceInfo['ip'] ?? 'غير معروف';
                        final userAgent = deviceInfo['userAgent'] ?? '';
                        final lastLogin = _formatDateTime(device['last_login']);
                        
                        // معلومات إضافية من الجهاز
                        final model = deviceInfo['model'];
                        final name = deviceInfo['name'];
                        final manufacturer = deviceInfo['manufacturer'];
                        final brand = deviceInfo['brand'];
                        final systemVersion = deviceInfo['systemVersion'];
                        final androidVersion = deviceInfo['androidVersion'];
                        
                        // تحديد أيقونة الجهاز بناءً على النوع
                        IconData deviceIcon;
                        String deviceType;
                        String deviceDetails = '';
                        
                        // استخدام البيانات الحقيقية من التطبيق
                        if (platform.toString().toLowerCase().contains('ios')) {
                          deviceIcon = Icons.phone_iphone;
                          // استخدام الاسم الفعلي للجهاز (مثل "iPhone 16 Pro")
                          deviceType = name ?? model ?? 'iPhone';
                          deviceDetails = 'iOS ${systemVersion ?? ''}';
                        } else if (platform.toString().toLowerCase().contains('android')) {
                          deviceIcon = Icons.phone_android;
                          deviceType = '${brand ?? manufacturer ?? 'Android'} ${model ?? ''}'.trim();
                          deviceDetails = 'Android ${androidVersion ?? ''}';
                        } else {
                          // أجهزة أخرى غير معروفة
                          deviceIcon = Icons.help_outline;
                          deviceType = 'جهاز غير معروف';
                          deviceDetails = platform;
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kMint.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kGreen.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: kGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(deviceIcon, color: kGreen, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deviceType,
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                        Text(
                                          deviceDetails.isNotEmpty ? deviceDetails : (platform == 'unknown' ? 'نوع غير معروف' : platform),
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index == 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: kGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'الحالي',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              // عرض الموقع الحقيقي إذا كان موجود
                              if (deviceInfo['location'] != null && deviceInfo['location']['latitude'] != null) ...[
                                _DeviceInfoRow(
                                  icon: Icons.location_on,
                                  label: 'الموقع (GPS)',
                                  value: '${deviceInfo['location']['latitude']?.toStringAsFixed(4)}, ${deviceInfo['location']['longitude']?.toStringAsFixed(4)}',
                                ),
                                const SizedBox(height: 8),
                              ] else ...[
                                _DeviceInfoRow(icon: Icons.wifi, label: 'IP', value: ip),
                                const SizedBox(height: 8),
                              ],
                              _DeviceInfoRow(icon: Icons.access_time, label: 'آخر دخول', value: lastLogin),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'user':
        return 'مستخدم';
      case 'provider':
        return 'مقدم خدمة';
      case 'media':
        return 'إعلامي';
      case 'admin':
        return 'مدير';
      default:
        return 'مستخدم';
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      print('\n📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📸 [FLUTTER] بدء عملية رفع صورة الملف الشخصي');
      
      final ImagePicker picker = ImagePicker();
      print('🖼️ [FLUTTER] فتح معرض الصور...');
      
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        print('❌ [FLUTTER] لم يتم اختيار صورة');
        print('📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return;
      }

      final imageSize = await image.length();
      print('✅ [FLUTTER] تم اختيار صورة:');
      print('   - المسار: ${image.path}');
      print('   - الحجم: ${(imageSize / 1024).toStringAsFixed(2)} KB');
      print('   - الصيغة: ${image.mimeType ?? image.path.split('.').last}');

      // عرض مؤشر التحميل
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kGreen),
                  SizedBox(height: 16),
                  Text('جاري رفع الصورة...', style: GoogleFonts.cairo()),
                ],
              ),
            ),
          ),
        ),
      );

      // تحضير الطلب
      print('🔐 [FLUTTER] تحضير الطلب...');
      final headers = await ApiConfig.getHeadersWithAuth(_token!);
      print('🔑 [FLUTTER] Headers:');
      print('   - X-API-Key: ${headers['X-API-Key']?.substring(0, 15)}...');
      print('   - X-Device-ID: ${headers['X-Device-ID']?.substring(0, 15)}...');
      print('   - Authorization: Bearer ${_token!.substring(0, 20)}...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/user/profile-picture'),
      );
      
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        image.path,
      ));

      print('📤 [FLUTTER] إرسال الطلب إلى السيرفر...');
      print('   - URL: $_baseUrl/api/user/profile-picture');
      print('   - Method: POST');
      print('   - Body: multipart/form-data (profile_picture)');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 [FLUTTER] استلام الرد من السيرفر:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Body: ${response.body}');

      if (!mounted) return;
      Navigator.pop(context); // إغلاق مؤشر التحميل

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [FLUTTER] تم رفع الصورة بنجاح!');
        print('   - Image URL: ${data['profile_image']}');
        
        setState(() {
          _userProfile!['profile_image'] = data['profile_image'];
        });
        
        print('✅ [FLUTTER] تم تحديث الواجهة');
        print('📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        NotificationsService.instance.toast(
          'تم تحديث صورة الملف الشخصي',
          icon: Icons.check_circle,
          color: kGreen,
        );
      } else {
        print('❌ [FLUTTER] فشل رفع الصورة');
        print('   - Status Code: ${response.statusCode}');
        print('   - Error: ${response.body}');
        print('📸━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        NotificationsService.instance.toast(
          'فشل رفع الصورة',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    } catch (e) {
      print('❌ [FLUTTER] خطأ في رفع الصورة: $e');
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    
    // مسح البيانات المحلية أولاً
    setState(() {
      _token = null;
      _userProfile = null;
      _isLoading = false;
      _hasError = false;
    });
    
    await AuthState.instance.logout();
    
    NotificationsService.instance.toast(
      'تم تسجيل الخروج',
      icon: Icons.logout,
      color: const Color(0xFFEF4444),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    
    if (_token == null && !_isLoading) {
      return Scaffold(
        backgroundColor: ThemeConfig.instance.backgroundColor,
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
                        colors: ThemeConfig.instance.isDarkMode
                          ? [ThemeConfig.kGoldNight.withOpacity(0.2), ThemeConfig.kGoldNight.withOpacity(0.05)]
                          : [ThemeConfig.kGreen.withOpacity(0.2), ThemeConfig.kGreen.withOpacity(0.05)],
                      ),
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 80,
                      color: ThemeConfig.instance.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // العنوان
                  Text(
                    'سجّل دخول لإدارة حسابك',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: ThemeConfig.instance.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // الوصف
                  Text(
                    'سجّل الدخول للوصول إلى:\n✨ معلومات حسابك الشخصية\n📱 الأجهزة المتصلة\n🎨 إعدادات الثيم والمظهر\n📍 العناوين المحفوظة',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: ThemeConfig.instance.textSecondaryColor,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // زر تسجيل الدخول
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: ThemeConfig.instance.isDarkMode
                          ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(0.8)]
                          : [ThemeConfig.kGreen, const Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (ThemeConfig.instance.isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.login_rounded, size: 24),
                      label: Text('تسجيل الدخول', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: ThemeConfig.instance.isDarkMode ? ThemeConfig.kNightDeep : Colors.white,
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
                    icon: Icon(Icons.person_add_outlined, color: ThemeConfig.instance.textSecondaryColor),
                    label: Text(
                      'ليس لديك حساب؟ أنشئ حساباً جديداً',
                      style: GoogleFonts.cairo(
                        color: ThemeConfig.instance.textSecondaryColor,
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: kMint,
        body: Center(
          child: CircularProgressIndicator(color: kGreen),
        ),
      );
    }

    if (_hasError || _userProfile == null) {
      return Scaffold(
        backgroundColor: kMint,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text('حدث خطأ في تحميل البيانات', style: GoogleFonts.cairo(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUserProfile,
                icon: Icon(Icons.refresh),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(backgroundColor: kGreen),
              ),
            ],
          ),
        ),
      );
    }

    final name = _userProfile!['name'] ?? 'مستخدم';
    final phone = _userProfile!['phone'] ?? '';
    final role = _userProfile!['role'] ?? 'user';
    final roleLabel = _getRoleLabel(role);
    final createdAt = _formatDate(_userProfile!['created_at']);
    final birthDate = _formatDate(_userProfile!['birth_date']);
    final isActive = _userProfile!['is_active'] ?? true;
    final connectedDevices = _userProfile!['connected_devices'] ?? 0;
    final profileImage = _userProfile!['profile_image'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9ED),
      body: CustomScrollView(
        slivers: [
          // الهيدر - نفس تصميم الصفحة الرئيسية
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                gradient: ThemeConfig.instance.headerGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // الشعار مع التوهج
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  color.withOpacity(0.25),
                                  color.withOpacity(0.15),
                                  color.withOpacity(0.08),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.3, 0.6, 1.0],
                              ),
                            ),
                          ),
                          // Avatar المستخدم مع زر تعديل
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [kGreen, Color(0xFF059669)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kGreen.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: Colors.black12.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                  image: profileImage != null
                                      ? DecorationImage(
                                          image: NetworkImage(profileImage),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profileImage == null
                                    ? Center(
                                        child: Text(
                                          name.trim().isNotEmpty ? name.trim()[0] : '؟',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontSize: 40,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              // زر تعديل الصورة
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _uploadProfilePicture,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: kGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // اسم المستخدم
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // الدور (Badge) بتدرج ناعم
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kMint.withOpacity(0.7),
                              kBeige.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: kGreen.withOpacity(0.4)),
                        ),
                        child: Text(
                          roleLabel,
                          style: GoogleFonts.cairo(
                            color: kGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // المحتوى
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // معلومات الحساب
                _InfoCard(
                  title: 'معلومات الحساب',
                  icon: Icons.person_outline,
                  children: [
                    _InfoRow(icon: Icons.phone, label: 'رقم الجوال', value: phone),
                    _InfoRow(icon: Icons.cake, label: 'تاريخ الميلاد', value: birthDate),
                    _InfoRow(icon: Icons.calendar_today, label: 'تاريخ الانضمام', value: createdAt),
                    _InfoRow(
                      icon: Icons.verified_user,
                      label: 'حالة الحساب',
                      valueWidget: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'نشط' : 'موقوف',
                            style: GoogleFonts.cairo(
                              color: isActive ? Colors.green[800] : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ActionRow(
                      icon: Icons.devices,
                      label: 'الأجهزة المتصلة ($connectedDevices)',
                      onTap: _showDevicesDialog,
                      color: kGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // إجراءات سريعة
                _InfoCard(
                  title: 'إجراءات سريعة',
                  icon: Icons.bolt,
                  children: [
                    // زر تبديل الوضع الليلي/النهاري
                    const ThemeToggleButton(showLabel: true),
                    const Divider(height: 1),
                    _ActionRow(
                      icon: Icons.edit,
                      label: 'تعديل الملف الشخصي',
                      onTap: () {},
                    ),
                    _ActionRow(
                      icon: Icons.campaign,
                      label: 'طلب أن تصبح إعلامي',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RequestMediaPage()),
                        );
                      },
                    ),
                    _ActionRow(
                      icon: Icons.work,
                      label: 'طلب أن تصبح مقدم خدمة',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RequestProviderPage()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // الأمان والخصوصية
                _InfoCard(
                  title: 'الأمان والخصوصية',
                  icon: Icons.lock_outline,
                  children: [
                    _ActionRow(
                      icon: Icons.security,
                      label: 'تفعيل التحقق الثنائي',
                      onTap: () {},
                    ),
                    _ActionRow(
                      icon: Icons.download,
                      label: 'تصدير بياناتي',
                      onTap: () {},
                    ),
                    _ActionRow(
                      icon: Icons.logout,
                      label: 'تسجيل الخروج',
                      onTap: _logout,
                      color: const Color(0xFFFF6B9D), // وردي ناعم بدل الأحمر الفاقع
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة معلومات
class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;

  const _InfoCard({required this.title, required this.children, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E2).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: const Color(0xFF10B981).withOpacity(0.6)),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          ...children,
        ],
      ),
    );
  }
}

/// صف معلومات
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                valueWidget ??
                    Text(
                      value ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
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

/// صف إجراء
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = color ?? const Color(0xFF10B981);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: actionColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            Icon(Icons.chevron_left, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// صف معلومات الجهاز
class _DeviceInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DeviceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
