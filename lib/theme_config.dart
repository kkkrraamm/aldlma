import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎨 إدارة الثيمات (النهاري والليلي) لتطبيق دلما
class ThemeConfig extends ChangeNotifier {
  static final ThemeConfig _instance = ThemeConfig._internal();
  static ThemeConfig get instance => _instance;
  
  ThemeConfig._internal() {
    _loadThemeMode();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // 🌅 ألوان الوضع النهاري (الحالي)
  static const kBeige = Color(0xFFFEF3E2);
  static const kMint = Color(0xFFECFDF5);
  static const kGreen = Color(0xFF10B981);
  static const kSand = Color(0xFFFBBF24);
  static const kInk = Color(0xFF111827);
  static const kSubtle = Color(0xFF6B7280);

  // 🌙 ألوان الوضع الليلي (جديد)
  static const kNightDeep = Color(0xFF0F172A);      // أزرق داكن عميق
  static const kNightSoft = Color(0xFF1E293B);      // أزرق داكن ناعم
  static const kNightAccent = Color(0xFF334155);    // أزرق رمادي
  static const kGreenNight = Color(0xFF10B981);     // نفس الأخضر
  static const kGoldNight = Color(0xFFFBBF24);      // ذهبي دافئ
  static const kTextPrimary = Color(0xFFF8FAFC);    // أبيض ناعم
  static const kTextSecondary = Color(0xFFCBD5E1);  // رمادي فاتح
  static const kTextMuted = Color(0xFF94A3B8);      // رمادي متوسط

  // 📐 التدرجات
  static const kDayGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kBeige, kMint, kBeige],
  );

  static const kNightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kNightDeep, kNightSoft, kNightDeep],
  );

  // 🔍 تتبع استخدام الألوان الثابتة (للتطوير فقط)
  static final Set<String> _loggedWidgets = {};
  
  static void logColorUsage(String widgetName, String colorType, Color color) {
    final isDark = instance.isDarkMode;
    final key = '$widgetName-$colorType';
    
    // تجنب الطباعة المتكررة لنفس الـ widget
    if (_loggedWidgets.contains(key)) return;
    
    final isStaticColor = _isStaticColor(color);
    
    if (isStaticColor && isDark) {
      print('⚠️ [THEME WARNING] $widgetName يستخدم لون ثابت: $colorType = ${_colorToString(color)} في الوضع الليلي!');
      _loggedWidgets.add(key);
    }
  }
  
  static bool _isStaticColor(Color color) {
    // الألوان الثابتة المحظورة في الوضع الليلي
    final staticColors = [
      Colors.white,
      Colors.black,
      Colors.grey,
      Color(0xFFFFFFFF), // white
      Color(0xFF000000), // black
    ];
    
    // التحقق من Colors.grey.shadeX
    if (color.value >= 0xFFF5F5F5 && color.value <= 0xFFEEEEEE) return true; // grey[50-100]
    if (color.value >= 0xFFE0E0E0 && color.value <= 0xFF9E9E9E) return true; // grey[200-500]
    
    return staticColors.any((c) => c.value == color.value);
  }
  
  static String _colorToString(Color color) {
    return 'Color(0x${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()})';
  }
  
  static void clearLogs() {
    _loggedWidgets.clear();
  }

  // 🎨 الحصول على الألوان الحالية بناءً على الوضع
  Color get backgroundColor => _isDarkMode ? kNightDeep : const Color(0xFFF5F9ED); // نفس لون الصفحة الرئيسية (بيج فاتح)
  Color get surfaceColor => _isDarkMode ? kNightSoft : kBeige.withOpacity(0.3);
  Color get cardColor => _isDarkMode ? kNightSoft : Colors.white;
  Color get primaryColor => _isDarkMode ? kGreenNight : kGreen;
  Color get accentColor => _isDarkMode ? kGoldNight : kSand;
  Color get textPrimaryColor => _isDarkMode ? kTextPrimary : kInk;
  Color get textSecondaryColor => _isDarkMode ? kTextSecondary : kSubtle;
  Color get borderColor => _isDarkMode ? kNightAccent : Colors.grey.shade300;
  
  LinearGradient get headerGradient => _isDarkMode ? kNightGradient : kDayGradient;

  // 🎨 الظلال
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: _isDarkMode 
        ? Colors.black.withOpacity(0.3) 
        : Colors.black12.withOpacity(0.08),
      blurRadius: _isDarkMode ? 12 : 8,
      offset: Offset(0, _isDarkMode ? 4 : 2),
    ),
  ];

  // 🔄 تبديل الوضع
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    clearLogs(); // مسح السجلات السابقة عند التبديل
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    
    print('🌙 [THEME] تم التبديل إلى: ${_isDarkMode ? "الوضع الليلي" : "الوضع النهاري"}');
    print('🔍 [THEME] سيتم تتبع الألوان الثابتة تلقائياً...');
  }

  // 💾 تحميل الوضع المحفوظ
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
    print('🎨 [THEME] تم تحميل الوضع: ${_isDarkMode ? "ليلي" : "نهاري"}');
  }

  // 🎨 ThemeData للـ MaterialApp
  ThemeData get themeData {
    if (_isDarkMode) {
      // الوضع الليلي
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: kGreenNight,
        scaffoldBackgroundColor: kNightDeep,
        cardColor: kNightSoft,
        dividerColor: kNightAccent,
        colorScheme: ColorScheme.dark(
          primary: kGreenNight,
          secondary: kGoldNight,
          surface: kNightSoft,
          onSurface: kTextPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: kNightSoft,
          foregroundColor: kTextPrimary,
          elevation: 0,
          iconTheme: IconThemeData(color: kTextPrimary),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: kNightSoft,
          selectedItemColor: kGreenNight,
          unselectedItemColor: kTextMuted,
        ),
        useMaterial3: true,
      );
    } else {
      // الوضع النهاري - نفس الألوان الأصلية بالضبط!
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: kGreen,
        scaffoldBackgroundColor: const Color(0xFFF5F9ED),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kGreen,
          surface: const Color(0xFFF5F9ED),
          onSurface: const Color(0xFF1F2937),
          secondary: const Color(0xFF6B7280),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: kGreen,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: kGreen,
          unselectedItemColor: Color(0xFF6B7280),
        ),
        useMaterial3: true,
      );
    }
  }
}

