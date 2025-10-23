import 'dart:async';
import 'theme_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PrayerPage extends StatefulWidget {
  @override
  _PrayerPageState createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> with TickerProviderStateMixin {
  Map<String, dynamic>? prayerData;
  bool loading = true;
  String? error;
  Map<String, dynamic>? nextPrayer;
  DateTime currentTime = DateTime.now();
  int currentAzkarIndex = 0;
  String religiousQuestion = "";
  String religiousAnswer = "";
  bool askingQuestion = false;
  late AnimationController _refreshController;
  late Timer _timeTimer;
  late Timer _azkarTimer;

  final List<String> placeholders = [
    "ما حكم من نسي صلاة العصر؟",
    "متى يجوز التيمم؟",
    "هل يجوز جمع المغرب والعشاء؟",
    "ما حكم الصلاة في البيت للرجل؟",
    "كيف أتوضأ الوضوء الصحيح؟",
    "ما هي أركان الصلاة؟"
  ];

  final List<Map<String, String>> authenticAzkar = [
    {
      "text": "اللهم أعني على ذكرك وشكرك وحسن عبادتك",
      "source": "دعاء علمه النبي ﷺ لمعاذ بن جبل - صحيح أبي داود"
    },
    {
      "text": "سبحان الله والحمد لله ولا إله إلا الله والله أكبر",
      "source": "أحب الكلام إلى الله - صحيح مسلم"
    },
    {
      "text": "أستغفر الله العظيم الذي لا إله إلا هو الحي القيوم وأتوب إليه",
      "source": "سيد الاستغفار - صحيح البخاري"
    },
    {
      "text": "اللهم أعوذ بك من الهم والحزن، وأعوذ بك من العجز والكسل",
      "source": "دعاء الهم والحزن - صحيح البخاري"
    },
    {
      "text": "رضيت بالله رباً وبالإسلام ديناً وبمحمد ﷺ رسولاً",
      "source": "من قال ذلك ثلاثاً وجبت له الجنة - صحيح أبي داود"
    }
  ];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    fetchPrayerTimes();
    
    // تحديث الوقت كل ثانية للعد التنازلي الدقيق
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
        if (prayerData != null) calculateNextPrayer();
      });
    });
    
    // تغيير الأذكار كل 10 ثوانِ
    _azkarTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        currentAzkarIndex = (currentAzkarIndex + 1) % authenticAzkar.length;
      });
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _timeTimer.cancel();
    _azkarTimer.cancel();
    super.dispose();
  }

  Future<void> fetchPrayerTimes() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      // استخدام API عام لأوقات الصلاة في عرعر
      final response = await http.get(
        Uri.parse('http://api.aladhan.com/v1/timingsByCity?city=Arar&country=Saudi%20Arabia&method=4'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          prayerData = data['data'];
          loading = false;
        });
        calculateNextPrayer();
      } else {
        throw Exception('Failed to load prayer times');
      }
    } catch (e) {
      setState(() {
        error = 'فشل في تحميل أوقات الصلاة';
        loading = false;
      });
    }
  }

  void calculateNextPrayer() {
    if (prayerData == null) return;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final prayers = [
      {'name': 'الفجر', 'time': prayerData!['timings']['Fajr'], 'key': 'Fajr'},
      {'name': 'الظهر', 'time': prayerData!['timings']['Dhuhr'], 'key': 'Dhuhr'},
      {'name': 'العصر', 'time': prayerData!['timings']['Asr'], 'key': 'Asr'},
      {'name': 'المغرب', 'time': prayerData!['timings']['Maghrib'], 'key': 'Maghrib'},
      {'name': 'العشاء', 'time': prayerData!['timings']['Isha'], 'key': 'Isha'}
    ];

    Map<String, dynamic>? nextPrayerInfo;

    for (final prayer in prayers) {
      final timeParts = prayer['time'].toString().split(':');
      final hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      final prayerMinutes = hours * 60 + minutes;

      if (prayerMinutes > currentMinutes) {
        final totalSecondsLeft = (prayerMinutes - currentMinutes) * 60 - currentTime.second;
        final hoursLeft = totalSecondsLeft ~/ 3600;
        final minutesLeft = (totalSecondsLeft % 3600) ~/ 60;
        final secondsLeft = totalSecondsLeft % 60;

        String countdown = '';
        if (hoursLeft > 0) {
          countdown = '$hoursLeft ساعة و $minutesLeft دقيقة و $secondsLeft ثانية';
        } else if (minutesLeft > 0) {
          countdown = '$minutesLeft دقيقة و $secondsLeft ثانية';
        } else {
          countdown = '$secondsLeft ثانية';
        }

        nextPrayerInfo = {
          'name': prayer['name'],
          'time': prayer['time'],
          'countdown': countdown,
          'isNear': totalSecondsLeft <= 600, // 10 دقائق = 600 ثانية
          'progress': ((86400 - totalSecondsLeft) / 86400 * 100).clamp(0, 100),
        };
        break;
      }
    }

    // إذا لم نجد صلاة اليوم، الصلاة القادمة هي فجر الغد
    if (nextPrayerInfo == null) {
      final fajrTomorrow = prayers[0];
      final timeParts = fajrTomorrow['time'].toString().split(':');
      final hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      final fajrMinutes = hours * 60 + minutes;
      final diff = (24 * 60) - currentMinutes + fajrMinutes;
      final hoursLeft = diff ~/ 60;
      final minutesLeft = diff % 60;

      nextPrayerInfo = {
        'name': 'الفجر (غداً)',
        'time': fajrTomorrow['time'],
        'countdown': '$hoursLeft ساعة و $minutesLeft دقيقة',
        'isNear': false,
        'progress': 95.0,
      };
    }

    setState(() {
      nextPrayer = nextPrayerInfo;
    });
  }

  String getPrayerIcon(String prayerKey) {
    switch (prayerKey) {
      case 'Fajr': return '🌄';
      case 'Sunrise': return '🌅';
      case 'Dhuhr': return '☀️';
      case 'Asr': return '🌞';
      case 'Maghrib': return '🌇';
      case 'Isha': return '🌙';
      default: return '🕌';
    }
  }

  Future<void> handleReligiousQuestion() async {
    if (religiousQuestion.trim().isEmpty) return;

    setState(() {
      askingQuestion = true;
      religiousAnswer = "";
    });

    // محاكاة استدعاء API - يمكن استبداله بـ API حقيقي
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      religiousAnswer = "هذا مثال على إجابة من مصادر موثقة. في التطبيق الحقيقي، ستتم الإجابة من خلال API متخصص في الفتاوى الشرعية الموثقة.";
      askingQuestion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNear = nextPrayer?['isNear'] == true;

    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9ED),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل أوقات الصلاة...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'من مدينة عرعر المباركة',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9ED),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'خطأ في التحميل',
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.red.shade700),
              ),
              const SizedBox(height: 8),
              Text(error!, style: TextStyle(color: Colors.red.shade600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchPrayerTimes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9ED),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            elevation: 0,
            pinned: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFEF3E2), Color(0xFFECFDF5), Color(0xFFFEF3E2)],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              children: [
                Text(
                  '🕌 الدلما تزكّي وقتك',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'مواقيت الصلاة وذكر الله',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: AnimatedBuilder(
                  animation: _refreshController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _refreshController.value * 2 * 3.14159,
                      child: Icon(
                        Icons.refresh,
                        color: Colors.grey.shade700,
                      ),
                    );
                  },
                ),
                onPressed: () async {
                  _refreshController.forward(from: 0);
                  await fetchPrayerTimes();
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // التاريخ الهجري والميلادي
                  if (prayerData != null) _DateCard(),
                  const SizedBox(height: 16),

                  // الصلاة القادمة
                  if (nextPrayer != null) _NextPrayerCard(),
                  const SizedBox(height: 16),

                  // مواقيت الصلاة
                  if (prayerData != null) _PrayerTimesCard(),
                  const SizedBox(height: 16),

                  // التبديل بين الأذكار والذكاء الديني
                  _TabsSection(),
                  const SizedBox(height: 16),

                  // رسالة دلما
                  _DalmaMessageCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2, // الرئيسية مختارة
        onDestinationSelected: (i) {
          if (i == 2) {
            Navigator.pop(context); // العودة للرئيسية
          }
          // يمكن إضافة منطق للتنقل لصفحات أخرى
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'التزودات'),
          NavigationDestination(icon: Icon(Icons.widgets_outlined), label: 'خدمات'),
        ],
      ),
    );
  }

  Widget _DateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.green.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                'التاريخ الهجري',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                prayerData!['date']['hijri']['weekday']['ar'] ?? '',
                style: TextStyle(color: Colors.green.shade700),
              ),
              Text(
                '${prayerData!['date']['hijri']['day']} ${prayerData!['date']['hijri']['month']['ar']} ${prayerData!['date']['hijri']['year']}',
                style: TextStyle(color: Colors.green.shade600),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'التاريخ الميلادي',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                _getArabicWeekday(currentTime.weekday),
                style: TextStyle(color: Colors.green.shade700),
              ),
              Text(
                prayerData!['date']['readable'] ?? '',
                style: TextStyle(color: Colors.green.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _NextPrayerCard() {
    final isNear = nextPrayer!['isNear'] as bool;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNear 
            ? [Colors.red.shade50, Colors.red.shade100]
            : [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNear ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Column(
        children: [
          Text(
            '⏰ الصلاة القادمة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isNear ? Colors.red.shade800 : Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nextPrayer!['name'],
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isNear ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
          Text(
            'الوقت: ${nextPrayer!['time']}',
            style: TextStyle(
              fontSize: 16,
              color: isNear ? Colors.red.shade600 : Colors.green.shade600,
            ),
          ),
          Text(
            'متبقي: ${nextPrayer!['countdown']}',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isNear ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
          if (isNear) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '✨ لا تنسَ الوضوء وأذكار الصلاة',
                style: GoogleFonts.cairo(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _PrayerTimesCard() {
    final prayers = [
      {'key': 'Fajr', 'name': 'الفجر', 'time': prayerData!['timings']['Fajr']},
      {'key': 'Sunrise', 'name': 'الشروق', 'time': prayerData!['timings']['Sunrise']},
      {'key': 'Dhuhr', 'name': 'الظهر', 'time': prayerData!['timings']['Dhuhr']},
      {'key': 'Asr', 'name': 'العصر', 'time': prayerData!['timings']['Asr']},
      {'key': 'Maghrib', 'name': 'المغرب', 'time': prayerData!['timings']['Maghrib']},
      {'key': 'Isha', 'name': 'العشاء', 'time': prayerData!['timings']['Isha']},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'مواقيت الصلاة - عرعر',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...prayers.map((prayer) {
            final isNext = nextPrayer?['name'] == prayer['name'];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isNext ? Colors.green.shade100 : Colors.transparent,
                border: isNext ? Border.all(color: Colors.green.shade400, width: 2) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        getPrayerIcon(prayer['key']!),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        prayer['name']!,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    prayer['time']!,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _TabsSection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('📿 أذكار موثقة'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('🧠 اسأل الدلما'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _AzkarTab(),
                _AskDalmaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _AzkarTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'أذكار موثقة من السنة النبوية',
                  style: GoogleFonts.cairo(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.amber),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          authenticAzkar[currentAzkarIndex]['text']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.amber.shade300),
                            ),
                          ),
                          child: Text(
                            '📚 ${authenticAzkar[currentAzkarIndex]['source']}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
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

  Widget _AskDalmaTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology_outlined, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '🧠 ذكاء الدلما الديني',
                      style: GoogleFonts.cairo(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'مساعد ذكي يجيب من مصادر موثقة سعودية فقط',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      '💡 أمثلة على الأسئلة: "ما حكم الجمع بين الصلوات؟" أو "متى يجوز التيمم؟"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => religiousQuestion = value),
                          decoration: InputDecoration(
                            hintText: placeholders[currentAzkarIndex % placeholders.length],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade400),
                            ),
                          ),
                          onSubmitted: (_) => handleReligiousQuestion(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: askingQuestion || religiousQuestion.trim().isEmpty 
                          ? null 
                          : handleReligiousQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        child: askingQuestion
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      ),
                    ],
                  ),
                  if (religiousAnswer.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('🕌', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'فتوى موثقة',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                religiousAnswer,
                                style: GoogleFonts.cairo(
                                  color: Colors.blue.shade900,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _DalmaMessageCard() {
    final isNear = nextPrayer?['isNear'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.pink.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'رسالة من الدلما',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isNear
              ? "🌟 حان وقت التقرب إلى الله، استعد للصلاة وتذكر أن الصلاة نور يضيء دربك"
              : "🌸 بارك الله في وقتك، استغل هذه اللحظات في الذكر والدعاء والاستغفار",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.purple.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _getArabicWeekday(int weekday) {
    const weekdays = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
    ];
    return weekdays[weekday - 1];
  }
}
