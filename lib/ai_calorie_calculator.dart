// lib/ai_calorie_calculator.dart
// حاسبة السعرات الحرارية بالذكاء الاصطناعي
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

class _AICalorieCalculatorPageState extends State<AICalorieCalculatorPage> {
  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;

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
          _result = null; // مسح النتائج السابقة
        });
        // تحليل الصورة تلقائياً
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
      // TODO: في التطبيق الحقيقي، سترسل الصورة لـ Vision API
      // هنا سنستخدم بيانات تجريبية واقعية
      
      await Future.delayed(const Duration(seconds: 2)); // محاكاة التحليل

      // نتائج تجريبية واقعية
      setState(() {
        _result = {
          'food_name': 'دجاج مشوي مع أرز وخضار',
          'total_calories': 650,
          'protein': 45,      // جرام
          'fats': 18,         // جرام
          'carbs': 72,        // جرام
          'fiber': 8,         // جرام
          'sugar': 5,         // جرام
          'is_healthy': true,
          'health_score': 82, // من 100
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
          'walking_minutes': 130,  // دقيقة مشي لحرق السعرات
          'running_minutes': 65,   // دقيقة جري
          'steps': 9000,           // عدد الخطوات
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🍽️ حاسبة السعرات',
          style: GoogleFonts.cairo(
            color: theme.textPrimaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: _image == null ? _buildEmptyState(theme, primaryColor) : _buildResultView(theme, primaryColor, isDark),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة كبيرة
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'التقط صورة وجبتك',
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'سيقوم الذكاء الاصطناعي بتحليل\nالقيم الغذائية والسعرات الحرارية',
              style: GoogleFonts.cairo(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // أزرار الاختيار
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'كاميرا',
                  color: primaryColor,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 16),
                _ActionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'معرض',
                  color: primaryColor,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(ThemeConfig theme, Color primaryColor, bool isDark) {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 20),
            Text(
              'جارٍ التحليل... 🤖',
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (_result == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة الطعام
          _buildFoodImage(),
          const SizedBox(height: 20),

          // اسم الوجبة
          _buildFoodName(theme),
          const SizedBox(height: 20),

          // إجمالي السعرات (بطاقة كبيرة)
          _buildTotalCaloriesCard(theme, primaryColor),
          const SizedBox(height: 20),

          // القيم الغذائية (بروتين، دهون، كربوهيدرات)
          _buildNutrientsGrid(theme),
          const SizedBox(height: 20),

          // الرسم البياني
          _buildNutrientsChart(theme, isDark),
          const SizedBox(height: 20),

          // مؤشر الصحة
          _buildHealthIndicator(theme, primaryColor),
          const SizedBox(height: 20),

          // الوصف والفوائد
          _buildDescription(theme),
          const SizedBox(height: 20),

          // خطوات الحرق
          _buildBurnSteps(theme, primaryColor),
          const SizedBox(height: 20),

          // زر تحليل صورة جديدة
          _buildNewAnalysisButton(primaryColor),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFoodImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        _image!,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFoodName(ThemeConfig theme) {
    return Text(
      _result!['food_name'],
      style: GoogleFonts.cairo(
        color: theme.textPrimaryColor,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildTotalCaloriesCard(ThemeConfig theme, Color primaryColor) {
    final calories = _result!['total_calories'];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.8), primaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'إجمالي السعرات الحرارية',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$calories',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, right: 4),
                child: Text(
                  'سعرة',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
        childAspectRatio: 1.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: nutrients.length,
      itemBuilder: (context, index) {
        final nutrient = nutrients[index];
        return _buildNutrientCard(
          theme,
          nutrient['emoji'] as String,
          nutrient['name'] as String,
          nutrient['value'] as int,
          nutrient['unit'] as String,
          nutrient['color'] as Color,
        );
      },
    );
  }

  Widget _buildNutrientCard(ThemeConfig theme, String emoji, String name, int value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
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
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            name,
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
                '$value',
                style: GoogleFonts.cairo(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                ' $unit',
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
          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('🥩 بروتين', Colors.red, theme),
              _buildLegendItem('🧈 دهون', Colors.orange, theme),
              _buildLegendItem('🍞 كربوهيدرات', Colors.amber, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeConfig theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: theme.textSecondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          // شريط التقدم
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

