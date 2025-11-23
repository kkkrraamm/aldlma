// lib/provider_dashboard_new.dart
// لوحة تحكم مقدم الخدمة - تصميم احترافي حديث
// Modern Provider Dashboard - Premium Design 🚀

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';

class ProviderDashboardNew extends StatefulWidget {
  const ProviderDashboardNew({super.key});

  @override
  State<ProviderDashboardNew> createState() => _ProviderDashboardNewState();
}

class _ProviderDashboardNewState extends State<ProviderDashboardNew>
    with TickerProviderStateMixin {
  
  bool _isLoading = true;
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _videos = [];
  String? _token;
  int _currentPage = 0;
  
  late PageController _pageController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _loadStoreData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/provider/store'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _storeData = data['store'];
            _products = List<Map<String, dynamic>>.from(data['products'] ?? []);
            _videos = List<Map<String, dynamic>>.from(data['videos'] ?? []);
            _isLoading = false;
          });
          _scaleController.forward();
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ خطأ: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changePage(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
              ),
              const SizedBox(height: 20),
              Text(
                'جاري تحميل المتجر...',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: theme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_storeData == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: _NoStoreWidget(),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              physics: const NeverScrollableScrollPhysics(), // منع التمرير الجانبي
              children: [
                _HomeTab(storeData: _storeData!, products: _products, videos: _videos, onPageChanged: _changePage),
                _ProductsTab(products: _products),
                _VideosTab(videos: _videos),
                _AnalyticsTab(storeData: _storeData!),
                _SettingsTab(storeData: _storeData!),
              ],
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentPage,
        onDestinationSelected: _changePage,
        backgroundColor: theme.cardColor,
        indicatorColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'المنتجات',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam_rounded),
            label: 'الفيديوهات',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'الإحصائيات',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }


}

// ============================================
// Home Tab
// ============================================
class _HomeTab extends StatelessWidget {
  final Map<String, dynamic> storeData;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> videos;
  final Function(int) onPageChanged;

  const _HomeTab({
    required this.storeData,
    required this.products,
    required this.videos,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Premium Header
          Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [ThemeConfig.kNightSoft, ThemeConfig.kNightDeep.withOpacity(0.8)]
                    : [const Color(0xFFECFDF5), ThemeConfig.kBeige],
              ),
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                          .withOpacity(0.1),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header with Back Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: theme.textPrimaryColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () => NotificationsService.instance
                                .toast('الإشعارات قريباً 🔔'),
                            icon: Icon(
                              Icons.notifications_rounded,
                              color: theme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      // Store Info
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? ThemeConfig.kGoldNight
                                    : ThemeConfig.kGreen,
                                width: 3,
                              ),
                              image: storeData['store_logo'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(storeData['store_logo']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: storeData['store_logo'] == null
                                ? Icon(
                                    Icons.store_rounded,
                                    color: theme.textPrimaryColor,
                                    size: 40,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        storeData['store_name'] ?? 'متجري',
                                        style: GoogleFonts.cairo(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: theme.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    if (storeData['is_verified'] == true)
                                      Icon(
                                        Icons.verified_rounded,
                                        color: isDark
                                            ? ThemeConfig.kGoldNight
                                            : ThemeConfig.kGreen,
                                        size: 24,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${storeData['rating'] ?? 0} (${storeData['followers_count'] ?? 0} متابع)',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: theme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإحصائيات السريعة',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _StatCard(
                      icon: Icons.shopping_bag_rounded,
                      title: 'المبيعات',
                      value: '${storeData['total_sales'] ?? 0}',
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'المنتجات',
                      value: '${storeData['products_count'] ?? 0}',
                      color: Colors.orange,
                    ),
                    _StatCard(
                      icon: Icons.videocam_rounded,
                      title: 'الفيديوهات',
                      value: '${storeData['videos_count'] ?? 0}',
                      color: Colors.purple,
                    ),
                    _StatCard(
                      icon: Icons.people_rounded,
                      title: 'المتابعون',
                      value: '${storeData['followers_count'] ?? 0}',
                      color: Colors.pink,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجراءات سريعة',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _QuickActionButton(
                  icon: Icons.add_shopping_cart_rounded,
                  title: 'إدارة المنتجات',
                  subtitle: 'عرض وإضافة وتعديل المنتجات',
                  onTap: () => onPageChanged(1),
                ),
                const SizedBox(height: 12),
                _QuickActionButton(
                  icon: Icons.video_call_rounded,
                  title: 'إدارة الفيديوهات',
                  subtitle: 'رفع وتعديل الفيديوهات',
                  onTap: () => onPageChanged(2),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // معلومات المتجر
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات المتجر',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                if (storeData['description'] != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوصف',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          storeData['description'] ?? 'لا يوجد وصف',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // آخر الطلبات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'آخر الطلبات',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => NotificationsService.instance.toast('عرض الكل قريباً'),
                      child: Text(
                        'عرض الكل',
                        style: GoogleFonts.cairo(
                          color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _RecentOrderCard(
                  orderNumber: '#1001',
                  customerName: 'أحمد محمد',
                  amount: '450 ر.س',
                  status: 'قيد التجهيز',
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _RecentOrderCard(
                  orderNumber: '#1000',
                  customerName: 'فاطمة علي',
                  amount: '320 ر.س',
                  status: 'تم التسليم',
                  theme: theme,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // التقييمات الحديثة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تقييمات العملاء',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _ReviewCard(
                  customerName: 'سارة محمود',
                  rating: 5,
                  review: 'منتجات ممتازة وجودة عالية جداً!',
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _ReviewCard(
                  customerName: 'علي حسن',
                  rating: 4,
                  review: 'جيد جداً، لكن التوصيل استغرق وقتاً',
                  theme: theme,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }
  
  void _showAddProductDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('إضافة منتج جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'اسم المنتج',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'الوصف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'السعر',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('✅ تم إضافة المنتج بنجاح!');
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
  
  void _showUploadVideoDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('رفع فيديو جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => NotificationsService.instance.toast('اختر فيديو من الجهاز'),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_rounded, size: 40, color: theme.textSecondaryColor),
                        const SizedBox(height: 8),
                        Text('اختر فيديو', style: GoogleFonts.cairo()),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'عنوان الفيديو',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('✅ تم رفع الفيديو بنجاح!');
            },
            child: const Text('رفع'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Recent Order Card
// ============================================
class _RecentOrderCard extends StatelessWidget {
  final String orderNumber;
  final String customerName;
  final String amount;
  final String status;
  final ThemeConfig theme;

  const _RecentOrderCard({
    required this.orderNumber,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'تم التسليم' ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الطلب $orderNumber',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customerName,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: theme.textSecondaryColor,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// Review Card
// ============================================
class _ReviewCard extends StatelessWidget {
  final String customerName;
  final int rating;
  final String review;
  final ThemeConfig theme;

  const _ReviewCard({
    required this.customerName,
    required this.rating,
    required this.review,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                customerName,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimaryColor,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Analytics Tab
// ============================================
class _AnalyticsTab extends StatefulWidget {
  final Map<String, dynamic> storeData;

  const _AnalyticsTab({required this.storeData});

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  String selectedPeriod = 'الشهر'; // اليوم، الأسبوع، الشهر، مخصص

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإحصائيات والتحليلات',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimaryColor,
                ),
              ),
              _PeriodSelector(
                selectedPeriod: selectedPeriod,
                onChanged: (value) => setState(() => selectedPeriod = value),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // مبيعات اليوم والشهر
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _StatCard(
                icon: Icons.trending_up_rounded,
                title: 'المبيعات',
                value: '${widget.storeData['total_sales'] ?? 0} ر.س',
                color: Colors.blue,
              ),
              _StatCard(
                icon: Icons.star_rounded,
                title: 'التقييم',
                value: '${widget.storeData['rating'] ?? 0}/5',
                color: Colors.amber,
              ),
              _StatCard(
                icon: Icons.shopping_bag_rounded,
                title: 'الطلبات',
                value: '${widget.storeData['total_orders'] ?? 0}',
                color: Colors.purple,
              ),
              _StatCard(
                icon: Icons.people_rounded,
                title: 'المتابعون',
                value: '${widget.storeData['followers'] ?? 0}',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // رسم بياني المبيعات
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي المبيعات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Expanded(child: _SalesChart()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // رسم بياني الطلبات
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توزيع الطلبات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _OrderStatItem(label: 'قيد المعالجة', value: '12', color: Colors.orange),
                        _OrderStatItem(label: 'قيد الشحن', value: '8', color: Colors.blue),
                        _OrderStatItem(label: 'تم التسليم', value: '45', color: Colors.green),
                        _OrderStatItem(label: 'ملغى', value: '2', color: Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // معلومات إضافية
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إحصائيات سريعة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_download_rounded),
                      onPressed: () => NotificationsService.instance.toast('📊 تصدير التقرير قريباً'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatRow(
                  label: 'إجمالي الطلبات',
                  value: '${widget.storeData['total_orders'] ?? 0}',
                  theme: theme,
                ),
                _StatRow(
                  label: 'العملاء الراضون',
                  value: '${widget.storeData['happy_customers'] ?? 0}%',
                  theme: theme,
                ),
                _StatRow(
                  label: 'متوسط الرد',
                  value: '2 ساعة',
                  theme: theme,
                ),
                _StatRow(
                  label: 'معدل الإكمال',
                  value: '95%',
                  theme: theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================
// Period Selector
// ============================================
class _PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onChanged;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final periods = ['اليوم', 'الأسبوع', 'الشهر'];

    return PopupMenuButton<String>(
      initialValue: selectedPeriod,
      onSelected: onChanged,
      itemBuilder: (context) => periods
          .map((period) => PopupMenuItem(
                value: period,
                child: Text(period),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedPeriod,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: theme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Order Stat Item
// ============================================
class _OrderStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OrderStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: const Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ============================================
// Settings Tab
// ============================================
class _SettingsTab extends StatelessWidget {
  final Map<String, dynamic> storeData;

  const _SettingsTab({required this.storeData});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إعدادات المتجر',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // قسم المتجر
          Text(
            'إدارة المتجر',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _SettingItem(
            icon: Icons.store_rounded,
            title: 'معلومات المتجر',
            subtitle: 'تعديل اسم المتجر والشعار والوصف',
            onTap: () => _showStoreInfoDialog(context),
          ),
          _SettingItem(
            icon: Icons.category_rounded,
            title: 'تصنيف المتجر',
            subtitle: 'حدد التصنيف الذي ينتمي إليه متجرك',
            onTap: () => _showCategorySelectionDialog(context),
          ),
          _SettingItem(
            icon: Icons.schedule_rounded,
            title: 'ساعات العمل',
            subtitle: 'تعيين أوقات الفتح والإغلاق',
            onTap: () => _showWorkingHoursDialog(context),
          ),
          _SettingItem(
            icon: Icons.payment_rounded,
            title: 'طرق الدفع',
            subtitle: 'إضافة أو تعديل طرق الدفع',
            onTap: () => _showPaymentMethodsDialog(context),
          ),
          
          const SizedBox(height: 24),
          
          // قسم السياسات
          Text(
            'السياسات',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _SettingItem(
            icon: Icons.assignment_return_rounded,
            title: 'سياسة الاسترجاع',
            subtitle: 'تحديد شروط الاسترجاع والتبديل',
            onTap: () => _showReturnPolicyDialog(context),
          ),
          _SettingItem(
            icon: Icons.local_shipping_rounded,
            title: 'سياسة الشحن',
            subtitle: 'تحديد تكاليف وشروط الشحن',
            onTap: () => NotificationsService.instance.toast('🚚 سياسة الشحن قريباً'),
          ),
          
          const SizedBox(height: 24),
          
          // قسم الأمان
          Text(
            'الأمان والخصوصية',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _SettingItem(
            icon: Icons.lock_rounded,
            title: 'كلمة المرور',
            subtitle: 'غير كلمة المرور الخاصة بك',
            onTap: () => NotificationsService.instance.toast('🔒 تغيير كلمة المرور قريباً'),
          ),
          _SettingItem(
            icon: Icons.privacy_tip_rounded,
            title: 'الخصوصية',
            subtitle: 'إدارة إعدادات الخصوصية',
            onTap: () => NotificationsService.instance.toast('🔐 إعدادات الخصوصية قريباً'),
          ),
          
          const SizedBox(height: 24),
          
          // قسم الدعم
          Text(
            'الدعم',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _SettingItem(
            icon: Icons.help_rounded,
            title: 'مركز المساعدة',
            subtitle: 'اطلع على الأسئلة الشائعة',
            onTap: () => NotificationsService.instance.toast('❓ مركز المساعدة قريباً'),
          ),
          _SettingItem(
            icon: Icons.phone_rounded,
            title: 'التواصل مع الدعم',
            subtitle: 'الاتصال بفريق الدعم الفني',
            onTap: () => NotificationsService.instance.toast('📞 الدعم الفني متاح 24/7'),
          ),
          
          const SizedBox(height: 24),
          
          // زر حذف الحساب
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showDeleteAccountDialog(context),
              child: Text(
                'حذف الحساب',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showStoreInfoDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    final nameController = TextEditingController(text: storeData['name'] ?? '');
    final descController = TextEditingController(text: storeData['description'] ?? '');
    final phoneController = TextEditingController(text: storeData['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('معلومات المتجر', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم المتجر',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف المتجر',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('✅ تم حفظ معلومات المتجر!');
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showCategorySelectionDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    // Sample categories with emojis (will be loaded from API in production)
    final categories = [
      {'name': 'الملابس والأزياء', 'emoji': '👔', 'id': 'clothing'},
      {'name': 'الإلكترونيات', 'emoji': '📱', 'id': 'electronics'},
      {'name': 'المنزل والأثاث', 'emoji': '🏠', 'id': 'furniture'},
      {'name': 'الغذائية والمشروبات', 'emoji': '🍔', 'id': 'food'},
      {'name': 'الجمال والعناية', 'emoji': '💄', 'id': 'beauty'},
      {'name': 'الرياضة واللياقة', 'emoji': '⚽', 'id': 'sports'},
      {'name': 'الكتب والتعليم', 'emoji': '📚', 'id': 'education'},
      {'name': 'الخدمات', 'emoji': '🛠️', 'id': 'services'},
    ];

    String? selectedCategory = storeData['category'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'تصنيف المتجر',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'اختر التصنيف الذي ينتمي إليه متجرك',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: theme.textSecondaryColor,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...categories.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => selectedCategory = cat['id'] as String,
                    borderRadius: BorderRadius.circular(12),
                    child: StatefulBuilder(
                      builder: (context, setState) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedCategory == cat['id']
                              ? (isDark
                                  ? ThemeConfig.kGoldNight
                                  : ThemeConfig.kGreen)
                                  .withOpacity(0.15)
                              : theme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedCategory == cat['id']
                                ? (isDark
                                    ? ThemeConfig.kGoldNight
                                    : ThemeConfig.kGreen)
                                : theme.borderColor,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              cat['emoji'] as String,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cat['name'] as String,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimaryColor,
                                ),
                              ),
                            ),
                            if (selectedCategory == cat['id'])
                              Icon(
                                Icons.check_circle_rounded,
                                color: isDark
                                    ? ThemeConfig.kGoldNight
                                    : ThemeConfig.kGreen,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedCategory != null) {
                Navigator.pop(context);
                NotificationsService.instance.toast(
                  '✅ تم تحديث تصنيف المتجر!',
                );
              } else {
                NotificationsService.instance.toast(
                  '⚠️ يرجى اختيار تصنيف',
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showWorkingHoursDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('ساعات العمل', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              'السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'
            ].map((day) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(day, style: GoogleFonts.cairo()),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '09:00',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('-', style: GoogleFonts.cairo()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '18:00',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('✅ تم حفظ ساعات العمل!');
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('طرق الدفع', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PaymentMethodCheckbox(label: 'تحويل بنكي', isSelected: true),
              _PaymentMethodCheckbox(label: 'بطاقة ائتمان', isSelected: false),
              _PaymentMethodCheckbox(label: 'محفظة رقمية', isSelected: false),
              _PaymentMethodCheckbox(label: 'الدفع عند الاستلام', isSelected: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('✅ تم تحديث طرق الدفع!');
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showReturnPolicyDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    final policyController = TextEditingController(
      text: storeData['return_policy'] ?? 'سياسة الاسترجاع الافتراضية: 30 يوم من تاريخ الشراء',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('سياسة الاسترجاع', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: policyController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'نص السياسة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('✅ تم تحديث سياسة الاسترجاع!');
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('حذف الحساب؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.red)),
        content: Text(
          'تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بيانات متجرك بشكل دائم.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('❌ تم حذف الحساب!');
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Products Tab - Professional Management
// ============================================
class _ProductsTab extends StatefulWidget {
  final List<Map<String, dynamic>> products;

  const _ProductsTab({required this.products});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _products;
  late List<Map<String, dynamic>> _filteredProducts;
  List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'إلكترونيات', 'color': Colors.blue},
    {'id': 2, 'name': 'ملابس', 'color': Colors.purple},
    {'id': 3, 'name': 'أثاث', 'color': Colors.orange},
  ];
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showCategoryInput = false;
  final _categoryController = TextEditingController();
  Map<int, bool> _expandedProducts = {};

  @override
  void initState() {
    super.initState();
    _products = widget.products;
    _filteredProducts = _products;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredProducts = _products
          .where((p) {
            final matchesSearch = (p['name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
            final matchesCategory = _selectedCategory == null ||
                p['category'] == _selectedCategory;
            return matchesSearch && matchesCategory;
          })
          .toList();
    });
  }

  void _addCategory() {
    if (_categoryController.text.isNotEmpty) {
      setState(() {
        _categories.add({
          'id': _categories.length + 1,
          'name': _categoryController.text,
          'color': Colors.primaries[_categories.length % Colors.primaries.length],
        });
        _categoryController.clear();
        _showCategoryInput = false;
      });
      NotificationsService.instance.toast('✅ تمت إضافة التصنيف!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return Column(
      children: [
        // Professional Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [ThemeConfig.kNightSoft, ThemeConfig.kNightDeep.withOpacity(0.8)]
                  : [const Color(0xFFECFDF5), ThemeConfig.kBeige],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة المنتجات',
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: theme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_products.length} منتج نشط',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: theme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'إضافة منتج',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Search Bar
                TextField(
                  onChanged: _filterProducts,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => _filterProducts(''),
                          )
                        : null,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Category Management
        Container(
          color: theme.cardColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'التصنيفات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  if (!_showCategoryInput)
                    GestureDetector(
                      onTap: () => setState(() => _showCategoryInput = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: isDark
                                  ? ThemeConfig.kGoldNight
                                  : ThemeConfig.kGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'إضافة',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? ThemeConfig.kGoldNight
                                    : ThemeConfig.kGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_showCategoryInput)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            hintText: 'اسم التصنيف الجديد',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                        ),
                        onPressed: _addCategory,
                        child: const Icon(Icons.check_rounded, size: 18),
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: () => setState(() => _showCategoryInput = false),
                        child: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedCategory = null;
                        _filterProducts(_searchQuery);
                      }),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedCategory == null
                              ? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)
                              : theme.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedCategory == null
                                ? (isDark
                                    ? ThemeConfig.kGoldNight
                                    : ThemeConfig.kGreen)
                                : theme.borderColor,
                          ),
                        ),
                        child: Text(
                          'الكل',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedCategory == null
                                ? Colors.white
                                : theme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = cat['name'];
                          _filterProducts(_searchQuery);
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (cat['color'] as Color).withOpacity(0.2)
                                : theme.backgroundColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? (cat['color'] as Color)
                                  : theme.borderColor,
                            ),
                          ),
                          child: Text(
                            cat['name'],
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (cat['color'] as Color)
                                  : theme.textPrimaryColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Products List
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: theme.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد منتجات',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ابدأ بإضافة منتجات لمتجرك',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    final isExpanded =
                        _expandedProducts[index] ?? false;
                    return _ProductItemCard(
                      product: product,
                      theme: theme,
                      isExpanded: isExpanded,
                      onToggleExpand: () => setState(
                        () => _expandedProducts[index] =
                            !isExpanded,
                      ),
                      onDelete: () {
                        setState(() {
                          _products.removeWhere(
                            (p) => p['id'] == product['id'],
                          );
                          _filterProducts(_searchQuery);
                        });
                        NotificationsService.instance
                            .toast('🗑️ تم حذف المنتج!');
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================
// Product Item Card - Professional Inline Editing
// ============================================
class _ProductItemCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final ThemeConfig theme;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;

  const _ProductItemCard({
    required this.product,
    required this.theme,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onDelete,
  });

  @override
  State<_ProductItemCard> createState() => _ProductItemCardState();
}

class _ProductItemCardState extends State<_ProductItemCard> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  List<String> _images = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.product['name'] ?? '');
    _priceController = TextEditingController(
        text: widget.product['price']?.toString() ?? '');
    _stockController = TextEditingController(
        text: widget.product['stock']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.product['description'] ?? '');
    _images = List<String>.from(widget.product['images'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image Gallery
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: _images.isNotEmpty
                      ? PageView.builder(
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                _images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      color: theme.textSecondaryColor,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              color: theme.textSecondaryColor,
                              size: 40,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'بدون صور',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 16),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_priceController.text} ر.س',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'المخزون: ${_stockController.text}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_images.length} صور',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color:
                            isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                      ),
                      onPressed: widget.onToggleExpand,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Expanded Details Section
          if (widget.isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing) ...[
                    // View Mode
                    _DetailRow(
                      label: 'الوصف',
                      value: _descriptionController.text.isEmpty
                          ? 'لا يوجد وصف'
                          : _descriptionController.text,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    // Image Gallery
                    Text(
                      'الصور (حد أقصى 5 صور)',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_images.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.borderColor),
                          borderStyle: BorderStyle.dashed,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              color: theme.textSecondaryColor,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد صور\nاضغط لإضافة صور',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._images.asMap().entries.map((entry) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.borderColor,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.network(
                                      entry.value,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons
                                                .image_not_supported_rounded,
                                            color: theme.textSecondaryColor,
                                            size: 30,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.red,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _images.removeAt(entry.key),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          if (_images.length < 5)
                            GestureDetector(
                              onTap: () {
                                NotificationsService.instance.toast(
                                  '📸 ميزة رفع الصور قريباً',
                                );
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: theme.backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.borderColor,
                                    style: BorderStyle.dashed,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_rounded,
                                      color: theme.textSecondaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'إضافة',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: theme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Edit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('تعديل المنتج'),
                        onPressed: () =>
                            setState(() => _isEditing = true),
                      ),
                    ),
                  ] else ...[
                    // Edit Mode
                    Text(
                      'تعديل المنتج',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _EditField(
                      label: 'اسم المنتج',
                      controller: _nameController,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EditField(
                            label: 'السعر',
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EditField(
                            label: 'المخزون',
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _EditField(
                      label: 'الوصف',
                      controller: _descriptionController,
                      maxLines: 3,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('حفظ'),
                            onPressed: () {
                              setState(() => _isEditing = false);
                              NotificationsService.instance
                                  .toast('✅ تم حفظ التغييرات!');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('إلغاء'),
                          onPressed: () =>
                              setState(() => _isEditing = false),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================
// Helper Widgets
// ============================================
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeConfig theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: theme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ThemeConfig theme;
  final TextInputType keyboardType;
  final int maxLines;

  const _EditField({
    required this.label,
    required this.controller,
    required this.theme,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// Videos Tab
// ============================================
class _VideosTab extends StatefulWidget {
  final List<Map<String, dynamic>> videos;

  const _VideosTab({required this.videos});

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  late List<Map<String, dynamic>> _videos;
  late List<Map<String, dynamic>> _filteredVideos;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _videos = widget.videos;
    _filteredVideos = _videos;
  }

  void _filterVideos(String query) {
    setState(() {
      _searchQuery = query;
      _filteredVideos = _videos
          .where((v) => (v['title'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return Column(
      children: [
        // Header
        Container(
          color: theme.cardColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الفيديوهات',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Text(
                      '${_videos.length} فيديو',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: _filterVideos,
                decoration: InputDecoration(
                  hintText: 'ابحث عن فيديو...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => _filterVideos(''),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _filteredVideos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off_rounded,
                        size: 80,
                        color: theme.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد فيديوهات',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVideos.length,
                  itemBuilder: (context, index) {
                    final video = _filteredVideos[index];
                    return _VideoItemCard(
                      video: video,
                      theme: theme,
                      onEdit: () => _showEditVideoDialog(context, video),
                      onDelete: () => _showDeleteVideoConfirmation(context, video),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEditVideoDialog(BuildContext context, Map<String, dynamic> video) {
    final theme = ThemeConfig.instance;
    final titleController = TextEditingController(text: video['title'] ?? '');
    final descController = TextEditingController(text: video['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('تعديل الفيديو', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الفيديو',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationsService.instance.toast('✅ تم تحديث الفيديو!');
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showDeleteVideoConfirmation(BuildContext context, Map<String, dynamic> video) {
    final theme = ThemeConfig.instance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('حذف الفيديو؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        content: Text(
          'هل أنت متأكد من حذف "${video['title']}"؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _videos.removeWhere((v) => v['id'] == video['id']);
                _filterVideos(_searchQuery);
              });
              Navigator.pop(context);
              NotificationsService.instance.toast('🗑️ تم حذف الفيديو!');
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Video Item Card
// ============================================
class _VideoItemCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final ThemeConfig theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VideoItemCard({
    required this.video,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    color: theme.textSecondaryColor,
                    size: 40,
                  ),
                  Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.red.withOpacity(0.7),
                    size: 50,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'] ?? 'فيديو',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video['description'] ?? 'بدون وصف',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: theme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye_rounded, size: 14, color: theme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '${video['views'] ?? 0} مشاهدة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Widgets
// ============================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: theme.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCheckbox extends StatefulWidget {
  final String label;
  final bool isSelected;

  const _PaymentMethodCheckbox({
    required this.label,
    required this.isSelected,
  });

  @override
  State<_PaymentMethodCheckbox> createState() => _PaymentMethodCheckboxState();
}

class _PaymentMethodCheckboxState extends State<_PaymentMethodCheckbox> {
  late bool selected;

  @override
  void initState() {
    super.initState();
    selected = widget.isSelected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selected = !selected),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (value) => setState(() => selected = value ?? false),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: theme.textPrimaryColor,
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            ThemeConfig.kGoldNight,
                            ThemeConfig.kGoldNight.withOpacity(0.7)
                          ]
                        : [ThemeConfig.kGreen, ThemeConfig.kGreen.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark ? ThemeConfig.kNightDeep : Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCardWithActions extends StatelessWidget {
  final Map<String, dynamic> product;
  final ThemeConfig theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCardWithActions({
    required this.product,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NotificationsService.instance.toast('تفاصيل المنتج'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    color: theme.textSecondaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'منتج',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${product['price'] ?? 0} ر.س',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          Text(
                            'المخزون: ${product['stock'] ?? 0}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NotificationsService.instance.toast('تفاصيل المنتج قريباً'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Icon(
                    Icons.image_rounded,
                    color: theme.textSecondaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name_ar'] ?? 'منتج',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['description'] ?? 'بدون وصف',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: theme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${product['price'] ?? 0} ر.س',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: ThemeConfig.kGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (product['stock'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ThemeConfig.kGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'الرصيد: ${product['stock']}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: ThemeConfig.kGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_rounded,
                  color: theme.textSecondaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoCardWithActions extends StatelessWidget {
  final Map<String, dynamic> video;
  final ThemeConfig theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VideoCardWithActions({
    required this.video,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.video_library_rounded,
                      size: 40,
                      color: theme.textSecondaryColor,
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          video['duration'] ?? '2:30',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'] ?? 'فيديو',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${video['views'] ?? 0} مشاهدة',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text('تعديل'),
                  ],
                ),
                onTap: onEdit,
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('حذف', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;

  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NotificationsService.instance.toast('تفاصيل الفيديو قريباً'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      size: 60,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'] ?? 'فيديو',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.remove_red_eye_rounded,
                              size: 14,
                              color: theme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${video['views_count'] ?? 0}',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: theme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        if (video['duration'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.backgroundColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video['duration'],
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: theme.textSecondaryColor,
                              ),
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
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.textPrimaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: theme.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 3.5),
                FlSpot(3, 5),
                FlSpot(4, 4),
                FlSpot(5, 6),
                FlSpot(6, 5.5),
              ],
              isCurved: true,
              color: ThemeConfig.kGreen,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: ThemeConfig.kGreen.withOpacity(0.1),
              ),
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStoreWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_rounded,
              size: 100,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'لم يتم إنشاء المتجر بعد',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى الانتظار حتى يتم الموافقة على طلبك',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Stat Row Widget
// ============================================
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeConfig theme;

  const _StatRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
