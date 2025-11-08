// lib/ai_fitness_analyzer.dart
// محلل البناء العضلي والتغذية الرياضية - AI Fitness Analyzer
// تحليل الجسم + برامج تمارين + نظام غذائي + متابعة التقدم
// by Abdulkarim ✨

import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import 'theme_config.dart';
import 'api_config.dart';
import 'notifications.dart';

class AIFitnessAnalyzerPage extends StatefulWidget {
  const AIFitnessAnalyzerPage({Key? key}) : super(key: key);

  @override
  State<AIFitnessAnalyzerPage> createState() => _AIFitnessAnalyzerPageState();
}

class _AIFitnessAnalyzerPageState extends State<AIFitnessAnalyzerPage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  int _currentNavIndex = 0;
  
  // سجل التحليلات
  List<Map<String, dynamic>> _analysisHistory = [];
  
  // البيانات الافتراضية (قبل التحليل)
  Map<String, dynamic> _result = {
    'body_type': 'في انتظار التحليل...',
    'body_fat_percentage': 0,
    'muscle_mass_percentage': 0,
    'bmi': 0.0,
    'fitness_level': 'مبتدئ',
    'goal_recommendation': 'قم بتصوير جسمك للحصول على تحليل مخصص',
    'areas_to_improve': [],
    'recommended_exercises': [],
    'workout_plan': [],
    'nutrition_plan': {
      'daily_calories': 0,
      'protein': 0,
      'carbs': 0,
      'fats': 0,
      'meals': [],
    },
    'supplements': [],
    'tips': [],
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // تحميل السجل
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('fitness_analysis_history');
      
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        setState(() {
          _analysisHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        print('📚 [HISTORY] تم تحميل ${_analysisHistory.length} تحليل من السجل');
      }
    } catch (e) {
      print('❌ [HISTORY] فشل تحميل السجل: $e');
    }
  }

  // حفظ السجل
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حذف الصورة من البيانات قبل الحفظ
      final historyToSave = _analysisHistory.map((item) {
        final copy = Map<String, dynamic>.from(item);
        copy.remove('image_path');
        return copy;
      }).toList();
      
      await prefs.setString('fitness_analysis_history', json.encode(historyToSave));
      print('✅ [HISTORY] تم حفظ السجل بنجاح');
    } catch (e) {
      print('❌ [HISTORY] فشل حفظ السجل: $e');
    }
  }

  // حفظ الصورة محلياً
  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'fitness_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('❌ فشل حفظ الصورة: $e');
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _image = File(image.path);
          // إعادة تعيين النتيجة
          _result = {
            'body_type': 'في انتظار التحليل...',
            'body_fat_percentage': 0,
            'muscle_mass_percentage': 0,
            'bmi': 0.0,
            'fitness_level': 'مبتدئ',
            'goal_recommendation': 'قم بتصوير جسمك للحصول على تحليل مخصص',
            'areas_to_improve': [],
            'recommended_exercises': [],
            'workout_plan': [],
            'nutrition_plan': {
              'daily_calories': 0,
              'protein': 0,
              'carbs': 0,
              'fats': 0,
              'meals': [],
            },
            'supplements': [],
            'tips': [],
          };
        });
        
        // تحليل تلقائي
        await _analyzeBody();
      }
    } catch (e) {
      NotificationsService.instance.toast(
        'فشل اختيار الصورة',
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> _analyzeBody() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/fitness-analyzer'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        
        // التحقق من أن الصورة تحتوي على جسم بشري
        if (result['is_body'] == false) {
          setState(() {
            _image = null;
          });
          
          NotificationsService.instance.toast(
            '⚠️ الصورة لا تحتوي على جسم بشري واضح',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          );
          return;
        }
        
        // حفظ الصورة محلياً
        final imagePath = await _saveImageLocally(_image!);
        
        setState(() {
          _result = result;
        });
        
        // إضافة إلى السجل
        final historyItem = Map<String, dynamic>.from(result);
        historyItem['timestamp'] = DateTime.now().toIso8601String();
        if (imagePath != null) {
          historyItem['image_path'] = imagePath;
        }
        
        setState(() {
          _analysisHistory.insert(0, historyItem);
          // الاحتفاظ بآخر 50 تحليل فقط
          if (_analysisHistory.length > 50) {
            _analysisHistory = _analysisHistory.sublist(0, 50);
          }
        });
        
        await _saveHistory();
        
      } else {
        NotificationsService.instance.toast(
          'فشل التحليل. حاول مرة أخرى',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    } catch (e) {
      NotificationsService.instance.toast(
        'حدث خطأ أثناء التحليل',
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
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
          icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'محلل البناء العضلي',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: _currentNavIndex == 0 ? _buildAnalysisPage(theme, primaryColor, isDark) : _buildHistoryPage(theme, primaryColor, isDark),
      bottomNavigationBar: _buildBottomNav(theme, primaryColor),
    );
  }

  Widget _buildAnalysisPage(ThemeConfig theme, Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Image Picker Section
          if (_image == null) ...[
            _buildImagePickerSection(theme, primaryColor, isDark),
          ] else ...[
            _buildSelectedImageSection(theme, primaryColor, isDark),
          ],

          const SizedBox(height: 20),

          // Analysis Result - دائماً ظاهر
          _buildAnalysisResult(theme, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildHistoryPage(ThemeConfig theme, Color primaryColor, bool isDark) {
    if (_analysisHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'لا يوجد سجل بعد',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ابدأ بتحليل جسمك للحصول على برنامج مخصص',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textPrimaryColor.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _analysisHistory.length,
      itemBuilder: (context, index) {
        final item = _analysisHistory[index];
        return _buildHistoryItem(item, theme, primaryColor, isDark);
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, ThemeConfig theme, Color primaryColor, bool isDark) {
    final timestamp = DateTime.parse(item['timestamp'] ?? DateTime.now().toIso8601String());
    final imagePath = item['image_path'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textPrimaryColor.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _result = item;
              _currentNavIndex = 0;
              if (imagePath != null) {
                _image = File(imagePath);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                // Image
                if (imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePath),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.image_not_supported, color: primaryColor),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '💪',
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                const SizedBox(width: 15),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['body_type'] ?? 'تحليل',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مستوى اللياقة: ${item['fitness_level'] ?? 'غير محدد'}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.textPrimaryColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(timestamp),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.textPrimaryColor.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  Widget _buildImagePickerSection(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'صوّر جسمك للتحليل',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'التقط صورة واضحة لجسمك\nللحصول على تحليل مخصص وبرنامج تدريبي',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textPrimaryColor.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    'الكاميرا',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                    'المعرض',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.cardColor,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImageSection(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Column(
      children: [
        // Image Preview with X button
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.file(
                _image!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              // X Button (Delete) - أسفل اليمين
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _image = null;
                      // إعادة تعيين النتيجة
                      _result = {
                        'body_type': 'في انتظار التحليل...',
                        'body_fat_percentage': 0,
                        'muscle_mass_percentage': 0,
                        'bmi': 0.0,
                        'fitness_level': 'مبتدئ',
                        'goal_recommendation': 'قم بتصوير جسمك للحصول على تحليل مخصص',
                        'areas_to_improve': [],
                        'recommended_exercises': [],
                        'workout_plan': [],
                        'nutrition_plan': {
                          'daily_calories': 0,
                          'protein': 0,
                          'carbs': 0,
                          'fats': 0,
                          'meals': [],
                        },
                        'supplements': [],
                        'tips': [],
                      };
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isAnalyzing) ...[
          const SizedBox(height: 20),
          Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 15),
              Text(
                'جاري تحليل جسمك...',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAnalysisResult(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Body Analysis Section
        _buildSectionTitle('📊 تحليل الجسم', theme, primaryColor),
        const SizedBox(height: 15),
        _buildBodyAnalysisCard(theme, primaryColor, isDark),
        
        const SizedBox(height: 25),
        
        // Goal & Areas to Improve
        _buildSectionTitle('🎯 الهدف والمناطق المستهدفة', theme, primaryColor),
        const SizedBox(height: 15),
        _buildGoalCard(theme, primaryColor, isDark),
        
        const SizedBox(height: 25),
        
        // Workout Plan
        if (_result['workout_plan'] != null && (_result['workout_plan'] as List).isNotEmpty) ...[
          _buildSectionTitle('💪 برنامج التمارين (30 يوم)', theme, primaryColor),
          const SizedBox(height: 15),
          _buildWorkoutPlan(theme, primaryColor, isDark),
          const SizedBox(height: 25),
        ],
        
        // Nutrition Plan
        _buildSectionTitle('🍽️ النظام الغذائي', theme, primaryColor),
        const SizedBox(height: 15),
        _buildNutritionPlan(theme, primaryColor, isDark),
        
        const SizedBox(height: 25),
        
        // Supplements
        if (_result['supplements'] != null && (_result['supplements'] as List).isNotEmpty) ...[
          _buildSectionTitle('💊 المكملات الغذائية', theme, primaryColor),
          const SizedBox(height: 15),
          _buildSupplements(theme, primaryColor, isDark),
          const SizedBox(height: 25),
        ],
        
        // Tips
        if (_result['tips'] != null && (_result['tips'] as List).isNotEmpty) ...[
          _buildSectionTitle('💡 نصائح مهمة', theme, primaryColor),
          const SizedBox(height: 15),
          _buildTips(theme, primaryColor, isDark),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeConfig theme, Color primaryColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryColor, primaryColor.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyAnalysisCard(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Body Type & Fitness Level
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'نوع الجسم',
                  _result['body_type'] ?? 'في انتظار التحليل...',
                  '🧬',
                  theme,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem(
                  'مستوى اللياقة',
                  _result['fitness_level'] ?? 'مبتدئ',
                  '⚡',
                  theme,
                  primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Body Fat & Muscle Mass
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'نسبة الدهون',
                  '${_result['body_fat_percentage'] ?? 0}%',
                  '📉',
                  theme,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem(
                  'نسبة العضلات',
                  '${_result['muscle_mass_percentage'] ?? 0}%',
                  '💪',
                  theme,
                  primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // BMI
          _buildStatItem(
            'مؤشر كتلة الجسم (BMI)',
            '${_result['bmi'] ?? 0.0}',
            '⚖️',
            theme,
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji, ThemeConfig theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.textPrimaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: theme.textPrimaryColor.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ThemeConfig theme, Color primaryColor, bool isDark) {
    final areasToImprove = _result['areas_to_improve'] as List? ?? [];
    final recommendedExercises = _result['recommended_exercises'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textPrimaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('🎯', style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الهدف المقترح',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.textPrimaryColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result['goal_recommendation'] ?? 'قم بتصوير جسمك للحصول على تحليل مخصص',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (areasToImprove.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 15),
            Text(
              'المناطق المستهدفة:',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areasToImprove.map((area) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    area.toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          if (recommendedExercises.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 15),
            Text(
              'التمارين الموصى بها:',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            ...recommendedExercises.map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.toString(),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutPlan(ThemeConfig theme, Color primaryColor, bool isDark) {
    final workoutPlan = _result['workout_plan'] as List? ?? [];
    
    if (workoutPlan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'سيتم عرض برنامج التمارين بعد التحليل',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textPrimaryColor.withOpacity(0.5),
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: workoutPlan.take(7).map((day) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.textPrimaryColor.withOpacity(0.1),
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('💪', style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day['day'] ?? 'اليوم',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        day['focus'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              const SizedBox(height: 10),
              ...(day['exercises'] as List? ?? []).map((exercise) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildExerciseDetail('مجموعات', '${exercise['sets']}', theme),
                          const SizedBox(width: 15),
                          _buildExerciseDetail('تكرارات', exercise['reps'] ?? '', theme),
                          const SizedBox(width: 15),
                          _buildExerciseDetail('راحة', exercise['rest'] ?? '', theme),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseDetail(String label, String value, ThemeConfig theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: theme.textPrimaryColor.withOpacity(0.5),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionPlan(ThemeConfig theme, Color primaryColor, bool isDark) {
    final nutritionPlan = _result['nutrition_plan'] as Map<String, dynamic>? ?? {};
    final meals = nutritionPlan['meals'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.textPrimaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Macros
          Row(
            children: [
              Expanded(
                child: _buildMacroItem('سعرات', '${nutritionPlan['daily_calories'] ?? 0}', '🔥', theme, primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroItem('بروتين', '${nutritionPlan['protein'] ?? 0}g', '🥩', theme, primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMacroItem('كارب', '${nutritionPlan['carbs'] ?? 0}g', '🍞', theme, primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMacroItem('دهون', '${nutritionPlan['fats'] ?? 0}g', '🥑', theme, primaryColor),
              ),
            ],
          ),
          
          if (meals.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 15),
            Text(
              'الوجبات اليومية:',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...meals.map((meal) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🍽️', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                meal['meal'] ?? '',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                '${meal['calories'] ?? 0} سعرة',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            meal['description'] ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: theme.textPrimaryColor.withOpacity(0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, String emoji, ThemeConfig theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: theme.textPrimaryColor.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplements(ThemeConfig theme, Color primaryColor, bool isDark) {
    final supplements = _result['supplements'] as List? ?? [];
    
    if (supplements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'لا توجد مكملات مقترحة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textPrimaryColor.withOpacity(0.5),
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: supplements.map((supplement) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: theme.textPrimaryColor.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('💊', style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplement['name'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${supplement['timing']} • ${supplement['dosage']}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.textPrimaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTips(ThemeConfig theme, Color primaryColor, bool isDark) {
    final tips = _result['tips'] as List? ?? [];
    
    if (tips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'لا توجد نصائح',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textPrimaryColor.withOpacity(0.5),
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip.toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: theme.textPrimaryColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNav(ThemeConfig theme, Color primaryColor) {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.analytics_rounded,
                label: 'تحليل',
                isActive: _currentNavIndex == 0,
                onTap: () {
                  setState(() {
                    _currentNavIndex = 0;
                  });
                },
                theme: theme,
                primaryColor: primaryColor,
              ),
              _buildNavItem(
                icon: Icons.history_rounded,
                label: 'السجل',
                isActive: _currentNavIndex == 1,
                onTap: () {
                  setState(() {
                    _currentNavIndex = 1;
                  });
                },
                theme: theme,
                primaryColor: primaryColor,
              ),
            ],
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

