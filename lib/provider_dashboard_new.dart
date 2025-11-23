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
              children: [
                _HomeTab(storeData: _storeData!, products: _products, videos: _videos),
                _ProductsTab(products: _products, onRefresh: _loadStoreData),
                _VideosTab(videos: _videos, onRefresh: _loadStoreData),
                _AnalyticsTab(storeData: _storeData!),
                _SettingsTab(storeData: _storeData!),
              ],
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [
          Icons.home_rounded,
          Icons.inventory_rounded,
          Icons.videocam_rounded,
          Icons.analytics_rounded,
          Icons.settings_rounded,
        ],
        activeIndex: _currentPage,
        gapLocation: GapLocation.end,
        notchSmoothness: NotchSmoothness.smoothEdge,
        onTap: _changePage,
        backgroundColor: theme.cardColor,
        activeColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
        inactiveColor: theme.textSecondaryColor,
        leftCornerRadius: 20,
        rightCornerRadius: 0,
        iconSize: 24,
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

  const _HomeTab({
    required this.storeData,
    required this.products,
    required this.videos,
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
                  title: 'إضافة منتج',
                  subtitle: 'أضف منتج جديد لمتجرك',
                  onTap: () => NotificationsService.instance
                      .toast('إضافة منتج قريباً 📦'),
                ),
                const SizedBox(height: 12),
                _QuickActionButton(
                  icon: Icons.video_call_rounded,
                  title: 'رفع فيديو',
                  subtitle: 'انشر فيديو لمنتجاتك',
                  onTap: () => NotificationsService.instance
                      .toast('رفع فيديو قريباً 🎬'),
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
// Products Tab
// ============================================
class _ProductsTab extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final VoidCallback onRefresh;

  const _ProductsTab({required this.products, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_rounded,
              size: 80,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد منتجات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w900,
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product);
      },
    );
  }
}

// ============================================
// Videos Tab
// ============================================
class _VideosTab extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final VoidCallback onRefresh;

  const _VideosTab({required this.videos, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_rounded,
              size: 80,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد فيديوهات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ برفع فيديوهات لمنتجاتك',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _VideoCard(video: video);
      },
    );
  }
}

// ============================================
// Analytics Tab
// ============================================
class _AnalyticsTab extends StatelessWidget {
  final Map<String, dynamic> storeData;

  const _AnalyticsTab({required this.storeData});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإحصائيات والتحليلات',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.borderColor),
            ),
            child: const _SalesChart(),
          ),
          const SizedBox(height: 30),
        ],
      ),
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
          _SettingItem(
            icon: Icons.store_rounded,
            title: 'معلومات المتجر',
            subtitle: 'تعديل اسم المتجر والشعار',
            onTap: () =>
                NotificationsService.instance.toast('معلومات المتجر قريباً'),
          ),
          _SettingItem(
            icon: Icons.notifications_rounded,
            title: 'الإشعارات',
            subtitle: 'إدارة إشعارات المتجر',
            onTap: () => NotificationsService.instance.toast('الإشعارات قريباً'),
          ),
          _SettingItem(
            icon: Icons.security_rounded,
            title: 'الأمان',
            subtitle: 'تغيير كلمة المرور والخصوصية',
            onTap: () =>
                NotificationsService.instance.toast('إعدادات الأمان قريباً'),
          ),
          _SettingItem(
            icon: Icons.help_rounded,
            title: 'المساعدة والدعم',
            subtitle: 'الاتصال بفريق الدعم',
            onTap: () =>
                NotificationsService.instance.toast('المساعدة قريباً 📞'),
          ),
        ],
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
                      Text(
                        '${product['price'] ?? 0} ر.س',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: ThemeConfig.kGreen,
                        ),
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
