// lib/ai_tools_page.dart
// Dalma AI Tools - أدوات الدلما الذكية
// أدوات ذكية متنوعة لخدمة المستخدمين
// by Abdulkarim ✨

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'theme_config.dart';
import 'ai_calorie_calculator.dart';

class AIToolsPage extends StatefulWidget {
  const AIToolsPage({super.key});

  @override
  State<AIToolsPage> createState() => _AIToolsPageState();
}

class _AIToolsPageState extends State<AIToolsPage> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _tools = [
    {
      'icon': '🍽️',
      'title': 'حاسبة السعرات',
      'subtitle': 'حلل صورة طعامك واعرف القيم الغذائية',
      'color': Colors.orange,
      'page': const AICalorieCalculatorPage(),
    },
    {
      'icon': '👨‍🍳',
      'title': 'مساعد الطبخ الذكي',
      'subtitle': 'وصفات من المكونات المتاحة لديك',
      'color': const Color(0xFFFF6B6B),
      'page': null, // سيتم إضافتها
    },
    {
      'icon': '📚',
      'title': 'مساعد التعليم',
      'subtitle': 'حل المسائل وشرح المفاهيم الدراسية',
      'color': const Color(0xFF4ECDC4),
      'page': null, // سيتم إضافتها
    },
    {
      'icon': '🌱',
      'title': 'محلل النباتات',
      'subtitle': 'التعرف على النباتات ونصائح العناية',
      'color': const Color(0xFF95E1D3),
      'page': null, // سيتم إضافتها
    },
    {
      'icon': '🩺',
      'title': 'محلل الأشعة',
      'subtitle': 'تحليل ذكي للأشعة الطبية',
      'color': Colors.blue,
      'page': null,
    },
    {
      'icon': '🚗',
      'title': 'تقييم السيارة',
      'subtitle': 'تحليل الأضرار وتقدير التكلفة',
      'color': Colors.red,
      'page': null,
    },
    {
      'icon': '📄',
      'title': 'قارئ المستندات',
      'subtitle': 'استخراج وترجمة النصوص',
      'color': Colors.indigo,
      'page': null,
    },
    {
      'icon': '🎨',
      'title': 'محلل الألوان',
      'subtitle': 'استخراج لوحة الألوان من الصور',
      'color': Colors.purple,
      'page': null,
    },
    {
      'icon': '👔',
      'title': 'مستشار الأزياء',
      'subtitle': 'تنسيقات ونصائح للملابس',
      'color': Colors.pink,
      'page': null,
    },
    {
      'icon': '🏠',
      'title': 'مقيّم العقارات',
      'subtitle': 'تقييم وتقدير قيمة العقار',
      'color': Colors.brown,
      'page': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar احترافي مع تأثير Glass
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textPrimaryColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // خلفية متدرجة
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.4),
                          primaryColor.withOpacity(0.1),
                          theme.backgroundColor,
                        ],
                      ),
                    ),
                  ),
                  // Glass Effect
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: theme.backgroundColor.withOpacity(0.3),
                    ),
                  ),
                  // المحتوى
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // شعار الدلما
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🤖',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Dalma AI',
                                  style: GoogleFonts.cairo(
                                    color: primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // العنوان الرئيسي
                          Text(
                            'أدوات الدلما',
                            style: GoogleFonts.cairo(
                              color: theme.textPrimaryColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // الوصف
                          Text(
                            'أدوات ذكية متنوعة لخدمتك بتقنية الذكاء الاصطناعي',
                            style: GoogleFonts.cairo(
                              color: theme.textSecondaryColor,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // قسم الإحصائيات السريعة
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: '⚡',
                      label: 'أداة متاحة',
                      value: '8',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '🚀',
                      label: 'قريباً',
                      value: '7',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: '✨',
                      label: 'مجاني',
                      value: '100%',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // عنوان القسم
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'اختر أداة',
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          // قائمة الأدوات
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tool = _tools[index];
                  return _AIToolCard(
                    icon: tool['icon'] as String,
                    title: tool['title'] as String,
                    subtitle: tool['subtitle'] as String,
                    color: tool['color'] as Color,
                    isAvailable: tool['page'] != null,
                    onTap: () {
                      final page = tool['page'] as Widget?;
                      if (page != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => page),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'قريباً 🚀',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: theme.textPrimaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
                childCount: _tools.length,
              ),
            ),
          ),

          // مساحة إضافية للشريط السفلي
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      
      // شريط تنقل ثابت
      bottomNavigationBar: _buildBottomBar(theme, isDark, primaryColor),
    );
  }

  Widget _buildBottomBar(ThemeConfig theme, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                isActive: _currentIndex == 0,
                onTap: () {
                  setState(() => _currentIndex = 0);
                  Navigator.pop(context);
                },
              ),
              _NavBarItem(
                icon: Icons.apps_rounded,
                label: 'الأدوات',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavBarItem(
                icon: Icons.favorite_rounded,
                label: 'المفضلة',
                isActive: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavBarItem(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: theme.textSecondaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AIToolCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isAvailable;
  final VoidCallback onTap;

  const _AIToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // المحتوى
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الأيقونة
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // العنوان
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: theme.textPrimaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // الوصف
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      color: theme.textSecondaryColor,
                      fontSize: 11,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // شارة "قريباً"
            if (!isAvailable)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'قريباً',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primaryColor : theme.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isActive ? primaryColor : theme.textSecondaryColor,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
