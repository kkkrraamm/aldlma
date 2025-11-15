import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'theme_config.dart';
import 'api_config.dart';
import 'realty_details_page.dart';
import 'rfp_form_page.dart';
import 'compare_page.dart';
import 'favorites_page.dart';
import 'chat_list_page.dart';
import 'chat_page.dart';

class RealtyPage extends StatefulWidget {
  const RealtyPage({super.key});

  @override
  State<RealtyPage> createState() => _RealtyPageState();
}

class _RealtyPageState extends State<RealtyPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<dynamic> _listings = [];
  bool _isLoading = true;
  bool _showFilters = false;
  bool _showMapView = true; // التبديل بين الخريطة والقائمة
  bool _showOfficeBanner = true; // إظهار بانر تسجيل المكتب
  int _currentView = 0; // 0: خريطة، 1: قائمة، 2: محادثات
  late AnimationController _filterAnimController;
  late Animation<double> _filterAnimation;
  
  // المحادثات
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoadingConversations = false;
  Timer? _conversationsRefreshTimer;
  
  // فلاتر البحث
  String? _selectedCity = 'عرعر';
  String? _selectedType;
  String? _selectedStatus;
  double? _minPrice;
  double? _maxPrice;
  
  // نظام المقارنة
  List<int> _selectedForCompare = [];
  bool _isCompareMode = false;
  
  // مركز الخريطة الافتراضي (عرعر)
  LatLng _center = const LatLng(30.9843, 41.0015);
  LatLng? _userLocation; // الموقع الحالي للمستخدم
  double _currentZoom = 13.0;
  
  // أنواع الخرائط
  int _mapTypeIndex = 1; // البدء بالقمر الصناعي
  final List<Map<String, String>> _mapTypes = [
    {
      'name': 'عادي',
      'light': 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      'dark': 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png',
    },
    {
      'name': 'قمر صناعي',
      'light': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'dark': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    },
    {
      'name': 'تضاريس',
      'light': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      'dark': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'نظيف',
      'light': 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      'dark': 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png',
    },
  ];
  
  // مدن الشمال المدعومة مع إحداثياتها
  final Map<String, Map<String, dynamic>> _cities = {
    // المدن الرئيسية
    'عرعر': {'lat': 30.9843, 'lng': 41.0015, 'zoom': 13.0},
    'رفحاء': {'lat': 29.6257, 'lng': 43.4945, 'zoom': 13.0},
    'طريف': {'lat': 31.6828, 'lng': 38.6644, 'zoom': 13.0},
    'العويقيلة': {'lat': 30.5000, 'lng': 42.2500, 'zoom': 14.0},
    // المراكز التابعة لعرعر
    'الجديدة': {'lat': 31.358333, 'lng': 41.443056, 'zoom': 14.0},
    'أم خنصر': {'lat': 30.694784, 'lng': 41.600252, 'zoom': 14.0},
    'حزم الجلاميد': {'lat': 31.280278, 'lng': 40.104167, 'zoom': 14.0},
    // المراكز التابعة لرفحاء
    'لينة': {'lat': 28.765106, 'lng': 43.738198, 'zoom': 14.0},
    'الشعبة': {'lat': 29.192778, 'lng': 44.715000, 'zoom': 14.0},
    'سماح': {'lat': 29.7000, 'lng': 43.3000, 'zoom': 14.0},
    'نصاب': {'lat': 29.4000, 'lng': 43.2000, 'zoom': 14.0},
    'طلعة التمياط': {'lat': 29.842633, 'lng': 43.144051, 'zoom': 14.0},
    'بن شريم': {'lat': 29.950195, 'lng': 43.363923, 'zoom': 14.0},
    'بن هباس': {'lat': 29.145615, 'lng': 44.321616, 'zoom': 14.0},
    'لوقة': {'lat': 29.873707, 'lng': 44.418682, 'zoom': 14.0},
    'أم رضمة': {'lat': 28.680180, 'lng': 44.695921, 'zoom': 14.0},
    'الخشيبي': {'lat': 29.138357, 'lng': 43.932916, 'zoom': 14.0},
    'زبالا': {'lat': 29.109498, 'lng': 43.965129, 'zoom': 14.0},
    'العجرمية': {'lat': 29.361242, 'lng': 43.646348, 'zoom': 14.0},
    'رغوة': {'lat': 29.466666, 'lng': 43.772156, 'zoom': 14.0},
    'الحدقة': {'lat': 28.465213, 'lng': 44.337846, 'zoom': 14.0},
    'الحدق': {'lat': 29.234739, 'lng': 43.351992, 'zoom': 14.0},
    'أعيوج لينة': {'lat': 28.583400, 'lng': 43.596800, 'zoom': 14.0},
    'الجميمة': {'lat': 29.5500, 'lng': 43.4500, 'zoom': 14.0},
    // المراكز التابعة لطريف
    'الجراني': {'lat': 31.933000, 'lng': 38.643000, 'zoom': 14.0},
    // المراكز التابعة للعويقيلة
    'صحن': {'lat': 30.214000, 'lng': 42.590000, 'zoom': 14.0},
    'الأيدية': {'lat': 29.999000, 'lng': 42.750000, 'zoom': 14.0},
    'الكاسب': {'lat': 30.040000, 'lng': 42.880000, 'zoom': 14.0},
    'نعيجان': {'lat': 30.018000, 'lng': 42.520000, 'zoom': 14.0},
    'أبو رواث': {'lat': 29.480000, 'lng': 43.000000, 'zoom': 14.0},
    'الدويد': {'lat': 30.310000, 'lng': 42.680000, 'zoom': 14.0},
    'زهوة': {'lat': 30.220000, 'lng': 42.360000, 'zoom': 14.0},
    // القرى والهجر
    'أم الضيان': {'lat': 31.1000, 'lng': 41.1000, 'zoom': 14.0},
    'قليب بن غنيم': {'lat': 31.2000, 'lng': 40.9000, 'zoom': 14.0},
    'حدق الجندة': {'lat': 29.4500, 'lng': 43.3500, 'zoom': 14.0},
    'قيصومة فيحان': {'lat': 29.3500, 'lng': 43.2500, 'zoom': 14.0},
    'ابن سوقي': {'lat': 29.2500, 'lng': 43.1500, 'zoom': 14.0},
    'ابن عجل': {'lat': 29.1500, 'lng': 43.0500, 'zoom': 14.0},
    'الشريفات': {'lat': 29.0500, 'lng': 42.9500, 'zoom': 14.0},
    'الجبهان': {'lat': 31.4000, 'lng': 38.4000, 'zoom': 14.0},
    'المركوز': {'lat': 30.3500, 'lng': 42.3500, 'zoom': 14.0},
    'الديدب': {'lat': 30.8000, 'lng': 41.2000, 'zoom': 14.0},
    'السليمانية': {'lat': 30.9000, 'lng': 41.1000, 'zoom': 14.0},
    'ابن سعيد': {'lat': 31.0000, 'lng': 41.2000, 'zoom': 14.0},
    'ابن بكر': {'lat': 31.1500, 'lng': 41.3000, 'zoom': 14.0},
    'ابن عايش': {'lat': 29.5500, 'lng': 43.3500, 'zoom': 14.0},
    'السلمانية': {'lat': 30.4500, 'lng': 42.2500, 'zoom': 14.0},
    'الأدية': {'lat': 30.3500, 'lng': 42.1500, 'zoom': 14.0},
    'آل علي': {'lat': 30.2500, 'lng': 42.0500, 'zoom': 14.0},
    'دغيليب الوجعان': {'lat': 30.1500, 'lng': 41.9500, 'zoom': 14.0},
    'كمب الثنيان': {'lat': 29.6500, 'lng': 43.4000, 'zoom': 14.0},
    'الركعا': {'lat': 29.7500, 'lng': 43.2000, 'zoom': 14.0},
    // مدن أخرى (خارج الحدود الشمالية)
    'القريات': {'lat': 31.3314, 'lng': 37.3404, 'zoom': 13.0},
    'سكاكا': {'lat': 29.9697, 'lng': 40.2064, 'zoom': 13.0},
    'حائل': {'lat': 27.5219, 'lng': 41.6901, 'zoom': 12.5},
    'تبوك': {'lat': 28.3838, 'lng': 36.5550, 'zoom': 12.5},
    'الجوف': {'lat': 29.8114, 'lng': 39.9294, 'zoom': 12.0},
    'دومة الجندل': {'lat': 29.8114, 'lng': 39.8714, 'zoom': 13.5},
    'الحديثة': {'lat': 30.4333, 'lng': 41.6667, 'zoom': 14.0},
  };
  
  final Map<String, String> _types = {
    'apartment': 'شقة',
    'villa': 'فيلا',
    'land': 'أرض',
    'building': 'عمارة',
    'farm': 'مزرعة',
    'warehouse': 'مستودع',
    'office': 'مكتب',
    'shop': 'محل',
  };
  
  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimController,
      curve: Curves.easeInOut,
    );
    _getCurrentLocation();
    _loadListings();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        // جلب الموقع الحالي
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        
        // تحريك الخريطة للموقع الحالي
        _mapController.move(_center, 14.0);
        
        debugPrint('📍 [LOCATION] الموقع الحالي: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      debugPrint('⚠️ [LOCATION] خطأ في جلب الموقع: $e');
      // استخدام الموقع الافتراضي (عرعر)
    }
  }

  void _changeCity(String? city) {
    if (city == null) return;
    
    setState(() {
      _selectedCity = city;
    });
    
    // تحريك الخريطة للمدينة المختارة
    final cityData = _cities[city];
    if (cityData != null) {
      final lat = cityData['lat'] as double;
      final lng = cityData['lng'] as double;
      final zoom = cityData['zoom'] as double;
      
      _mapController.move(LatLng(lat, lng), zoom);
      setState(() {
        _center = LatLng(lat, lng);
        _currentZoom = zoom;
      });
      
      debugPrint('🏙️ [CITY] الانتقال إلى $city');
    }
    
    // تحميل العقارات للمدينة الجديدة
    _loadListings();
  }

  @override
  void dispose() {
    _filterAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/realty/search').replace(
        queryParameters: {
          if (_selectedCity != null) 'city': _selectedCity!,
          if (_selectedType != null) 'type': _selectedType!,
          if (_selectedStatus != null) 'status': _selectedStatus!,
          if (_minPrice != null) 'min_price': _minPrice.toString(),
          if (_maxPrice != null) 'max_price': _maxPrice.toString(),
          'limit': '200',
        },
      );

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listings = data['listings'] ?? [];
          _isLoading = false;
        });
        
        debugPrint('✅ [REALTY] تم تحميل ${_listings.length} عقار');
      } else {
        throw Exception('فشل تحميل العقارات');
      }
    } catch (e) {
      debugPrint('❌ [REALTY] خطأ: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    Widget currentView;
    if (_currentView == 0) {
      currentView = _buildModernMapView(theme);
    } else if (_currentView == 1) {
      currentView = _buildFullListView(theme);
    } else {
      currentView = _buildConversationsView(theme);
    }
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf5f7fa),
      body: Stack(
        children: [
          // المحتوى الرئيسي (خريطة، قائمة، أو محادثات)
          currentView,
          
          // شريط البحث العائم في الأعلى
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildModernSearchBar(theme),
          ),
          
          // شريط الفلاتر السريعة
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: _buildQuickFilters(theme),
          ),
          
          // بانر "سجّل كمكتب عقاري"
          if (!_showFilters && _showOfficeBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: _buildOfficeBanner(theme),
            ),
          
          // أزرار التحكم بالخريطة (يمين) - فقط في وضع الخريطة
          if (_showMapView)
            Positioned(
              right: 16,
              bottom: 100,
              child: _buildMapControls(theme),
            ),
          
          // زر طلب عقار - في وضع الخريطة فقط (يسار أسفل)
          if (_showMapView)
            Positioned(
              left: 16,
              bottom: 100,
              child: _buildRfpButton(theme),
            ),
          
          // مؤشر التحميل
          if (_isLoading)
            Positioned(
              top: MediaQuery.of(context).padding.top + 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'جاري التحميل...',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // الشريط السفلي للتبديل
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // الخريطة الحديثة بهوية الدلما
  Widget _buildModernMapView(ThemeConfig theme) {
    // اختيار نوع الخريطة حسب الوضع (ليلي/نهاري)
    final currentMapType = _mapTypes[_mapTypeIndex];
    final mapStyle = theme.isDarkMode 
        ? currentMapType['dark']! 
        : currentMapType['light']!;
    
    return Container(
      color: theme.isDarkMode ? const Color(0xFF1a1f2e) : const Color(0xFFe5e7eb),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: _currentZoom,
          minZoom: 5.0,
          maxZoom: 18.0,
          onPositionChanged: (position, hasGesture) {
            if (hasGesture) {
              setState(() {
                _currentZoom = position.zoom ?? _currentZoom;
              });
            }
          },
        ),
        children: [
          // طبقة الخريطة الأساسية
          TileLayer(
            urlTemplate: mapStyle,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.dalma.app',
            tileProvider: NetworkTileProvider(),
          ),
        
        // طبقة الوديان والشعبان - تعمل تلقائياً على جميع أنواع الخرائط
        // الشفافية تختلف حسب نوع الخريطة للحصول على أفضل رؤية
        Opacity(
          opacity: _mapTypeIndex == 1 ? 0.5 : (_mapTypeIndex == 2 ? 0.0 : 0.35),
          // قمر صناعي: 50% | تضاريس: 0% (لأنها مدمجة) | عادي/نظيف: 35%
          child: TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.dalma.app',
            tileProvider: NetworkTileProvider(),
          ),
        ),
        
        // Markers للعقارات
        MarkerLayer(
          markers: [
            // موقع المستخدم الحالي
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // دائرة خارجية نابضة
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    // دائرة داخلية
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // العقارات
            ..._listings
                .where((l) => l['lat'] != null && l['lng'] != null)
                .map((listing) {
              final type = listing['type'] ?? 'apartment';
              final icon = _getIconForType(type);
              final color = _getColorForType(type, theme);
              
              final officeLogo = listing['office_logo'];
              final price = double.tryParse(listing['price']?.toString() ?? '0') ?? 0;
              final typeLabel = _types[listing['type']] ?? '';
              final priceK = price >= 1000 ? '${(price / 1000).toStringAsFixed(0)}k' : '${price.toStringAsFixed(0)}';
              
              return Marker(
                point: LatLng(
                  double.parse(listing['lat'].toString()),
                  double.parse(listing['lng'].toString()),
                ),
                width: 70,
                height: 100,
                child: GestureDetector(
                  onTap: () => _showModernListingPopup(listing, theme),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // لوجو المكتب في الأعلى
                      if (officeLogo != null) ...[
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: color, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              officeLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.business,
                                size: 12,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      // الدائرة الرئيسية
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // ظل
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          // الدائرة
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // نوع العقار
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          typeLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // السعر
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.9)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          priceK,
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
      ),
    );
  }

  void _handleCall(dynamic listing) async {
    // تسجيل الحدث
    await _postEvent('click_call', listing['id']);
    
    // TODO: فتح الاتصال
    final phone = listing['office_phone'];
    if (phone != null) {
      debugPrint('📞 اتصال بـ $phone');
      // استخدم url_launcher لفتح الاتصال
    }
  }

  void _handleWhatsApp(dynamic listing) async {
    // تسجيل الحدث
    await _postEvent('click_whatsapp', listing['id']);
    
    // TODO: فتح واتساب
    final phone = listing['office_phone'];
    if (phone != null) {
      debugPrint('💬 واتساب $phone');
      // استخدم url_launcher لفتح واتساب
    }
  }

  Future<void> _postEvent(String eventType, int refId) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/realty/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'event_type': eventType,
          'ref_id': refId,
          'meta': {},
        }),
      );
    } catch (e) {
      debugPrint('❌ [EVENT] خطأ: $e');
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num = double.tryParse(price.toString()) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)} مليون';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(0)} ألف';
    }
    return num.toStringAsFixed(0);
  }

  // شريط البحث الحديث
  Widget _buildModernSearchBar(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: theme.isDarkMode ? Border.all(
          color: const Color(0xFF2a2f3e),
          width: 1,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: theme.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // قائمة المدن - محسّنة
          Expanded(
            child: GestureDetector(
              onTap: () => _showCitiesMenu(theme),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.1),
                      theme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // أيقونة الموقع
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // النص
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'المدينة',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _selectedCity ?? 'اختر المدينة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1a1f2e),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // سهم
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // زر أطلب عقار (في وضع القائمة فقط)
          if (!_showMapView)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RfpFormPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_home, color: Colors.white, size: 20),
              ),
            ),
          
          if (!_showMapView) const SizedBox(width: 12),
          
          // زر المفضلة
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.favorite, color: Colors.red, size: 20),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // زر المقارنة
          GestureDetector(
            onTap: () {
              if (_selectedForCompare.isEmpty) {
                setState(() => _isCompareMode = !_isCompareMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isCompareMode 
                        ? 'اختر عقارين على الأقل للمقارنة'
                        : 'تم إلغاء وضع المقارنة',
                      style: GoogleFonts.cairo(),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                _openComparePage();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isCompareMode 
                  ? theme.primaryColor 
                  : theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Stack(
                children: [
                  Icon(
                    Icons.compare_arrows,
                    color: _isCompareMode ? Colors.white : theme.primaryColor,
                    size: 20,
                  ),
                  if (_selectedForCompare.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_selectedForCompare.length}',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // زر الفلترة
          GestureDetector(
            onTap: () {
              setState(() => _showFilters = !_showFilters);
              if (_showFilters) {
                _filterAnimController.forward();
              } else {
                _filterAnimController.reverse();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 20),
            ),
          ),
          
          if (_showMapView) ...[
            const SizedBox(width: 12),
            // زر الرجوع (في وضع الخريطة فقط)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back, color: theme.primaryColor, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // قائمة المدن
  void _showCitiesMenu(ThemeConfig theme) {
    // تقسيم المدن حسب النوع
    final mainCities = ['عرعر', 'رفحاء', 'طريف', 'العويقيلة'];
    final centers = [
      'الجديدة', 'أم خنصر', 'حزم الجلاميد', 'لينة', 'الشعبة', 'سماح', 'نصاب',
      'طلعة التمياط', 'بن شريم', 'بن هباس', 'لوقة', 'أم رضمة', 'الخشيبي',
      'زبالا', 'العجرمية', 'رغوة', 'الحدقة', 'الحدق', 'أعيوج لينة', 'الجميمة',
      'الجراني', 'صحن', 'الأيدية', 'الكاسب', 'نعيجان', 'أبو رواث', 'الدويد', 'زهوة'
    ];
    final villages = [
      'أم الضيان', 'قليب بن غنيم', 'حدق الجندة', 'قيصومة فيحان', 'ابن سوقي',
      'ابن عجل', 'الشريفات', 'الجبهان', 'المركوز', 'الديدب', 'السليمانية',
      'ابن سعيد', 'ابن بكر', 'ابن عايش', 'السلمانية', 'الأدية', 'آل علي',
      'دغيليب الوجعان', 'كمب الثنيان', 'الركعا'
    ];
    final otherCities = ['القريات', 'سكاكا', 'حائل', 'تبوك', 'الجوف', 'دومة الجندل', 'الحديثة'];
    
    final allCitiesList = [...mainCities, ...centers, ...villages, ...otherCities];
    
    final searchController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> filteredCities = allCitiesList;
            
            if (searchController.text.isNotEmpty) {
              filteredCities = allCitiesList
                  .where((city) => city.contains(searchController.text))
                  .toList();
            }
            
            final filteredMain = filteredCities.where((c) => mainCities.contains(c)).toList();
            final filteredCenters = filteredCities.where((c) => centers.contains(c)).toList();
            final filteredVillages = filteredCities.where((c) => villages.contains(c)).toList();
            final filteredOther = filteredCities.where((c) => otherCities.contains(c)).toList();
            
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: theme.isDarkMode ? Border.all(
                      color: const Color(0xFF2a2f3e),
                      width: 1,
                    ) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(theme.isDarkMode ? 0.5 : 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // مؤشر السحب
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.isDarkMode 
                                ? const Color(0xFF3a3f4e)
                                : const Color(0xFFe2e8f0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // العنوان
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'اختر المدينة',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // حقل البحث
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setModalState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث عن المدينة...',
                            hintStyle: GoogleFonts.cairo(
                              color: theme.textSecondaryColor,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: theme.textSecondaryColor),
                                    onPressed: () {
                                      searchController.clear();
                                      setModalState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: theme.isDarkMode 
                                ? const Color(0xFF0b0f14)
                                : const Color(0xFFf1f5f9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: theme.isDarkMode 
                                  ? const BorderSide(color: Color(0xFF2a2f3e))
                                  : BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: theme.isDarkMode 
                                  ? const BorderSide(color: Color(0xFF2a2f3e))
                                  : BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // المحتوى القابل للتمرير
                      Expanded(
                        child: filteredCities.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: theme.textSecondaryColor.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد نتائج',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        color: theme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: [
                                  // المدن الرئيسية
                                  if (filteredMain.isNotEmpty) ...[
                                    _buildCitySection('🏙️ المدن الرئيسية', filteredMain, theme),
                                    const SizedBox(height: 20),
                                  ],
                                  // المراكز الإدارية
                                  if (filteredCenters.isNotEmpty) ...[
                                    _buildCitySection('🏘️ المراكز الإدارية', filteredCenters, theme),
                                    const SizedBox(height: 20),
                                  ],
                                  // القرى والهجر
                                  if (filteredVillages.isNotEmpty) ...[
                                    _buildCitySection('🏡 القرى والهجر', filteredVillages, theme),
                                    const SizedBox(height: 20),
                                  ],
                                  // مدن أخرى
                                  if (filteredOther.isNotEmpty) ...[
                                    _buildCitySection('📍 مدن أخرى', filteredOther, theme),
                                    const SizedBox(height: 20),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCitySection(String title, List<String> cities, ThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cities.where((city) => _cities.containsKey(city)).map((city) {
            final isSelected = _selectedCity == city;
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _changeCity(city);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                        )
                      : null,
                  color: isSelected 
                      ? null 
                      : (theme.isDarkMode 
                          ? const Color(0xFF0b0f14)
                          : const Color(0xFFf1f5f9)),
                  borderRadius: BorderRadius.circular(12),
                  border: !isSelected && theme.isDarkMode 
                      ? Border.all(color: const Color(0xFF2a2f3e))
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  city,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : theme.textSecondaryColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // فلاتر سريعة
  Widget _buildQuickFilters(ThemeConfig theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: _showFilters
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // النوع
                  Text(
                    'نوع العقار',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1a1f2e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.entries.map((e) {
                      final isSelected = _selectedType == e.key;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = isSelected ? null : e.key;
                          });
                          _loadListings();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFFf1f5f9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            e.value,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF64748b),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // الحالة
                  Text(
                    'الحالة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1a1f2e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusChip('for_sale', 'للبيع', theme),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusChip('for_rent', 'للإيجار', theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // نطاق السعر
                  Text(
                    'نطاق السعر (ر.س)',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1a1f2e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'من',
                            hintStyle: GoogleFonts.cairo(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFf8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: GoogleFonts.cairo(fontSize: 13),
                          onChanged: (value) {
                            _minPrice = double.tryParse(value);
                            _loadListings();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('—', style: GoogleFonts.cairo(color: const Color(0xFF64748b))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'إلى',
                            hintStyle: GoogleFonts.cairo(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFf8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: GoogleFonts.cairo(fontSize: 13),
                          onChanged: (value) {
                            _maxPrice = double.tryParse(value);
                            _loadListings();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // نطاق المساحة
                  Text(
                    'نطاق المساحة (م²)',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1a1f2e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'من',
                            hintStyle: GoogleFonts.cairo(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFf8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: GoogleFonts.cairo(fontSize: 13),
                          onChanged: (value) {
                            setState(() {
                              // سيتم إضافة دعم min_area في API call
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('—', style: GoogleFonts.cairo(color: const Color(0xFF64748b))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'إلى',
                            hintStyle: GoogleFonts.cairo(fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFf8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: GoogleFonts.cairo(fontSize: 13),
                          onChanged: (value) {
                            setState(() {
                              // سيتم إضافة دعم max_area في API call
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // زر إعادة تعيين
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedType = null;
                          _selectedStatus = null;
                          _minPrice = null;
                          _maxPrice = null;
                        });
                        _loadListings();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'إعادة تعيين الفلاتر',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                        side: BorderSide(color: theme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStatusChip(String value, String label, ThemeConfig theme) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = isSelected ? null : value;
        });
        _loadListings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                )
              : null,
          color: isSelected ? null : const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF64748b),
            ),
          ),
        ),
      ),
    );
  }

  // أزرار التحكم بالخريطة (تكبير/تصغير/موقعي/نوع الخريطة)
  Widget _buildMapControls(ThemeConfig theme) {
    return Column(
      children: [
        // نوع الخريطة
        _buildControlButton(
          icon: Icons.layers,
          onTap: () {
            setState(() {
              _mapTypeIndex = (_mapTypeIndex + 1) % _mapTypes.length;
            });
            // عرض رسالة
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'نوع الخريطة: ${_mapTypes[_mapTypeIndex]['name']}',
                  style: GoogleFonts.cairo(),
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: theme.primaryColor,
              ),
            );
          },
          theme: theme,
          tooltip: _mapTypes[_mapTypeIndex]['name'],
        ),
        const SizedBox(height: 8),
        // تكبير
        _buildControlButton(
          icon: Icons.add,
          onTap: () {
            _mapController.move(_mapController.camera.center, _currentZoom + 1);
            setState(() => _currentZoom += 1);
          },
          theme: theme,
        ),
        const SizedBox(height: 8),
        // تصغير
        _buildControlButton(
          icon: Icons.remove,
          onTap: () {
            _mapController.move(_mapController.camera.center, _currentZoom - 1);
            setState(() => _currentZoom -= 1);
          },
          theme: theme,
        ),
        const SizedBox(height: 8),
        // موقعي
        _buildControlButton(
          icon: Icons.my_location,
          onTap: () async {
            await _getCurrentLocation();
          },
          theme: theme,
          isActive: _userLocation != null,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeConfig theme,
    bool isActive = false,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? theme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isActive 
                    ? theme.primaryColor.withOpacity(0.4)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon, 
            color: isActive ? Colors.white : theme.primaryColor, 
            size: 22,
          ),
        ),
      ),
    );
  }

  // زر طلب عقار (كبير - للخريطة)
  Widget _buildRfpButton(ThemeConfig theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RfpFormPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_home, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'أطلب عقار',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Popup حديث للعقار
  void _showModernListingPopup(dynamic listing, ThemeConfig theme) {
    // جلب الصورة المصغرة
    final thumbnail = listing['thumbnail'];
    final hasImage = thumbnail != null && thumbnail.toString().isNotEmpty;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مؤشر السحب
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFe2e8f0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // الصورة (إذا موجودة)
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    thumbnail,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFf1f5f9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_work, size: 48, color: theme.textSecondaryColor),
                            const SizedBox(height: 8),
                            Text(
                              listing['title'] ?? 'عقار',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // العنوان
              Text(
                listing['title'] ?? 'بدون عنوان',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1a1f2e),
                ),
              ),
              const SizedBox(height: 12),
              // السعر
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_formatPrice(listing['price'])} ر.س',
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // الموقع
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: theme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    '${listing['city']} • ${listing['district'] ?? ''}',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // زر عرض التفاصيل
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RealtyDetailsPage(listingId: listing['id']),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'عرض التفاصيل الكاملة',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // الشريط السفلي الحديث بهوية الدلما
  Widget _buildBottomNavBar(ThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.1),
                theme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // خريطة العقار
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentView = 0;
                      _showMapView = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _currentView == 0
                          ? LinearGradient(
                              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _currentView == 0
                          ? [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: _currentView == 0 ? Colors.white : theme.textSecondaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'خريطة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _currentView == 0 ? Colors.white : theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // قائمة العقار
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentView = 1;
                      _showMapView = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _currentView == 1
                          ? LinearGradient(
                              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _currentView == 1
                          ? [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_list_rounded,
                            color: _currentView == 1 ? Colors.white : theme.textSecondaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'قائمة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _currentView == 1 ? Colors.white : theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // المحادثات
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _currentView = 2);
                    _loadConversations();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _currentView == 2
                          ? LinearGradient(
                              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                            )
                          : null,
                      color: _currentView == 2
                          ? null
                          : (theme.isDarkMode
                              ? const Color(0xFF2a2f3e)
                              : const Color(0xFFf1f5f9)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _currentView == 2
                          ? [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: _currentView == 2 ? Colors.white : theme.textSecondaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'محادثات',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _currentView == 2 ? Colors.white : theme.textSecondaryColor,
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
    );
  }

  // عرض القائمة الكاملة
  Widget _buildFullListView(ThemeConfig theme) {
    if (_listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد عقارات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير المدينة أو الفلاتر',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 150,
        left: 16,
        right: 16,
        bottom: 100,
      ),
      itemCount: _listings.length,
      itemBuilder: (context, index) {
        return _buildFullListingCard(_listings[index], theme);
      },
    );
  }

  // بطاقة عقار كاملة للقائمة
  Widget _buildFullListingCard(dynamic listing, ThemeConfig theme) {
    final thumbnail = listing['thumbnail'];
    final price = listing['price'];
    final title = listing['title'] ?? 'بدون عنوان';
    final city = listing['city'] ?? '';
    final district = listing['district'] ?? '';
    final area = listing['area'];
    final rooms = listing['rooms'];
    final status = listing['status'];
    final type = listing['type'];
    
    final isSelected = _selectedForCompare.contains(listing['id']);
    
    return GestureDetector(
      onTap: () {
        if (_isCompareMode) {
          _toggleCompareSelection(listing['id']);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RealtyDetailsPage(listingId: listing['id']),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: thumbnail != null
                      ? Image.network(
                          thumbnail,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.home_work,
                              size: 60,
                              color: theme.primaryColor,
                            ),
                          ),
                        )
                      : Container(
                          height: 200,
                          color: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.home_work,
                            size: 60,
                            color: theme.primaryColor,
                          ),
                        ),
                ),
                // شارة الحالة
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'for_sale'
                          ? Colors.green.withOpacity(0.9)
                          : Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'for_sale' ? 'للبيع' : 'للإيجار',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Checkbox للمقارنة
                if (_isCompareMode)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleCompareSelection(listing['id']),
                        activeColor: theme.primaryColor,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                // نوع العقار
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _types[type] ?? type ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // التفاصيل
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // الموقع
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: theme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '$city${district != null && district.isNotEmpty ? ' • $district' : ''}',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // المواصفات
                  Row(
                    children: [
                      if (area != null) ...[
                        _buildSpecChip(Icons.square_foot, '${double.tryParse(area.toString())?.toStringAsFixed(0) ?? area} م²', theme),
                        const SizedBox(width: 8),
                      ],
                      if (rooms != null) ...[
                        _buildSpecChip(Icons.bed, '$rooms غرف', theme),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      // السعر
                      Text(
                        '${_formatPrice(price)} ر.س',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
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

  Widget _buildSpecChip(IconData icon, String text, ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // أيقونة حسب نوع العقار
  IconData _getIconForType(String type) {
    switch (type) {
      case 'apartment':
        return Icons.apartment;
      case 'villa':
        return Icons.villa;
      case 'land':
        return Icons.landscape;
      case 'building':
        return Icons.business;
      case 'farm':
        return Icons.agriculture;
      case 'warehouse':
        return Icons.warehouse;
      case 'office':
        return Icons.corporate_fare;
      case 'shop':
        return Icons.storefront;
      default:
        return Icons.home_work;
    }
  }

  // لون حسب نوع العقار
  Color _getColorForType(String type, ThemeConfig theme) {
    switch (type) {
      case 'apartment':
        return theme.primaryColor; // أخضر (شقة)
      case 'villa':
        return const Color(0xFF8b5cf6); // بنفسجي (فيلا)
      case 'land':
        return const Color(0xFFf59e0b); // برتقالي (أرض)
      case 'building':
        return const Color(0xFF3b82f6); // أزرق (عمارة)
      case 'farm':
        return const Color(0xFF10b981); // أخضر فاتح (مزرعة)
      case 'warehouse':
        return const Color(0xFF6b7280); // رمادي (مستودع)
      case 'office':
        return const Color(0xFF06b6d4); // سماوي (مكتب)
      case 'shop':
        return const Color(0xFFec4899); // وردي (محل)
      default:
        return theme.primaryColor;
    }
  }

  // بانر تسجيل المكتب
  Widget _buildOfficeBanner(ThemeConfig theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfficeRegistrationPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.primaryColor.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة متحركة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.business_center_rounded,
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // النص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'أنت مكتب عقاري؟',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'مجاناً',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'سجّل الآن واعرض عقاراتك لآلاف العملاء',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // زر السهم
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            // زر الإغلاق
            GestureDetector(
              onTap: () {
                setState(() => _showOfficeBanner = false);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // دوال المحادثات
  // ═══════════════════════════════════════════════════════════
  
  Future<void> _loadConversations() async {
    setState(() => _isLoadingConversations = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null) {
        setState(() {
          _conversations = [];
          _isLoadingConversations = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(data['conversations'] ?? []);
          _isLoadingConversations = false;
        });
        debugPrint('✅ [CONVERSATIONS] تم جلب ${_conversations.length} محادثة');
      }
    } catch (e) {
      debugPrint('❌ [CONVERSATIONS] خطأ: $e');
      setState(() {
        _conversations = [];
        _isLoadingConversations = false;
      });
    }
  }
  
  Widget _buildConversationsView(ThemeConfig theme) {
    if (_isLoadingConversations) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
    }
    
    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 60,
                color: theme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد محادثات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ابدأ محادثة من صفحة تفاصيل العقار',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        left: 16,
        right: 16,
        bottom: 100,
      ),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        final unreadCount = int.tryParse(conv['unread_count']?.toString() ?? '0') ?? 0;
        
        return Card(
          margin: EdgeInsets.only(
            top: index == 0 ? 16 : 0,
            bottom: 12,
          ),
          color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: unreadCount > 0
                ? BorderSide(color: theme.primaryColor, width: 2)
                : BorderSide.none,
          ),
          elevation: theme.isDarkMode ? 0 : 3,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    officeId: conv['office_id'],
                    officeName: conv['office_name'] ?? 'مكتب',
                    officeLogo: conv['office_logo'],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: unreadCount > 0
                                ? theme.primaryColor
                                : theme.textSecondaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: conv['office_logo'] != null
                            ? CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(conv['office_logo']),
                              )
                            : CircleAvatar(
                                radius: 30,
                                backgroundColor: theme.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.business,
                                  color: theme.primaryColor,
                                  size: 30,
                                ),
                              ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.isDarkMode
                                    ? const Color(0xFF1a1f2e)
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv['office_name'] ?? 'مكتب',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          conv['last_message'] ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: unreadCount > 0
                                ? theme.textPrimaryColor
                                : theme.textSecondaryColor,
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // دوال المقارنة
  // ═══════════════════════════════════════════════════════════
  
  void _openComparePage() {
    if (_selectedForCompare.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اختر عقارين على الأقل للمقارنة',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }
    
    if (_selectedForCompare.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يمكنك مقارنة 4 عقارات كحد أقصى',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }
    
    // جلب العقارات المحددة
    final selectedListings = _listings
        .where((listing) => _selectedForCompare.contains(listing['id']))
        .toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComparePage(
          properties: List<Map<String, dynamic>>.from(selectedListings),
        ),
      ),
    ).then((_) {
      // إعادة تعيين وضع المقارنة بعد الرجوع
      setState(() {
        _isCompareMode = false;
        _selectedForCompare.clear();
      });
    });
  }
  
  void _toggleCompareSelection(int listingId) {
    setState(() {
      if (_selectedForCompare.contains(listingId)) {
        _selectedForCompare.remove(listingId);
      } else {
        if (_selectedForCompare.length < 4) {
          _selectedForCompare.add(listingId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'يمكنك مقارنة 4 عقارات كحد أقصى',
                style: GoogleFonts.cairo(),
              ),
            ),
          );
        }
      }
    });
  }
}

// ============================================================
// صفحة تسجيل المكتب العقاري
// ============================================================

class OfficeRegistrationPage extends StatefulWidget {
  const OfficeRegistrationPage({super.key});

  @override
  State<OfficeRegistrationPage> createState() => _OfficeRegistrationPageState();
}

class _OfficeRegistrationPageState extends State<OfficeRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _officeNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCity = 'عرعر';
  String _selectedPlan = 'free';
  bool _isSubmitting = false;

  final List<String> _cities = [
    'عرعر', 'رفحاء', 'طريف', 'القريات', 'سكاكا',
    'حائل', 'تبوك', 'الجوف', 'دومة الجندل',
  ];

  final Map<String, Map<String, dynamic>> _plans = {
    'free': {
      'name': 'مجاني',
      'subtitle': 'ابدأ بدون تكلفة',
      'price': 0,
      'color': const Color(0xFF6b7280),
      'icon': Icons.stars,
      'features': [
        {'icon': Icons.home_work, 'text': '5 إعلانات نشطة'},
        {'icon': Icons.image, 'text': '8 صور لكل إعلان'},
        {'icon': Icons.visibility, 'text': 'معاينة الطلبات الخاصة'},
        {'icon': Icons.search, 'text': 'ظهور في نتائج البحث'},
      ],
    },
    'basic': {
      'name': 'أساسي',
      'subtitle': 'للمكاتب المتوسطة',
      'price': 149,
      'badge': 'الأكثر شعبية',
      'color': const Color(0xFF10b981),
      'icon': Icons.trending_up,
      'features': [
        {'icon': Icons.home_work, 'text': '20 إعلان نشط'},
        {'icon': Icons.image, 'text': '12 صورة لكل إعلان'},
        {'icon': Icons.location_city, 'text': 'طلبات خاصة من مدينتك'},
        {'icon': Icons.analytics, 'text': 'إحصائيات أساسية'},
        {'icon': Icons.mail, 'text': 'رد على الطلبات'},
      ],
    },
    'pro': {
      'name': 'احترافي',
      'subtitle': 'للمكاتب الكبيرة',
      'price': 499,
      'badge': 'الأفضل قيمة',
      'color': const Color(0xFF8b5cf6),
      'icon': Icons.rocket_launch,
      'features': [
        {'icon': Icons.home_work, 'text': '80 إعلان نشط'},
        {'icon': Icons.image, 'text': '20 صورة لكل إعلان'},
        {'icon': Icons.public, 'text': 'طلبات من كامل المنطقة'},
        {'icon': Icons.insights, 'text': 'تحليلات متقدمة + أوقات الذروة'},
        {'icon': Icons.map, 'text': 'خريطة توزيع الطلبات'},
        {'icon': Icons.priority_high, 'text': 'ترتيب أعلى في البحث'},
      ],
    },
    'vip': {
      'name': 'VIP',
      'subtitle': 'للشركات العقارية',
      'price': 1999,
      'badge': '🔥 حصري',
      'color': const Color(0xFFf59e0b),
      'icon': Icons.workspace_premium,
      'features': [
        {'icon': Icons.all_inclusive, 'text': 'إعلانات غير محدودة'},
        {'icon': Icons.image, 'text': '30 صورة لكل إعلان'},
        {'icon': Icons.flash_on, 'text': 'أولوية مطلقة في الطلبات'},
        {'icon': Icons.notifications_active, 'text': 'تنبيهات فورية (SMS + Push)'},
        {'icon': Icons.thermostat, 'text': 'Heatmap كامل للسوق'},
        {'icon': Icons.picture_as_pdf, 'text': 'تقارير PDF أسبوعية'},
        {'icon': Icons.verified, 'text': 'شارة VIP للثقة'},
        {'icon': Icons.support_agent, 'text': 'دعم فني أولوية'},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf5f7fa),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme),
            
            // المحتوى
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معلومات المكتب
                      _buildSectionTitle('معلومات المكتب', Icons.business, theme),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _officeNameController,
                        label: 'اسم المكتب',
                        hint: 'مكتب الدلما العقاري',
                        icon: Icons.store,
                        theme: theme,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildCityDropdown(theme),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _licenseController,
                        label: 'رقم الترخيص',
                        hint: 'اختياري',
                        icon: Icons.badge,
                        theme: theme,
                      ),
                      const SizedBox(height: 24),
                      
                      // معلومات التواصل
                      _buildSectionTitle('معلومات التواصل', Icons.contact_phone, theme),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'رقم الجوال',
                        hint: '05XXXXXXXX',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        theme: theme,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'info@office.com',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        theme: theme,
                      ),
                      const SizedBox(height: 24),
                      
                      // اختيار الباقة
                      _buildSectionTitle('اختر الباقة', Icons.workspace_premium, theme),
                      const SizedBox(height: 16),
                      _buildPlanSelector(theme),
                      const SizedBox(height: 24),
                      
                      // ملاحظات
                      _buildSectionTitle('ملاحظات (اختياري)', Icons.note, theme),
                      const SizedBox(height: 16),
                      _buildNotesField(theme),
                      const SizedBox(height: 32),
                      
                      // زر الإرسال
                      _buildSubmitButton(theme),
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

  Widget _buildHeader(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // الصف الأول: زر الرجوع + العنوان
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'انضم كمكتب عقاري',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'مجاناً',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اعرض عقاراتك وتواصل مع آلاف العملاء',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // الصف الثاني: المميزات السريعة
          Row(
            children: [
              _buildQuickFeature(Icons.flash_on, 'تفعيل فوري', theme),
              const SizedBox(width: 12),
              _buildQuickFeature(Icons.verified_user, 'موثوق', theme),
              const SizedBox(width: 12),
              _buildQuickFeature(Icons.trending_up, 'زيادة المبيعات', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFeature(IconData icon, String text, ThemeConfig theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, ThemeConfig theme) {
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    required ThemeConfig theme,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(color: theme.textPrimaryColor),
        validator: isRequired
            ? (v) => v == null || v.isEmpty ? '$label مطلوب' : null
            : null,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: theme.primaryColor) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
          hintStyle: GoogleFonts.cairo(color: theme.textSecondaryColor.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildCityDropdown(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
          width: 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.primaryColor),
          style: GoogleFonts.cairo(color: theme.textPrimaryColor),
          dropdownColor: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          items: _cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Row(
                children: [
                  Icon(Icons.location_city, size: 18, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(city),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCity = value!),
        ),
      ),
    );
  }

  Widget _buildPlanSelector(ThemeConfig theme) {
    return Column(
      children: _plans.entries.map((e) {
        final isSelected = _selectedPlan == e.key;
        final plan = e.value;
        final features = (plan['features'] as List?) ?? [];
        
        return GestureDetector(
          onTap: () => setState(() => _selectedPlan = e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isSelected 
                  ? LinearGradient(
                      colors: [
                        (plan['color'] as Color).withOpacity(0.15),
                        (plan['color'] as Color).withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isSelected ? null : (theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? (plan['color'] as Color)
                    : (theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0)),
                width: isSelected ? 3 : 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (plan['color'] as Color).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header الباقة
                Row(
                  children: [
                    // الأيقونة
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (plan['color'] as Color),
                            (plan['color'] as Color).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        (plan['icon'] as IconData?) ?? Icons.card_membership,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // الاسم والوصف
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan['name'],
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected 
                                      ? (plan['color'] as Color)
                                      : theme.textPrimaryColor,
                                ),
                              ),
                              if (plan['badge'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (plan['color'] as Color),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    plan['badge'] ?? '',
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
                          Text(
                            plan['subtitle'] ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // السعر
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (plan['price'] == 0)
                          Text(
                            'مجاني',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: (plan['color'] as Color),
                            ),
                          )
                        else ...[
                          Text(
                            '${plan['price']}',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: (plan['color'] as Color),
                            ),
                          ),
                          Text(
                            'ر.س/شهر',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // المميزات
                if (features.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (plan['color'] as Color).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: features.map<Widget>((feature) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                (feature['icon'] as IconData?) ?? Icons.check_circle_outline,
                                size: 18,
                                color: (plan['color'] as Color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  feature['text'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textPrimaryColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: (plan['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: (plan['color'] as Color),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تم الاختيار',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: (plan['color'] as Color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField(ThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.isDarkMode ? const Color(0xFF2a2f3e) : const Color(0xFFe2e8f0),
          width: 2,
        ),
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        style: GoogleFonts.cairo(color: theme.textPrimaryColor),
        decoration: InputDecoration(
          labelText: 'ملاحظات أو طلبات خاصة',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeConfig theme) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3b82f6), Color(0xFF2563eb)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'إرسال طلب التسجيل',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/office/register-request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'office_name': _officeNameController.text,
          'city': _selectedCity,
          'license_number': _licenseController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
          'requested_plan': _selectedPlan,
          'notes': _notesController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        
        final theme = Provider.of<ThemeConfig>(context, listen: false);
        
        showDialog(
          context: context,
          builder: (context) => _buildSuccessDialog(theme),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSuccessDialog(ThemeConfig theme) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10b981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              'تم إرسال طلبك!',
              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'سنراجع طلبك ونتواصل معك خلال 24 ساعة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: theme.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('حسناً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

