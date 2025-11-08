import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'theme_config.dart';
import 'api_config.dart';
import 'notifications.dart';

class AIFitnessIntegratedProgramPage extends StatefulWidget {
  final Map<String, dynamic> initialAnalysis;

  const AIFitnessIntegratedProgramPage({
    Key? key,
    required this.initialAnalysis,
  }) : super(key: key);

  @override
  _AIFitnessIntegratedProgramPageState createState() => _AIFitnessIntegratedProgramPageState();
}

class _AIFitnessIntegratedProgramPageState extends State<AIFitnessIntegratedProgramPage> {
  Map<String, Map<String, bool>> _dailyProgress = {};
  List<Map<String, dynamic>> _weeklySnapshots = []; // صور أسبوعية
  DateTime? _programStartDate;
  int _currentWeek = 1;
  int _currentDayInWeek = 1;
  bool _isLoading = false;
  File? _weeklyImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProgramData();
  }

  Future<void> _loadProgramData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('integrated_program_progress');
      final snapshotsJson = prefs.getString('integrated_program_snapshots');
      final startDateStr = prefs.getString('integrated_program_start_date');
      
      if (progressJson != null) {
        final decoded = json.decode(progressJson) as Map<String, dynamic>;
        setState(() {
          _dailyProgress = decoded.map((key, value) => 
            MapEntry(key, Map<String, bool>.from(value as Map))
          );
        });
      }
      
      if (snapshotsJson != null) {
        final decoded = json.decode(snapshotsJson) as List;
        setState(() {
          _weeklySnapshots = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
      
      if (startDateStr != null) {
        _programStartDate = DateTime.parse(startDateStr);
        final daysPassed = DateTime.now().difference(_programStartDate!).inDays + 1;
        setState(() {
          _currentWeek = ((daysPassed - 1) ~/ 7) + 1;
          _currentDayInWeek = ((daysPassed - 1) % 7) + 1;
        });
      }
    } catch (e) {
      print('❌ فشل تحميل البيانات: $e');
    }
  }

  Future<void> _saveProgramData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('integrated_program_progress', json.encode(_dailyProgress));
      await prefs.setString('integrated_program_snapshots', json.encode(_weeklySnapshots));
      if (_programStartDate != null) {
        await prefs.setString('integrated_program_start_date', _programStartDate!.toIso8601String());
      }
    } catch (e) {
      print('❌ فشل حفظ البيانات: $e');
    }
  }

  Future<void> _startProgram() async {
    setState(() {
      _programStartDate = DateTime.now();
      _currentWeek = 1;
      _currentDayInWeek = 1;
      _dailyProgress.clear();
      _weeklySnapshots.clear();
    });
    
    // حفظ التحليل الأولي كأول snapshot
    _weeklySnapshots.add({
      'week': 0,
      'date': DateTime.now().toIso8601String(),
      'analysis': widget.initialAnalysis,
      'image': null,
    });
    
    await _saveProgramData();
  }

  Future<void> _pickWeeklyImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _weeklyImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل التقاط الصورة: $e');
    }
  }

  Future<void> _submitWeeklySnapshot() async {
    if (_weeklyImage == null) {
      NotificationsService.instance.toast('⚠️ يرجى التقاط صورة أولاً');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await _weeklyImage!.readAsBytes();
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
          // حفظ الـ snapshot
          _weeklySnapshots.add({
            'week': _currentWeek,
            'date': DateTime.now().toIso8601String(),
            'analysis': result,
            'image': base64Image,
          });

          await _saveProgramData();

          setState(() {
            _weeklyImage = null;
            _currentWeek++;
            _currentDayInWeek = 1;
          });

          NotificationsService.instance.toast('✅ تم حفظ تقدم الأسبوع بنجاح!');
          
          // عرض المقارنة
          _showWeeklyComparison();
        } else {
          NotificationsService.instance.toast('⚠️ ${result['goal_recommendation']}');
          setState(() {
            _weeklyImage = null;
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

  void _showWeeklyComparison() {
    if (_weeklySnapshots.length < 2) return;

    final previous = _weeklySnapshots[_weeklySnapshots.length - 2];
    final current = _weeklySnapshots[_weeklySnapshots.length - 1];

    final prevFat = double.tryParse(previous['analysis']['body_fat_percentage']?.toString() ?? '0') ?? 0;
    final currFat = double.tryParse(current['analysis']['body_fat_percentage']?.toString() ?? '0') ?? 0;
    final fatChange = currFat - prevFat;

    final prevMuscle = double.tryParse(previous['analysis']['muscle_mass_percentage']?.toString() ?? '0') ?? 0;
    final currMuscle = double.tryParse(current['analysis']['muscle_mass_percentage']?.toString() ?? '0') ?? 0;
    final muscleChange = currMuscle - prevMuscle;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 تقدم الأسبوع ${_currentWeek - 1}', style: GoogleFonts.cairo()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildChangeRow('نسبة الدهون', fatChange, '%', true),
            const SizedBox(height: 10),
            _buildChangeRow('نسبة العضلات', muscleChange, '%', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('رائع!', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(String label, double change, String unit, bool lowerIsBetter) {
    final isImproved = lowerIsBetter ? change < 0 : change > 0;
    final color = change == 0 ? Colors.grey : (isImproved ? Colors.green : Colors.red);
    final icon = change == 0 ? Icons.remove : (change < 0 ? Icons.arrow_downward : Icons.arrow_upward);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 14)),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              '${change.abs().toStringAsFixed(1)}$unit',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _toggleTask(String day, String task) {
    setState(() {
      if (!_dailyProgress.containsKey(day)) {
        _dailyProgress[day] = {};
      }
      _dailyProgress[day]![task] = !(_dailyProgress[day]![task] ?? false);
    });
    _saveProgramData();
  }

  List<Map<String, dynamic>> _getCurrentWeekPlan() {
    final List<Map<String, dynamic>> weekPlan = [];
    
    // الحصول على آخر تحليل
    final latestAnalysis = _weeklySnapshots.isNotEmpty 
        ? _weeklySnapshots.last['analysis'] 
        : widget.initialAnalysis;
    
    final workoutPlan = latestAnalysis['workout_plan'] as List? ?? [];
    final nutritionMeals = latestAnalysis['nutrition_plan']?['meals'] as List? ?? [];
    final waterLiters = latestAnalysis['nutrition_plan']?['water_liters'] ?? 3;
    
    for (int dayInWeek = 1; dayInWeek <= 7; dayInWeek++) {
      Map<String, dynamic> dayPlan = {
        'dayInWeek': dayInWeek,
        'dayNumber': ((_currentWeek - 1) * 7) + dayInWeek,
        'date': _programStartDate?.add(Duration(days: ((_currentWeek - 1) * 7) + dayInWeek - 1)),
        'tasks': <Map<String, dynamic>>[],
      };

      if (dayInWeek == 7) {
        // يوم 7: التقاط صورة + راحة
        dayPlan['tasks'] = [
          {
            'type': 'photo',
            'title': '📸 التقاط صورة الأسبوع',
            'subtitle': 'لتحليل التقدم وتوليد الأسبوع التالي',
            'icon': Icons.camera_alt,
          },
          {
            'type': 'rest',
            'title': '🌟 يوم راحة',
            'subtitle': 'استرخاء وتعافي',
            'icon': Icons.spa,
          },
          {
            'type': 'water',
            'title': '💧 شرب الماء',
            'subtitle': '$waterLiters لتر',
            'icon': Icons.water_drop,
          },
          {
            'type': 'sleep',
            'title': '😴 نوم كافي',
            'subtitle': '8-10 ساعات',
            'icon': Icons.bedtime,
          },
        ];
      } else {
        // أيام التمرين العادية
        final weekIndex = workoutPlan.isEmpty ? 0 : ((_currentWeek - 1) % workoutPlan.length);
        
        if (workoutPlan.isNotEmpty && weekIndex < workoutPlan.length) {
          final week = workoutPlan[weekIndex];
          final days = week['days'] as List? ?? [];
          
          if (dayInWeek - 1 < days.length) {
            final dayWorkout = days[dayInWeek - 1];
            final exercises = dayWorkout['exercises'] as List? ?? [];
            
            dayPlan['tasks'].add({
              'type': 'workout',
              'title': '💪 ${dayWorkout['focus'] ?? 'تمرين'}',
              'subtitle': '${exercises.length} تمارين',
              'icon': Icons.fitness_center,
            });
            
            for (var exercise in exercises) {
              dayPlan['tasks'].add({
                'type': 'exercise',
                'title': exercise['name'] ?? 'تمرين',
                'subtitle': '${exercise['sets']} مجموعات × ${exercise['reps']} تكرار',
                'icon': Icons.sports_gymnastics,
              });
            }
          }
        }

        // الوجبات
        if (nutritionMeals.isNotEmpty) {
          dayPlan['tasks'].add({
            'type': 'meals',
            'title': '🍽️ ${nutritionMeals.length} وجبات',
            'subtitle': '${latestAnalysis['nutrition_plan']?['daily_calories'] ?? 0} سعرة',
            'icon': Icons.restaurant,
          });
          
          for (var meal in nutritionMeals) {
            dayPlan['tasks'].add({
              'type': 'meal',
              'title': meal['meal'] ?? 'وجبة',
              'subtitle': '${meal['time'] ?? ''} - ${meal['calories'] ?? 0} سعرة',
              'icon': Icons.lunch_dining,
            });
          }
        }

        // الماء والنوم
        dayPlan['tasks'].add({
          'type': 'water',
          'title': '💧 شرب الماء',
          'subtitle': '$waterLiters لتر',
          'icon': Icons.water_drop,
        });
        
        dayPlan['tasks'].add({
          'type': 'sleep',
          'title': '😴 نوم كافي',
          'subtitle': '7-9 ساعات',
          'icon': Icons.bedtime,
        });
      }

      weekPlan.add(dayPlan);
    }

    return weekPlan;
  }

  double _calculateDayProgress(String day, List<Map<String, dynamic>> tasks) {
    if (!_dailyProgress.containsKey(day)) return 0.0;
    final completed = _dailyProgress[day]!.values.where((v) => v).length;
    return tasks.isEmpty ? 0.0 : completed / tasks.length;
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
          'برنامج 30 يوم المتكامل',
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
      body: _programStartDate == null
          ? _buildStartScreen(theme, primaryColor, isDark)
          : _buildProgramScreen(theme, primaryColor, isDark),
    );
  }

  Widget _buildStartScreen(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.2),
                    primaryColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                size: 100,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'برنامج 30 يوم المتكامل',
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              '4 أسابيع × 7 أيام',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(Icons.calendar_view_week, 'جدول أسبوعي مفصل (7 أيام)', theme),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.camera_alt, 'صورة أسبوعية للتتبع', theme),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.trending_up, 'تحليل التقدم تلقائياً', theme),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.refresh, 'تحديث البرنامج كل أسبوع', theme),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startProgram,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  'ابدأ البرنامج الآن',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, ThemeConfig theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.textPrimaryColor.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textPrimaryColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgramScreen(ThemeConfig theme, Color primaryColor, bool isDark) {
    final weekPlan = _getCurrentWeekPlan();
    final totalDays = (_currentWeek - 1) * 7 + _currentDayInWeek;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.15),
                primaryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأسبوع $_currentWeek من 4',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'اليوم $_currentDayInWeek من 7',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: theme.textPrimaryColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$totalDays/30',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Week days
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: weekPlan.length,
            itemBuilder: (context, index) {
              return _buildDayCard(weekPlan[index], theme, primaryColor, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(
    Map<String, dynamic> dayPlan,
    ThemeConfig theme,
    Color primaryColor,
    bool isDark,
  ) {
    final dayInWeek = dayPlan['dayInWeek'] as int;
    final dayNumber = dayPlan['dayNumber'] as int;
    final dayKey = 'day_$dayNumber';
    final tasks = dayPlan['tasks'] as List<Map<String, dynamic>>;
    final progress = _calculateDayProgress(dayKey, tasks);
    final isToday = dayInWeek == _currentDayInWeek;
    final isPast = dayInWeek < _currentDayInWeek;
    final isFuture = dayInWeek > _currentDayInWeek;
    final isDay7 = dayInWeek == 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDay7
              ? [Colors.purple.withOpacity(0.15), Colors.purple.withOpacity(0.08)]
              : isToday
                  ? [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.08)]
                  : [
                      theme.textPrimaryColor.withOpacity(0.05),
                      theme.textPrimaryColor.withOpacity(0.02),
                    ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDay7
              ? Colors.purple.withOpacity(0.5)
              : isToday
                  ? primaryColor.withOpacity(0.5)
                  : theme.textPrimaryColor.withOpacity(0.1),
          width: isToday || isDay7 ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDay7
                  ? Colors.purple.withOpacity(0.2)
                  : progress == 1.0
                      ? Colors.green.withOpacity(0.2)
                      : isToday
                          ? primaryColor.withOpacity(0.2)
                          : theme.textPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDay7
                    ? Colors.purple
                    : progress == 1.0
                        ? Colors.green
                        : isToday
                            ? primaryColor
                            : theme.textPrimaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: progress == 1.0
                  ? const Icon(Icons.check, color: Colors.green, size: 28)
                  : isDay7
                      ? const Icon(Icons.camera_alt, color: Colors.purple, size: 24)
                      : Text(
                          '$dayInWeek',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDay7
                                ? Colors.purple
                                : isToday
                                    ? primaryColor
                                    : theme.textPrimaryColor,
                          ),
                        ),
            ),
          ),
          title: Row(
            children: [
              Text(
                'اليوم $dayInWeek',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'اليوم',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              if (isDay7) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'صورة',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                isDay7 ? 'يوم التقييم الأسبوعي' : '${tasks.length} مهمة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: theme.textPrimaryColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.textPrimaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDay7
                        ? Colors.purple
                        : progress == 1.0
                            ? Colors.green
                            : primaryColor,
                  ),
                ),
              ),
            ],
          ),
          trailing: Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDay7
                  ? Colors.purple
                  : progress == 1.0
                      ? Colors.green
                      : primaryColor,
            ),
          ),
          children: [
            if (isDay7 && isToday) ...[
              // قسم التقاط الصورة
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    if (_weeklyImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          _weeklyImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickWeeklyImage,
                            icon: const Icon(Icons.camera_alt, size: 20),
                            label: Text(
                              'التقاط صورة',
                              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (_weeklyImage != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _submitWeeklySnapshot,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check, size: 20),
                              label: Text(
                                'تحليل وحفظ',
                                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            // المهام
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Column(
                children: tasks.map((task) {
                  final taskKey = '${task['title']}_${task['subtitle']}';
                  final isCompleted = _dailyProgress[dayKey]?[taskKey] ?? false;
                  final isPhotoTask = task['type'] == 'photo';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : theme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.3)
                            : theme.textPrimaryColor.withOpacity(0.1),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isCompleted,
                      onChanged: (isFuture || (isPhotoTask && _weeklyImage == null))
                          ? null
                          : (value) => _toggleTask(dayKey, taskKey),
                      title: Row(
                        children: [
                          Icon(
                            task['icon'] as IconData,
                            size: 20,
                            color: isCompleted
                                ? Colors.green
                                : theme.textPrimaryColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task['title'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.textPrimaryColor,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        task['subtitle'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.textPrimaryColor.withOpacity(0.6),
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

