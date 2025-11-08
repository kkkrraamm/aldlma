import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_config.dart';

class AIFitness30DayPlanPage extends StatefulWidget {
  final Map<String, dynamic> workoutPlan;
  final Map<String, dynamic> nutritionPlan;
  final String goalRecommendation;

  const AIFitness30DayPlanPage({
    Key? key,
    required this.workoutPlan,
    required this.nutritionPlan,
    required this.goalRecommendation,
  }) : super(key: key);

  @override
  _AIFitness30DayPlanPageState createState() => _AIFitness30DayPlanPageState();
}

class _AIFitness30DayPlanPageState extends State<AIFitness30DayPlanPage> {
  Map<String, Map<String, bool>> _dailyProgress = {}; // {day: {task: completed}}
  DateTime? _planStartDate;
  int _currentDay = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('fitness_30day_progress');
      final startDateStr = prefs.getString('fitness_30day_start_date');
      
      if (progressJson != null) {
        final decoded = json.decode(progressJson) as Map<String, dynamic>;
        setState(() {
          _dailyProgress = decoded.map((key, value) => 
            MapEntry(key, Map<String, bool>.from(value as Map))
          );
        });
      }
      
      if (startDateStr != null) {
        _planStartDate = DateTime.parse(startDateStr);
        final daysPassed = DateTime.now().difference(_planStartDate!).inDays + 1;
        setState(() {
          _currentDay = daysPassed.clamp(1, 30);
        });
      }
    } catch (e) {
      print('❌ فشل تحميل التقدم: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fitness_30day_progress', json.encode(_dailyProgress));
      if (_planStartDate != null) {
        await prefs.setString('fitness_30day_start_date', _planStartDate!.toIso8601String());
      }
    } catch (e) {
      print('❌ فشل حفظ التقدم: $e');
    }
  }

  Future<void> _startPlan() async {
    setState(() {
      _planStartDate = DateTime.now();
      _currentDay = 1;
      _dailyProgress.clear();
    });
    await _saveProgress();
  }

  Future<void> _resetPlan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعادة تعيين البرنامج', style: GoogleFonts.cairo()),
        content: Text('هل أنت متأكد؟ سيتم حذف جميع التقدم.', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _planStartDate = null;
        _currentDay = 1;
        _dailyProgress.clear();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fitness_30day_progress');
      await prefs.remove('fitness_30day_start_date');
    }
  }

  void _toggleTask(String day, String task) {
    setState(() {
      if (!_dailyProgress.containsKey(day)) {
        _dailyProgress[day] = {};
      }
      _dailyProgress[day]![task] = !(_dailyProgress[day]![task] ?? false);
    });
    _saveProgress();
  }

  List<Map<String, dynamic>> _generate30DayPlan() {
    final List<Map<String, dynamic>> plan = [];
    
    // استخراج برنامج التمارين من الـ workout_plan
    final workoutPlan = widget.workoutPlan['workout_plan'] as List? ?? [];
    final nutritionMeals = widget.nutritionPlan['meals'] as List? ?? [];
    
    for (int day = 1; day <= 30; day++) {
      final weekIndex = ((day - 1) ~/ 7).clamp(0, workoutPlan.length - 1);
      final dayInWeek = ((day - 1) % 7);
      
      Map<String, dynamic> dayPlan = {
        'day': day,
        'date': _planStartDate?.add(Duration(days: day - 1)),
        'tasks': <Map<String, dynamic>>[],
      };

      // إضافة تمارين اليوم
      if (workoutPlan.isNotEmpty && weekIndex < workoutPlan.length) {
        final week = workoutPlan[weekIndex];
        final days = week['days'] as List? ?? [];
        
        if (dayInWeek < days.length) {
          final dayWorkout = days[dayInWeek];
          final exercises = dayWorkout['exercises'] as List? ?? [];
          
          dayPlan['tasks'].add({
            'type': 'workout',
            'title': '💪 ${dayWorkout['focus'] ?? 'تمرين'}',
            'subtitle': '${exercises.length} تمارين',
            'icon': Icons.fitness_center,
          });
          
          // إضافة كل تمرين كمهمة منفصلة
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

      // إضافة الوجبات
      if (nutritionMeals.isNotEmpty) {
        dayPlan['tasks'].add({
          'type': 'meals',
          'title': '🍽️ ${nutritionMeals.length} وجبات',
          'subtitle': '${widget.nutritionPlan['daily_calories'] ?? 0} سعرة',
          'icon': Icons.restaurant,
        });
        
        // إضافة كل وجبة كمهمة منفصلة
        for (var meal in nutritionMeals) {
          dayPlan['tasks'].add({
            'type': 'meal',
            'title': meal['meal'] ?? 'وجبة',
            'subtitle': '${meal['time'] ?? ''} - ${meal['calories'] ?? 0} سعرة',
            'icon': Icons.lunch_dining,
          });
        }
      }

      // إضافة الماء
      final waterLiters = widget.nutritionPlan['water_liters'] ?? 3;
      dayPlan['tasks'].add({
        'type': 'water',
        'title': '💧 شرب الماء',
        'subtitle': '$waterLiters لتر',
        'icon': Icons.water_drop,
      });

      // إضافة النوم
      dayPlan['tasks'].add({
        'type': 'sleep',
        'title': '😴 نوم كافي',
        'subtitle': '7-9 ساعات',
        'icon': Icons.bedtime,
      });

      // يوم راحة كل 7 أيام
      if (day % 7 == 0) {
        dayPlan['tasks'] = [
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
      }

      plan.add(dayPlan);
    }

    return plan;
  }

  double _calculateDayProgress(String day, List<Map<String, dynamic>> tasks) {
    if (!_dailyProgress.containsKey(day)) return 0.0;
    final completed = _dailyProgress[day]!.values.where((v) => v).length;
    return tasks.isEmpty ? 0.0 : completed / tasks.length;
  }

  double _calculateOverallProgress() {
    final plan = _generate30DayPlan();
    int totalTasks = 0;
    int completedTasks = 0;

    for (var dayPlan in plan) {
      final day = 'day_${dayPlan['day']}';
      final tasks = dayPlan['tasks'] as List<Map<String, dynamic>>;
      totalTasks += tasks.length;
      if (_dailyProgress.containsKey(day)) {
        completedTasks += _dailyProgress[day]!.values.where((v) => v).length;
      }
    }

    return totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
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
          'برنامج 30 يوم',
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
        actions: [
          if (_planStartDate != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetPlan,
              tooltip: 'إعادة تعيين',
            ),
        ],
      ),
      body: _planStartDate == null
          ? _buildStartScreen(theme, primaryColor, isDark)
          : _buildPlanScreen(theme, primaryColor, isDark),
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
                Icons.calendar_month,
                size: 100,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'برنامج 30 يوم',
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'هدفك: ${widget.goalRecommendation}',
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
                  _buildFeatureRow(Icons.fitness_center, 'تمارين يومية مخصصة', theme),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.restaurant, '5-6 وجبات صحية', theme),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.check_circle, 'تتبع المهام اليومية', theme),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.trending_up, 'قياس التقدم', theme),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startPlan,
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
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: theme.textPrimaryColor.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanScreen(ThemeConfig theme, Color primaryColor, bool isDark) {
    final plan = _generate30DayPlan();
    final overallProgress = _calculateOverallProgress();
    final daysCompleted = plan.where((day) {
      final dayKey = 'day_${day['day']}';
      final tasks = day['tasks'] as List<Map<String, dynamic>>;
      return _calculateDayProgress(dayKey, tasks) == 1.0;
    }).length;

    return Column(
      children: [
        // Header with progress
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
                        'اليوم $_currentDay من 30',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '$daysCompleted أيام مكتملة',
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
                      '${(overallProgress * 100).toInt()}%',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: overallProgress,
                  minHeight: 10,
                  backgroundColor: theme.textPrimaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
            ],
          ),
        ),

        // Days list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: plan.length,
            itemBuilder: (context, index) {
              final dayPlan = plan[index];
              return _buildDayCard(dayPlan, theme, primaryColor, isDark);
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
    final day = dayPlan['day'] as int;
    final dayKey = 'day_$day';
    final tasks = dayPlan['tasks'] as List<Map<String, dynamic>>;
    final progress = _calculateDayProgress(dayKey, tasks);
    final isToday = day == _currentDay;
    final isPast = day < _currentDay;
    final isFuture = day > _currentDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.08)]
              : [
                  theme.textPrimaryColor.withOpacity(0.05),
                  theme.textPrimaryColor.withOpacity(0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isToday
              ? primaryColor.withOpacity(0.5)
              : theme.textPrimaryColor.withOpacity(0.1),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: progress == 1.0
                  ? Colors.green.withOpacity(0.2)
                  : isToday
                      ? primaryColor.withOpacity(0.2)
                      : theme.textPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: progress == 1.0
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
                  : Text(
                      '$day',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isToday ? primaryColor : theme.textPrimaryColor,
                      ),
                    ),
            ),
          ),
          title: Row(
            children: [
              Text(
                'اليوم $day',
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
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              Text(
                '${tasks.length} مهمة',
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
                    progress == 1.0 ? Colors.green : primaryColor,
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
              color: progress == 1.0 ? Colors.green : primaryColor,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Column(
                children: tasks.map((task) {
                  final taskKey = '${task['title']}_${task['subtitle']}';
                  final isCompleted = _dailyProgress[dayKey]?[taskKey] ?? false;

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
                      onChanged: isFuture
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

