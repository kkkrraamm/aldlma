import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'theme_config.dart';
import 'api_config.dart';
import 'realty_details_page.dart';
import 'rfp_form_page.dart';

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
  late AnimationController _filterAnimController;
  late Animation<double> _filterAnimation;
  
  // فلاتر البحث
  String? _selectedCity = 'عرعر';
  String? _selectedType;
  String? _selectedStatus;
  double? _minPrice;
  double? _maxPrice;
  
  // مركز الخريطة الافتراضي (عرعر)
  LatLng _center = const LatLng(30.9843, 41.0015);
  LatLng? _userLocation; // الموقع الحالي للمستخدم
  double _currentZoom = 13.0;
  
  // أنواع الخرائط
  int _mapTypeIndex = 0;
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
    'عرعر': {'lat': 30.9843, 'lng': 41.0015, 'zoom': 13.0},
    'رفحاء': {'lat': 29.6257, 'lng': 43.4945, 'zoom': 13.0},
    'طريف': {'lat': 31.6828, 'lng': 38.6644, 'zoom': 13.0},
    'القريات': {'lat': 31.3314, 'lng': 37.3404, 'zoom': 13.0},
    'سكاكا': {'lat': 29.9697, 'lng': 40.2064, 'zoom': 13.0},
    'حائل': {'lat': 27.5219, 'lng': 41.6901, 'zoom': 12.5},
    'تبوك': {'lat': 28.3838, 'lng': 36.5550, 'zoom': 12.5},
    'الجوف': {'lat': 29.8114, 'lng': 39.9294, 'zoom': 12.0},
    'دومة الجندل': {'lat': 29.8114, 'lng': 39.8714, 'zoom': 13.5},
    'العويقيلة': {'lat': 30.5000, 'lng': 42.2500, 'zoom': 14.0},
    'لينة': {'lat': 30.7833, 'lng': 40.9333, 'zoom': 14.0},
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
    
    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf5f7fa),
      body: Stack(
        children: [
          // المحتوى الرئيسي (خريطة أو قائمة)
          _showMapView ? _buildModernMapView(theme) : _buildFullListView(theme),
          
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
              
              return Marker(
                point: LatLng(
                  double.parse(listing['lat'].toString()),
                  double.parse(listing['lng'].toString()),
                ),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _showModernListingPopup(listing, theme),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ظل
                      Container(
                        width: 40,
                        height: 40,
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
                      // الدائرة الرئيسية
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color,
                              color.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // قائمة المدن
          Expanded(
            child: GestureDetector(
              onTap: () => _showCitiesMenu(theme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _selectedCity ?? 'اختر المدينة',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1a1f2e),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF64748b),
                        size: 18,
                      ),
                    ],
                  ),
                  if (_selectedType != null || _selectedStatus != null)
                    Text(
                      '${_types[_selectedType] ?? ''} ${_selectedStatus == 'for_sale' ? 'للبيع' : _selectedStatus == 'for_rent' ? 'للإيجار' : ''}',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: const Color(0xFF64748b),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              // العنوان
              Text(
                'مدن الشمال المدعومة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1a1f2e),
                ),
              ),
              const SizedBox(height: 16),
              // قائمة المدن
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _cities.keys.map((city) {
                  final isSelected = _selectedCity == city;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _changeCity(city);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                              )
                            : null,
                        color: isSelected ? null : const Color(0xFFf1f5f9),
                        borderRadius: BorderRadius.circular(12),
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
                          color: isSelected ? Colors.white : const Color(0xFF64748b),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // معلومة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'اختر المدينة لعرض العقارات المتاحة فيها',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF1a1f2e),
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
    // جلب الصور
    final images = listing['images'] as List<dynamic>? ?? [];
    final hasImages = images.isNotEmpty;
    
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
              if (hasImages) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[0],
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
                    setState(() => _showMapView = true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: _showMapView
                          ? LinearGradient(
                              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _showMapView
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
                            color: _showMapView ? Colors.white : theme.textSecondaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'خريطة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _showMapView ? Colors.white : theme.textSecondaryColor,
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
                    setState(() => _showMapView = false);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: !_showMapView
                          ? LinearGradient(
                              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: !_showMapView
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
                            color: !_showMapView ? Colors.white : theme.textSecondaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'قائمة',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !_showMapView ? Colors.white : theme.textSecondaryColor,
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
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RealtyDetailsPage(listingId: listing['id']),
          ),
        );
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3b82f6),
              Color(0xFF2563eb),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3b82f6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.business_center, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أنت مكتب عقاري؟',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'سجّل الآن واعرض عقاراتك مجاناً',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // زر الإغلاق
            GestureDetector(
              onTap: () {
                setState(() => _showOfficeBanner = false);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3b82f6), const Color(0xFF2563eb)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3b82f6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
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
                Text(
                  'انضم كمكتب عقاري',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'اعرض عقاراتك وتواصل مع آلاف العملاء',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
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

