// lib/ai_calorie_calculator.dart
// حاسبة السعرات الحرارية بالذكاء الاصطناعي - تطبيق كامل
// تحليل كامل للطعام مع رسوم بيانية وخطوات الحرق + انيميشن مبهر
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

class _AICalorieCalculatorPageState extends State<AICalorieCalculatorPage> with TickerProviderStateMixin {
  File? _image;
  bool _isAnalyzing = false;
  late TabController _tabController;
  int _currentNavIndex = 0;

  // Animation Controllers
  late AnimationController _numberAnimationController;
  late AnimationController _chartAnimationController;
  
  // البيانات الافتراضية (قبل التحليل)
  Map<String, dynamic> _result = {
    'food_name': 'في انتظار التحليل...',
    'total_calories': 0,
    'protein': 0,
    'fats': 0,
    'carbs': 0,
    'fiber': 0,
    'sugar': 0,
    'is_healthy': true,
    'health_score': 0,
    'description': 'قم بالتقاط صورة وجبتك للحصول على تحليل كامل للقيم الغذائية والسعرات الحرارية.',
    'benefits': [],
    'warnings': [],
    'walking_minutes': 0,
    'running_minutes': 0,
    'steps': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // تهيئة Animation Controllers
    _numberAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _numberAnimationController.dispose();
    _chartAnimationController.dispose();
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
      // قراءة الصورة وتحويلها إلى Base64
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('📸 [CALORIE] بدء تحليل الصورة...');
      print('📸 [CALORIE] حجم الصورة: ${bytes.length} bytes');

      // إرسال الصورة إلى Backend API
      final response = await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/ai/analyze-food'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'image': base64Image,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.');
        },
      );

      print('📸 [CALORIE] استجابة API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [CALORIE] تم التحليل بنجاح');
        print('📊 [CALORIE] البيانات: ${data.toString().substring(0, 100)}...');

        // التحقق من أن الصورة تحتوي على طعام
        final isFood = data['is_food'] ?? true;
        
        if (!isFood) {
          // الصورة لا تحتوي على طعام
          print('⚠️ [CALORIE] الصورة لا تحتوي على طعام');
          
          setState(() {
            _result = {
              'food_name': data['food_name'] ?? 'ليس طعاماً',
              'total_calories': 0,
              'protein': 0,
              'fats': 0,
              'carbs': 0,
              'fiber': 0,
              'sugar': 0,
              'is_healthy': true,
              'health_score': 0,
              'description': data['description'] ?? 'عذراً، هذه الصورة لا تحتوي على طعام. نظام كارمار الذكي مصمم لتحليل الأطعمة فقط.',
              'benefits': [],
              'warnings': List<String>.from(data['warnings'] ?? ['يرجى تصوير وجبة غذائية للحصول على التحليل']),
              'walking_minutes': 0,
              'running_minutes': 0,
              'steps': 0,
            };
          });
          
          NotificationsService.instance.toast(
            '⚠️ هذه الصورة لا تحتوي على طعام',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          );
          return;
        }

        setState(() {
          _result = {
            'food_name': data['food_name'] ?? 'وجبة غير معروفة',
            'total_calories': data['total_calories'] ?? 0,
            'protein': data['protein'] ?? 0,
            'fats': data['fats'] ?? 0,
            'carbs': data['carbs'] ?? 0,
            'fiber': data['fiber'] ?? 0,
            'sugar': data['sugar'] ?? 0,
            'is_healthy': data['is_healthy'] ?? true,
            'health_score': data['health_score'] ?? 0,
            'description': data['description'] ?? 'لا يوجد وصف متاح',
            'benefits': List<String>.from(data['benefits'] ?? []),
            'warnings': List<String>.from(data['warnings'] ?? []),
            'walking_minutes': data['walking_minutes'] ?? 0,
            'running_minutes': data['running_minutes'] ?? 0,
            'steps': data['steps'] ?? 0,
          };
        });

        // تشغيل الانيميشن
        _numberAnimationController.forward(from: 0);
        _chartAnimationController.forward(from: 0);

        NotificationsService.instance.toast(
          'تم التحليل بنجاح! 🎉',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      } else {
        print('❌ [CALORIE] فشل التحليل: ${response.statusCode}');
        print('❌ [CALORIE] الرسالة: ${response.body}');
        throw Exception('فشل تحليل الصورة. الرجاء المحاولة مرة أخرى.');
      }
    } catch (e) {
      print('❌ [CALORIE] خطأ: $e');
      NotificationsService.instance.toast(
        'فشل التحليل: ${e.toString()}',
        icon: Icons.error,
        color: Colors.red,
      );
      
      // في حالة الفشل، استخدم بيانات تجريبية
      setState(() {
        _result = {
          'food_name': 'فشل التحليل - بيانات تجريبية',
          'total_calories': 500,
          'protein': 30,
          'fats': 15,
          'carbs': 60,
          'fiber': 5,
          'sugar': 3,
          'is_healthy': true,
          'health_score': 70,
          'description': 'لم نتمكن من تحليل الصورة. يرجى التأكد من اتصالك بالإنترنت والمحاولة مرة أخرى.',
          'benefits': ['يرجى المحاولة مرة أخرى'],
          'warnings': ['فشل الاتصال بالخادم'],
          'walking_minutes': 100,
          'running_minutes': 50,
          'steps': 7000,
        };
      });
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
      body: Stack(
        children: [
          // المحتوى الرئيسي
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // AppBar مصغر
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: theme.backgroundColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍽️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'حاسبة السعرات',
                      style: GoogleFonts.cairo(
                        color: theme.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
                actions: [
                  if (_image != null) ...[
                    IconButton(
                      icon: Icon(Icons.share_rounded, color: theme.textPrimaryColor),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.favorite_border_rounded, color: theme.textPrimaryColor),
                      onPressed: () {},
                    ),
                  ],
                ],
              ),

              // المحتوى
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // منطقة الصورة أو زر التقاط
                      _buildImageSection(theme, primaryColor),
                      const SizedBox(height: 20),

                      // إجمالي السعرات
                      _buildTotalCaloriesCard(theme),
                      const SizedBox(height: 20),

                      // القيم الغذائية
                      _buildNutrientsGrid(theme),
                      const SizedBox(height: 20),

                      // الرسم البياني
                      _buildNutrientsChart(theme, isDark),
                      const SizedBox(height: 20),

                      // مؤشر الصحة
                      _buildHealthIndicator(theme, Colors.orange),
                      const SizedBox(height: 20),

                      // الوصف والفوائد
                      _buildDescription(theme),
                      const SizedBox(height: 20),

                      // خطوات الحرق
                      _buildBurnSteps(theme, Colors.orange),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // شاشة التحميل
          if (_isAnalyzing)
            Container(
              color: theme.backgroundColor.withOpacity(0.9),
              child: Center(
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
                      'جارٍ التحليل... 🔬',
                      style: GoogleFonts.cairo(
                        color: theme.textPrimaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'نظام كارمار الذكي يحلل الصورة',
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
      bottomNavigationBar: _buildBottomNav(theme, isDark, primaryColor),
    );
  }

  Widget _buildImageSection(ThemeConfig theme, Color primaryColor) {
    if (_image == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.2),
              Colors.deepOrange.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'التقط صورة وجبتك',
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'للحصول على تحليل كامل',
              style: GoogleFonts.cairo(
                color: theme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SmallActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'كاميرا',
                  color: Colors.orange,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 12),
                _SmallActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'معرض',
                  color: Colors.deepOrange,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.file(
            _image!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _image = null;
                  _result = {
                    'food_name': 'في انتظار التحليل...',
                    'total_calories': 0,
                    'protein': 0,
                    'fats': 0,
                    'carbs': 0,
                    'fiber': 0,
                    'sugar': 0,
                    'is_healthy': true,
                    'health_score': 0,
                    'description': 'قم بالتقاط صورة وجبتك للحصول على تحليل كامل.',
                    'benefits': [],
                    'warnings': [],
                    'walking_minutes': 0,
                    'running_minutes': 0,
                    'steps': 0,
                  };
                  _numberAnimationController.reset();
                  _chartAnimationController.reset();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCaloriesCard(ThemeConfig theme) {
    // تحويل آمن للقيم (قد تكون int أو double)
    final caloriesRaw = _result['total_calories'];
    final healthScoreRaw = _result['health_score'];
    
    final calories = caloriesRaw is int ? caloriesRaw : (caloriesRaw is double ? caloriesRaw.toInt() : 0);
    final healthScore = healthScoreRaw is int ? healthScoreRaw : (healthScoreRaw is double ? healthScoreRaw.toInt() : 0);
    final isAnalyzed = calories > 0;
    
    return AnimatedBuilder(
      animation: _numberAnimationController,
      builder: (context, child) {
        final animatedCalories = isAnalyzed 
          ? (_numberAnimationController.value * calories).toInt()
          : 0;
        final animatedScore = isAnalyzed
          ? (_numberAnimationController.value * healthScore).toInt()
          : 0;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAnalyzed 
                ? [Colors.orange.shade600, Colors.deepOrange.shade700]
                : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isAnalyzed ? Colors.orange : Colors.grey).withOpacity(0.4),
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
                          '$animatedCalories',
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
                      '$animatedScore',
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
      },
    );
  }

  Widget _buildNutrientsGrid(ThemeConfig theme) {
    final nutrients = [
      {'emoji': '🥩', 'name': 'البروتين', 'value': _result['protein'], 'unit': 'جم', 'color': Colors.red},
      {'emoji': '🧈', 'name': 'الدهون', 'value': _result['fats'], 'unit': 'جم', 'color': Colors.orange},
      {'emoji': '🍞', 'name': 'الكربوهيدرات', 'value': _result['carbs'], 'unit': 'جم', 'color': Colors.amber},
      {'emoji': '🌾', 'name': 'الألياف', 'value': _result['fiber'], 'unit': 'جم', 'color': Colors.brown},
    ];

    return AnimatedBuilder(
      animation: _numberAnimationController,
      builder: (context, child) {
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
            // تحويل آمن للقيمة (قد تكون int أو double)
            final rawValue = nutrient['value'];
            final value = rawValue is int ? rawValue : (rawValue is double ? rawValue.toInt() : 0);
            final isZero = value == 0;
            final animatedValue = isZero ? 0 : (_numberAnimationController.value * value).toInt();
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isZero 
                    ? Colors.grey.withOpacity(0.3)
                    : (nutrient['color'] as Color).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: isZero ? 0.3 : 1.0,
                    child: Text(
                      nutrient['emoji'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nutrient['name'] as String,
                    style: GoogleFonts.cairo(
                      color: theme.textSecondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$animatedValue',
                        style: GoogleFonts.cairo(
                          color: isZero ? Colors.grey : (nutrient['color'] as Color),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        ' ${nutrient['unit']}',
                        style: GoogleFonts.cairo(
                          color: theme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNutrientsChart(ThemeConfig theme, bool isDark) {
    // تحويل آمن للقيم (قد تكون int أو double)
    final proteinRaw = _result['protein'];
    final fatsRaw = _result['fats'];
    final carbsRaw = _result['carbs'];
    
    final protein = (proteinRaw is int ? proteinRaw.toDouble() : (proteinRaw is double ? proteinRaw : 0.0));
    final fats = (fatsRaw is int ? fatsRaw.toDouble() : (fatsRaw is double ? fatsRaw : 0.0));
    final carbs = (carbsRaw is int ? carbsRaw.toDouble() : (carbsRaw is double ? carbsRaw : 0.0));
    
    final total = protein + fats + carbs;
    final isZero = total == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
            child: isZero
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: 0.3,
                            child: const Text('📊', style: TextStyle(fontSize: 50)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'في انتظار التحليل',
                        style: GoogleFonts.cairo(
                          color: theme.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : AnimatedBuilder(
                  animation: _chartAnimationController,
                  builder: (context, child) {
                    return PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: protein * _chartAnimationController.value,
                            color: Colors.red,
                            title: _chartAnimationController.value > 0.8
                              ? '${(protein / total * 100).toStringAsFixed(0)}%'
                              : '',
                            radius: 80 * _chartAnimationController.value,
                            titleStyle: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          PieChartSectionData(
                            value: fats * _chartAnimationController.value,
                            color: Colors.orange,
                            title: _chartAnimationController.value > 0.8
                              ? '${(fats / total * 100).toStringAsFixed(0)}%'
                              : '',
                            radius: 80 * _chartAnimationController.value,
                            titleStyle: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          PieChartSectionData(
                            value: carbs * _chartAnimationController.value,
                            color: Colors.amber,
                            title: _chartAnimationController.value > 0.8
                              ? '${(carbs / total * 100).toStringAsFixed(0)}%'
                              : '',
                            radius: 80 * _chartAnimationController.value,
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
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(ThemeConfig theme, Color primaryColor) {
    final isHealthy = _result['is_healthy'] as bool;
    // تحويل آمن للقيمة (قد تكون int أو double)
    final scoreRaw = _result['health_score'];
    final score = scoreRaw is int ? scoreRaw : (scoreRaw is double ? scoreRaw.toInt() : 0);
    final isZero = score == 0;

    return AnimatedBuilder(
      animation: _numberAnimationController,
      builder: (context, child) {
        final animatedScore = isZero ? 0 : (_numberAnimationController.value * score).toInt();
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isZero 
                ? Colors.grey.withOpacity(0.3)
                : (isHealthy ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    isZero ? '⏳ في انتظار التحليل' : (isHealthy ? '🥗 وجبة صحية' : '🍔 غير صحية'),
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
                      color: isZero 
                        ? Colors.grey.withOpacity(0.2)
                        : (isHealthy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$animatedScore/100',
                      style: GoogleFonts.cairo(
                        color: isZero ? Colors.grey : (isHealthy ? Colors.green : Colors.red),
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
                  value: animatedScore / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(
                    isZero ? Colors.grey : (isHealthy ? Colors.green : Colors.orange)
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescription(ThemeConfig theme) {
    final description = _result['description'] as String;
    final benefits = _result['benefits'] as List;
    final warnings = _result['warnings'] as List?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
          if (benefits.isNotEmpty) ...[
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
          ],
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
    // تحويل آمن للقيم (قد تكون int أو double)
    final stepsRaw = _result['steps'];
    final walkingRaw = _result['walking_minutes'];
    final runningRaw = _result['running_minutes'];
    
    final steps = stepsRaw is int ? stepsRaw : (stepsRaw is double ? stepsRaw.toInt() : 0);
    final walking = walkingRaw is int ? walkingRaw : (walkingRaw is double ? walkingRaw.toInt() : 0);
    final running = runningRaw is int ? runningRaw : (runningRaw is double ? runningRaw.toInt() : 0);
    final isZero = steps == 0;

    return AnimatedBuilder(
      animation: _numberAnimationController,
      builder: (context, child) {
        final animatedWalking = isZero ? 0 : (_numberAnimationController.value * walking).toInt();
        final animatedRunning = isZero ? 0 : (_numberAnimationController.value * running).toInt();
        final animatedSteps = isZero ? 0 : (_numberAnimationController.value * steps).toInt();
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
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
              _buildBurnOption('🚶', 'المشي', '$animatedWalking دقيقة', Colors.blue, theme, isZero),
              const SizedBox(height: 12),
              _buildBurnOption('🏃', 'الجري', '$animatedRunning دقيقة', Colors.orange, theme, isZero),
              const SizedBox(height: 12),
              _buildBurnOption('👟', 'الخطوات', '${(animatedSteps / 1000).toStringAsFixed(1)}K خطوة', Colors.green, theme, isZero),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBurnOption(String emoji, String activity, String duration, Color color, ThemeConfig theme, bool isZero) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isZero ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isZero ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: isZero ? 0.3 : 1.0,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
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
              color: isZero ? Colors.grey : color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
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
