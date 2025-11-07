// API Configuration
// This file contains API keys and configuration
// The API key is obfuscated for security

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // API Base URL
  static const String baseUrl = 'https://dalma-api.onrender.com';
  
  // API Key - يُقرأ من Backend Environment Variables فقط
  // لا يُحفظ في Flutter للأمان
  // Backend سيتحقق من APP_API_KEY في Render Environment
  static String get apiKey => ''; // سيتم إزالة التحقق من Flutter
  
  // Get or generate Device ID (persisted)
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null || deviceId.isEmpty) {
      // Generate new device ID based on platform
      final deviceInfo = DeviceInfoPlugin();
      
      try {
        if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? _generateRandomId();
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isMacOS) {
          final macInfo = await deviceInfo.macOsInfo;
          deviceId = macInfo.systemGUID ?? _generateRandomId();
        } else {
          deviceId = _generateRandomId();
        }
        
        // Save for future use
        await prefs.setString('device_id', deviceId);
        print('🆔 [DEVICE ID] تم إنشاء معرف جديد: ${deviceId.substring(0, 10)}...');
      } catch (e) {
        print('⚠️ [DEVICE ID] خطأ في الحصول على معرف الجهاز: $e');
        deviceId = _generateRandomId();
        await prefs.setString('device_id', deviceId);
      }
    } else {
      print('🆔 [DEVICE ID] استخدام معرف محفوظ: ${deviceId.substring(0, 10)}...');
    }
    
    return deviceId;
  }
  
  // Generate random device ID as fallback
  static String _generateRandomId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 31) % 1000000;
    return 'mobile_$timestamp\_$random';
  }
  
  // Get default headers for all requests (async to include Device ID)
  static Future<Map<String, String>> getHeaders() async {
    final deviceId = await getDeviceId();
    return {
      'Content-Type': 'application/json',
      'X-Device-ID': deviceId,
    };
  }
  
  // Get headers with authentication token
  static Future<Map<String, String>> getHeadersWithAuth(String token) async {
    final deviceId = await getDeviceId();
    return {
      'Content-Type': 'application/json',
      'X-Device-ID': deviceId,
      'Authorization': 'Bearer $token',
    };
  }
}


