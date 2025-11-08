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
      bottomNavigationBar: Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: false,
                  onTap: () => Navigator.pop(context),
                  theme: theme,
                  primaryColor: primaryColor,
                ),
                _buildNavItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'الأدوات',
                  isActive: true,
                  onTap: () {},
                  theme: theme,
                  primaryColor: primaryColor,
                ),
                _buildNavItem(
                  icon: Icons.explore_rounded,
                  label: 'استكشف',
                  isActive: false,
                  onTap: () {},
                  theme: theme,
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header مثل الصفحة الرئيسية
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                gradient: theme.headerGradient,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),
                        // Top row with back button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.cardColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: primaryColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'رجوع',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // AI Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.3),
                                    primaryColor.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '✨',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI Tools',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Logo with glow effect
                        Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft radial glow
                              Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      primaryColor.withOpacity(0.3),
                                      primaryColor.withOpacity(0.2),
                                      primaryColor.withOpacity(0.1),
                                      primaryColor.withOpacity(0.05),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                                  ),
                                ),
                              ),
                              // Logo
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/img/aldlma.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              primaryColor,
                                              primaryColor.withOpacity(0.7),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'د',
                                            style: GoogleFonts.cairo(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'أدوات الدلما الذكية',
                                style: GoogleFonts.cairo(
                                  fontSize: 24,
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
                              const SizedBox(height: 8),
                              Text(
                                'أدوات ذكية لتسهيل حياتك اليومية',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: theme.textPrimaryColor.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Elegant Categories Grid
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                                (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'التصنيفات',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_getFilteredTools().length} أداة',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: theme.textPrimaryColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Categories Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategoryIndex == index;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      (category['color'] as Color).withOpacity(0.8),
                                      (category['color'] as Color).withOpacity(0.5),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      theme.cardColor.withOpacity(0.5),
                                      theme.cardColor.withOpacity(0.3),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? (category['color'] as Color).withOpacity(0.6)
                                  : theme.textPrimaryColor.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (category['color'] as Color).withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                tween: Tween(
                                  begin: isSelected ? 0.8 : 1.0,
                                  end: isSelected ? 1.1 : 1.0,
                                ),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Text(
                                      category['icon'],
                                      style: TextStyle(
                                        fontSize: isSelected ? 32 : 28,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category['name'],
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.textPrimaryColor.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
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
              padding: const EdgeInsets.all(16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon مع تأثير
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      tool['icon'],
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    tool['title'],
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Subtitle
                  Flexible(
                    child: Text(
                      tool['subtitle'],
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
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

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeConfig theme,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.2),
                    primaryColor.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(15),
          border: isActive
              ? Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primaryColor : theme.textPrimaryColor.withOpacity(0.5),
              size: isActive ? 24 : 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
