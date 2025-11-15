import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'api_config.dart';

class AuthState extends ChangeNotifier {
  static final AuthState instance = AuthState._internal();
  AuthState._internal();

  bool _isLoggedIn = false;
  String? _userName;
  String? _phone;
  String? _userRole;
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[]; // {phone, name, password, dob}
  
  // السيرفر الحقيقي (من ApiConfig)
  static String get _baseUrl => ApiConfig.baseUrl;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get phone => _phone;
  String? get userRole => _userRole;
  
  // Reload auth state (useful after login from other pages)
  Future<void> reloadAuthState() async {
    await loadFromDisk();
  }

  // التحقق من صلاحية الـ token
  Future<bool> _verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('✅ [AUTH] Token صالح');
        return true;
      } else {
        print('❌ [AUTH] Token غير صالح - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('⚠️ [AUTH] خطأ في التحقق من Token: $e');
      // في حالة عدم الاتصال بالإنترنت، نفترض أن الـ token صالح
      return true;
    }
  }
  
  // حذف بيانات المصادقة
  Future<void> _clearAuthData(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('user_token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    print('🗑️ [AUTH] تم حذف بيانات المصادقة');
  }

  // جمع معلومات الجهاز الحقيقية
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> info = {};
    
    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'systemVersion': iosInfo.systemVersion,
          'name': iosInfo.name,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'androidVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        };
      } else {
        info = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      print('⚠️ [DEVICE INFO] خطأ في جمع معلومات الجهاز: $e');
      info = {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      };
    }
    
    // جمع الموقع الحقيقي (GPS)
    try {
      print('📍 [LOCATION] جاري الحصول على الموقع الحقيقي...');
      
      // التحقق من صلاحيات الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ [LOCATION] خدمة الموقع غير مفعلة');
        info['location'] = {'error': 'Location service disabled'};
        return info;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ [LOCATION] تم رفض إذن الموقع');
          info['location'] = {'error': 'Location permission denied'};
          return info;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('⚠️ [LOCATION] إذن الموقع مرفوض بشكل دائم');
        info['location'] = {'error': 'Location permission denied forever'};
        return info;
      }

      // الحصول على الموقع الحالي
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      info['location'] = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'timestamp': position.timestamp?.toIso8601String(),
      };
      
      print('✅ [LOCATION] تم الحصول على الموقع: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('⚠️ [LOCATION] خطأ في الحصول على الموقع: $e');
      info['location'] = {'error': e.toString()};
    }
    
    return info;
  }

  static const _kIsLoggedIn = 'auth_is_logged_in';
  static const _kUserName = 'auth_user_name';
  static const _kPhone = 'auth_phone';
  static const _kUsers = 'auth_users_v1';

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check for token first (new system)
    final token = prefs.getString('token');
    final tokenUserName = prefs.getString('user_name');
    final tokenUserPhone = prefs.getString('user_phone');
    final tokenUserRole = prefs.getString('user_role');
    
    if (token != null && token.isNotEmpty) {
      // التحقق من صلاحية الـ token
      final isTokenValid = await _verifyToken(token);
      
      if (isTokenValid) {
        // Token صالح - المستخدم مسجل دخول
        _isLoggedIn = true;
        _userName = tokenUserName;
        _phone = tokenUserPhone;
        _userRole = tokenUserRole;
        
        // التأكد من وجود user_token للمفضلة والدردشة
        await prefs.setString('user_token', token);
        print('✅ [AUTH] تم تحديث user_token للمفضلة والدردشة');
        
        print('🔐 [AUTH STATE] تحميل من Token - مسجل دخول ✅');
        print('👤 الاسم: $_userName');
        print('📱 الجوال: $_phone');
      } else {
        // Token منتهي أو غير صالح - تسجيل خروج تلقائي
        print('⚠️ [AUTH] Token منتهي الصلاحية - تسجيل خروج تلقائي');
        await _clearAuthData(prefs);
        _isLoggedIn = false;
        _userName = null;
        _phone = null;
        _userRole = null;
      }
    } else {
      // Fallback to old system
      _isLoggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
      _userName = prefs.getString(_kUserName);
      _phone = prefs.getString(_kPhone);
      print('🔐 [AUTH STATE] تحميل من النظام القديم');
    }
    
    // Load users list
    final storedUsers = prefs.getStringList(_kUsers) ?? <String>[];
    _users = storedUsers.map((s) {
      try {
        final parts = s.split('\u0001');
        // phone, name, password, dobIso
        return <String, dynamic>{
          'phone': parts.isNotEmpty ? parts[0] : '',
          'name': parts.length > 1 ? parts[1] : '',
          'password': parts.length > 2 ? parts[2] : '',
          'dob': parts.length > 3 ? parts[3] : null,
        };
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => (m['phone'] ?? '').toString().isNotEmpty).toList();
    // If logged in but missing name, hydrate from users list
    if (_isLoggedIn && (_userName == null || _userName!.trim().isEmpty) && _phone != null) {
      final u = _users.cast<Map<String, dynamic>?>().firstWhere(
        (e) => e != null && e['phone'] == _phone,
        orElse: () => null,
      );
      if (u != null) _userName = (u['name'] as String?) ?? _userName;
    }
    
    print('📊 [AUTH STATE] حالة النهائية: isLoggedIn=$_isLoggedIn');
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, _isLoggedIn);
    if (_userName != null) await prefs.setString(_kUserName, _userName!); else await prefs.remove(_kUserName);
    if (_phone != null) await prefs.setString(_kPhone, _phone!); else await prefs.remove(_kPhone);
    // Persist users list (compact string list to avoid heavy JSON)
    final serialized = _users.map((u) {
      final phone = (u['phone'] ?? '').toString();
      final name = (u['name'] ?? '').toString();
      final pwd = (u['password'] ?? '').toString();
      final dob = (u['dob'] ?? '').toString();
      return [phone, name, pwd, dob].join('\u0001');
    }).toList();
    await prefs.setStringList(_kUsers, serialized);
  }

  Future<bool> login({required String phone, required String password}) async {
    print('\n🔐━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔐 [AUTH] بدء عملية تسجيل الدخول');
    print('📱 الجوال: $phone');
    print('🔑 كلمة المرور: ${password.replaceAll(RegExp(r'.'), '*')}');
    print('🌐 السيرفر: $_baseUrl');
    
    try {
      print('📤 [HTTP] إرسال طلب POST إلى /login');
      
      final headers = await ApiConfig.getHeaders();
      print('🆔 [DEVICE ID] إرسال X-Device-ID: ${headers['X-Device-ID']?.substring(0, 15)}...');
      
      // جمع معلومات الجهاز الحقيقية
      final deviceInfo = await _getDeviceInfo();
      print('📱 [DEVICE INFO] ${deviceInfo['platform']} - ${deviceInfo['model'] ?? deviceInfo['name'] ?? 'Unknown'}');
      
      // الحصول على FCM Token من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken != null) {
        print('📲 [FCM] إرسال FCM Token مع Login: ${fcmToken.substring(0, 20)}...');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: headers,
        body: json.encode({
          'phone': phone.trim(),
          'password': password.trim(),
          'deviceInfo': deviceInfo, // إرسال معلومات الجهاز
          if (fcmToken != null) 'fcm_token': fcmToken, // إرسال FCM Token إذا كان موجوداً
        }),
      );
      
      print('📥 [HTTP] استلام الرد - Status: ${response.statusCode}');
      print('📦 [HTTP] Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final name = data['name'];
        final role = data['role'] ?? 'user';
        
        print('✅ [AUTH] تسجيل دخول ناجح!');
        print('👤 الاسم: $name');
        print('🎭 الدور: $role');
        print('🎫 Token: ${token.substring(0, 20)}...');
        
        // حفظ في SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_token', token); // للمفضلة والدردشة
        await prefs.setString('user_name', name);
        await prefs.setString('user_phone', phone.trim());
        await prefs.setString('user_role', role);
        
        _isLoggedIn = true;
        _userName = name;
        _phone = phone.trim();
        _userRole = role;
        
        print('💾 [STORAGE] تم حفظ البيانات في SharedPreferences');
        print('🔐━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        notifyListeners();
        return true;
      } else {
        print('❌ [AUTH] فشل تسجيل الدخول - Status: ${response.statusCode}');
        print('❌ الرسالة: ${response.body}');
        print('🔐━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 [ERROR] خطأ في تسجيل الدخول');
      print('❌ الخطأ: $e');
      print('📍 Stack Trace: $stackTrace');
      print('🔐━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required DateTime dob,
    required String phone,
    required String password,
    required String username, // إلزامي
  }) async {
    print('\n📝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📝 [SIGNUP] بدء عملية إنشاء حساب جديد');
    print('👤 الاسم: $name');
    print('📱 الجوال: $phone');
    print('🔑 كلمة المرور: ${password.replaceAll(RegExp(r'.'), '*')}');
    print('🎂 تاريخ الميلاد: ${dob.toIso8601String()}');
    print('🌐 السيرفر: $_baseUrl');
    
    try {
      print('📤 [HTTP] إرسال طلب POST إلى /user');
      
      final headers = await ApiConfig.getHeaders();
      print('🆔 [DEVICE ID] إرسال X-Device-ID: ${headers['X-Device-ID']?.substring(0, 15)}...');
      
      // جمع معلومات الجهاز الحقيقية
      final deviceInfo = await _getDeviceInfo();
      print('📱 [DEVICE INFO] ${deviceInfo['platform']} - ${deviceInfo['model'] ?? deviceInfo['name'] ?? 'Unknown'}');
      
      final body = {
        'name': name.trim(),
        'phone': phone.trim(),
        'password': password.trim(),
        'dob': dob.toIso8601String(),
        'username': username.trim().toLowerCase(), // إلزامي
        'deviceInfo': deviceInfo, // إرسال معلومات الجهاز
      };
      
      print('🆔 [USERNAME] $username');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/user'),
        headers: headers,
        body: json.encode(body),
      );
      
      print('📥 [HTTP] استلام الرد - Status: ${response.statusCode}');
      print('📦 [HTTP] Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userName = data['name'] ?? name;
        final role = data['role'] ?? 'user';
        
        print('✅ [SIGNUP] تم إنشاء الحساب بنجاح!');
        print('👤 الاسم: $userName');
        print('🎭 الدور: $role');
        print('🎫 Token: ${token.substring(0, 20)}...');
        
        // حفظ في SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_token', token); // للمفضلة والدردشة
        await prefs.setString('user_name', userName);
        await prefs.setString('user_phone', phone.trim());
        await prefs.setString('user_role', role);
        
        _isLoggedIn = true;
        _userName = userName;
        _phone = phone.trim();
        _userRole = role;
        
        print('💾 [STORAGE] تم حفظ البيانات في SharedPreferences');
        print('📝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        
        notifyListeners();
        return true;
      } else {
        print('❌ [SIGNUP] فشل إنشاء الحساب - Status: ${response.statusCode}');
        print('❌ الرسالة: ${response.body}');
        print('📝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 [ERROR] خطأ في إنشاء الحساب');
      print('❌ الخطأ: $e');
      print('📍 Stack Trace: $stackTrace');
      print('📝━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      return false;
    }
  }

  Future<void> logout() async {
    print('🚪 [AUTH STATE] تسجيل الخروج...');
    
    // مسح البيانات من الذاكرة
    _isLoggedIn = false;
    _userName = null;
    _phone = null;
    _userRole = null;
    
    // مسح جميع البيانات من SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_token'); // للمفضلة والدردشة
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_role');
    
    print('✅ [AUTH STATE] تم تسجيل الخروج بنجاح');
    
    // حفظ الحالة الجديدة
    await _persist();
    
    // إشعار جميع المستمعين
    notifyListeners();
  }
}


