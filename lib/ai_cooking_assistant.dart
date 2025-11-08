// lib/ai_cooking_assistant.dart
// مساعد الطبخ الذكي - Smart Cooking Assistant
// تحليل المكونات واقتراح وصفات مع خطوات تفاعلية + سجل
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
import 'package:path/path.dart' as path;

import 'theme_config.dart';
import 'api_config.dart';
import 'notifications.dart';

class AICookingAssistantPage extends StatefulWidget {
  const AICookingAssistantPage({Key? key}) : super(key: key);

  @override
  State<AICookingAssistantPage> createState() => _AICookingAssistantPageState();
}

class _AICookingAssistantPageState extends State<AICookingAssistantPage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  int _currentNavIndex = 0;
  
  // سجل الوصفات
  List<Map<String, dynamic>> _recipeHistory = [];
  
  // للخطوات التفاعلية
  List<bool> _completedSteps = [];
  
  // للمؤقتات (Timers)
  Map<int, int> _stepTimers = {}; // index -> seconds remaining
  Map<int, bool> _timerRunning = {}; // index -> is running
  
  // البيانات الافتراضية (قبل التحليل)
  Map<String, dynamic> _result = {
    'recipe_name': 'في انتظار التحليل...',
    'icon': '👨‍🍳',
    'cuisine_type': 'مطبخ عالمي',
    'cooking_time': '0 دقيقة',
    'servings': '0 أشخاص',
    'difficulty': 'سهل',
    'ingredients': ['قم بتصوير المكونات المتاحة لديك'],
    'steps': ['سيتم عرض خطوات التحضير بعد التحليل'],
    'calories': '0',
    'protein': '0',
    'carbs': '0',
    'fats': '0',
    'tips': ['سيتم عرض نصائح الطبخ بعد التحليل'],
    'health_benefits': 'قم بتصوير المكونات المتاحة لديك للحصول على وصفة مخصصة.',
  };

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // تحميل السجل
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('cooking_recipe_history');
      
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        setState(() {
          _recipeHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
        print('📚 [HISTORY] تم تحميل ${_recipeHistory.length} وصفة من السجل');
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
      final historyToSave = _recipeHistory.map((item) {
        final copy = Map<String, dynamic>.from(item);
        copy.remove('image_path');
        return copy;
      }).toList();
      
      await prefs.setString('cooking_recipe_history', json.encode(historyToSave));
      print('✅ [HISTORY] تم حفظ السجل بنجاح');
    } catch (e) {
      print('❌ [HISTORY] فشل حفظ السجل: $e');
    }
  }

  // حفظ الصورة محلياً
  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
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
          _completedSteps = [];
          // إعادة تعيين النتيجة
          _result = {
            'recipe_name': 'في انتظار التحليل...',
            'icon': '👨‍🍳',
            'cuisine_type': 'مطبخ عالمي',
            'cooking_time': '0 دقيقة',
            'servings': '0 أشخاص',
            'difficulty': 'سهل',
            'ingredients': ['قم بتصوير المكونات المتاحة لديك'],
            'steps': ['سيتم عرض خطوات التحضير بعد التحليل'],
            'calories': '0',
            'protein': '0',
            'carbs': '0',
            'fats': '0',
            'tips': ['سيتم عرض نصائح الطبخ بعد التحليل'],
            'health_benefits': 'قم بتصوير المكونات المتاحة لديك للحصول على وصفة مخصصة.',
          };
        });
        
        // تحليل تلقائي
        await _analyzeIngredients();
      }
    } catch (e) {
      NotificationsService.instance.toast(
        'فشل اختيار الصورة',
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  Future<void> _analyzeIngredients() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/cooking-assistant'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'image': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        
        // التحقق من أن الصورة تحتوي على طعام/مكونات
        if (result['is_food'] == false) {
          setState(() {
            _image = null;
          });
          
          // إظهار Toast نفس حاسبة السعرات
          NotificationsService.instance.toast(
            '⚠️ هذه الصورة لا تحتوي على طعام أو مكونات',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          );
          return;
        }
        
        // حفظ الصورة محلياً
        final imagePath = await _saveImageLocally(_image!);
        
        setState(() {
          _result = result;
          // تهيئة قائمة الخطوات المكتملة
          if (result['steps'] != null && result['steps'] is List) {
            _completedSteps = List.filled((result['steps'] as List).length, false);
          }
        });
        
        // إضافة إلى السجل
        final historyItem = Map<String, dynamic>.from(result);
        historyItem['timestamp'] = DateTime.now().toIso8601String();
        if (imagePath != null) {
          historyItem['image_path'] = imagePath;
        }
        
        setState(() {
          _recipeHistory.insert(0, historyItem);
          // الاحتفاظ بآخر 50 وصفة فقط
          if (_recipeHistory.length > 50) {
            _recipeHistory = _recipeHistory.sublist(0, 50);
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

  // استخراج الوقت من نص الخطوة
  int? _extractTimeFromStep(String step) {
    // البحث عن أنماط مثل: "5 دقائق", "10 دقيقة", "نصف ساعة", "ساعة"
    final patterns = [
      RegExp(r'(\d+)\s*دقيقة', caseSensitive: false),
      RegExp(r'(\d+)\s*دقائق', caseSensitive: false),
      RegExp(r'(\d+)\s*د', caseSensitive: false),
      RegExp(r'(\d+)\s*min', caseSensitive: false),
      RegExp(r'(\d+)\s*minutes?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(step);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 0;
      }
    }

    // البحث عن "نصف ساعة"
    if (step.contains('نصف ساعة') || step.contains('نص ساعة')) {
      return 30;
    }

    // البحث عن "ساعة"
    if (step.contains('ساعة') && !step.contains('نصف')) {
      final hourPattern = RegExp(r'(\d+)\s*ساعة');
      final match = hourPattern.firstMatch(step);
      if (match != null) {
        final hours = int.tryParse(match.group(1)!) ?? 1;
        return hours * 60;
      }
      return 60; // ساعة واحدة
    }

    return null;
  }

  // بدء/إيقاف المؤقت
  void _toggleTimer(int stepIndex, int minutes) {
    setState(() {
      if (_timerRunning[stepIndex] == true) {
        // إيقاف المؤقت
        _timerRunning[stepIndex] = false;
      } else {
        // بدء المؤقت
        if (!_stepTimers.containsKey(stepIndex)) {
          _stepTimers[stepIndex] = minutes * 60; // تحويل إلى ثواني
        }
        _timerRunning[stepIndex] = true;
        _runTimer(stepIndex);
      }
    });
  }

  // تشغيل المؤقت
  void _runTimer(int stepIndex) {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      if (_timerRunning[stepIndex] == true && _stepTimers[stepIndex]! > 0) {
        setState(() {
          _stepTimers[stepIndex] = _stepTimers[stepIndex]! - 1;
        });
        _runTimer(stepIndex);
      } else if (_stepTimers[stepIndex] == 0) {
        // انتهى المؤقت
        setState(() {
          _timerRunning[stepIndex] = false;
        });
        // إشعار Toast
        NotificationsService.instance.toast(
          '⏰ انتهى وقت الخطوة ${stepIndex + 1}!',
          icon: Icons.alarm_on_rounded,
          color: Colors.green,
        );
      }
    });
  }

  // إعادة تعيين المؤقت
  void _resetTimer(int stepIndex, int minutes) {
    setState(() {
      _stepTimers[stepIndex] = minutes * 60;
      _timerRunning[stepIndex] = false;
    });
  }

  // تنسيق الوقت المتبقي
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
          'مساعد الطبخ الذكي',
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
    if (_recipeHistory.isEmpty) {
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
              'ابدأ بتحليل مكوناتك للحصول على وصفات',
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
      itemCount: _recipeHistory.length,
      itemBuilder: (context, index) {
        final item = _recipeHistory[index];
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
              if (item['steps'] != null && item['steps'] is List) {
                _completedSteps = List.filled((item['steps'] as List).length, false);
              }
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
                        item['icon'] ?? '👨‍🍳',
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
                        item['recipe_name'] ?? 'وصفة',
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
                        '${item['cuisine_type'] ?? ''} • ${item['cooking_time'] ?? ''}',
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
            Icons.camera_alt_rounded,
            size: 80,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'صوّر المكونات المتاحة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'التقط صورة للمكونات في مطبخك\nوسنقترح لك أفضل الوصفات',
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
                      _completedSteps = [];
                      _stepTimers.clear();
                      _timerRunning.clear();
                      // إعادة تعيين النتيجة
                      _result = {
                        'recipe_name': 'في انتظار التحليل...',
                        'icon': '👨‍🍳',
                        'cuisine_type': 'مطبخ عالمي',
                        'cooking_time': '0 دقيقة',
                        'servings': '0 أشخاص',
                        'difficulty': 'سهل',
                        'ingredients': ['قم بتصوير المكونات المتاحة لديك'],
                        'steps': ['سيتم عرض خطوات التحضير بعد التحليل'],
                        'calories': '0',
                        'protein': '0',
                        'carbs': '0',
                        'fats': '0',
                        'tips': ['سيتم عرض نصائح الطبخ بعد التحليل'],
                        'health_benefits': 'قم بتصوير المكونات المتاحة لديك للحصول على وصفة مخصصة.',
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
                'جاري تحليل المكونات...',
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
    final recipe = _result;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Title
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.2),
                primaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recipe['icon'] ?? '🍳',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['recipe_name'] ?? 'وصفة مقترحة',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          recipe['cuisine_type'] ?? 'مطبخ عالمي',
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
              const SizedBox(height: 15),
              // Time and Servings
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildInfoChip(
                    icon: Icons.timer_outlined,
                    label: recipe['cooking_time'] ?? '30 دقيقة',
                    color: primaryColor,
                  ),
                  _buildInfoChip(
                    icon: Icons.restaurant_outlined,
                    label: recipe['servings'] ?? '4 أشخاص',
                    color: primaryColor,
                  ),
                  _buildInfoChip(
                    icon: Icons.local_fire_department_outlined,
                    label: recipe['difficulty'] ?? 'متوسط',
                    color: primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Ingredients
        _buildSectionTitle('المكونات المطلوبة', Icons.shopping_basket_outlined, theme, primaryColor),
        const SizedBox(height: 10),
        ...List.generate(
          (recipe['ingredients'] as List?)?.length ?? 0,
          (index) {
            final ingredient = recipe['ingredients'][index];
            return _buildIngredientItem(ingredient, theme, primaryColor);
          },
        ),
        const SizedBox(height: 20),
        // Steps with Checkboxes
        _buildSectionTitle('خطوات التحضير', Icons.list_alt_rounded, theme, primaryColor),
        const SizedBox(height: 10),
        ...List.generate(
          (recipe['steps'] as List?)?.length ?? 0,
          (index) {
            final step = recipe['steps'][index];
            return _buildStepItem(index, step, theme, primaryColor);
          },
        ),
        const SizedBox(height: 20),
        // Nutrition Info
        _buildInfoCard(
          title: 'القيمة الغذائية',
          icon: Icons.restaurant_menu_rounded,
          theme: theme,
          primaryColor: primaryColor,
          children: [
            _buildNutritionRow('السعرات', recipe['calories'] ?? '0', 'kcal', primaryColor, theme),
            _buildNutritionRow('البروتين', recipe['protein'] ?? '0', 'g', primaryColor, theme),
            _buildNutritionRow('الكربوهيدرات', recipe['carbs'] ?? '0', 'g', primaryColor, theme),
            _buildNutritionRow('الدهون', recipe['fats'] ?? '0', 'g', primaryColor, theme),
          ],
        ),
        const SizedBox(height: 15),
        // Tips
        if ((recipe['tips'] as List?)?.isNotEmpty ?? false)
          _buildInfoCard(
            title: 'نصائح الطبخ',
            icon: Icons.lightbulb_outline_rounded,
            theme: theme,
            primaryColor: primaryColor,
            children: [
              ...List.generate(
                (recipe['tips'] as List?)?.length ?? 0,
                (index) => _buildTipItem(recipe['tips'][index], theme, primaryColor),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, ThemeConfig theme, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 10),
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

  Widget _buildIngredientItem(String ingredient, ThemeConfig theme, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.textPrimaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int index, String step, ThemeConfig theme, Color primaryColor) {
    final isCompleted = _completedSteps.length > index ? _completedSteps[index] : false;
    final timeInMinutes = _extractTimeFromStep(step);
    final hasTimer = timeInMinutes != null && timeInMinutes > 0;
    final timerSeconds = _stepTimers[index] ?? (timeInMinutes != null ? timeInMinutes * 60 : 0);
    final isTimerRunning = _timerRunning[index] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCompleted
              ? primaryColor.withOpacity(0.5)
              : theme.textPrimaryColor.withOpacity(0.1),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (_completedSteps.length > index) {
                _completedSteps[index] = !_completedSteps[index];
              }
            });
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                    const SizedBox(width: 15),
                    // Step Number and Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'الخطوة ${index + 1}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              if (hasTimer) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 12,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$timeInMinutes د',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            step,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: theme.textPrimaryColor.withOpacity(
                                isCompleted ? 0.6 : 1.0,
                              ),
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Timer Controls
                if (hasTimer) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.1),
                          primaryColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Timer Display
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: isTimerRunning ? Colors.green : primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatTime(timerSeconds),
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isTimerRunning ? Colors.green : theme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        // Timer Buttons
                        Row(
                          children: [
                            // Start/Pause Button
                            IconButton(
                              onPressed: () => _toggleTimer(index, timeInMinutes!),
                              icon: Icon(
                                isTimerRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: isTimerRunning ? Colors.orange : Colors.green,
                                size: 32,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 10),
                            // Reset Button
                            IconButton(
                              onPressed: () => _resetTimer(index, timeInMinutes!),
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: primaryColor,
                                size: 28,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required ThemeConfig theme,
    required Color primaryColor,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 24),
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
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, String unit, Color primaryColor, ThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimaryColor,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: primaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip, ThemeConfig theme, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textPrimaryColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
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
                icon: Icons.auto_awesome_rounded,
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
