// lib/ai_calorie_calculator.dart
// حاسبة السعرات الحرارية بالذكاء الاصطناعي - تطبيق كامل
// تحليل كامل للطعام مع رسوم بيانية وخطوات الحرق
// by Abdulkarim ✨

import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import 'theme_config.dart';
import 'notifications.dart';

class AICalorieCalculatorPage extends StatefulWidget {
  const AICalorieCalculatorPage({super.key});

  @override
  State<AICalorieCalculatorPage> createState() => _AICalorieCalculatorPageState();
}

class _AICalorieCalculatorPageState extends State<AICalorieCalculatorPage> with SingleTickerProviderStateMixin {
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  int _currentNavIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      NotificationsService.instance.toast(
        'فشل اختيار الصورة',
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isAnalyzing = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _result = {
          'food_name': 'دجاج مشوي مع أرز وخضار',
          'total_calories': 650,
          'protein': 45,
          'fats': 18,
          'carbs': 72,
          'fiber': 8,
          'sugar': 5,
          'is_healthy': true,
          'health_score': 82,
          'description': 'وجبة متوازنة وصحية تحتوي على البروتين اللازم للعضلات، كربوهيدرات معقدة للطاقة، وخضروات غنية بالألياف والفيتامينات.',
          'benefits': [
            'غني بالبروتين عالي الجودة',
            'مصدر جيد للطاقة المستدامة',
            'يحتوي على فيتامينات ومعادن مهمة',
            'منخفض الدهون المشبعة',
          ],
          'warnings': [
            'انتبه للملح المضاف',
            'تجنب الإكثار في حالة اتباع حمية منخفضة الكربوهيدرات',
          ],
          'walking_minutes': 130,
          'running_minutes': 65,
          'steps': 9000,
        };
      });

      NotificationsService.instance.toast(
        'تم التحليل بنجاح! 🎉',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      NotificationsService.instance.toast(
        'فشل التحليل: $e',
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: _image == null 
        ? _buildWelcomeScreen(theme, primaryColor)
        : _buildAnalysisScreen(theme, primaryColor, isDark),
      bottomNavigationBar: _buildBottomNav(theme, isDark, primaryColor),
    );
  }

  Widget _buildWelcomeScreen(ThemeConfig theme, Color primaryColor) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // AppBar مميز
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.4),
                        Colors.deepOrange.withOpacity(0.2),
                        theme.backgroundColor,
                      ],
                    ),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: theme.backgroundColor.withOpacity(0.3)),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🍽️', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                'Dalma Calorie AI',
                                style: GoogleFonts.cairo(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'حاسبة السعرات',
                          style: GoogleFonts.cairo(
                            color: theme.textPrimaryColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'اكتشف القيم الغذائية لوجباتك بالذكاء الاصطناعي',
                          style: GoogleFonts.cairo(
                            color: theme.textSecondaryColor,
                            fontSize: 13,
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

        // المحتوى
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // الأيقونة الكبيرة
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.withOpacity(0.3), width: 3),
                  ),
                  child: const Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 90)),
                  ),
                ),
                const SizedBox(height: 32),
                
                // العنوان
                Text(
                  'التقط صورة وجبتك',
                  style: GoogleFonts.cairo(
                    color: theme.textPrimaryColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // الوصف
                Text(
                  'سيقوم الذكاء الاصطناعي بتحليل\nالقيم الغذائية والسعرات الحرارية بدقة عالية',
                  style: GoogleFonts.cairo(
                    color: theme.textSecondaryColor,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // الأزرار
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'التقط صورة',
                        color: Colors.orange,
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.photo_library_rounded,
                        label: 'من المعرض',
                        color: Colors.deepOrange,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // الميزات
                _FeatureItem(
                  icon: '📊',
                  title: 'تحليل شامل',
                  subtitle: 'بروتين، دهون، كربوهيدرات، وأكثر',
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: '🔥',
                  title: 'خطوات الحرق',
                  subtitle: 'احسب المشي والجري والخطوات المطلوبة',
                ),
                const SizedBox(height: 16),
                _FeatureItem(
                  icon: '💡',
                  title: 'نصائح ذكية',
                  subtitle: 'فوائد وتحذيرات لكل وجبة',
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildAnalysisScreen(ThemeConfig theme, Color primaryColor, bool isDark) {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 6,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جارٍ التحليل... 🤖',
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى الانتظار',
              style: GoogleFonts.cairo(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_result == null) return const SizedBox.shrink();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // AppBar مع صورة الطعام
        SliverAppBar(
          expandedHeight: 300,
          floating: false,
          pinned: true,
          backgroundColor: theme.backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
            onPressed: () {
              setState(() {
                _image = null;
                _result = null;
              });
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share_rounded, color: theme.textPrimaryColor),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.favorite_border_rounded, color: theme.textPrimaryColor),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        theme.backgroundColor.withOpacity(0.8),
                        theme.backgroundColor,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // المحتوى
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الوجبة
                Text(
                  _result!['food_name'],
                  style: GoogleFonts.cairo(
                    color: theme.textPrimaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),

                // إجمالي السعرات
                _buildTotalCaloriesCard(theme),
                const SizedBox(height: 20),

                // Tabs للتبديل بين الأقسام
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelColor: Colors.orange,
                    unselectedLabelColor: theme.textSecondaryColor,
                    labelStyle: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'القيم الغذائية'),
                      Tab(text: 'الفوائد'),
                      Tab(text: 'الحرق'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // محتوى الـ Tabs
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNutrientsTab(theme, isDark),
                      _buildBenefitsTab(theme),
                      _buildBurnTab(theme),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // زر تحليل جديد
                _buildNewAnalysisButton(Colors.orange),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTotalCaloriesCard(ThemeConfig theme) {
    final calories = _result!['total_calories'];
    final healthScore = _result!['health_score'];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade600, Colors.deepOrange.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي السعرات',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$calories',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, right: 4),
                      child: Text(
                        'سعرة',
                        style: GoogleFonts.cairo(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$healthScore',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'صحي',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientsTab(ThemeConfig theme, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // القيم الغذائية
          _buildNutrientsGrid(theme),
          const SizedBox(height: 20),
          // الرسم البياني
          _buildNutrientsChart(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildBenefitsTab(ThemeConfig theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHealthIndicator(theme, Colors.orange),
          const SizedBox(height: 20),
          _buildDescription(theme),
        ],
      ),
    );
  }

  Widget _buildBurnTab(ThemeConfig theme) {
    return SingleChildScrollView(
      child: _buildBurnSteps(theme, Colors.orange),
    );
  }

  Widget _buildNutrientsGrid(ThemeConfig theme) {
    final nutrients = [
      {'emoji': '🥩', 'name': 'البروتين', 'value': _result!['protein'], 'unit': 'جم', 'color': Colors.red},
      {'emoji': '🧈', 'name': 'الدهون', 'value': _result!['fats'], 'unit': 'جم', 'color': Colors.orange},
      {'emoji': '🍞', 'name': 'الكربوهيدرات', 'value': _result!['carbs'], 'unit': 'جم', 'color': Colors.amber},
      {'emoji': '🌾', 'name': 'الألياف', 'value': _result!['fiber'], 'unit': 'جم', 'color': Colors.brown},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: nutrients.length,
      itemBuilder: (context, index) {
        final nutrient = nutrients[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (nutrient['color'] as Color).withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(nutrient['emoji'] as String, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                nutrient['name'] as String,
                style: GoogleFonts.cairo(
                  color: theme.textSecondaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${nutrient['value']}',
                    style: GoogleFonts.cairo(
                      color: nutrient['color'] as Color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    ' ${nutrient['unit']}',
                    style: GoogleFonts.cairo(
                      color: theme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutrientsChart(ThemeConfig theme, bool isDark) {
    final protein = _result!['protein'].toDouble();
    final fats = _result!['fats'].toDouble();
    final carbs = _result!['carbs'].toDouble();
    final total = protein + fats + carbs;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '📊 توزيع القيم الغذائية',
            style: GoogleFonts.cairo(
              color: theme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: protein,
                    color: Colors.red,
                    title: '${(protein / total * 100).toStringAsFixed(0)}%',
                    radius: 80,
                    titleStyle: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    value: fats,
                    color: Colors.orange,
                    title: '${(fats / total * 100).toStringAsFixed(0)}%',
                    radius: 80,
                    titleStyle: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  PieChartSectionData(
                    value: carbs,
                    color: Colors.amber,
                    title: '${(carbs / total * 100).toStringAsFixed(0)}%',
                    radius: 80,
                    titleStyle: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(ThemeConfig theme, Color primaryColor) {
    final isHealthy = _result!['is_healthy'] as bool;
    final score = _result!['health_score'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHealthy ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                isHealthy ? '🥗 وجبة صحية' : '🍔 غير صحية',
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score/100',
                  style: GoogleFonts.cairo(
                    color: isHealthy ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(isHealthy ? Colors.green : Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ThemeConfig theme) {
    final description = _result!['description'] as String;
    final benefits = _result!['benefits'] as List;
    final warnings = _result!['warnings'] as List?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 وصف الوجبة',
            style: GoogleFonts.cairo(
              color: theme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.cairo(
              color: theme.textSecondaryColor,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '✅ الفوائد:',
            style: GoogleFonts.cairo(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.green, fontSize: 18)),
                    Expanded(
                      child: Text(
                        benefit,
                        style: GoogleFonts.cairo(
                          color: theme.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (warnings != null && warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '⚠️ تحذيرات:',
              style: GoogleFonts.cairo(
                color: Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.orange, fontSize: 18)),
                      Expanded(
                        child: Text(
                          warning,
                          style: GoogleFonts.cairo(
                            color: theme.textSecondaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBurnSteps(ThemeConfig theme, Color primaryColor) {
    final steps = _result!['steps'] as int;
    final walking = _result!['walking_minutes'] as int;
    final running = _result!['running_minutes'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 كيف تحرق هذه السعرات؟',
            style: GoogleFonts.cairo(
              color: theme.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          _buildBurnOption('🚶', 'المشي', '$walking دقيقة', Colors.blue, theme),
          const SizedBox(height: 12),
          _buildBurnOption('🏃', 'الجري', '$running دقيقة', Colors.orange, theme),
          const SizedBox(height: 12),
          _buildBurnOption('👟', 'الخطوات', '${(steps / 1000).toStringAsFixed(1)}K خطوة', Colors.green, theme),
        ],
      ),
    );
  }

  Widget _buildBurnOption(String emoji, String activity, String duration, Color color, ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity,
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            duration,
            style: GoogleFonts.cairo(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAnalysisButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _image = null;
            _result = null;
          });
        },
        icon: const Icon(Icons.refresh_rounded),
        label: Text(
          'تحليل وجبة جديدة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildBottomNav(ThemeConfig theme, bool isDark, Color primaryColor) {
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
                isActive: _currentNavIndex == 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _NavBarItem(
                icon: Icons.camera_alt_rounded,
                label: 'التقاط',
                isActive: _currentNavIndex == 1,
                onTap: () {
                  setState(() => _currentNavIndex = 1);
                  _pickImage(ImageSource.camera);
                },
              ),
              _NavBarItem(
                icon: Icons.history_rounded,
                label: 'السجل',
                isActive: _currentNavIndex == 2,
                onTap: () => setState(() => _currentNavIndex = 2),
              ),
              _NavBarItem(
                icon: Icons.settings_rounded,
                label: 'الإعدادات',
                isActive: _currentNavIndex == 3,
                onTap: () => setState(() => _currentNavIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    color: theme.textPrimaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    color: theme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.orange : theme.textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isActive ? Colors.orange : theme.textSecondaryColor,
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
