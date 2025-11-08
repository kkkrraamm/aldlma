// lib/ai_tools_page.dart
// Dalma AI Tools - أدوات الدلما الذكية
// أدوات ذكية متنوعة لخدمة المستخدمين مع تصنيفات احترافية
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
  int _selectedCategoryIndex = 0;

  // التصنيفات مع الأدوات
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'name': 'الكل',
      'icon': '✨',
      'color': const Color(0xFF6C63FF),
      'gradient': const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
      ),
    },
    {
      'id': 'health',
      'name': 'الصحة',
      'icon': '🏥',
      'color': const Color(0xFF4CAF50),
      'gradient': const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
      ),
    },
    {
      'id': 'food',
      'name': 'الطعام',
      'icon': '🍽️',
      'color': const Color(0xFFFF9800),
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
      ),
    },
    {
      'id': 'education',
      'name': 'التعليم',
      'icon': '📚',
      'color': const Color(0xFF2196F3),
      'gradient': const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
      ),
    },
    {
      'id': 'nature',
      'name': 'الطبيعة',
      'icon': '🌿',
      'color': const Color(0xFF009688),
      'gradient': const LinearGradient(
        colors: [Color(0xFF009688), Color(0xFF26A69A)],
      ),
    },
    {
      'id': 'realestate',
      'name': 'العقارات',
      'icon': '🏠',
      'color': const Color(0xFF795548),
      'gradient': const LinearGradient(
        colors: [Color(0xFF795548), Color(0xFF8D6E63)],
      ),
    },
    {
      'id': 'sports',
      'name': 'الرياضة',
      'icon': '💪',
      'color': const Color(0xFFE91E63),
      'gradient': const LinearGradient(
        colors: [Color(0xFFE91E63), Color(0xFFEC407A)],
      ),
    },
    {
      'id': 'lifestyle',
      'name': 'نمط الحياة',
      'icon': '✨',
      'color': const Color(0xFF9C27B0),
      'gradient': const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFFAB47BC)],
      ),
    },
  ];

  // الأدوات مع التصنيفات
  final List<Map<String, dynamic>> _tools = [
    // الصحة
    {
      'icon': '🩺',
      'title': 'محلل الأشعة',
      'subtitle': 'تحليل ذكي للأشعة الطبية',
      'category': 'health',
      'gradient': const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      ),
      'page': null,
    },
    {
      'icon': '💊',
      'title': 'محلل الأدوية',
      'subtitle': 'فهم الوصفات الطبية والأدوية',
      'category': 'health',
      'gradient': const LinearGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
      ),
      'page': null,
    },
    
    // الطعام
    {
      'icon': '🍎',
      'title': 'حاسبة السعرات',
      'subtitle': 'حلل صورة طعامك واعرف القيم الغذائية',
      'category': 'food',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
      ),
      'page': const AICalorieCalculatorPage(),
    },
    {
      'icon': '👨‍🍳',
      'title': 'مساعد الطبخ الذكي',
      'subtitle': 'وصفات من المكونات المتاحة لديك',
      'category': 'food',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
      ),
      'page': null,
    },
    
    // التعليم
    {
      'icon': '📚',
      'title': 'مساعد التعليم',
      'subtitle': 'حل المسائل وشرح المفاهيم الدراسية',
      'category': 'education',
      'gradient': const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
      ),
      'page': null,
    },
    {
      'icon': '📝',
      'title': 'محلل المستندات',
      'subtitle': 'تحليل وتلخيص الوثائق والتقارير',
      'category': 'education',
      'gradient': const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      ),
      'page': null,
    },
    
    // الطبيعة
    {
      'icon': '🌱',
      'title': 'محلل النباتات',
      'subtitle': 'التعرف على النباتات ونصائح العناية',
      'category': 'nature',
      'gradient': const LinearGradient(
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      ),
      'page': null,
    },
    
    // العقارات
    {
      'icon': '🏘️',
      'title': 'مُقيّم العقارات',
      'subtitle': 'تقييم دقيق لقيمة العقار',
      'category': 'realestate',
      'gradient': const LinearGradient(
        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      ),
      'page': null,
    },
    {
      'icon': '🔍',
      'title': 'كاشف عيوب البناء',
      'subtitle': 'اكتشاف المشاكل والعيوب في العقار',
      'category': 'realestate',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFA8BFF), Color(0xFF2BD2FF)],
      ),
      'page': null,
    },
    {
      'icon': '🎨',
      'title': 'مصمم الديكور',
      'subtitle': 'تصميم وتحسين ديكور المنزل',
      'category': 'realestate',
      'gradient': const LinearGradient(
        colors: [Color(0xFFF857A6), Color(0xFFFF5858)],
      ),
      'page': null,
    },
    
    // الرياضة
    {
      'icon': '🏋️',
      'title': 'المدرب الشخصي',
      'subtitle': 'برنامج تدريب مخصص حسب هدفك',
      'category': 'sports',
      'gradient': const LinearGradient(
        colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
      ),
      'page': null,
    },
    {
      'icon': '🥗',
      'title': 'مخطط النظام الغذائي',
      'subtitle': 'نظام غذائي متكامل للرياضيين',
      'category': 'sports',
      'gradient': const LinearGradient(
        colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      ),
      'page': null,
    },
    {
      'icon': '📏',
      'title': 'حاسبة مؤشر الجسم',
      'subtitle': 'تحليل شامل لتكوين الجسم',
      'category': 'sports',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF6B95), Color(0xFFFFC796)],
      ),
      'page': null,
    },
    
    // نمط الحياة
    {
      'icon': '👔',
      'title': 'مستشار الأزياء',
      'subtitle': 'تنسيقات ونصائح للملابس',
      'category': 'lifestyle',
      'gradient': const LinearGradient(
        colors: [Color(0xFFD38312), Color(0xFFA83279)],
      ),
      'page': null,
    },
    {
      'icon': '🚗',
      'title': 'محلل السيارات',
      'subtitle': 'تشخيص مشاكل السيارة',
      'category': 'lifestyle',
      'gradient': const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
      ),
      'page': null,
    },
    {
      'icon': '🌍',
      'title': 'مساعد الترجمة',
      'subtitle': 'ترجمة نصوص وصور بذكاء',
      'category': 'lifestyle',
      'gradient': const LinearGradient(
        colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
      ),
      'page': null,
    },
  ];


  List<Map<String, dynamic>> _getFilteredTools() {
    if (_selectedCategoryIndex == 0) {
      return _tools; // الكل
    }
    final selectedCategory = _categories[_selectedCategoryIndex]['id'];
    return _tools.where((tool) => tool['category'] == selectedCategory).toList();
  }

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
          // AppBar مبهر مع تأثير Glass
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            ThemeConfig.kGoldNight.withOpacity(0.3),
                            ThemeConfig.kGoldNight.withOpacity(0.1),
                          ]
                        : [
                            ThemeConfig.kGreen.withOpacity(0.3),
                            ThemeConfig.kGreen.withOpacity(0.1),
                          ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated circles background
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryColor.withOpacity(0.3),
                              primaryColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryColor.withOpacity(0.2),
                              primaryColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          // Icon مع تأثير Glow
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.3),
                                  primaryColor.withOpacity(0.1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              '🤖',
                              style: const TextStyle(fontSize: 50),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Title
                          Text(
                            'أدوات الدلما',
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimaryColor,
                              shadows: [
                                Shadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'أدوات ذكية لتسهيل حياتك',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: theme.textPrimaryColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Innovative 3D Categories Carousel
          SliverToBoxAdapter(
            child: Container(
              height: 160,
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Stack(
                children: [
                  // Background Glow Effect
                  Positioned.fill(
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (_categories[_selectedCategoryIndex]['color'] as Color).withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // 3D Carousel
                  PageView.builder(
                    controller: PageController(
                      viewportFraction: 0.35,
                      initialPage: _selectedCategoryIndex,
                    ),
                    onPageChanged: (index) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategoryIndex == index;
                      final distance = (index - _selectedCategoryIndex).abs();
                      final scale = isSelected ? 1.0 : 0.75 - (distance * 0.1);
                      final opacity = isSelected ? 1.0 : 0.4 - (distance * 0.15);
                      
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: scale.clamp(0.5, 1.0)),
                        builder: (context, scaleValue, child) {
                          return Transform.scale(
                            scale: scaleValue,
                            child: Opacity(
                              opacity: opacity.clamp(0.2, 1.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryIndex = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: isSelected ? 10 : 20,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              (category['color'] as Color),
                                              (category['color'] as Color).withOpacity(0.7),
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              theme.cardColor.withOpacity(0.6),
                                              theme.cardColor.withOpacity(0.4),
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.5)
                                          : theme.textPrimaryColor.withOpacity(0.15),
                                      width: isSelected ? 2.5 : 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (category['color'] as Color).withOpacity(0.4),
                                              blurRadius: 25,
                                              spreadRadius: 3,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.1),
                                              blurRadius: 10,
                                              spreadRadius: -5,
                                              offset: const Offset(0, -5),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: isSelected ? 15 : 8,
                                        sigmaY: isSelected ? 15 : 8,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(isSelected ? 0.15 : 0.05),
                                              Colors.white.withOpacity(isSelected ? 0.05 : 0.02),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Animated Icon
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(milliseconds: 400),
                                              curve: Curves.elasticOut,
                                              tween: Tween(
                                                begin: 0,
                                                end: isSelected ? 1.2 : 1.0,
                                              ),
                                              builder: (context, iconScale, child) {
                                                return Transform.scale(
                                                  scale: iconScale,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isSelected
                                                          ? Colors.white.withOpacity(0.2)
                                                          : Colors.transparent,
                                                    ),
                                                    child: Text(
                                                      category['icon'],
                                                      style: TextStyle(
                                                        fontSize: isSelected ? 40 : 32,
                                                        shadows: isSelected
                                                            ? [
                                                                Shadow(
                                                                  color: Colors.black.withOpacity(0.3),
                                                                  blurRadius: 10,
                                                                  offset: const Offset(0, 4),
                                                                ),
                                                              ]
                                                            : [],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            
                                            const SizedBox(height: 8),
                                            
                                            // Category Name
                                            Text(
                                              category['name'],
                                              style: GoogleFonts.cairo(
                                                fontSize: isSelected ? 16 : 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : theme.textPrimaryColor.withOpacity(0.8),
                                                shadows: isSelected
                                                    ? [
                                                        Shadow(
                                                          color: Colors.black.withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Tools Count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  key: ValueKey(_selectedCategoryIndex),
                  '${_getFilteredTools().length} أداة متاحة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimaryColor.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),

          // Tools Grid
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              key: ValueKey(_selectedCategoryIndex),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tool = _getFilteredTools()[index];
                  return _buildToolCard(context, tool, theme, isDark);
                },
                childCount: _getFilteredTools().length,
              ),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    Map<String, dynamic> tool,
    ThemeConfig theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        if (tool['page'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => tool['page']),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'قريباً... 🚀',
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              backgroundColor: theme.textPrimaryColor.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.all(20),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: tool['gradient'],
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: (tool['gradient'] as LinearGradient).colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon مع تأثير
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      tool['icon'],
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Title
                  Text(
                    tool['title'],
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    tool['subtitle'],
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Badge إذا كانت جاهزة
                  if (tool['page'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'متاح الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'قريباً',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
