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

      // الحصول على اسم المدينة (مبسط)
      setState(() {
        _cityName = 'موقعك الحالي';
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
        gradient: const LinearGradient(
          colors: [Color(0xFF10b981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to prayer times page
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // الصف الأول: المدينة والأيقونة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isDaytime ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _cityName,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mosque_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'أوقات الصلاة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // الصف الثاني: الصلاة القادمة والوقت المتبقي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الصلاة القادمة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _nextPrayer,
                            style: GoogleFonts.cairo(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'باقي',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _timeRemaining,
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFeatures: [const FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // الخط الفاصل
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // الدعاء المتحرك
                SizedBox(
                  height: 30,
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
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _duaas[_currentDuaaIndex],
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

