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
  final Map<String, dynamic>? initialAnalysis;
  final String? programId;

  const AIFitnessIntegratedProgramPage({
    Key? key,
    this.initialAnalysis,
    this.programId,
  }) : super(key: key);

  @override
  _AIFitnessIntegratedProgramPageState createState() => _AIFitnessIntegratedProgramPageState();
}

class _AIFitnessIntegratedProgramPageState extends State<AIFitnessIntegratedProgramPage> with SingleTickerProviderStateMixin {
  Map<String, Map<String, bool>> _dailyProgress = {};
  List<Map<String, dynamic>> _weeklySnapshots = [];
  DateTime? _programStartDate;
  int _currentWeek = 1;
  int _currentDayInWeek = 1;
  bool _isLoading = false;
  File? _weeklyImage;
  final ImagePicker _picker = ImagePicker();
  
  // للبرامج المتعددة
  List<Map<String, dynamic>> _allPrograms = [];
  String? _currentProgramId;
  TabController? _tabController;
  int _selectedTabIndex = 0;
  
  // للأهداف والتحليل الذكي
  Map<String, dynamic>? _monthlyGoal;
  List<Map<String, dynamic>> _weeklyGoals = [];
  Map<String, dynamic>? _expectedResults;
  Map<String, dynamic>? _weeklyAnalysis;

  @override
  void initState() {
    super.initState();
    _loadAllPrograms();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadAllPrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final programsJson = prefs.getString('all_fitness_programs');
      
      if (programsJson != null) {
        final decoded = json.decode(programsJson) as List;
        _allPrograms = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      // إذا كان هناك برنامج محدد، حمّله
      if (widget.programId != null) {
        _currentProgramId = widget.programId;
        _loadSpecificProgram(widget.programId!);
      } else if (_allPrograms.isNotEmpty) {
        // حمّل آخر برنامج
        _currentProgramId = _allPrograms.last['id'];
        _loadSpecificProgram(_currentProgramId!);
      } else if (widget.initialAnalysis != null) {
        // لا توجد برامج محفوظة، اطلب إنشاء برنامج جديد
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startProgram();
        });
      }
      
      // إنشاء TabController
      if (_allPrograms.isNotEmpty) {
        _tabController = TabController(
          length: _allPrograms.length,
          vsync: this,
          initialIndex: _allPrograms.indexWhere((p) => p['id'] == _currentProgramId).clamp(0, _allPrograms.length - 1),
        );
        _tabController!.addListener(() {
          if (_tabController!.indexIsChanging) {
            setState(() {
              _selectedTabIndex = _tabController!.index;
              _currentProgramId = _allPrograms[_selectedTabIndex]['id'];
              _loadSpecificProgram(_currentProgramId!);
            });
          }
        });
      }
      
      setState(() {});
    } catch (e) {
      print('❌ فشل تحميل البرامج: $e');
    }
  }

  Future<void> _loadSpecificProgram(String programId) async {
    try {
      final program = _allPrograms.firstWhere((p) => p['id'] == programId);
      
      setState(() {
        _dailyProgress = (program['progress'] as Map<String, dynamic>?)?.map((key, value) => 
          MapEntry(key, Map<String, bool>.from(value as Map))
        ) ?? {};
        
        _weeklySnapshots = (program['snapshots'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        
        // تحميل الأهداف
        _monthlyGoal = program['monthly_goal'] as Map<String, dynamic>?;
        _weeklyGoals = (program['weekly_goals'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _expectedResults = program['expected_results'] as Map<String, dynamic>?;
        
        if (program['startDate'] != null) {
          _programStartDate = DateTime.parse(program['startDate']);
          final daysPassed = DateTime.now().difference(_programStartDate!).inDays + 1;
          _currentWeek = ((daysPassed - 1) ~/ 7) + 1;
          _currentDayInWeek = ((daysPassed - 1) % 7) + 1;
        }
      });
    } catch (e) {
      print('❌ فشل تحميل البرنامج: $e');
    }
  }

  Future<void> _saveProgramData() async {
    try {
      if (_currentProgramId == null) return;
      
      // تحديث البرنامج الحالي
      final programIndex = _allPrograms.indexWhere((p) => p['id'] == _currentProgramId);
      if (programIndex != -1) {
        _allPrograms[programIndex]['progress'] = _dailyProgress;
        _allPrograms[programIndex]['snapshots'] = _weeklySnapshots;
        _allPrograms[programIndex]['startDate'] = _programStartDate?.toIso8601String();
        _allPrograms[programIndex]['lastUpdated'] = DateTime.now().toIso8601String();
      }
      
      // حفظ جميع البرامج
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('all_fitness_programs', json.encode(_allPrograms));
    } catch (e) {
      print('❌ فشل حفظ البيانات: $e');
    }
  }

  Future<void> _startProgram() async {
    if (widget.initialAnalysis == null) {
      NotificationsService.instance.toast(
        'يرجى إجراء التحليل أولاً',
        icon: Icons.warning,
        color: Colors.orange,
      );
      return;
    }
    
    // طلب اسم البرنامج
    final TextEditingController nameController = TextEditingController();
    final programName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اسم البرنامج', style: GoogleFonts.cairo()),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'مثال: برنامج بناء العضلات',
            hintStyle: GoogleFonts.cairo(),
          ),
          style: GoogleFonts.cairo(),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: Text('ابدأ', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
    
    if (programName == null || programName.isEmpty) return;
    
    // عرض مؤشر التحميل
    setState(() {
      _isLoading = true;
    });
    
    try {
      // استدعاء API لتوليد خطة 30 يوم
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/fitness/generate-30day-plan'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'program_name': programName,
          'initial_analysis': widget.initialAnalysis,
          'user_data': {
            'weight': prefs.getString('user_weight'),
            'height': prefs.getString('user_height'),
            'age': prefs.getString('user_age'),
            'gender': prefs.getString('user_gender'),
            'waist': prefs.getString('user_waist'),
            'neck': prefs.getString('user_neck'),
            'activity_level': prefs.getString('user_activity_level'),
            'goal': prefs.getString('user_goal'),
            'fitness_level': prefs.getString('user_fitness_level'),
          },
        }),
      );
      
      print('📊 [30-DAY PLAN] Status Code: ${response.statusCode}');
      print('📊 [30-DAY PLAN] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final planData = json.decode(response.body);
        
        // حفظ الأهداف
        _monthlyGoal = planData['plan']['monthly_goal'];
        _weeklyGoals = List<Map<String, dynamic>>.from(planData['plan']['weekly_goals'] ?? []);
        _expectedResults = planData['plan']['expected_results'];
        
        NotificationsService.instance.toast(
          'تم توليد خطة 30 يوم بنجاح! 🎯',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      } else {
        print('❌ [30-DAY PLAN] Error Response: ${response.body}');
        throw Exception('فشل توليد الخطة: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في توليد الخطة: $e');
      NotificationsService.instance.toast(
        'حدث خطأ أثناء توليد الخطة',
        icon: Icons.error,
        color: Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // إنشاء برنامج جديد
    final newProgramId = DateTime.now().millisecondsSinceEpoch.toString();
    final newProgram = {
      'id': newProgramId,
      'name': programName,
      'startDate': DateTime.now().toIso8601String(),
      'lastUpdated': DateTime.now().toIso8601String(),
      'progress': <String, Map<String, bool>>{},
      'snapshots': [
        {
          'week': 0,
          'date': DateTime.now().toIso8601String(),
          'analysis': widget.initialAnalysis,
          'image': null,
        }
      ],
      'monthly_goal': _monthlyGoal,
      'weekly_goals': _weeklyGoals,
      'expected_results': _expectedResults,
      'weekly_analyses': [],
    };
    
    _allPrograms.add(newProgram);
    _currentProgramId = newProgramId;
    
    setState(() {
      _programStartDate = DateTime.now();
      _currentWeek = 1;
      _currentDayInWeek = 1;
      _dailyProgress.clear();
      _weeklySnapshots = (newProgram['snapshots'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      _isLoading = false;
    });
    
    // إنشاء TabController جديد
    _tabController?.dispose();
    _tabController = TabController(
      length: _allPrograms.length,
      vsync: this,
      initialIndex: _allPrograms.length - 1,
    );
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController!.index;
          _currentProgramId = _allPrograms[_selectedTabIndex]['id'];
          _loadSpecificProgram(_currentProgramId!);
        });
      }
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

      // أولاً: تحليل الجسم
      final analysisResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/fitness-analyzer'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'image': base64Image,
          'user_data': userData,
        }),
      );

      if (analysisResponse.statusCode != 200) {
        throw Exception('فشل تحليل الجسم');
      }

      final bodyAnalysis = json.decode(utf8.decode(analysisResponse.bodyBytes));

      if (bodyAnalysis['is_body'] != true) {
        NotificationsService.instance.toast('⚠️ الصورة لا تحتوي على جسم واضح');
        setState(() {
          _weeklyImage = null;
          _isLoading = false;
        });
        return;
      }

      // ثانياً: تحليل التقدم الأسبوعي
      final previousSnapshot = _weeklySnapshots.isNotEmpty ? _weeklySnapshots.last : null;
      final currentWeekGoal = _weeklyGoals.isNotEmpty && _currentWeek <= _weeklyGoals.length
          ? _weeklyGoals[_currentWeek - 1]
          : null;

      // حساب المهام المكتملة
      final completedTasks = <String, bool>{};
      for (int day = 1; day <= 7; day++) {
        final dayKey = 'week${_currentWeek}_day$day';
        if (_dailyProgress.containsKey(dayKey)) {
          completedTasks.addAll(_dailyProgress[dayKey]!);
        }
      }

      final weeklyAnalysisResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/fitness/analyze-weekly-progress'),
        headers: await ApiConfig.getHeaders(),
        body: json.encode({
          'week_number': _currentWeek,
          'image': base64Image,
          'current_stats': {
            'weight': userData['weight'],
            'body_fat': bodyAnalysis['body_fat_percentage'],
            'muscle_mass': bodyAnalysis['muscle_mass_percentage'],
            'bmi': bodyAnalysis['bmi'],
          },
          'previous_stats': previousSnapshot != null ? {
            'weight': previousSnapshot['analysis']['weight'] ?? userData['weight'],
            'body_fat': previousSnapshot['analysis']['body_fat_percentage'],
            'muscle_mass': previousSnapshot['analysis']['muscle_mass_percentage'],
            'bmi': previousSnapshot['analysis']['bmi'],
          } : {
            'weight': userData['weight'],
            'body_fat': bodyAnalysis['body_fat_percentage'],
            'muscle_mass': bodyAnalysis['muscle_mass_percentage'],
            'bmi': bodyAnalysis['bmi'],
          },
          'weekly_goal': currentWeekGoal,
          'completed_tasks': completedTasks,
          'program_history': {
            'monthly_goal': _monthlyGoal,
            'weekly_goals': _weeklyGoals,
            'previous_weeks': _weeklySnapshots.map((s) => {
              'week': s['week'],
              'analysis': s['analysis'],
            }).toList(),
          },
        }),
      );

      Map<String, dynamic>? weeklyAnalysisData;
      if (weeklyAnalysisResponse.statusCode == 200) {
        weeklyAnalysisData = json.decode(utf8.decode(weeklyAnalysisResponse.bodyBytes));
        _weeklyAnalysis = weeklyAnalysisData;
      }

      // حفظ الـ snapshot
      _weeklySnapshots.add({
        'week': _currentWeek,
        'date': DateTime.now().toIso8601String(),
        'analysis': bodyAnalysis,
        'image': base64Image,
        'weekly_analysis': weeklyAnalysisData,
      });

      // حفظ التحليل الأسبوعي في البرنامج
      final programIndex = _allPrograms.indexWhere((p) => p['id'] == _currentProgramId);
      if (programIndex != -1) {
        if (_allPrograms[programIndex]['weekly_analyses'] == null) {
          _allPrograms[programIndex]['weekly_analyses'] = [];
        }
        (_allPrograms[programIndex]['weekly_analyses'] as List).add(weeklyAnalysisData);
      }

      await _saveProgramData();

      setState(() {
        _weeklyImage = null;
        _currentWeek++;
        _currentDayInWeek = 1;
      });

      NotificationsService.instance.toast(
        '✅ تم تحليل الأسبوع بنجاح! نسبة النجاح: ${weeklyAnalysisData?['analysis']?['success_rate']?.toStringAsFixed(0) ?? '0'}%',
        icon: Icons.check_circle,
        color: Colors.green,
      );
      
      // عرض التحليل الأسبوعي
      if (weeklyAnalysisData != null) {
        _showWeeklyAnalysisDialog(weeklyAnalysisData);
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

  void _showWeeklyAnalysisDialog(Map<String, dynamic> analysisData) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;
    
    final analysis = analysisData['analysis'];
    final successRate = (analysis?['success_rate'] ?? 0).toDouble();
    final performanceRating = analysis?['performance_rating'] ?? 'جيد';
    final weekNumber = analysisData['week_number'] ?? _currentWeek;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.analytics, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تحليل الأسبوع $weekNumber',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Rate
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      'نسبة النجاح',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: theme.textPrimaryColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${successRate.toStringAsFixed(0)}%',
                      style: GoogleFonts.cairo(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      performanceRating,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Achievements
              if (analysis?['achievements'] != null) ...[
                Text(
                  '🏆 الإنجازات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                ...((analysis['achievements'] as List).map((achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          achievement.toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
                const SizedBox(height: 15),
              ],
              
              // Areas to Improve
              if (analysis?['areas_to_improve'] != null && (analysis['areas_to_improve'] as List).isNotEmpty) ...[
                Text(
                  '📈 نقاط التحسين',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                ...((analysis['areas_to_improve'] as List).map((area) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.trending_up, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          area.toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))),
                const SizedBox(height: 15),
              ],
              
              // Motivation Message
              if (analysis?['motivation_message'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          analysis['motivation_message'].toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'رائع! 💪',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteProgramDialog(ThemeConfig theme, Color primaryColor) {
    if (_currentProgramId == null || _allPrograms.isEmpty) return;
    
    final currentProgram = _allPrograms.firstWhere((p) => p['id'] == _currentProgramId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'حذف البرنامج',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف برنامج "${currentProgram['name']}"؟\n\nسيتم حذف جميع البيانات والتقدم المرتبط بهذا البرنامج.',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: theme.textPrimaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: theme.textPrimaryColor.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProgram(_currentProgramId!);
            },
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProgram(String programId) async {
    try {
      final programIndex = _allPrograms.indexWhere((p) => p['id'] == programId);
      if (programIndex == -1) return;
      
      _allPrograms.removeAt(programIndex);
      
      // حفظ التغييرات
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('all_fitness_programs', json.encode(_allPrograms));
      
      // إعادة تحميل البرامج
      if (_allPrograms.isEmpty) {
        setState(() {
          _currentProgramId = null;
          _programStartDate = null;
          _monthlyGoal = null;
          _weeklyGoals.clear();
          _expectedResults = null;
          _dailyProgress.clear();
          _weeklySnapshots.clear();
          _tabController?.dispose();
          _tabController = null;
        });
      } else {
        // الانتقال لآخر برنامج
        _currentProgramId = _allPrograms.last['id'];
        await _loadSpecificProgram(_currentProgramId!);
        
        // إعادة إنشاء TabController
        _tabController?.dispose();
        _tabController = TabController(
          length: _allPrograms.length,
          vsync: this,
          initialIndex: _allPrograms.length - 1,
        );
        _tabController!.addListener(() {
          if (_tabController!.indexIsChanging) {
            setState(() {
              _selectedTabIndex = _tabController!.index;
              _currentProgramId = _allPrograms[_selectedTabIndex]['id'];
              _loadSpecificProgram(_currentProgramId!);
            });
          }
        });
        
        setState(() {});
      }
      
      NotificationsService.instance.toast(
        'تم حذف البرنامج بنجاح',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    } catch (e) {
      print('❌ فشل حذف البرنامج: $e');
      NotificationsService.instance.toast(
        'حدث خطأ أثناء الحذف',
        icon: Icons.error,
        color: Colors.red,
      );
    }
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
      body: _allPrograms.isEmpty
          ? _buildStartScreen(theme, primaryColor, isDark)
          : _buildProgramScreen(theme, primaryColor, isDark),
    );
  }

  Widget _buildStartScreen(ThemeConfig theme, Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(25),
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
                size: 80,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'برنامج 30 يوم المتكامل',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '4 أسابيع × 7 أيام',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
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
                  const SizedBox(height: 10),
                  _buildFeatureRow(Icons.camera_alt, 'صورة أسبوعية للتتبع', theme),
                  const SizedBox(height: 10),
                  _buildFeatureRow(Icons.trending_up, 'تحليل التقدم تلقائياً', theme),
                  const SizedBox(height: 10),
                  _buildFeatureRow(Icons.refresh, 'تحديث البرنامج كل أسبوع', theme),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startProgram,
                icon: const Icon(Icons.play_arrow, size: 24),
                label: Text(
                  'ابدأ البرنامج الآن',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
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
            const SizedBox(height: 30),
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

  Widget _buildGoalsSection(ThemeConfig theme, Color primaryColor, bool isDark) {
    final currentWeekGoal = _weeklyGoals.isNotEmpty && _currentWeek <= _weeklyGoals.length
        ? _weeklyGoals[_currentWeek - 1]
        : null;

    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Goal
          if (_monthlyGoal != null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.emoji_events, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الهدف الشهري',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.textPrimaryColor.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        _monthlyGoal!['title'] ?? 'هدف الشهر',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoalMetric(
                    'الوزن المستهدف',
                    '${_monthlyGoal!['target_weight_change'] ?? 0} كجم',
                    Icons.monitor_weight,
                    theme,
                    primaryColor,
                  ),
                  const SizedBox(height: 8),
                  _buildGoalMetric(
                    'نسبة الدهون',
                    '${_monthlyGoal!['target_body_fat_change'] ?? 0}%',
                    Icons.trending_down,
                    theme,
                    primaryColor,
                  ),
                  const SizedBox(height: 8),
                  _buildGoalMetric(
                    'نسبة العضلات',
                    '+${_monthlyGoal!['target_muscle_change'] ?? 0}%',
                    Icons.fitness_center,
                    theme,
                    primaryColor,
                  ),
                ],
              ),
            ),
          ],
          
          // Weekly Goal
          if (currentWeekGoal != null) ...[
            const SizedBox(height: 20),
            Divider(color: primaryColor.withOpacity(0.3)),
            const SizedBox(height: 15),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_today, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'هدف الأسبوع $_currentWeek',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.textPrimaryColor.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        currentWeekGoal['title'] ?? 'هدف الأسبوع',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 التركيز: ${currentWeekGoal['focus'] ?? ''}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🍽️ التغذية: ${currentWeekGoal['nutrition_focus'] ?? ''}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalMetric(String label, String value, IconData icon, ThemeConfig theme, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: theme.textPrimaryColor.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: primaryColor,
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
        // Program Tabs with Actions
        if (_allPrograms.isNotEmpty && _tabController != null)
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: primaryColor,
                    unselectedLabelColor: theme.textPrimaryColor.withOpacity(0.5),
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: _allPrograms.map((program) {
                      return Tab(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 5),
                            Text(program['name'] ?? 'برنامج'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // New Program Button
                IconButton(
                  icon: Icon(Icons.add_circle, color: primaryColor, size: 28),
                  onPressed: () => _startProgram(),
                  tooltip: 'برنامج جديد',
                ),
                // Delete Program Button
                if (_allPrograms.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 24),
                    onPressed: () => _showDeleteProgramDialog(theme, primaryColor),
                    tooltip: 'حذف البرنامج',
                  ),
              ],
            ),
          ),
        
        // Goals Section
        if (_monthlyGoal != null || (_weeklyGoals.isNotEmpty && _currentWeek <= _weeklyGoals.length))
          _buildGoalsSection(theme, primaryColor, isDark),
        
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

