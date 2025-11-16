import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerButton extends StatefulWidget {
  const PrayerButton({super.key});

  @override
  State<PrayerButton> createState() => _PrayerButtonState();
}

class _PrayerButtonState extends State<PrayerButton> with SingleTickerProviderStateMixin {
  Timer? _timer;
  Timer? _duaaTimer;
  PrayerTimes? _prayerTimes;
  String _nextPrayer = 'جاري التحميل...';
  String _timeRemaining = '--:--:--';
  String _cityName = 'جاري تحديد الموقع...';
  bool _isDaytime = true;
  int _currentDuaaIndex = 0;
  bool _isAnimating = false;
  
  final List<String> _duaas = [
    'اللهم صل وسلم على نبينا محمد',
    'سبحان الله وبحمده سبحان الله العظيم',
    'لا إله إلا الله وحده لا شريك له',
    'اللهم إني أسألك العفو والعافية',
    'حسبي الله ونعم الوكيل',
    'اللهم اجعلني من التوابين واجعلني من المتطهرين',
    'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة',
    'اللهم إني أعوذ بك من الهم والحزن',
    'اللهم أعني على ذكرك وشكرك وحسن عبادتك',
    'اللهم إني أسألك علماً نافعاً ورزقاً طيباً',
  ];

  @override
  void initState() {
    super.initState();
    _initializePrayerTimes();
    _startDuaaAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _duaaTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePrayerTimes() async {
    try {
      // التحقق من صلاحيات الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _cityName = 'الرياض';
          _calculatePrayerTimes(24.7136, 46.6753); // الرياض كموقع افتراضي
        });
        return;
      }

      // الحصول على الموقع الحالي
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // حفظ الموقع
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latitude', position.latitude);
      await prefs.setDouble('longitude', position.longitude);

      // تحديد اسم المدينة بناءً على الإحداثيات (مدن السعودية الرئيسية)
      String cityName = _getCityNameFromCoordinates(position.latitude, position.longitude);
      
      setState(() {
        _cityName = cityName;
      });

      _calculatePrayerTimes(position.latitude, position.longitude);
    } catch (e) {
      // في حالة الخطأ، استخدم الرياض كموقع افتراضي
      setState(() {
        _cityName = 'الرياض';
      });
      _calculatePrayerTimes(24.7136, 46.6753);
    }
  }

  String _getCityNameFromCoordinates(double lat, double lon) {
    // قائمة المدن السعودية الرئيسية مع إحداثياتها
    final cities = [
      {'name': 'الرياض', 'lat': 24.7136, 'lon': 46.6753},
      {'name': 'جدة', 'lat': 21.5433, 'lon': 39.1728},
      {'name': 'مكة المكرمة', 'lat': 21.4225, 'lon': 39.8262},
      {'name': 'المدينة المنورة', 'lat': 24.5247, 'lon': 39.5692},
      {'name': 'الدمام', 'lat': 26.4207, 'lon': 50.0888},
      {'name': 'الخبر', 'lat': 26.2172, 'lon': 50.1971},
      {'name': 'الظهران', 'lat': 26.2654, 'lon': 50.1533},
      {'name': 'الطائف', 'lat': 21.2703, 'lon': 40.4158},
      {'name': 'تبوك', 'lat': 28.3838, 'lon': 36.5550},
      {'name': 'بريدة', 'lat': 26.3260, 'lon': 43.9750},
      {'name': 'خميس مشيط', 'lat': 18.3067, 'lon': 42.7289},
      {'name': 'أبها', 'lat': 18.2164, 'lon': 42.5053},
      {'name': 'حائل', 'lat': 27.5219, 'lon': 41.6901},
      {'name': 'الجبيل', 'lat': 27.0174, 'lon': 49.6251},
      {'name': 'ينبع', 'lat': 24.0896, 'lon': 38.0618},
      {'name': 'القطيف', 'lat': 26.5654, 'lon': 50.0089},
      {'name': 'الأحساء', 'lat': 25.4295, 'lon': 49.5906},
      {'name': 'الخرج', 'lat': 24.1553, 'lon': 47.3119},
      {'name': 'جازان', 'lat': 16.8892, 'lon': 42.5511},
      {'name': 'نجران', 'lat': 17.4924, 'lon': 44.1277},
      {'name': 'الباحة', 'lat': 20.0129, 'lon': 41.4677},
      {'name': 'عرعر', 'lat': 30.9753, 'lon': 41.0381},
      {'name': 'سكاكا', 'lat': 29.9697, 'lon': 40.2064},
      {'name': 'القريات', 'lat': 31.3321, 'lon': 37.3439},
    ];

    // البحث عن أقرب مدينة
    double minDistance = double.infinity;
    String closestCity = 'موقعك الحالي';

    for (var city in cities) {
      double cityLat = city['lat'] as double;
      double cityLon = city['lon'] as double;
      
      // حساب المسافة باستخدام صيغة Haversine المبسطة
      double distance = _calculateDistance(lat, lon, cityLat, cityLon);
      
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = city['name'] as String;
      }
    }

    // إذا كانت المسافة أقل من 50 كم، نعتبرها نفس المدينة
    return minDistance < 50 ? closestCity : 'موقعك الحالي';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // صيغة Haversine المبسطة لحساب المسافة بين نقطتين
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومترات
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(lat1).cos() * _toRadians(lat2).cos() *
        (dLon / 2).sin() * (dLon / 2).sin();
    
    double c = 2 * (a.sqrt()).asin();
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  void _calculatePrayerTimes(double latitude, double longitude) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes.today(coordinates, params);
    
    setState(() {
      _prayerTimes = prayerTimes;
      _updateNextPrayer();
    });

    // تحديث كل ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateNextPrayer();
    });
  }

  void _updateNextPrayer() {
    if (_prayerTimes == null) return;

    final now = DateTime.now();
    final prayers = [
      {'name': 'الفجر', 'time': _prayerTimes!.fajr},
      {'name': 'الشروق', 'time': _prayerTimes!.sunrise},
      {'name': 'الظهر', 'time': _prayerTimes!.dhuhr},
      {'name': 'العصر', 'time': _prayerTimes!.asr},
      {'name': 'المغرب', 'time': _prayerTimes!.maghrib},
      {'name': 'العشاء', 'time': _prayerTimes!.isha},
    ];

    // تحديد إذا كان النهار أو الليل
    final isDaytime = now.isAfter(_prayerTimes!.sunrise) && 
                      now.isBefore(_prayerTimes!.maghrib);

    // البحث عن الصلاة القادمة
    for (var prayer in prayers) {
      final prayerTime = prayer['time'] as DateTime;
      if (now.isBefore(prayerTime)) {
        final difference = prayerTime.difference(now);
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        final seconds = difference.inSeconds % 60;

        setState(() {
          _nextPrayer = prayer['name'] as String;
          _timeRemaining = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          _isDaytime = isDaytime;
        });
        return;
      }
    }

    // إذا لم نجد صلاة اليوم، الصلاة القادمة هي فجر الغد
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowCoordinates = Coordinates(
      _prayerTimes!.coordinates.latitude,
      _prayerTimes!.coordinates.longitude,
    );
    final params = CalculationMethod.umm_al_qura.getParameters();
    final tomorrowPrayers = PrayerTimes(tomorrowCoordinates, 
      DateComponents(tomorrow.year, tomorrow.month, tomorrow.day), params);
    
    final difference = tomorrowPrayers.fajr.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    setState(() {
      _nextPrayer = 'الفجر';
      _timeRemaining = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      _isDaytime = isDaytime;
    });
  }

  void _startDuaaAnimation() {
    _duaaTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      setState(() {
        _isAnimating = true;
      });

      // بعد ثانية من بدء الحركة، غير الدعاء
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _currentDuaaIndex = (_currentDuaaIndex + 1) % _duaas.length;
            _isAnimating = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // الخلفية مع Pattern إسلامي
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10b981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
                child: Container(),
              ),
            ),
            
            // المحتوى
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Navigate to prayer times page
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // الصف الأول: أيقونة المسجد والمدينة
                      Row(
                        children: [
                          // أيقونة المسجد مع دائرة
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _isDaytime ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // المدينة والعنوان
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'أوقات الصلاة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _cityName,
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // أيقونة السهم
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // خط فاصل مع زخرفة
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.mosque_rounded,
                              color: Colors.white.withOpacity(0.6),
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.4),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // الصلاة القادمة والوقت
                      Row(
                        children: [
                          // الصلاة القادمة
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الصلاة القادمة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _nextPrayer,
                                  style: GoogleFonts.cairo(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // الوقت المتبقي
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'باقي',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _timeRemaining,
                                  style: GoogleFonts.cairo(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFeatures: [const FontFeature.tabularFigures()],
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // الدعاء المتحرك
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          height: 28,
                          child: ClipRect(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(-1.0, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Row(
                                key: ValueKey<int>(_currentDuaaIndex),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '﷽',
                                    style: GoogleFonts.amiriQuran(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      _duaas[_currentDuaaIndex],
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '﷽',
                                    style: GoogleFonts.amiriQuran(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// رسام Pattern إسلامي للخلفية
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // رسم نمط هندسي إسلامي بسيط
    final spacing = 40.0;
    
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // رسم نجمة صغيرة
        _drawStar(canvas, paint, Offset(x, y), 8);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    const points = 8;
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159) / points;
      final r = i.isEven ? radius : radius / 2;
      final x = center.dx + r * (angle.cos());
      final y = center.dy + r * (angle.sin());
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
}

