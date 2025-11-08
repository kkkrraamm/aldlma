import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'theme_config.dart';
import 'api_config.dart';
import 'notifications_service.dart';

class AIFitnessWeeklyTrackingPage extends StatefulWidget {
  const AIFitnessWeeklyTrackingPage({Key? key}) : super(key: key);

  @override
  _AIFitnessWeeklyTrackingPageState createState() => _AIFitnessWeeklyTrackingPageState();
}

class _AIFitnessWeeklyTrackingPageState extends State<AIFitnessWeeklyTrackingPage> {
  List<Map<String, dynamic>> _weeklyRecords = [];
  bool _isLoading = false;
  File? _currentWeekImage;
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _loadWeeklyRecords();
  }

  // تحميل السجلات الأسبوعية
  Future<void> _loadWeeklyRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getString('weekly_fitness_records');
      if (recordsJson != null) {
        final List<dynamic> decoded = json.decode(recordsJson);
        setState(() {
          _weeklyRecords = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          // ترتيب من الأحدث للأقدم
          _weeklyRecords.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
        });
      }
    } catch (e) {
      print('❌ فشل تحميل السجلات الأسبوعية: $e');
    }
  }

  // حفظ السجلات الأسبوعية
  Future<void> _saveWeeklyRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('weekly_fitness_records', json.encode(_weeklyRecords));
    } catch (e) {
      print('❌ فشل حفظ السجلات الأسبوعية: $e');
    }
  }

  // التقاط أو اختيار صورة
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _currentWeekImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل اختيار الصورة: $e');
    }
  }

  // رفع صورة الأسبوع وتحليلها
  Future<void> _uploadWeeklyImage() async {
    if (_currentWeekImage == null) {
      NotificationsService.instance.toast('⚠️ يرجى التقاط صورة أولاً');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await _currentWeekImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // تحميل بيانات المستخدم
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> userData = {};
      if (prefs.getString('user_weight')?.isNotEmpty ?? false) {
        userData['weight'] = prefs.getString('user_weight');
      }
      if (prefs.getString('user_height')?.isNotEmpty ?? false) {
        userData['height'] = prefs.getString('user_height');
      }
      if (prefs.getString('user_age')?.isNotEmpty ?? false) {
        userData['age'] = prefs.getString('user_age');
      }
      if (prefs.getString('user_waist')?.isNotEmpty ?? false) {
        userData['waist'] = prefs.getString('user_waist');
      }
      if (prefs.getString('user_neck')?.isNotEmpty ?? false) {
        userData['neck'] = prefs.getString('user_neck');
      }
      userData['gender'] = prefs.getString('user_gender') ?? 'ذكر';
      userData['activity_level'] = prefs.getString('user_activity_level') ?? 'متوسط';
      userData['goal'] = prefs.getString('user_goal') ?? 'بناء عضلات';
      userData['fitness_level'] = prefs.getString('user_fitness_level') ?? 'مبتدئ';
      userData['medical_conditions'] = prefs.getString('user_medical_conditions') ?? 'لا يوجد';
      userData['allergies'] = prefs.getString('user_allergies') ?? 'لا يوجد';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/fitness-analyzer'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'image': base64Image,
          'user_data': userData,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));

        if (result['is_body'] == true) {
          // حفظ السجل الأسبوعي
          final weekRecord = {
            'date': DateTime.now().toIso8601String(),
            'week_number': _weeklyRecords.length + 1,
            'image': base64Image,
            'body_fat_percentage': result['body_fat_percentage'],
            'muscle_mass_percentage': result['muscle_mass_percentage'],
            'bmi': result['bmi'],
            'weight': userData['weight'] ?? '0',
            'waist': userData['waist'] ?? '0',
            'analysis': result,
          };

          setState(() {
            _weeklyRecords.insert(0, weekRecord);
            _currentWeekImage = null;
          });

          await _saveWeeklyRecords();

          NotificationsService.instance.toast('✅ تم حفظ سجل الأسبوع بنجاح!');
        } else {
          NotificationsService.instance.toast('⚠️ ${result['goal_recommendation']}');
          setState(() {
            _currentWeekImage = null;
          });
        }
      } else {
        NotificationsService.instance.toast('❌ فشل التحليل: ${response.statusCode}');
      }
    } catch (e) {
      NotificationsService.instance.toast('❌ حدث خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // حذف سجل أسبوعي
  Future<void> _deleteRecord(int index) async {
    setState(() {
      _weeklyRecords.removeAt(index);
    });
    await _saveWeeklyRecords();
    NotificationsService.instance.toast('🗑️ تم حذف السجل');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'التتبع الأسبوعي',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 20),
                  Text(
                    'جاري التحليل...',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            )
          : _buildContent(theme, primaryColor, isDark),
    );
  }

  Widget _buildContent(ThemeConfig theme, Color primaryColor, bool isDark) {
    return CustomScrollView(
      slivers: [
        // رفع صورة الأسبوع
        SliverToBoxAdapter(
          child: _buildUploadSection(theme, primaryColor, isDark),
        ),

        // عنوان السجلات
        if (_weeklyRecords.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
              child: Row(
                children: [
                  Icon(Icons.history, color: primaryColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'سجل التتبع الأسبوعي',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_weeklyRecords.length} أسبوع',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // قائمة السجلات
        if (_weeklyRecords.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: theme.textPrimaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'لا توجد سجلات أسبوعية بعد',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ابدأ بتصوير جسمك الآن!',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.textPrimaryColor.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildWeekCard(
                    _weeklyRecords[index],
                    index,
                    theme,
                    primaryColor,
                    isDark,
                  );
                },
                childCount: _weeklyRecords.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadSection(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
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
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // الأيقونة والعنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صورة هذا الأسبوع',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'التقط صورة لجسمك لتتبع تقدمك',
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

          const SizedBox(height: 20),

          // معاينة الصورة
          if (_currentWeekImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _currentWeekImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentWeekImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // أزرار التصوير
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: Text(
                    'التقاط صورة',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: Text(
                    'من المعرض',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor.withOpacity(0.2),
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // زر التحليل
          if (_currentWeekImage != null) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadWeeklyImage,
                icon: const Icon(Icons.analytics, size: 22),
                label: Text(
                  'تحليل وحفظ السجل',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeekCard(
    Map<String, dynamic> record,
    int index,
    ThemeConfig theme,
    Color primaryColor,
    bool isDark,
  ) {
    final date = DateTime.parse(record['date']);
    final formattedDate = DateFormat('dd/MM/yyyy', 'ar').format(date);
    final weekNumber = record['week_number'];

    // حساب التغيير من الأسبوع السابق
    String changeText = '';
    Color changeColor = Colors.grey;
    if (index < _weeklyRecords.length - 1) {
      final previousRecord = _weeklyRecords[index + 1];
      final currentFat = double.tryParse(record['body_fat_percentage']?.toString() ?? '0') ?? 0;
      final previousFat = double.tryParse(previousRecord['body_fat_percentage']?.toString() ?? '0') ?? 0;
      final fatChange = currentFat - previousFat;

      if (fatChange < 0) {
        changeText = '↓ ${fatChange.abs().toStringAsFixed(1)}% دهون';
        changeColor = Colors.green;
      } else if (fatChange > 0) {
        changeText = '↑ ${fatChange.toStringAsFixed(1)}% دهون';
        changeColor = Colors.red;
      } else {
        changeText = '= ثابت';
        changeColor = Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الأسبوع $weekNumber',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formattedDate,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textPrimaryColor.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                if (changeText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: changeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      changeText,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _deleteRecord(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصورة
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(record['image']),
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),

                // البيانات
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow(
                        Icons.monitor_weight,
                        'الوزن',
                        '${record['weight']} كجم',
                        theme,
                        primaryColor,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        Icons.water_drop,
                        'نسبة الدهون',
                        '${record['body_fat_percentage']}%',
                        theme,
                        primaryColor,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        Icons.fitness_center,
                        'نسبة العضلات',
                        '${record['muscle_mass_percentage']}%',
                        theme,
                        primaryColor,
                      ),
                      const SizedBox(height: 8),
                      _buildStatRow(
                        Icons.straighten,
                        'محيط الخصر',
                        '${record['waist']} سم',
                        theme,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, ThemeConfig theme, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: theme.textPrimaryColor.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: theme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

