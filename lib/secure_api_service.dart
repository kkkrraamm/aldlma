import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Secure API Service with automatic API Key and Token management
class SecureApiService {
  // Singleton pattern
  static final SecureApiService _instance = SecureApiService._internal();
  factory SecureApiService() => _instance;
  SecureApiService._internal();

  /// Get stored authentication token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('⚠️ [SECURE API] Error getting token: $e');
      return null;
    }
  }

  /// Make a secure GET request
  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    print('\n🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔒 [SECURE API] GET Request');
    print('📍 Endpoint: $endpoint');
    print('🔐 Require Auth: $requireAuth');

    try {
      Map<String, String> headers;

      if (requireAuth) {
        final token = await _getToken();
        if (token == null) {
          print('❌ [SECURE API] No authentication token found');
          print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          return http.Response(
            json.encode({'error': 'Authentication required'}),
            401,
          );
        }
        headers = await ApiConfig.getHeadersWithAuth(token);
        print('🎫 Token found: ${token.substring(0, 15)}...');
      } else {
        headers = await ApiConfig.getHeaders();
      }

      print('🔑 [SECURITY] Request includes X-API-Key + X-Device-ID');
      print('📤 Sending request...');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
      );

      print('📥 Response received - Status: ${response.statusCode}');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return response;
    } catch (e) {
      print('💥 [SECURE API] Error: $e');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      return http.Response(
        json.encode({'error': 'Network error', 'details': e.toString()}),
        500,
      );
    }
  }

  /// Make a secure POST request
  Future<http.Response> post(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    print('\n🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔒 [SECURE API] POST Request');
    print('📍 Endpoint: $endpoint');
    print('🔐 Require Auth: $requireAuth');

    try {
      Map<String, String> headers;

      if (requireAuth) {
        final token = await _getToken();
        if (token == null) {
          print('❌ [SECURE API] No authentication token found');
          print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          return http.Response(
            json.encode({'error': 'Authentication required'}),
            401,
          );
        }
        headers = await ApiConfig.getHeadersWithAuth(token);
        print('🎫 Token found: ${token.substring(0, 15)}...');
      } else {
        headers = await ApiConfig.getHeaders();
      }

      print('🔑 [SECURITY] Request includes X-API-Key + X-Device-ID');
      print('📤 Sending request...');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: json.encode(body),
      );

      print('📥 Response received - Status: ${response.statusCode}');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return response;
    } catch (e) {
      print('💥 [SECURE API] Error: $e');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      return http.Response(
        json.encode({'error': 'Network error', 'details': e.toString()}),
        500,
      );
    }
  }

  /// Make a secure PUT request
  Future<http.Response> put(
    String endpoint,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    print('\n🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔒 [SECURE API] PUT Request');
    print('📍 Endpoint: $endpoint');
    print('🔐 Require Auth: $requireAuth');

    try {
      Map<String, String> headers;

      if (requireAuth) {
        final token = await _getToken();
        if (token == null) {
          print('❌ [SECURE API] No authentication token found');
          print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          return http.Response(
            json.encode({'error': 'Authentication required'}),
            401,
          );
        }
        headers = await ApiConfig.getHeadersWithAuth(token);
        print('🎫 Token found: ${token.substring(0, 15)}...');
      } else {
        headers = await ApiConfig.getHeaders();
      }

      print('🔑 [SECURITY] Request includes X-API-Key + X-Device-ID');
      print('📤 Sending request...');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
        body: json.encode(body),
      );

      print('📥 Response received - Status: ${response.statusCode}');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return response;
    } catch (e) {
      print('💥 [SECURE API] Error: $e');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      return http.Response(
        json.encode({'error': 'Network error', 'details': e.toString()}),
        500,
      );
    }
  }

  /// Make a secure DELETE request
  Future<http.Response> delete(String endpoint, {bool requireAuth = true}) async {
    print('\n🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔒 [SECURE API] DELETE Request');
    print('📍 Endpoint: $endpoint');
    print('🔐 Require Auth: $requireAuth');

    try {
      Map<String, String> headers;

      if (requireAuth) {
        final token = await _getToken();
        if (token == null) {
          print('❌ [SECURE API] No authentication token found');
          print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          return http.Response(
            json.encode({'error': 'Authentication required'}),
            401,
          );
        }
        headers = await ApiConfig.getHeadersWithAuth(token);
        print('🎫 Token found: ${token.substring(0, 15)}...');
      } else {
        headers = await ApiConfig.getHeaders();
      }

      print('🔑 [SECURITY] Request includes X-API-Key + X-Device-ID');
      print('📤 Sending request...');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: headers,
      );

      print('📥 Response received - Status: ${response.statusCode}');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return response;
    } catch (e) {
      print('💥 [SECURE API] Error: $e');
      print('🔒━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      return http.Response(
        json.encode({'error': 'Network error', 'details': e.toString()}),
        500,
      );
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  /// Verify token with server
  Future<bool> verifyToken() async {
    try {
      final response = await get('/verify-token', requireAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

