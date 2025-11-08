import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'theme_config.dart';

class AIFitnessProgressComparisonPage extends StatefulWidget {
  const AIFitnessProgressComparisonPage({Key? key}) : super(key: key);

  @override
  _AIFitnessProgressComparisonPageState createState() => _AIFitnessProgressComparisonPageState();
}

class _AIFitnessProgressComparisonPageState extends State<AIFitnessProgressComparisonPage> {
  List<Map<String, dynamic>> _weeklyRecords = [];
  int _selectedWeek1 = 0; // الأسبوع الأول للمقارنة
  int _selectedWeek2 = 0; // الأسبوع الثاني للمقارنة
  
  @override
  void initState() {
    super.initState();
    _loadWeeklyRecords();
  }

  Future<void> _loadWeeklyRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getString('weekly_fitness_records');
      if (recordsJson != null) {
        final List<dynamic> decoded = json.decode(recordsJson);
        setState(() {
          _weeklyRecords = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          _weeklyRecords.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
          
          if (_weeklyRecords.length >= 2) {
            _selectedWeek1 = 0; // الأقدم
            _selectedWeek2 = _weeklyRecords.length - 1; // الأحدث
          }
        });
      }
    } catch (e) {
      print('❌ فشل تحميل السجلات: $e');
    }
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
          'مقارنة التقدم',
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
      body: _weeklyRecords.length < 2
          ? _buildEmptyState(theme, primaryColor)
          : _buildComparisonContent(theme, primaryColor, isDark),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 100,
            color: theme.textPrimaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'تحتاج إلى أسبوعين على الأقل',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'سجل صورة أسبوعية لمدة أسبوعين لبدء المقارنة',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textPrimaryColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonContent(ThemeConfig theme, Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اختيار الأسابيع للمقارنة
          _buildWeekSelectors(theme, primaryColor),
          
          const SizedBox(height: 25),
          
          // مقارنة الصور
          _buildImageComparison(theme, primaryColor, isDark),
          
          const SizedBox(height: 25),
          
          // مقارنة الأرقام
          _buildStatsComparison(theme, primaryColor, isDark),
          
          const SizedBox(height: 25),
          
          // الرسوم البيانية
          _buildProgressCharts(theme, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildWeekSelectors(ThemeConfig theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'اختر الأسابيع للمقارنة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildWeekDropdown(
                  'من',
                  _selectedWeek1,
                  (value) => setState(() => _selectedWeek1 = value!),
                  theme,
                  primaryColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward, color: primaryColor),
              ),
              Expanded(
                child: _buildWeekDropdown(
                  'إلى',
                  _selectedWeek2,
                  (value) => setState(() => _selectedWeek2 = value!),
                  theme,
                  primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDropdown(
    String label,
    int selectedValue,
    Function(int?) onChanged,
    ThemeConfig theme,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: theme.textPrimaryColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: DropdownButton<int>(
            value: selectedValue,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
            dropdownColor: theme.backgroundColor,
            items: List.generate(_weeklyRecords.length, (index) {
              return DropdownMenuItem<int>(
                value: index,
                child: Text('الأسبوع ${_weeklyRecords[index]['week_number']}'),
              );
            }),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildImageComparison(ThemeConfig theme, Color primaryColor, bool isDark) {
    final week1 = _weeklyRecords[_selectedWeek1];
    final week2 = _weeklyRecords[_selectedWeek2];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            Text(
              'مقارنة الصور',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildImageCard(week1, 'قبل', theme, primaryColor),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildImageCard(week2, 'بعد', theme, primaryColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCard(Map<String, dynamic> record, String label, ThemeConfig theme, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Center(
              child: Text(
                '$label - الأسبوع ${record['week_number']}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(13),
              bottomRight: Radius.circular(13),
            ),
            child: Image.memory(
              base64Decode(record['image']),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsComparison(ThemeConfig theme, Color primaryColor, bool isDark) {
    final week1 = _weeklyRecords[_selectedWeek1];
    final week2 = _weeklyRecords[_selectedWeek2];

    final weight1 = double.tryParse(week1['weight']?.toString() ?? '0') ?? 0;
    final weight2 = double.tryParse(week2['weight']?.toString() ?? '0') ?? 0;
    final fat1 = double.tryParse(week1['body_fat_percentage']?.toString() ?? '0') ?? 0;
    final fat2 = double.tryParse(week2['body_fat_percentage']?.toString() ?? '0') ?? 0;
    final muscle1 = double.tryParse(week1['muscle_mass_percentage']?.toString() ?? '0') ?? 0;
    final muscle2 = double.tryParse(week2['muscle_mass_percentage']?.toString() ?? '0') ?? 0;
    final waist1 = double.tryParse(week1['waist']?.toString() ?? '0') ?? 0;
    final waist2 = double.tryParse(week2['waist']?.toString() ?? '0') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            Text(
              'مقارنة الأرقام',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildStatComparisonRow('الوزن', weight1, weight2, 'كجم', true, theme, primaryColor),
        const SizedBox(height: 10),
        _buildStatComparisonRow('نسبة الدهون', fat1, fat2, '%', true, theme, primaryColor),
        const SizedBox(height: 10),
        _buildStatComparisonRow('نسبة العضلات', muscle1, muscle2, '%', false, theme, primaryColor),
        const SizedBox(height: 10),
        _buildStatComparisonRow('محيط الخصر', waist1, waist2, 'سم', true, theme, primaryColor),
      ],
    );
  }

  Widget _buildStatComparisonRow(
    String label,
    double value1,
    double value2,
    String unit,
    bool lowerIsBetter,
    ThemeConfig theme,
    Color primaryColor,
  ) {
    final change = value2 - value1;
    final isImproved = lowerIsBetter ? change < 0 : change > 0;
    final changeColor = change == 0 ? Colors.grey : (isImproved ? Colors.green : Colors.red);
    final changeIcon = change == 0 ? Icons.remove : (change < 0 ? Icons.arrow_downward : Icons.arrow_upward);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${value1.toStringAsFixed(1)} $unit',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: theme.textPrimaryColor.withOpacity(0.7),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(changeIcon, size: 14, color: changeColor),
                const SizedBox(width: 4),
                Text(
                  change.abs().toStringAsFixed(1),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${value2.toStringAsFixed(1)} $unit',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCharts(ThemeConfig theme, Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, color: primaryColor, size: 24),
            const SizedBox(width: 10),
            Text(
              'الرسوم البيانية',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // رسم بياني للوزن
        _buildChart(
          'الوزن (كجم)',
          _weeklyRecords.map((r) => double.tryParse(r['weight']?.toString() ?? '0') ?? 0).toList(),
          Colors.blue,
          theme,
          primaryColor,
        ),
        
        const SizedBox(height: 20),
        
        // رسم بياني لنسبة الدهون
        _buildChart(
          'نسبة الدهون (%)',
          _weeklyRecords.map((r) => double.tryParse(r['body_fat_percentage']?.toString() ?? '0') ?? 0).toList(),
          Colors.red,
          theme,
          primaryColor,
        ),
        
        const SizedBox(height: 20),
        
        // رسم بياني لنسبة العضلات
        _buildChart(
          'نسبة العضلات (%)',
          _weeklyRecords.map((r) => double.tryParse(r['muscle_mass_percentage']?.toString() ?? '0') ?? 0).toList(),
          Colors.green,
          theme,
          primaryColor,
        ),
      ],
    );
  }

  Widget _buildChart(String title, List<double> data, Color lineColor, ThemeConfig theme, Color primaryColor) {
    if (data.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.textPrimaryColor.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 && value.toInt() < _weeklyRecords.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'أ${_weeklyRecords[value.toInt()]['week_number']}',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: theme.textPrimaryColor.withOpacity(0.6),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (data.reduce((a, b) => a > b ? a : b) - data.reduce((a, b) => a < b ? a : b)) / 4,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: theme.textPrimaryColor.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: theme.textPrimaryColor.withOpacity(0.1)),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: data.reduce((a, b) => a < b ? a : b) * 0.95,
                maxY: data.reduce((a, b) => a > b ? a : b) * 1.05,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      data.length,
                      (index) => FlSpot(index.toDouble(), data[index]),
                    ),
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

