import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'prayer_page.dart';
import 'desert_transition.dart';
import 'ask_dalma_dialog.dart';
import 'orders_page.dart';
import 'trends_page.dart';
import 'services_page.dart';
import 'auth.dart';
import 'login_page.dart';
import 'notifications.dart';
import 'orders_service.dart';
import 'my_account_page.dart';
import 'my_account_oasis.dart';
import 'media_dashboard.dart';
import 'ai_tools_page.dart';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'theme_aware_widgets.dart';
import 'widget_inspector.dart';
import 'app_config.dart';
import 'notifications_service.dart' as fcm;

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load persisted auth before app builds UI
  await AuthState.instance.loadFromDisk();
  await OrdersService.instance.loadFromDisk();
  
  // Load app config from API
  await AppConfig.instance.loadSettings();
  
  // Initialize Firebase FCM
  try {
    await fcm.NotificationsService.initialize();
    print('✅ [FCM] Initialized successfully');
  } catch (e) {
    print('❌ [FCM] Initialization failed: $e');
  }
  
  try {
    // تحميل الطلبات المخزنة
    // ignore: avoid_print
    print('Loading OrdersService...');
    // Lazy import via reflection avoided; direct import expected in file
  } catch (_) {}
  
  await NotificationsService.instance.attachNavigatorKey(_navKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AuthState.instance),
        ChangeNotifierProvider.value(value: ThemeConfig.instance),
      ],
      child: Consumer<ThemeConfig>(
        builder: (context, themeConfig, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'الدلما',
            navigatorKey: _navKey,
            locale: const Locale('ar'),
            theme: themeConfig.themeData,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            routes: {
              '/login': (context) => const LoginPage(),
            },
            home: const MyHomePage(title: 'الدلما'),
            builder: (context, child) {
              return Directionality(textDirection: TextDirection.rtl, child: child!);
            },
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 2; // home tab

  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات الثيم للتتبع التلقائي
    ThemeConfig.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeConfig.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    // عند التبديل للوضع الليلي، سيتم تتبع الألوان تلقائياً
    if (ThemeConfig.instance.isDarkMode) {
      print('🔍 [THEME TRACKER] بدء تتبع الألوان في الوضع الليلي...');
    }
  }

  @override
  Widget build(BuildContext context) {
    // استمع لتغييرات AuthState في جميع الصفحات
    return Consumer<AuthState>(
      builder: (context, authState, child) {
        Widget getCurrentPage() {
          print('🔄 [MAIN] getCurrentPage - Index: $_currentIndex, isLoggedIn: ${authState.isLoggedIn}, role: ${authState.userRole}');
          switch (_currentIndex) {
            case 0:
              // ✅ دائماً عرض صفحة المستخدم العادي (يحتوي على زر للانتقال لـ Media Dashboard)
              print('📱 [MAIN] عرض صفحة DalmaMyAccountOasis');
              return const DalmaMyAccountOasis();
            case 1:
              return OrdersPage(showAppBar: false);
            case 2:
              return _HomeScreen(
                onNavigate: (index) {
                  setState(() => _currentIndex = index);
                },
              );
            case 3:
              return TrendsPage();
            case 4:
              return ServicesPage(showAppBar: false);
            default:
              return _HomeScreen(
                onNavigate: (index) {
                  setState(() => _currentIndex = index);
                },
              );
          }
        }

        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          autofocus: true,
          onKeyEvent: (event) {
            DalmaWidgetInspector.instance.handleKeyEvent(event);
          },
          child: InspectorOverlay(
            child: Scaffold(
              body: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: getCurrentPage(),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) {
                  setState(() => _currentIndex = i);
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
                  NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'طلباتي'),
                  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
                  NavigationDestination(icon: Icon(Icons.trending_up), label: 'التزودات'),
                  NavigationDestination(icon: Icon(Icons.widgets_outlined), label: 'خدمات'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;
  
  const _HomeScreen({required this.onNavigate});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HeroHeader()),
        SliverToBoxAdapter(
          child: Container(
            transform: Matrix4.translationValues(0, -16, 0),
            child: Column(
              children: [
                // Search field with backdrop blur
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SearchField(),
                ),
                const SizedBox(height: 16),
                // زر اسأل الدلما
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _AskDalmaButton(),
                ),
                const SizedBox(height: 16),
                // زر أدوات الذكاء الاصطناعي
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _AIToolsButton(),
                ),
                const SizedBox(height: 24),
                // Content with proper spacing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _QuickGrid(
                        onNavigate: onNavigate,
                      ),
                      const SizedBox(height: 32),
                      _PartnersSection(),
                      const SizedBox(height: 32),
                      _OffersSection(),
                      const SizedBox(height: 32),
                      _ServicesSection(),
                      const SizedBox(height: 32),
                      _MapSection(),
                      const SizedBox(height: 32),
                _FeaturedSection(),
                const SizedBox(height: 32),
                _Footer(),
                const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final themeConfig = ThemeConfig.instance;
        final glowColor = themeConfig.primaryColor;
        
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          decoration: BoxDecoration(
            gradient: themeConfig.headerGradient,
          ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // Top row with login button and icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _LoginButton(),
                    Row(
                      children: const [
                        _ThemeToggleButton(),
                        SizedBox(width: 8),
                        NotificationsBell(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Logo with glow effect
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft radial glow exactly like in the image
                      Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              glowColor.withOpacity(0.25),
                              glowColor.withOpacity(0.15),
                              glowColor.withOpacity(0.08),
                              glowColor.withOpacity(0.03),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Logo
                      Image.asset('assets/img/aldlma.png', width: 176, height: 176),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Dynamic greeting
                AnimatedBuilder(
                  animation: AuthState.instance,
                  builder: (context, _) {
                    final logged = AuthState.instance.isLoggedIn;
                    final name = AuthState.instance.userName ?? '';
                    if (!logged) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'الله حيّه ${name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    );
                  },
                ),
                // Title - exactly as in reference
                Text(
                  'الدلما... زرعها طيب، وخيرها باقٍ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'الدلما منصة مجتمعية تقنية تربطك بخدمات مدينتك، من أهل عرعر إلى أهلها، نوصلك بالأفضل… بضغطة زر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

class _SoftHeadline extends StatelessWidget {
  final String text;
  const _SoftHeadline(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0F172A).withOpacity(0.08),
        height: 1.1,
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final Color color;
  const _Ring({required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final LinearGradient gradient;
  final double fontSize;
  final FontWeight fontWeight;
  const _GradientText(this.text, {required this.gradient, this.fontSize = 28, this.fontWeight = FontWeight.w700});
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: fontWeight)),
    );
  }
}

// 🌙 زر تبديل الوضع الليلي/النهاري
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, child) {
        final themeConfig = ThemeConfig.instance;
        final isDark = themeConfig.isDarkMode;
        
        return InkWell(
          onTap: () {
            themeConfig.toggleTheme();
            NotificationsService.instance.toast(
              isDark ? 'تم التبديل للوضع النهاري' : 'تم التبديل للوضع الليلي',
              icon: isDark ? Icons.wb_sunny : Icons.nightlight_round,
              color: themeConfig.primaryColor,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? ThemeConfig.kNightAccent : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: themeConfig.cardShadow,
            ),
            child: Center(
              child: Icon(
                isDark ? Icons.wb_sunny : Icons.nightlight_round,
                color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});
  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.instance;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: themeConfig.isDarkMode ? ThemeConfig.kNightAccent : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: themeConfig.cardShadow,
      ),
      child: Center(
        child: Icon(
          icon, 
          color: const Color(0xFF6B7280), 
          size: 20,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final String? count;
  final Color badgeColor;
  const _IconBadge({required this.icon, this.count, this.badgeColor = Colors.red});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              icon, 
              color: const Color(0xFF6B7280), 
              size: 20,
            ),
          ),
          if (count != null)
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    count!, 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthState.instance,
      builder: (context, child) {
        final isLoggedIn = AuthState.instance.isLoggedIn;
        return InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          onTap: () async {
            if (isLoggedIn) {
              await AuthState.instance.logout();
              NotificationsService.instance.toast('تم تسجيل الخروج', icon: Icons.logout, color: const Color(0xFFEF4444));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            }
          },
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFF059669)]),
              borderRadius: BorderRadius.all(Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isLoggedIn ? Icons.logout : Icons.person_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  Future<void> _launchKarmarWebsite() async {
    final Uri url = Uri.parse('https://karmar-sa.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : const Color(0xFFFCF5E4),
        border: Border(top: BorderSide(color: theme.textSecondaryColor.withOpacity(0.2))),
      ),
      child: GestureDetector(
        onTap: _launchKarmarWebsite,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Karmar logo
            Image.asset(
              'assets/img/logo_karmar.png',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'حقوق الطبع محفوظة لشركة كارمار',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: theme.textSecondaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(color: theme.textSecondaryColor.withOpacity(0.5)),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  'صُنع بـ',
                  style: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.favorite,
                  size: 14,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ]),
          ),
        ),
        _Footer(),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AskDalmaButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(context: context, builder: (_) => const AskDalmaDialog());
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology_outlined, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                const Text('اسأل الدلما', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AIToolsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final themeConfig = ThemeConfig.instance;
        final primaryColor = themeConfig.primaryColor;
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade600,
                Colors.deepPurple.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIToolsPage()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      'أدوات الدلما',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final theme = ThemeConfig.instance;
        final isDark = theme.isDarkMode;
        
        return Container(
          decoration: BoxDecoration(
            color: isDark ? ThemeConfig.kNightSoft : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: theme.cardShadow,
          ),
      child: TextField(
        style: TextStyle(color: theme.textPrimaryColor),
        decoration: InputDecoration(
          hintText: 'ابحث عن الخدمات والمحلات...',
          hintStyle: TextStyle(color: theme.textSecondaryColor),
          suffixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
        );
      },
    );
  }
}

class _QuickGrid extends StatelessWidget {
  final Function(int) onNavigate;
  
  const _QuickGrid({required this.onNavigate});
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final theme = ThemeConfig.instance;
        final isDark = theme.isDarkMode;
        
        final items = [
      ('تصفح الخدمات', '🛍️'),
      ('خريطة عرعر', Icons.map_outlined),
      ('مزاد/حراج', '🏷️'),
      ('الوظائف', '💼'),
      ('محفوظاتي', '⭐'),
      ('الصلاة', '🕌'),
      ('التذكيرات', Icons.calendar_today),
      ('الترندات', '🔥'),
      ('طلباتي', '📋'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSpecial = item.$1 == 'محفوظاتي';
          return Container(
            decoration: BoxDecoration(
              color: isDark ? ThemeConfig.kNightSoft : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isSpecial ? Border.all(color: isDark ? ThemeConfig.kGoldNight : Colors.yellow.shade200) : null,
              boxShadow: theme.cardShadow,
            ),
          child: InkWell(
            onTap: () {
              if (item.$1 == 'الصلاة') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => PrayerPage(),
                    transitionDuration: const Duration(milliseconds: 800),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return DesertWindTransition(
                        animation: animation,
                        child: child,
                      );
                    },
                  ),
                );
              } else if (item.$1 == 'طلباتي') {
          // الانتقال لصفحة الطلبات في الشريط السفلي
          onNavigate(1); // Orders page index
        } else if (item.$1 == 'الترندات') {
          // الانتقال لصفحة الترندات في الشريط السفلي
          onNavigate(3); // Trends page index
        } else if (item.$1 == 'تصفح الخدمات') {
          // الانتقال لصفحة الخدمات في الشريط السفلي
          onNavigate(4); // Services page index
        }
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Special handling for image buttons
                if (item.$1 == 'تصفح الخدمات')
                  Image.asset(
                    'assets/img/al5dmat.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'خريطة عرعر')
                  Image.asset(
                    'assets/img/arar.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'مزاد/حراج')
                  Image.asset(
                    'assets/img/mzad.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'الوظائف')
                  Image.asset(
                    'assets/img/alw4aef.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'محفوظاتي')
                  Image.asset(
                    'assets/img/m7fowat.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'الصلاة')
                  Image.asset(
                    'assets/img/al9lah.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'التذكيرات')
                  Image.asset(
                    'assets/img/alt2kerat.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'الترندات')
                  Image.asset(
                    'assets/img/altrndat.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else if (item.$1 == 'طلباتي')
                  Image.asset(
                    'assets/img/lbaty.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSpecial 
                        ? (isDark ? ThemeConfig.kGoldNight.withOpacity(0.2) : Colors.yellow.shade100) 
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: item.$2 is String 
                        ? Text(item.$2 as String, style: TextStyle(fontSize: 20, color: theme.textPrimaryColor))
                        : Icon(item.$2 as IconData, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  item.$1,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.textPrimaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
               Text(
                  _getSubtitle(item.$1),
                  style: TextStyle(fontSize: 10, color: theme.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          );
      },
        );
      },
    );
  }
  
  String _getSubtitle(String title) {
    switch (title) {
      case 'تصفح الخدمات': return 'اكتشف جميع الخدمات المتاحة';
      case 'خريطة عرعر': return 'اكتشف الأماكن في المدينة';
      case 'مزاد/حراج': return 'تصفح المزادات المتاحة';
      case 'الوظائف': return 'ابحث عن فرص عمل';
      case 'محفوظاتي': return 'أماكنك المحفوظة';
      case 'الصلاة': return 'أوقات الصلاة والأذكار';
      case 'التذكيرات': return 'إدارة المواعيد والتذكيرات';
      case 'الترندات': return 'الخدمات الأكثر طلباً';
      case 'طلباتي': return 'تتبع جميع طلباتك';
      default: return '';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        Text('عرض المزيد', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: const [
          Icon(Icons.restaurant_menu, size: 28),
          SizedBox(width: 12),
          Expanded(child: Text('عروض خاصة للمطاعم - خصم %30 على جميع الوجبات')),
          Icon(Icons.chevron_left),
        ],
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final List<String> items;
  const _ChipsRow({required this.items});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map_outlined),
              label: const Text('الخريطة التفاعلية'),
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            );
          }
          return FilterChip(label: Text(items[i - 1]), onSelected: (_) {});
        },
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.cardShadow,
      ),
      child: Center(child: Icon(Icons.location_pin, size: 36, color: theme.textSecondaryColor)),
    );
  }
}

class _PartnersSection extends StatefulWidget {
  @override
  _PartnersSectionState createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<_PartnersSection> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<dynamic> partners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
  }
  
  Future<void> _loadPartners() async {
    try {
      print('🤝 [PARTNERS] Loading from API...');
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/partners'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          partners = data;
          _loading = false;
          if (partners.isNotEmpty) {
            _animation = Tween<double>(begin: 0, end: -partners.length.toDouble()).animate(
              CurvedAnimation(parent: _controller, curve: Curves.linear),
            );
            _controller.repeat();
          }
        });
        print('✅ [PARTNERS] Loaded ${partners.length} partners');
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ [PARTNERS] Error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (partners.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Text('شركاؤنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
        const SizedBox(height: 16),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? ThemeConfig.kNightSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: theme.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: OverflowBox(
              maxWidth: double.infinity,
              child: AnimatedBuilder(
                animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_animation.value * 280, 0),
                  child: Row(
                    children: [
                      ...partners.map((partner) => _buildPartnerItem(partner)),
                      ...partners.map((partner) => _buildPartnerItem(partner)), // Seamless duplicate
                    ],
                  ),
                );
              },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerItem(dynamic partner) {
    return GestureDetector(
      onTap: () async {
        if (partner['website_url'] != null && partner['website_url'].toString().isNotEmpty) {
          try {
            final url = Uri.parse(partner['website_url']);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            print('❌ Error launching URL: $e');
          }
        }
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: partner['logo_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        partner['logo_url'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.business, size: 24);
                        },
                      ),
                    )
                  : const Icon(Icons.business, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                partner['name'] ?? 'شريك', 
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffersSection extends StatefulWidget {
  @override
  _OffersSectionState createState() => _OffersSectionState();
}

class _OffersSectionState extends State<_OffersSection> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> offers = [
    {'emoji': '🍽️', 'title': 'عروض خاصة للمطاعم', 'subtitle': 'خصم 30% على جميع الوجبات', 'color': Colors.orange.shade100},
    {'emoji': '🧽', 'title': 'خدمات التنظيف', 'subtitle': 'احجز الآن واحصل على خصم 20%', 'color': Colors.blue.shade100},
    {'emoji': '❄️', 'title': 'صيانة مكيفات', 'subtitle': 'صيانة شاملة بأفضل الأسعار', 'color': Colors.cyan.shade100},
    {'emoji': '🚗', 'title': 'صيانة السيارات', 'subtitle': 'خدمة سريعة وجودة عالية', 'color': Colors.green.shade100},
    {'emoji': '🏠', 'title': 'تنظيف المنازل', 'subtitle': 'فريق محترف ومعدات حديثة', 'color': Colors.purple.shade100},
    {'emoji': '📱', 'title': 'إصلاح الهواتف', 'subtitle': 'إصلاح سريع وضمان شامل', 'color': Colors.pink.shade100},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < offers.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('العروض والإعلانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('عرض الكل', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _BannerCard(
                  offer['emoji'],
                  offer['title'],
                  offer['subtitle'],
                  offer['color'],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: offers.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _BannerCard(this.emoji, this.title, this.subtitle, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: ThemeConfig.instance.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.9),
                color,
                color.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
              // Large centered emoji as the main image
              Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep the old _OfferCard for other uses if needed
class _OfferCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _OfferCard(this.emoji, this.title, this.subtitle, this.color);
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.textPrimaryColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: theme.textSecondaryColor),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('الخدمات الرئيسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('عرض المزيد', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ServiceCard('🍽️', 'مطاعم', '12+'),
              const SizedBox(width: 12),
              _ServiceCard('🔧', 'صيانة', '8+'),
              const SizedBox(width: 12),
              _ServiceCard('🧽', 'تنظيف', '15+'),
              const SizedBox(width: 12),
              _ServiceCard('💄', 'تجميل', '6+'),
              const SizedBox(width: 12),
              _ServiceCard('🚚', 'نقل', '10+'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String count;
  const _ServiceCard(this.emoji, this.title, this.count);
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.textPrimaryColor)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(count, style: TextStyle(fontSize: 10, color: theme.textSecondaryColor)),
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('أماكن في عرعر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('الخريطة التفاعلية', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: theme.cardShadow,
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: theme.isDarkMode ? [ThemeConfig.kNightAccent, ThemeConfig.kNightSoft] : [Colors.green.shade100, Colors.blue.shade100]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('📍', style: TextStyle(fontSize: 24)),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (theme.isDarkMode ? ThemeConfig.kNightSoft : Colors.white).withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('مستشفى عرعر العام', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_pin, size: 12, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('1.2 كم', style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('توجيه', style: TextStyle(fontSize: 12, color: theme.textPrimaryColor)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('المميزون', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
            Text('عرض المزيد', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 16),
        _FeaturedCard('مطعم الدلما التراثي', 'مطاعم', '🍽️', 4.8, '2.1 كم'),
        const SizedBox(height: 12),
        _FeaturedCard('ورشة الماهر للصيانة', 'صيانة', '🔧', 4.9, '2.1 كم'),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final String title;
  final String category;
  final String emoji;
  final double rating;
  final String distance;
  const _FeaturedCard(this.title, this.category, this.emoji, this.rating, this.distance);
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(category, style: TextStyle(fontSize: 10, color: theme.textPrimaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title == 'مطعم الدلما التراثي' ? 'مطعم عربي أصيل يقدم أشهى المأكولات التراثية' : 'خدمات صيانة شاملة للمنازل والمكاتب', 
                    style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('$rating', style: TextStyle(color: theme.textPrimaryColor)),
                    const SizedBox(width: 16),
                    Icon(Icons.location_pin, size: 16, color: theme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(distance, style: TextStyle(color: theme.textSecondaryColor)),
                    const SizedBox(width: 16),
                    const Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('مفتوح', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
