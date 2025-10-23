import 'package:http/http.dart' as http;
import 'dart:convert';

class AppConfig {
  static final AppConfig instance = AppConfig._internal();
  factory AppConfig() => instance;
  AppConfig._internal();

  // Default settings
  Map<String, dynamic> _settings = {
    'app_name': 'دلما',
    'app_version': '1.0.0',
    'primary_color': '#6366f1',
    'maintenance_mode': false,
  };

  bool _initialized = false;
  bool _loading = false;

  // Getters
  String get appName => _settings['app_name'] ?? 'دلما';
  String get appVersion => _settings['app_version'] ?? '1.0.0';
  String get primaryColor => _settings['primary_color'] ?? '#6366f1';
  bool get maintenanceMode => _settings['maintenance_mode'] ?? false;
  Map<String, dynamic> get allSettings => Map.from(_settings);
  bool get isInitialized => _initialized;
  bool get isLoading => _loading;

  // Load settings from API
  Future<void> loadSettings() async {
    if (_loading) {
      print('⚠️ [CONFIG] Already loading...');
      return;
    }

    try {
      _loading = true;
      print('⚙️ [CONFIG] Loading app settings...');

      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/app/settings'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _settings = Map<String, dynamic>.from(data);
        _initialized = true;
        print('✅ [CONFIG] Settings loaded: $_settings');
      } else {
        print('⚠️ [CONFIG] Failed to load settings, using defaults');
        _initialized = true;
      }
    } catch (e) {
      print('❌ [CONFIG] Error loading settings: $e');
      print('⚠️ [CONFIG] Using default settings');
      _initialized = true;
    } finally {
      _loading = false;
    }
  }

  // Refresh settings
  Future<void> refresh() async {
    _initialized = false;
    await loadSettings();
  }

  // Get specific setting
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings[key] ?? defaultValue;
  }

  // Check if app is in maintenance mode
  bool isMaintenanceMode() {
    return maintenanceMode;
  }
}

