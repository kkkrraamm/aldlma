import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:quran/quran.dart' as quran;

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  Timer? _timer;
  PrayerTimes? _prayerTimes;
  String _nextPrayer = 'جاري التحميل...';
  String _timeRemaining = '--:--:--';
  String _cityName = 'جاري تحديد الموقع...';
  bool _isDaytime = true;
  double _progressValue = 0.0;
  int _tasbihCount = 0;
  int _totalTasbihCount = 0; // العداد الإجمالي
  String _currentTasbih = 'سبحان الله';
  bool _showIslamicAI = false;
  final TextEditingController _islamicAIController = TextEditingController();
  final List<Map<String, dynamic>> _islamicAIMessages = [];
  bool _isIslamicAITyping = false;
  final GlobalKey _islamicAIChatKey = GlobalKey();
  
  // للقرآن
  int? _selectedSurah;
  final GlobalKey _quranSectionKey = GlobalKey();
  int _currentQuranPage = 0;
  late PageController _quranPageController;
  
  // للقبلة
  double? _currentLatitude;
  double? _currentLongitude;
  double _qiblaDirection = 0.0;
  double _compassHeading = 0.0;
  String _qiblaDistance = '---';
  StreamSubscription<CompassEvent>? _compassSubscription;
  
  final Map<String, bool> _prayedStatus = {
    'الفجر': false,
    'الظهر': false,
    'العصر': false,
    'المغرب': false,
    'العشاء': false,
  };

  final List<String> _tasbihOptions = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
  ];

  @override
  void initState() {
    super.initState();
    _initializePrayerTimes();
    _loadPrayedStatus();
    _initializeCompass();
    _quranPageController = PageController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _islamicAIController.dispose();
    _compassSubscription?.cancel();
    _quranPageController.dispose();
    super.dispose();
  }

  Future<void> _loadPrayedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    setState(() {
      _prayedStatus['الفجر'] = prefs.getBool('prayed_fajr_$today') ?? false;
      _prayedStatus['الظهر'] = prefs.getBool('prayed_dhuhr_$today') ?? false;
      _prayedStatus['العصر'] = prefs.getBool('prayed_asr_$today') ?? false;
      _prayedStatus['المغرب'] = prefs.getBool('prayed_maghrib_$today') ?? false;
      _prayedStatus['العشاء'] = prefs.getBool('prayed_isha_$today') ?? false;
    });
  }

  Future<void> _togglePrayedStatus(String prayer) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'prayed_${_getPrayerKey(prayer)}_$today';
    
    setState(() {
      _prayedStatus[prayer] = !(_prayedStatus[prayer] ?? false);
    });
    
    await prefs.setBool(key, _prayedStatus[prayer] ?? false);
  }

  String _getPrayerKey(String prayer) {
    switch (prayer) {
      case 'الفجر': return 'fajr';
      case 'الظهر': return 'dhuhr';
      case 'العصر': return 'asr';
      case 'المغرب': return 'maghrib';
      case 'العشاء': return 'isha';
      default: return '';
    }
  }

  Future<void> _initializePrayerTimes() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _cityName = 'الرياض';
          _calculatePrayerTimes(24.7136, 46.6753);
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String cityName = _getCityNameFromCoordinates(position.latitude, position.longitude);
      
      setState(() {
        _cityName = cityName;
      });

      _calculatePrayerTimes(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _cityName = 'الرياض';
      });
      _calculatePrayerTimes(24.7136, 46.6753);
    }
  }

  String _getCityNameFromCoordinates(double lat, double lon) {
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

    double minDistance = double.infinity;
    String closestCity = 'موقعك الحالي';

    for (var city in cities) {
      double cityLat = city['lat'] as double;
      double cityLon = city['lon'] as double;
      double distance = _calculateDistance(lat, lon, cityLat, cityLon);
      
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = city['name'] as String;
      }
    }

    return minDistance < 50 ? closestCity : 'موقعك الحالي';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
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

    // حساب القبلة
    _calculateQibla(latitude, longitude);

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

    final isDaytime = now.isAfter(_prayerTimes!.sunrise) && 
                      now.isBefore(_prayerTimes!.maghrib);

    DateTime? previousPrayerTime;
    DateTime? nextPrayerTime;

    for (int i = 0; i < prayers.length; i++) {
      final prayerTime = prayers[i]['time'] as DateTime;
      if (now.isBefore(prayerTime)) {
        nextPrayerTime = prayerTime;
        if (i > 0) {
          previousPrayerTime = prayers[i - 1]['time'] as DateTime;
        }
        
        final difference = prayerTime.difference(now);
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        final seconds = difference.inSeconds % 60;

        // حساب Progress
        double progress = 0.0;
        if (previousPrayerTime != null) {
          final totalDuration = nextPrayerTime.difference(previousPrayerTime).inSeconds;
          final elapsed = now.difference(previousPrayerTime).inSeconds;
          progress = elapsed / totalDuration;
        }

        setState(() {
          _nextPrayer = prayers[i]['name'] as String;
          _timeRemaining = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          _isDaytime = isDaytime;
          _progressValue = progress.clamp(0.0, 1.0);
        });
        return;
      }
    }

    // فجر الغد
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
      _progressValue = 0.0;
    });
  }

  String _getHijriDate() {
    final now = DateTime.now();
    final weekDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final weekDay = weekDays[now.weekday % 7];
    
    // حساب التاريخ الهجري التقريبي
    // الفرق بين التقويم الميلادي والهجري حوالي 622 سنة و8 أشهر
    final gregorianYear = now.year;
    final gregorianMonth = now.month;
    final gregorianDay = now.day;
    
    // صيغة تقريبية لتحويل التاريخ الميلادي إلى هجري
    final hijriYear = ((gregorianYear - 622) * 1.030684).floor() + 1;
    
    // أسماء الشهور الهجرية
    final hijriMonths = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];
    
    // حساب تقريبي للشهر واليوم (هذا تقريبي جداً)
    final dayOfYear = now.difference(DateTime(gregorianYear, 1, 1)).inDays;
    final hijriMonth = ((dayOfYear / 29.5) % 12).floor();
    final hijriDay = ((dayOfYear % 29.5) + 1).floor();
    
    return '$weekDay $hijriDay ${hijriMonths[hijriMonth]} $hijriYear هـ';
  }

  void _initializeCompass() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _compassHeading = event.heading ?? 0.0;
      });
    });
  }

  void _calculateQibla(double latitude, double longitude) {
    // إحداثيات الكعبة المشرفة
    const double meccaLat = 21.4225;
    const double meccaLon = 39.8262;

    setState(() {
      _currentLatitude = latitude;
      _currentLongitude = longitude;
    });

    // حساب الاتجاه
    final double dLon = _toRadians(meccaLon - longitude);
    final double lat1 = _toRadians(latitude);
    final double lat2 = _toRadians(meccaLat);

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x);
    bearing = (bearing * 180 / math.pi + 360) % 360;

    // حساب المسافة
    final double distance = _calculateDistance(latitude, longitude, meccaLat, meccaLon);

    setState(() {
      _qiblaDirection = bearing;
      _qiblaDistance = '${distance.toStringAsFixed(0)} كم';
    });
  }

  String _getQiblaDirectionText() {
    if (_currentLatitude == null) return 'جاري التحميل...';
    
    final double angle = (_qiblaDirection - _compassHeading + 360) % 360;
    
    if (angle >= 337.5 || angle < 22.5) return 'شمال';
    if (angle >= 22.5 && angle < 67.5) return 'شمال شرق';
    if (angle >= 67.5 && angle < 112.5) return 'شرق';
    if (angle >= 112.5 && angle < 157.5) return 'جنوب شرق';
    if (angle >= 157.5 && angle < 202.5) return 'جنوب';
    if (angle >= 202.5 && angle < 247.5) return 'جنوب غرب';
    if (angle >= 247.5 && angle < 292.5) return 'غرب';
    return 'شمال غرب';
  }

  Future<void> _sendIslamicAIMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _islamicAIMessages.add({
        'role': 'user',
        'content': message,
      });
      _isIslamicAITyping = true;
    });

    _islamicAIController.clear();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/islamic-ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'history': _islamicAIMessages.take(_islamicAIMessages.length - 1).toList(),
          'prompt_id': 'islamic_ai',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _islamicAIMessages.add({
            'role': 'assistant',
            'content': data['reply'],
          });
          _isIslamicAITyping = false;
        });
      } else {
        throw Exception('فشل الاتصال');
      }
    } catch (e) {
      setState(() {
        _islamicAIMessages.add({
          'role': 'assistant',
          'content': 'عذراً، حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى.',
        });
        _isIslamicAITyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFf0f0f0),
      body: CustomScrollView(
        slivers: [
          // Header
          _buildHeader(theme),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // الصلاة القادمة
                _buildNextPrayerCard(theme),
                
                const SizedBox(height: 20),
                
                // جدول الصلوات
                _buildPrayersList(theme),
                
                const SizedBox(height: 20),
                
                // الأذكار والأدعية
                _buildAzkarSection(theme),
                
                const SizedBox(height: 20),
                
                // القبلة
                _buildQiblaSection(theme),
                
                const SizedBox(height: 20),
                
                // السبحة الإلكترونية
                _buildTasbihSection(theme),
                
                const SizedBox(height: 20),
                
                // القرآن الكريم
                _buildQuranSection(theme),
                
                const SizedBox(height: 20),
                
                // ذكاء الدلما الإسلامي
                _buildIslamicAISection(theme),
                
                // قسم الدردشة (يظهر عند الضغط)
                if (_showIslamicAI) ...[
                  const SizedBox(height: 20),
                  _buildIslamicAIChatSection(theme),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeConfig theme) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF047857),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF047857),
                    Color(0xFF065f46),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
                child: Container(),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getHijriDate(),
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          'أوقات الصلاة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildNextPrayerCard(ThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF047857),
                    Color(0xFF065f46),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
                child: Container(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mosque_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الصلاة القادمة',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nextPrayer,
                    style: GoogleFonts.cairo(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_prayerTimes != null) ...[
                    Text(
                      _formatPrayerTime(_getNextPrayerTime()),
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'باقي',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _timeRemaining,
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Progress Bar
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progressValue * 100).toInt()}% من الوقت مضى',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getNextPrayerTime() {
    if (_prayerTimes == null) return DateTime.now();
    
    final now = DateTime.now();
    final prayers = [
      _prayerTimes!.fajr,
      _prayerTimes!.sunrise,
      _prayerTimes!.dhuhr,
      _prayerTimes!.asr,
      _prayerTimes!.maghrib,
      _prayerTimes!.isha,
    ];

    for (var time in prayers) {
      if (now.isBefore(time)) {
        return time;
      }
    }

    return _prayerTimes!.fajr;
  }

  String _formatPrayerTime(DateTime time) {
    return DateFormat('hh:mm a', 'ar').format(time);
  }

  Widget _buildPrayersList(ThemeConfig theme) {
    if (_prayerTimes == null) {
      return const SizedBox();
    }

    final prayers = [
      {'name': 'الفجر', 'time': _prayerTimes!.fajr, 'icon': Icons.wb_twilight_rounded},
      {'name': 'الشروق', 'time': _prayerTimes!.sunrise, 'icon': Icons.wb_sunny_rounded},
      {'name': 'الظهر', 'time': _prayerTimes!.dhuhr, 'icon': Icons.wb_sunny_outlined},
      {'name': 'العصر', 'time': _prayerTimes!.asr, 'icon': Icons.wb_cloudy_rounded},
      {'name': 'المغرب', 'time': _prayerTimes!.maghrib, 'icon': Icons.wb_twilight},
      {'name': 'العشاء', 'time': _prayerTimes!.isha, 'icon': Icons.nightlight_round},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFF10b981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'مواقيت الصلاة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
          ),
          ...prayers.map((prayer) => _buildPrayerItem(
            prayer['name'] as String,
            prayer['time'] as DateTime,
            prayer['icon'] as IconData,
            theme,
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(String name, DateTime time, IconData icon, ThemeConfig theme) {
    final isNext = name == _nextPrayer;
    final isPrayed = _prayedStatus[name] ?? false;
    final canBePrayed = name != 'الشروق'; // الشروق ليس صلاة

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isNext 
            ? const Color(0xFF10b981).withOpacity(0.1)
            : (theme.isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFf9fafb)),
        borderRadius: BorderRadius.circular(16),
        border: isNext ? Border.all(
          color: const Color(0xFF10b981).withOpacity(0.3),
          width: 2,
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canBePrayed ? () => _togglePrayedStatus(name) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isNext 
                        ? const Color(0xFF10b981)
                        : (theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isNext ? Colors.white : const Color(0xFF10b981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                        ),
                      ),
                      if (isNext) ...[
                        const SizedBox(height: 2),
                        Text(
                          'القادمة',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFF10b981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  _formatPrayerTime(time),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                if (canBePrayed) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isPrayed 
                          ? const Color(0xFF10b981)
                          : (theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPrayed 
                            ? const Color(0xFF10b981)
                            : Colors.grey.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isPrayed ? Icons.check_rounded : Icons.check_rounded,
                      color: isPrayed ? Colors.white : Colors.grey.withOpacity(0.3),
                      size: 16,
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

  Widget _buildAzkarSection(ThemeConfig theme) {
    final azkarItems = [
      {'title': 'أذكار الصباح', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFf59e0b)},
      {'title': 'أذكار المساء', 'icon': Icons.nightlight_round, 'color': const Color(0xFF8b5cf6)},
      {'title': 'أدعية مأثورة', 'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFF10b981)},
      {'title': 'أذكار بعد الصلاة', 'icon': Icons.mosque_rounded, 'color': const Color(0xFF06b6d4)},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF10b981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'الأذكار والأدعية',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: azkarItems.length,
            itemBuilder: (context, index) {
              final item = azkarItems[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (item['color'] as Color).withOpacity(0.8),
                      (item['color'] as Color),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // TODO: Navigate to azkar page
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'] as String,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaSection(ThemeConfig theme) {
    final double qiblaAngle = (_qiblaDirection - _compassHeading + 360) % 360;
    
    // تحديد إذا كان السهم يشير للقبلة (ضمن 15 درجة)
    final bool isPointingToQibla = qiblaAngle.abs() < 15 || qiblaAngle.abs() > 345;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPointingToQibla 
                        ? const Color(0xFF059669).withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.explore_rounded,
                    color: isPointingToQibla 
                        ? const Color(0xFF047857)
                        : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'اتجاه القبلة',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // البوصلة الخارجية (ثابتة)
            Stack(
              alignment: Alignment.center,
              children: [
                // الدائرة الخارجية مع العلامات
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.isDarkMode 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // علامة الشمال
                      Positioned(
                        top: 5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'ش',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                            ),
                          ),
                        ),
                      ),
                      // علامة الجنوب
                      Positioned(
                        bottom: 5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'ج',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      // علامة الشرق
                      Positioned(
                        left: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            'ق',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      // علامة الغرب
                      Positioned(
                        right: 5,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            'غ',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // السهم المتحرك
                Transform.rotate(
                  angle: qiblaAngle * (math.pi / 180),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isPointingToQibla
                            ? [
                                const Color(0xFF059669),
                                const Color(0xFF047857),
                                const Color(0xFF065f46),
                              ]
                            : [
                                Colors.grey[400]!,
                                Colors.grey[500]!,
                                Colors.grey[600]!,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isPointingToQibla
                              ? const Color(0xFF059669).withOpacity(0.4)
                              : Colors.grey.withOpacity(0.3),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: isPointingToQibla
                              ? const Color(0xFF10b981).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.navigation_rounded,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // رسالة التوجيه
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isPointingToQibla
                    ? const Color(0xFF059669).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPointingToQibla
                      ? const Color(0xFF059669)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPointingToQibla ? Icons.check_circle_rounded : Icons.explore_rounded,
                    color: isPointingToQibla
                        ? const Color(0xFF059669)
                        : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPointingToQibla ? 'اتجاه القبلة ✓' : 'لف الجهاز للبحث عن القبلة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isPointingToQibla
                          ? const Color(0xFF059669)
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              'المسافة إلى مكة: $_qiblaDistance',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            if (_currentLatitude != null) ...[
              const SizedBox(height: 8),
              Text(
                '${qiblaAngle.toStringAsFixed(1)}°',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: isPointingToQibla
                      ? const Color(0xFF059669)
                      : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasbihSection(ThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF047857),
                    Color(0xFF065f46),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
                child: Container(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'سبحة إلكترونية',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // السبحة الحقيقية
                  SizedBox(
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // الجزء الدوار (الخيط والكور)
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween<double>(
                            begin: 0.0,
                            end: _tasbihCount.toDouble(),
                          ),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: (value * 360 / 33) * (math.pi / 180),
                              child: child,
                            );
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // الخيط (الدائرة)
                              CustomPaint(
                                size: const Size(240, 240),
                                painter: _TasbihStringPainter(),
                              ),
                        
                        // الكور (33 كورة)
                        ...List.generate(33, (index) {
                          final angle = (index * 360 / 33) * (math.pi / 180);
                          final radius = 110.0;
                          final x = radius * math.cos(angle - math.pi / 2);
                          final y = radius * math.sin(angle - math.pi / 2);
                          
                          // تحديد إذا كانت الكورة مضاءة (تم العد لها)
                          final isActive = index < _tasbihCount;
                          // الكورة الحالية (آخر واحدة تم عدها)
                          final isCurrent = index == _tasbihCount - 1;
                          
                          // حجم الكورة
                          final beadSize = isCurrent ? 28.0 : 24.0;
                          
                          return Positioned(
                            left: 120 + x - (beadSize / 2),
                            top: 120 + y - (beadSize / 2),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 400),
                              tween: Tween<double>(
                                begin: 0.0,
                                end: isActive ? 1.0 : 0.0,
                              ),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: isCurrent ? 1.0 + (0.3 * value) : 1.0,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: beadSize,
                                    height: beadSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: isActive 
                                          ? LinearGradient(
                                              colors: [
                                                Colors.amber[200]!,
                                                Colors.amber[400]!,
                                                Colors.orange[600]!,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: isActive 
                                          ? null
                                          : Colors.white.withOpacity(0.25),
                                      border: Border.all(
                                        color: isActive 
                                            ? Colors.amber[100]!
                                            : Colors.white.withOpacity(0.3),
                                        width: isCurrent ? 3 : 2,
                                      ),
                                      boxShadow: isActive ? [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.8),
                                          blurRadius: isCurrent ? 20 : 12,
                                          spreadRadius: isCurrent ? 4 : 2,
                                        ),
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.6),
                                          blurRadius: isCurrent ? 15 : 8,
                                          spreadRadius: isCurrent ? 2 : 1,
                                        ),
                                      ] : [],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: isCurrent ? 12 : 10,
                                        height: isCurrent ? 12 : 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive 
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                            ],
                          ),
                        ),
                        
                        // الكورة الكبيرة في الوسط (العداد) - ثابتة لا تدور
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$_tasbihCount',
                              style: GoogleFonts.cairo(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    _currentTasbih,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // العداد الإجمالي
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.all_inclusive_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'الإجمالي: ',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_totalTasbihCount',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTasbihButton(
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          setState(() {
                            _tasbihCount = 0;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildTasbihButton(
                        icon: Icons.add_rounded,
                        onTap: () {
                          setState(() {
                            _tasbihCount++;
                            _totalTasbihCount++; // زيادة العداد الإجمالي
                            if (_tasbihCount >= 33) {
                              // إعادة تعيين الكور والعداد
                              _tasbihCount = 0;
                              // تغيير التسبيح تلقائياً
                              final currentIndex = _tasbihOptions.indexOf(_currentTasbih);
                              if (currentIndex < _tasbihOptions.length - 1) {
                                _currentTasbih = _tasbihOptions[currentIndex + 1];
                              }
                            }
                          });
                        },
                        size: 80,
                        iconSize: 40,
                      ),
                      const SizedBox(width: 16),
                      _buildTasbihButton(
                        icon: Icons.swap_horiz_rounded,
                        onTap: () {
                          setState(() {
                            final currentIndex = _tasbihOptions.indexOf(_currentTasbih);
                            _currentTasbih = _tasbihOptions[(currentIndex + 1) % _tasbihOptions.length];
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasbihButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 28,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.25),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIslamicAISection(ThemeConfig theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF047857),
                    Color(0xFF065f46),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
                child: Container(),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final wasHidden = !_showIslamicAI;
                  
                  setState(() {
                    _showIslamicAI = !_showIslamicAI;
                  });
                  
                  // Scroll to chat section after opening
                  if (wasHidden) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      final context = _islamicAIChatKey.currentContext;
                      if (context != null) {
                        Scrollable.ensureVisible(
                          context,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    });
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mosque_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ذكاء الدلما الإسلامي',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'مساعدك في التفسير والأحكام الشرعية',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildIslamicAIFeature(
                              icon: Icons.menu_book_rounded,
                              title: 'تفسير القرآن',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildIslamicAIFeature(
                              icon: Icons.gavel_rounded,
                              title: 'الأحكام الشرعية',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildIslamicAIFeature(
                              icon: Icons.verified_rounded,
                              title: 'مصادر موثوقة',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildIslamicAIFeature(
                              icon: Icons.source_rounded,
                              title: 'ذكر المصدر',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ابدأ المحادثة',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
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

  Widget _buildIslamicAIFeature({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicAIChatSection(ThemeConfig theme) {
    return Container(
      key: _islamicAIChatKey,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxHeight: 500),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.isDarkMode 
                  ? const Color(0xFF0f172a) 
                  : const Color(0xFFf9fafb),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.mosque_rounded,
                  color: Color(0xFF059669),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ذكاء الدلما الإسلامي',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _showIslamicAI = false;
                    });
                  },
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _islamicAIMessages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mosque_rounded,
                            size: 64,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'بسم الله الرحمن الرحيم',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اسأل عن التفسير والأحكام الشرعية',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _islamicAIMessages.length + (_isIslamicAITyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _islamicAIMessages.length && _isIslamicAITyping) {
                        return _buildTypingIndicator(theme);
                      }
                      
                      final message = _islamicAIMessages[index];
                      final isUser = message['role'] == 'user';
                      
                      return Align(
                        alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF059669),
                                      Color(0xFF047857),
                                      Color(0xFF065f46),
                                    ],
                                  )
                                : null,
                            color: isUser
                                ? null
                                : (theme.isDarkMode 
                                    ? const Color(0xFF2d3748) 
                                    : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isUser ? 20 : 4),
                              topRight: Radius.circular(isUser ? 4 : 20),
                              bottomLeft: const Radius.circular(20),
                              bottomRight: const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            message['content'],
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: isUser 
                                  ? Colors.white 
                                  : (theme.isDarkMode ? Colors.white : const Color(0xFF1e293b)),
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.isDarkMode 
                  ? const Color(0xFF0f172a) 
                  : const Color(0xFFf9fafb),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _islamicAIController,
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك...',
                      hintStyle: GoogleFonts.cairo(
                        color: theme.isDarkMode ? Colors.white38 : Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: theme.isDarkMode 
                          ? const Color(0xFF1e293b) 
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.cairo(
                      color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _sendIslamicAIMessage(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF059669),
                        Color(0xFF047857),
                        Color(0xFF065f46),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_islamicAIController.text.trim().isNotEmpty) {
                        _sendIslamicAIMessage(_islamicAIController.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeConfig theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.isDarkMode ? const Color(0xFF2d3748) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'جاري الكتابة',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.isDarkMode ? Colors.white70 : Colors.grey[600]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // قسم القرآن الكريم
  Widget _buildQuranSection(ThemeConfig theme) {
    if (_selectedSurah == null) {
      // عرض زر القرآن
      return Container(
        key: _quranSectionKey,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.4),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: const Color(0xFF10b981).withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF047857),
                      Color(0xFF065f46),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CustomPaint(
                  painter: _IslamicPatternPainter(),
                  child: Container(),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showSurahPicker(theme);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'القرآن الكريم',
                              style: GoogleFonts.amiriQuran(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'اقرأ وتدبر كلام الله',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'اختر سورة للقراءة',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
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
    } else {
      // عرض السورة المختارة بتصميم الكتاب
      return _buildQuranReader(theme, _selectedSurah!);
    }
  }

  // عارض القرآن بتصميم الكتاب
  Widget _buildQuranReader(ThemeConfig theme, int surahNumber) {
    final surahName = quran.getSurahNameArabic(surahNumber);
    final versesCount = quran.getVerseCount(surahNumber);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // تقسيم الآيات إلى صفحات بناءً على عدد الأحرف (أدق من تقدير الأسطر)
    List<String> pages = [];
    String currentPage = '';
    
    // إضافة البسملة في الصفحة الأولى (ما عدا التوبة والفاتحة)
    if (surahNumber != 1 && surahNumber != 9) {
      currentPage = '${quran.basmala}\n\n';
    }
    
    // حد أقصى للأحرف في كل صفحة (تقريباً 13 سطر × 40 حرف = 520 حرف)
    const int maxCharsPerPage = 520;
    
    for (int i = 1; i <= versesCount; i++) {
      final verseText = quran.getVerse(surahNumber, i);
      final verseWithNumber = '$verseText ﴿$i﴾ ';
      
      // إذا إضافة الآية ستتجاوز الحد، ابدأ صفحة جديدة
      if (currentPage.length + verseWithNumber.length > maxCharsPerPage && currentPage.isNotEmpty) {
        pages.add(currentPage.trim());
        currentPage = verseWithNumber;
      } else {
        currentPage += verseWithNumber;
      }
    }
    
    // إضافة آخر صفحة
    if (currentPage.isNotEmpty) {
      pages.add(currentPage.trim());
    }
    
    // إعادة تهيئة PageController عند تغيير السورة
    if (_currentQuranPage >= pages.length) {
      _currentQuranPage = 0;
      _quranPageController = PageController(initialPage: 0);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1e293b) : const Color(0xFFf5f3e8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header السورة
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF059669),
                  Color(0xFF047857),
                  Color(0xFF065f46),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedSurah = null;
                      _currentQuranPage = 0;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    surahName,
                    style: GoogleFonts.amiriQuran(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.list_rounded, color: Colors.white),
                  onPressed: () {
                    _showSurahPicker(theme);
                  },
                ),
              ],
            ),
          ),
          
          // الصفحات (PageView)
          SizedBox(
            height: 350, // ارتفاع ثابت بدون فراغ
            child: PageView.builder(
              controller: _quranPageController,
              reverse: true, // للتمرير من اليمين لليسار (عربي)
              onPageChanged: (index) {
                setState(() {
                  _currentQuranPage = index;
                });
              },
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  alignment: Alignment.topRight,
                  child: Text(
                    pages[index],
                    style: GoogleFonts.amiriQuran(
                      fontSize: 18,
                      height: 1.8,
                      color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.justify,
                    maxLines: 13, // حد أقصى 13 سطر!
                    overflow: TextOverflow.clip, // قطع النص الزائد
                  ),
                );
              },
            ),
          ),
          
          // مؤشر رقم الصفحة
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // زر الصفحة السابقة
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  onPressed: _currentQuranPage < pages.length - 1
                      ? () {
                          _quranPageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
                
                const SizedBox(width: 16),
                
                // رقم الصفحة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_currentQuranPage + 1} / ${pages.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // زر الصفحة التالية
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: _currentQuranPage > 0
                      ? () {
                          _quranPageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // عرض قائمة السور
  void _showSurahPicker(ThemeConfig theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFf9fafb),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF059669)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'اختر سورة',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // قائمة السور
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 114,
                itemBuilder: (context, index) {
                  final surahNumber = index + 1;
                  final surahName = quran.getSurahNameArabic(surahNumber);
                  final versesCount = quran.getVerseCount(surahNumber);
                  final revelationType = quran.getPlaceOfRevelation(surahNumber);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFf9fafb),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSurah = surahNumber;
                          });
                          Navigator.pop(context);
                          
                          // Scroll to Quran section
                          Future.delayed(const Duration(milliseconds: 300), () {
                            final context = _quranSectionKey.currentContext;
                            if (context != null) {
                              Scrollable.ensureVisible(
                                context,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF059669), Color(0xFF047857)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '$surahNumber',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      surahName,
                                      style: GoogleFonts.amiriQuran(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.isDarkMode ? Colors.white : const Color(0xFF1e293b),
                                      ),
                                    ),
                                    Text(
                                      '$revelationType • $versesCount آية',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: theme.isDarkMode ? Colors.white70 : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: theme.isDarkMode ? Colors.white38 : Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 40.0;
    
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, paint, Offset(x, y), 8);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    const points = 8;
    
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points;
      final r = i.isEven ? radius : radius / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      
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

// رسام خيط السبحة
class _TasbihStringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = 110.0;

    // رسم الدائرة (الخيط)
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
