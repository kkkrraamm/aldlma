// lib/ai_tools_page.dart
// Dalma AI Tools - صفحة أدوات الذكاء الاصطناعي
// أدوات ذكية متنوعة لخدمة المستخدمين
// by Abdulkarim ✨

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'theme_config.dart';
import 'ai_calorie_calculator.dart';

class AIToolsPage extends StatelessWidget {
  const AIToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    final tools = [
      {
        'icon': '🍽️',
        'title': 'حاسبة السعرات',
        'subtitle': 'حلل صورة طعامك واعرف القيم الغذائية',
        'color': Colors.orange,
        'page': const AICalorieCalculatorPage(),
      },
      {
        'icon': '🩺',
        'title': 'محلل الأشعة',
        'subtitle': 'تحليل ذكي للأشعة الطبية',
        'color': Colors.blue,
        'page': null, // سننفذها لاحقاً
      },
      {
        'icon': '🌿',
        'title': 'معرّف النباتات',
        'subtitle': 'اكتشف اسم ونوع النبات',
        'color': Colors.green,
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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar مع تأثير Glass
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // خلفية متدرجة
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          primaryColor.withOpacity(0.3),
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🤖 أدوات الذكاء الاصطناعي',
                            style: GoogleFonts.cairo(
                              color: theme.textPrimaryColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'أدوات ذكية متنوعة لخدمتك',
                            style: GoogleFonts.cairo(
                              color: theme.textSecondaryColor,
                              fontSize: 14,
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

          // قائمة الأدوات
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tool = tools[index];
                  return _AIToolCard(
                    icon: tool['icon'] as String,
                    title: tool['title'] as String,
                    subtitle: tool['subtitle'] as String,
                    color: tool['color'] as Color,
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
                              style: GoogleFonts.cairo(),
                            ),
                            backgroundColor: primaryColor,
                          ),
                        );
                      }
                    },
                  );
                },
                childCount: tools.length,
              ),
            ),
          ),

          // مساحة إضافية
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
  final VoidCallback onTap;

  const _AIToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الأيقونة
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // العنوان
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: theme.textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                // الوصف
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      color: theme.textSecondaryColor,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

