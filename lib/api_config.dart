// API Configuration
// This file contains API keys and configuration
// The API key is obfuscated for security

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // API Base URL
  static const String baseUrl = 'https://dalma-api.onrender.com';
  
  // Obfuscated API Key parts (will be reconstructed at runtime)
  // This prevents the key from appearing in plain text in the compiled app
  // dalma_app_2025_secure_key
  static String get _part1 => String.fromCharCodes([100, 97, 108, 109, 97, 95, 97, 112, 112]);
  static String get _part2 => String.fromCharCodes([95, 50, 48, 50, 53, 95]);
  static String get _part3 => String.fromCharCodes([115, 101, 99, 117, 114, 101, 95, 107, 101, 121]);
  
  // Reconstruct API key at runtime
  static String get apiKey => _part1 + _part2 + _part3;
  
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


