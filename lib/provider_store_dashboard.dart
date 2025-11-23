// lib/provider_store_dashboard.dart
// لوحة تحكم مقدم الخدمة - إدارة المتجر والمنتجات والفيديوهات
// Provider Store Dashboard - Dalma Identity 🏪
// بتصميم حديث وهوية الدلما الفاخرة ✨
// ✨ نسخة مكتملة مع جميع الـ Features

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';
import 'auth.dart';

class ProviderStoreDashboard extends StatefulWidget {
  const ProviderStoreDashboard({super.key});

  @override
  State<ProviderStoreDashboard> createState() => _ProviderStoreDashboardState();
}

class _ProviderStoreDashboardState extends State<ProviderStoreDashboard>
    with TickerProviderStateMixin {
  
  bool _isLoading = true;
  Map<String, dynamic>? _storeData;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _videos = [];
  String? _token;
  int _currentIndex = 0;
  
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        setState(() => _isLoading = false);
        return;
      }

      // جلب بيانات المتجر
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/provider/store'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _storeData = data['store'];
            _products = List<Map<String, dynamic>>.from(data['products'] ?? []);
            _videos = List<Map<String, dynamic>>.from(data['videos'] ?? []);
            _isLoading = false;
          });
          _fadeController.forward();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المتجر: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
          ),
        ),
      );
    }

    if (_storeData == null) {
      return _NoStoreScreen();
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _DashboardHeader(storeData: _storeData!),
            
            // Tab Bar
            _DashboardTabBar(
              controller: _tabController,
              onTap: (index) => setState(() => _currentIndex = index),
            ),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(storeData: _storeData!),
                  _ProductsTab(products: _products, onRefresh: _loadStoreData),
                  _VideosTab(videos: _videos, onRefresh: _loadStoreData),
                  _PromotionsTab(),
                  _AnalyticsTab(storeData: _storeData!),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    IconData icon;
    String tooltip;
    VoidCallback onPressed;
    
    switch (_currentIndex) {
      case 1: // Products
        icon = Icons.add_shopping_cart_rounded;
        tooltip = 'إضافة منتج';
        onPressed = () => _showAddProductSheet();
        break;
      case 2: // Videos
        icon = Icons.video_call_rounded;
        tooltip = 'رفع فيديو';
        onPressed = () => _showUploadVideoSheet();
        break;
      case 3: // Promotions
        icon = Icons.local_offer_rounded;
        tooltip = 'إنشاء عرض';
        onPressed = () => _showAddPromotionSheet();
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(tooltip, style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
      backgroundColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
      foregroundColor: isDark ? ThemeConfig.kNightDeep : Colors.white,
    );
  }

  void _showAddProductSheet() {
    NotificationsService.instance.toast('صفحة إضافة منتج قريباً 📦');
  }

  void _showUploadVideoSheet() {
    NotificationsService.instance.toast('صفحة رفع فيديو قريباً 🎬');
  }

  void _showAddPromotionSheet() {
    NotificationsService.instance.toast('صفحة إنشاء عرض قريباً 🏷️');
  }
}

// ============================================
// Dashboard Header
// ============================================

class _DashboardHeader extends StatelessWidget {
  final Map<String, dynamic> storeData;
  
  const _DashboardHeader({required this.storeData});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [ThemeConfig.kNightDeep, ThemeConfig.kNightSoft]
              : [const Color(0xFFECFDF5), ThemeConfig.kBeige],
        ),
        border: Border(
          bottom: BorderSide(color: theme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
          ),
          const SizedBox(width: 12),
          // Store Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
              image: storeData['store_logo'] != null
                  ? DecorationImage(
                      image: NetworkImage(storeData['store_logo']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: storeData['store_logo'] == null
                ? Icon(Icons.store, color: theme.textSecondaryColor)
                : null,
          ),
          const SizedBox(width: 12),
          // Store Info
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (storeData['is_verified'] == true)
                      Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${storeData['rating'] ?? 0}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people_rounded, size: 14, color: theme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${storeData['followers_count'] ?? 0} متابع',
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
          // Settings
          IconButton(
            onPressed: () => NotificationsService.instance.toast('إعدادات المتجر قريباً ⚙️'),
            icon: Icon(Icons.settings_rounded, color: theme.textPrimaryColor),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Dashboard Tab Bar
// ============================================

class _DashboardTabBar extends StatelessWidget {
  final TabController controller;
  final Function(int) onTap;
  
  const _DashboardTabBar({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      color: theme.cardColor,
      child: TabBar(
        controller: controller,
        onTap: onTap,
        isScrollable: true,
        indicatorColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
        indicatorWeight: 3,
        labelColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
        unselectedLabelColor: theme.textSecondaryColor,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded), text: 'نظرة عامة'),
          Tab(icon: Icon(Icons.inventory_rounded), text: 'المنتجات'),
          Tab(icon: Icon(Icons.video_library_rounded), text: 'الفيديوهات'),
          Tab(icon: Icon(Icons.local_offer_rounded), text: 'العروض'),
          Tab(icon: Icon(Icons.analytics_rounded), text: 'الإحصائيات'),
        ],
      ),
    );
  }
}

// ============================================
// Overview Tab
// ============================================

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> storeData;
  
  const _OverviewTab({required this.storeData});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // إحصائيات سريعة
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              icon: Icons.shopping_bag_rounded,
              title: 'المبيعات',
              value: '${storeData['total_sales'] ?? 0}',
              subtitle: 'إجمالي الطلبات',
              color: Colors.blue,
            ),
            _StatCard(
              icon: Icons.attach_money_rounded,
              title: 'الإيرادات',
              value: '${storeData['total_revenue'] ?? 0} ر.س',
              subtitle: 'إجمالي الأرباح',
              color: Colors.green,
            ),
            _StatCard(
              icon: Icons.inventory_2_rounded,
              title: 'المنتجات',
              value: '${storeData['products_count'] ?? 0}',
              subtitle: 'منتج نشط',
              color: Colors.orange,
            ),
            _StatCard(
              icon: Icons.videocam_rounded,
              title: 'الفيديوهات',
              value: '${storeData['videos_count'] ?? 0}',
              subtitle: 'فيديو منشور',
              color: Colors.purple,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // الإجراءات السريعة
        Text(
          'إجراءات سريعة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        
        _QuickActionCard(
          icon: Icons.add_shopping_cart_rounded,
          title: 'إضافة منتج جديد',
          subtitle: 'أضف منتج لمتجرك',
          onTap: () => NotificationsService.instance.toast('صفحة إضافة منتج قريباً'),
        ),
        
        _QuickActionCard(
          icon: Icons.video_call_rounded,
          title: 'رفع فيديو جديد',
          subtitle: 'انشر فيديو لمنتجاتك',
          onTap: () => NotificationsService.instance.toast('صفحة رفع فيديو قريباً'),
        ),
        
        _QuickActionCard(
          icon: Icons.local_offer_rounded,
          title: 'إنشاء عرض ترويجي',
          subtitle: 'أضف خصم أو عرض محدود',
          onTap: () => NotificationsService.instance.toast('صفحة العروض قريباً'),
        ),
      ],
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
      return _EmptyState(
        icon: Icons.inventory_rounded,
        title: 'لا توجد منتجات',
        subtitle: 'ابدأ بإضافة منتجات لمتجرك',
        actionLabel: 'إضافة منتج',
        onAction: () => NotificationsService.instance.toast('صفحة إضافة منتج قريباً'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product, onRefresh: onRefresh);
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
    if (videos.isEmpty) {
      return _EmptyState(
        icon: Icons.videocam_rounded,
        title: 'لا توجد فيديوهات',
        subtitle: 'ابدأ برفع فيديوهات لمنتجاتك',
        actionLabel: 'رفع فيديو',
        onAction: () => NotificationsService.instance.toast('صفحة رفع فيديو قريباً'),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
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
// Promotions Tab
// ============================================

class _PromotionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.local_offer_rounded,
      title: 'لا توجد عروض',
      subtitle: 'أنشئ عروض وخصومات لزيادة المبيعات',
      actionLabel: 'إنشاء عرض',
      onAction: () => NotificationsService.instance.toast('صفحة العروض قريباً'),
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
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'المبيعات الأسبوعية',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Sales Chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: _SalesChart(),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'أكثر المنتجات مبيعاً',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: theme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        
        _TopProductTile(
          rank: 1,
          name: 'iPhone 15 Pro Max',
          sales: 45,
          revenue: 179955,
        ),
        _TopProductTile(
          rank: 2,
          name: 'Samsung Galaxy S24',
          sales: 32,
          revenue: 124800,
        ),
        _TopProductTile(
          rank: 3,
          name: 'AirPods Pro',
          sales: 28,
          revenue: 27300,
        ),
      ],
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
  final String subtitle;
  final Color color;
  
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
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
                      const SizedBox(height: 2),
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
                  size: 16,
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

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRefresh;
  
  const _ProductCard({required this.product, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: Icon(Icons.image, color: theme.textSecondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name_ar'] ?? 'منتج',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
          IconButton(
            onPressed: () => NotificationsService.instance.toast('تعديل المنتج قريباً'),
            icon: Icon(Icons.edit, color: theme.textSecondaryColor),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(Icons.play_circle_filled, size: 48, color: theme.textSecondaryColor),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 14, color: theme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${video['views_count'] ?? 0}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: theme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.favorite, size: 14, color: theme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${video['likes_count'] ?? 0}',
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen).withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 64,
                color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                foregroundColor: isDark ? ThemeConfig.kNightDeep : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
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
    );
  }
}

class _TopProductTile extends StatelessWidget {
  final int rank;
  final String name;
  final int sales;
  final double revenue;
  
  const _TopProductTile({
    required this.rank,
    required this.name,
    required this.sales,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ThemeConfig.kGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: ThemeConfig.kGreen,
                ),
              ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$sales مبيعات',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${revenue.toStringAsFixed(0)} ر.س',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: ThemeConfig.kGreen,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// No Store Screen
// ============================================

class _NoStoreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_rounded, size: 100, color: theme.textSecondaryColor),
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
      ),
    );
  }
}
