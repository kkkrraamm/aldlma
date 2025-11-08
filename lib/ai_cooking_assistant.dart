// lib/ai_cooking_assistant.dart
// مساعد الطبخ الذكي - Smart Cooking Assistant
// تحليل المكونات واقتراح وصفات مع خطوات تفاعلية
// by Abdulkarim ✨

import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'theme_config.dart';
import 'api_config.dart';

class AICookingAssistantPage extends StatefulWidget {
  const AICookingAssistantPage({Key? key}) : super(key: key);

  @override
  State<AICookingAssistantPage> createState() => _AICookingAssistantPageState();
}

class _AICookingAssistantPageState extends State<AICookingAssistantPage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  late TabController _tabController;
  
  // للخطوات التفاعلية
  List<bool> _completedSteps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          _selectedImage = File(image.path);
          _analysisResult = null;
          _completedSteps = [];
        });
      }
    } catch (e) {
      _showError('فشل اختيار الصورة: $e');
    }
  }

  Future<void> _analyzeIngredients() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
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
        
        setState(() {
          _analysisResult = result;
          // تهيئة قائمة الخطوات المكتملة
          if (result['steps'] != null) {
            _completedSteps = List.filled(result['steps'].length, false);
          }
        });
      } else {
        _showError('فشل التحليل. حاول مرة أخرى.');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ),
    );
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
          // Hero Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                gradient: theme.headerGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [
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
                          // Badge
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
                                  '👨‍🍳',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Chef',
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
                      // Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryColor.withOpacity(0.3),
                              primaryColor.withOpacity(0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '👨‍🍳',
                            style: TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      Text(
                        'مساعد الطبخ الذكي',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'صوّر المكونات واحصل على وصفات مخصصة',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: theme.textPrimaryColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Image Picker Section
                  if (_selectedImage == null) ...[
                    _buildImagePickerSection(theme, primaryColor, isDark),
                  ] else ...[
                    _buildSelectedImageSection(theme, primaryColor, isDark),
                  ],

                  const SizedBox(height: 20),

                  // Analysis Result
                  if (_analysisResult != null) ...[
                    _buildAnalysisResult(theme, primaryColor, isDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme, primaryColor),
    );
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
        // Image Preview
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _selectedImage!,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeIngredients,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isAnalyzing ? 'جاري التحليل...' : 'تحليل المكونات',
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
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _analysisResult = null;
                  _completedSteps = [];
                });
              },
              icon: const Icon(Icons.delete_outline),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalysisResult(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Column(
      children: [
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: theme.textPrimaryColor.withOpacity(0.6),
            labelStyle: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'الوصفة'),
              Tab(text: 'المعلومات'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Tab Content
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRecipeTab(theme, primaryColor, isDark),
              _buildInfoTab(theme, primaryColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeTab(ThemeConfig theme, Color primaryColor, bool isDark) {
    final recipe = _analysisResult!;
    
    return SingleChildScrollView(
      child: Column(
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
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      label: recipe['cooking_time'] ?? '30 دقيقة',
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
                    _buildInfoChip(
                      icon: Icons.restaurant_outlined,
                      label: recipe['servings'] ?? '4 أشخاص',
                      color: primaryColor,
                    ),
                    const SizedBox(width: 10),
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
        ],
      ),
    );
  }

  Widget _buildInfoTab(ThemeConfig theme, Color primaryColor, bool isDark) {
    final recipe = _analysisResult!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Nutrition Info
          _buildInfoCard(
            title: 'القيمة الغذائية',
            icon: Icons.restaurant_menu_rounded,
            theme: theme,
            primaryColor: primaryColor,
            children: [
              _buildNutritionRow('السعرات', recipe['calories'] ?? '0', 'kcal', primaryColor),
              _buildNutritionRow('البروتين', recipe['protein'] ?? '0', 'g', primaryColor),
              _buildNutritionRow('الكربوهيدرات', recipe['carbs'] ?? '0', 'g', primaryColor),
              _buildNutritionRow('الدهون', recipe['fats'] ?? '0', 'g', primaryColor),
            ],
          ),
          const SizedBox(height: 15),
          // Tips
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
          const SizedBox(height: 15),
          // Health Benefits
          if (recipe['health_benefits'] != null)
            _buildInfoCard(
              title: 'الفوائد الصحية',
              icon: Icons.favorite_outline_rounded,
              theme: theme,
              primaryColor: primaryColor,
              children: [
                Text(
                  recipe['health_benefits'],
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: theme.textPrimaryColor.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
              ],
            ),
        ],
      ),
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
            child: Row(
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
                      Text(
                        'الخطوة ${index + 1}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
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

  Widget _buildNutritionRow(String label, String value, String unit, Color primaryColor) {
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
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                isActive: false,
                onTap: () => Navigator.pop(context),
                theme: theme,
                primaryColor: primaryColor,
              ),
              _buildNavItem(
                icon: Icons.restaurant_menu_rounded,
                label: 'الطبخ',
                isActive: true,
                onTap: () {},
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

