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
              final isForSale = listing['status'] == 'for_sale';
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
                              color: theme.primaryColor.withOpacity(0.4),
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
                              theme.primaryColor,
                              theme.primaryColor.withOpacity(0.8),
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
                          isForSale ? Icons.sell : Icons.key,
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
                        _buildSpecChip(Icons.square_foot, '${area.toStringAsFixed(0)} م²', theme),
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
}

