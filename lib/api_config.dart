// API Configuration
// This file contains API keys and configuration
// The API key is obfuscated for security

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // API Base URL
  static const String baseUrl = 'https://dalma-api.onrender.com';
  
  // API Key - مُشفّر بطريقة آمنة (obfuscated)
  // يُعاد بناؤه في Runtime فقط
  // لا يظهر بنص واضح في compiled app
  static String get _k1 => String.fromCharCodes([70, 75, 83, 79, 69, 52, 52, 53, 68, 70, 76, 67, 68]);
  static String get _k2 => String.fromCharCodes([36, 37, 67, 68, 35, 35, 103, 52, 56, 100, 35]);
  static String get _k3 => String.fromCharCodes([100, 51, 79, 76, 53, 38, 37, 107, 100, 107, 102, 38, 53]);
  static String get _k4 => String.fromCharCodes([103, 100, 79, 100, 75, 101, 75, 75, 68, 83]);
  
  // Reconstruct API key at runtime
  static String get apiKey => _k1 + _k2 + _k3 + _k4;
  
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
      'X-API-Key': apiKey,
      'X-Device-ID': deviceId,
    };
  }
  
  // Get headers with authentication token
  static Future<Map<String, String>> getHeadersWithAuth(String token) async {
    final deviceId = await getDeviceId();
    return {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Device-ID': deviceId,
      'Authorization': 'Bearer $token',
    };
  }
}


