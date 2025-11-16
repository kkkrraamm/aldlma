import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'unified_provider_profile.dart';
import 'desert_transition.dart';
import 'login_page.dart';
import 'auth.dart';
import 'notifications.dart';
import 'orders_service.dart';
import 'orders_page.dart';
import 'theme_config.dart';
// سنستخدم نسخة محلية من الهيدر المطابق الموجود في الرئيسية/الترندات

class ServicesPage extends StatefulWidget {
  final bool showAppBar;
  final Function(int)? onNavigate;
  
  const ServicesPage({Key? key, this.showAppBar = true, this.onNavigate}) : super(key: key);
  
  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  String _selectedCategory = "all";
  String _searchQuery = "";
  bool _showSearchInput = false;
  PageController? _adsController;
  Timer? _adsTimer;
  int _adsIndex = 0;

  // الفئات المتاحة
  List<Map<String, dynamic>> categories = [
    {"id": "all", "name": "الكل", "icon": "📋"},
  ];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _adsController = PageController(viewportFraction: 0.95);
    _adsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _adsController == null) return;
      final next = (_adsIndex + 1) % 3;
      _adsController!.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
      setState(() => _adsIndex = next);
    });
  }
  
  Future<void> _loadCategories() async {
    try {
      print('🗂️ [CATEGORIES] Loading from API...');
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/categories'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          categories = [
            {"id": "all", "name": "الكل", "icon": "📋"},
            ...data.map((cat) => {
              "id": cat['name'],
              "name": cat['name'],
              "icon": cat['icon_emoji'] ?? '📋',
            }).toList(),
          ];
          _loadingCategories = false;
        });
        print('✅ [CATEGORIES] Loaded ${categories.length} categories');
      } else {
        setState(() => _loadingCategories = false);
      }
    } catch (e) {
      print('❌ [CATEGORIES] Error: $e');
      setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _adsTimer?.cancel();
    _adsController?.dispose();
    super.dispose();
  }

  // مقدمو الخدمات (بيانات تجريبية)
  final List<Map<String, dynamic>> providers = [
    {
      "id": 1,
      "name": "مطعم الدلما التراثي",
      "description": "أطباق سعودية تراثية أصيلة بنكهات عربية عريقة",
      "category": "مطاعم",
      "address": "حي النزهة، شارع الملك فهد، عرعر",
      "phone": "+966501234567",
      "rating": "4.8",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 2,
      "name": "ورشة الماهر للصيانة",
      "description": "صيانة جميع أنواع الأجهزة الكهربائية والإلكترونية",
      "category": "صيانة",
      "address": "حي الصناعية، شارع الأمير عبدالله، عرعر",
      "phone": "+966502345678",
      "rating": "4.7",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 3,
      "name": "النظافة الشاملة",
      "description": "خدمات تنظيف المنازل والمكاتب والفلل بأحدث المعدات",
      "category": "تنظيف",
      "address": "حي السلام، شارع التحلية، عرعر",
      "phone": "+966503456789",
      "rating": "4.9",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 4,
      "name": "صالون الأناقة للسيدات",
      "description": "خدمات تجميل شاملة للسيدات مع أحدث صيحات الموضة",
      "category": "تجميل",
      "address": "حي الروضة، شارع الأميرات، عرعر",
      "phone": "+966504567890",
      "rating": "4.6",
      "isOpen": false,
      "status": "approved"
    },
    {
      "id": 5,
      "name": "شركة النقل السريع",
      "description": "خدمات نقل البضائع والأثاث داخل وخارج مدينة عرعر",
      "category": "نقل",
      "address": "حي الورود، شارع الملك سعود، عرعر",
      "phone": "+966505678901",
      "rating": "4.5",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 6,
      "name": "عيادة الدكتور أحمد للأسنان",
      "description": "علاج وتجميل الأسنان بأحدث التقنيات الطبية",
      "category": "صحة",
      "address": "حي المطار، شارع الملك خالد، عرعر",
      "phone": "+966506789012",
      "rating": "4.9",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 7,
      "name": "أكاديمية التفوق التعليمية",
      "description": "دروس تقوية في جميع المواد للمراحل الدراسية المختلفة",
      "category": "تعليم",
      "address": "حي الجامعة، شارع التعليم، عرعر",
      "phone": "+966507890123",
      "rating": "4.7",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 8,
      "name": "سوق الدلما المركزي",
      "description": "متجر شامل لجميع احتياجات المنزل والأسرة مع توصيل عبر تطبيقات متعددة",
      "category": "تسوق",
      "address": "وسط المدينة، شارع التجارة، عرعر",
      "phone": "+966508901234",
      "rating": "4.4",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 2,
      "name": "سباك الخبرة المحترف",
      "description": "خدمات السباكة المتكاملة وإصلاح جميع الأعطال بضمان شامل",
      "category": "خدمات منزلية",
      "address": "حي الصناعية، شارع التخصصي، عرعر",
      "phone": "+966502345678",
      "rating": "4.9",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 3,
      "name": "نجارة الإتقان والجودة",
      "description": "أعمال النجارة والديكور الخشبي المتميز بأحدث التقنيات",
      "category": "خدمات منزلية",
      "address": "حي الملز، شارع الأمير سلطان، عرعر",
      "phone": "+966503456789",
      "rating": "4.7",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 4,
      "name": "بستان الورود الطبيعية",
      "description": "أجمل الورود والنباتات الطبيعية لجميع المناسبات مع التنسيق الاحترافي",
      "category": "هدايا وورود",
      "address": "حي الروضة، شارع العليا، عرعر",
      "phone": "+966504567890",
      "rating": "4.6",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 5,
      "name": "عالم الهدايا المميزة",
      "description": "هدايا مميزة وفريدة لجميع المناسبات والأعمار مع التغليف الفاخر",
      "category": "هدايا وورود",
      "address": "حي المطار، شارع الملك خالد، عرعر",
      "phone": "+966505678901",
      "rating": "4.5",
      "isOpen": true,
      "status": "approved"
    },
    {
      "id": 6,
      "name": "مملكة الألعاب التعليمية",
      "description": "ألعاب تعليمية وترفيهية آمنة لجميع الأعمار مع استشارات تربوية",
      "category": "ألعاب وترفيه",
      "address": "حي الشفاء، شارع الأندلس، عرعر",
      "phone": "+966506789012",
      "rating": "4.4",
      "isOpen": true,
      "status": "approved"
    },
  ];

  // فلترة المقدمين
  List<Map<String, dynamic>> get filteredProviders {
    return providers.where((provider) {
      final matchesCategory = _selectedCategory == "all" || provider['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          provider['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          provider['category'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (provider['description']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildServicesHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'اكتشف خدمات الدلما',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showSearchInput = !_showSearchInput),
            icon: const Icon(Icons.search, size: 18),
            label: Text('بحث', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdsCarousel() {
    final List<String> banners = [
      'assets/img/aldlma.png',
      'assets/img/al5dmat.png',
      'assets/img/al5re6h.png',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _adsController,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _adsIndex = i),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(banners[index], fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _adsIndex ? const Color(0xFF10B981) : Colors.grey.shade300,
              ),
            )),
          ),
        ],
      ),
    );
  }
  // أيقونة الفئة
  String _getCategoryIcon(String category) {
    switch (category) {
      case "مطاعم": return "🍽️";
      case "خدمات منزلية": return "🔧";
      case "هدايا وورود": return "🎁";
      case "ألعاب وترفيه": return "🧸";
      case "صيانة": return "🔧";
      case "تنظيف": return "🧽";
      case "تجميل": return "💄";
      case "نقل": return "🚚";
      case "صحة": return "🏥";
      case "تعليم": return "📚";
      case "تسوق": return "🛍️";
      default: return "🏢";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final theme = ThemeConfig.instance;
        final isDark = theme.isDarkMode;
        
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: CustomScrollView(
        slivers: [
          // نفس هيدر الرئيسية/الترندات (نسخة محلية)
          SliverToBoxAdapter(child: _HeroHeader()),
          
          // زر وفلتر وبحث
          SliverToBoxAdapter(child: _buildServicesHeader()),
          SliverToBoxAdapter(child: _showSearchInput ? _buildSearchInput() : const SizedBox.shrink()),
          SliverToBoxAdapter(child: _buildCategoriesFilter()),

          // بانر واحد بالعرض يدور تلقائياً
          SliverToBoxAdapter(child: _buildAdsCarousel()),

          // قسم طلباتي (مدمج)
          SliverToBoxAdapter(child: _buildMyOrdersSection()),

          // قائمة مقدمي الخدمات
          SliverToBoxAdapter(child: _buildProvidersList()),
        ],
      ),
        );
      },
    );
  }

  Widget _buildMyOrdersSection() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return AnimatedBuilder(
      animation: Listenable.merge([AuthState.instance, OrdersService.instance, theme]),
      builder: (context, _) {
        if (!AuthState.instance.isLoggedIn) return const SizedBox.shrink();
        final phone = AuthState.instance.phone;
        if (phone == null || phone.isEmpty) return const SizedBox.shrink();
        final orders = OrdersService.instance.getOrdersForPhone(phone);
        final hasOrders = orders.isNotEmpty;
        final last = hasOrders ? orders.last : null;

        return Container(
          color: Colors.transparent, // خلفية شفافة لإظهار البيج
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'طلباتي',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: hasOrders
                    ? _LastOrderCard(order: last!)
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'لا توجد طلبات',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: theme.textSecondaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // الانتقال إلى تبويب "طلباتي" في شريط التنقل السفلي (index 1)
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(1);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                      foregroundColor: isDark ? ThemeConfig.kNightDeep : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: Text('طلباتي', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 15,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFEF3E2),
            Color(0xFFECFDF5),
            Color(0xFFFEF3E2),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'خدمات الدلما',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _showSearchInput ? Icons.close : Icons.search,
                color: Color(0xFF10B981),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showSearchInput = !_showSearchInput;
                  if (!_showSearchInput) _searchQuery = "";
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFEF3E2),
            Color(0xFFECFDF5),
            Color(0xFFFEF3E2),
          ],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // توهج خلف الشعار
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF4F46E5).withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_repair_service,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'خدمات الدلما',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'اكتشف جميع الخدمات المتاحة في عرعر',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      color: theme.cardColor,
      padding: EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor),
        ),
        child: TextField(
          textAlign: TextAlign.right,
          style: TextStyle(color: theme.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'ابحث عن خدمة...',
            hintStyle: GoogleFonts.cairo(color: theme.textSecondaryColor),
            prefixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesFilter() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      color: Colors.transparent, // خلفية شفافة لإظهار البيج
      padding: EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category['id'];
            
            return Container(
              margin: EdgeInsets.only(left: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category['icon'],
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 6),
                    Text(
                      category['name'],
                      style: GoogleFonts.cairo(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                          ? (isDark ? ThemeConfig.kNightDeep : Colors.white)
                          : theme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                selectedColor: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                backgroundColor: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade100,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category['id'];
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProvidersList() {
    final filtered = filteredProviders;
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.textSecondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد خدمات متاحة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: theme.textPrimaryColor,
              ),
            ),
            Text(
              'جرب البحث بكلمات مختلفة أو اختر فئة أخرى',
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
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildProviderCard(filtered[index]);
      },
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // الانتقال لصفحة البروفايل الموحدة الفاخرة
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                UnifiedProviderProfile(providerId: provider['id']),
              transitionDuration: const Duration(milliseconds: 800),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return DesertWindTransition(
                  animation: animation,
                  child: child,
                );
              },
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة الخدمة
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(0.7)]
                      : [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _getCategoryIcon(provider['category']),
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
              SizedBox(width: 16),
              
              // معلومات المقدم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم والتقييم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            provider['name'],
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              provider['rating'],
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    
                    // الوصف
                    Text(
                      provider['description'],
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    
                    // المعلومات الإضافية
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.textSecondaryColor,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider['address'],
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: theme.textSecondaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: theme.textSecondaryColor,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          provider['phone'],
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: provider['isOpen'] 
                              ? (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade100)
                              : (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            provider['isOpen'] ? 'مفتوح' : 'مغلق',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: provider['isOpen'] 
                                ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                                : (isDark ? Colors.red.shade300 : Colors.red.shade700),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // الفئة وسهم التفاصيل
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            provider['category'],
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: theme.textSecondaryColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// نسخة مطابقة من الهيدر المستخدم في الصفحات الأخرى
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final color = Theme.of(context).colorScheme.primary;
    
    return AnimatedBuilder(
      animation: theme,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          decoration: BoxDecoration(
            gradient: theme.headerGradient,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _LoginButton(),
                    Row(
                      children: [
                        _ThemeToggleButton(),
                        SizedBox(width: 8),
                        NotificationsBell(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              color.withOpacity(0.25),
                              color.withOpacity(0.15),
                              color.withOpacity(0.08),
                              color.withOpacity(0.03),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                      Image.asset('assets/img/aldlma.png', width: 176, height: 176),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'اكتشف خدمات مدينتك من أهلها، مع أفضل التجارب.',
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

class _LoginButton extends StatelessWidget {
  const _LoginButton({super.key});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      onTap: () async {
        if (AuthState.instance.isLoggedIn) {
          await AuthState.instance.logout();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الخروج')));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFF059669)]),
          borderRadius: BorderRadius.all(Radius.circular(6)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: AnimatedBuilder(
          animation: AuthState.instance,
          builder: (context, _) {
            final isIn = AuthState.instance.isLoggedIn;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isIn ? Icons.logout : Icons.person_outline, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(isIn ? 'تسجيل الخروج' : 'تسجيل الدخول', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ]);
          },
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, child) {
        final theme = ThemeConfig.instance;
        final isDark = theme.isDarkMode;
        
        return GestureDetector(
          onTap: () async {
            await theme.toggleTheme();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? ThemeConfig.kNightSoft : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: theme.cardShadow,
            ),
            child: Center(
              child: Text(
                isDark ? '☀️' : '🌙',
                style: const TextStyle(fontSize: 20),
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
      child: Center(child: Icon(icon, color: const Color(0xFF6B7280), size: 20)),
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
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        const Center(child: Icon(Icons.notifications_none, color: Color(0xFF6B7280), size: 20)),
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
                child: Text(count!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _LastOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _LastOrderCard({required this.order});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text((order['icon'] ?? '🛍️').toString(), style: const TextStyle(fontSize: 18)),
          ),
        ),
        title: Text(
          (order['service'] ?? 'خدمة').toString(),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: theme.textPrimaryColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              'طلب #${order['orderNumber'] ?? ''} • ${(order['date'] ?? '')}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: theme.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              (order['status'] ?? '').toString(),
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: theme.textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              (order['totalDisplay'] ?? '').toString(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? ThemeConfig.kNightAccent : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (order['deliveryMethod'] == 'pickup') ? 'استلام' : 'توصيل',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: theme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}