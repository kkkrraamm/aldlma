import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'notifications.dart';

/// 🌙 زر تبديل الوضع الليلي/النهاري - يمكن استخدامه في أي صفحة
class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double size;
  
  const ThemeToggleButton({
    Key? key,
    this.showLabel = false,
    this.size = 40,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, child) {
        final themeConfig = ThemeConfig.instance;
        final isDark = themeConfig.isDarkMode;
        
        if (showLabel) {
          // نسخة مع نص (للإعدادات)
          return ListTile(
            leading: Icon(
              isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: themeConfig.primaryColor,
            ),
            title: Text(
              isDark ? 'الوضع النهاري' : 'الوضع الليلي',
              style: TextStyle(color: themeConfig.textPrimaryColor),
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => _toggleTheme(themeConfig, isDark),
              activeColor: themeConfig.primaryColor,
            ),
            onTap: () => _toggleTheme(themeConfig, isDark),
          );
        }
        
        // نسخة أيقونة فقط (للـ AppBar)
        return InkWell(
          onTap: () => _toggleTheme(themeConfig, isDark),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark ? ThemeConfig.kNightAccent : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: themeConfig.cardShadow,
            ),
            child: Center(
              child: Icon(
                isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                size: size * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _toggleTheme(ThemeConfig themeConfig, bool isDark) {
    themeConfig.toggleTheme();
    NotificationsService.instance.toast(
      isDark ? 'تم التبديل للوضع النهاري' : 'تم التبديل للوضع الليلي',
      icon: isDark ? Icons.wb_sunny : Icons.nightlight_round,
      color: themeConfig.primaryColor,
    );
  }
}



