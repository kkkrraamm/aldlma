import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'trends_page.dart';
import 'auth.dart';
import 'orders_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'notifications.dart';

class OrdersPage extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;
  
  const OrdersPage({Key? key, this.showAppBar = true, this.showBottomNav = false}) : super(key: key);
  
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimation;
  late AnimationController _cardsAnimation;
  int _selectedTab = 0;
  String _searchQuery = '';
  bool _showSearch = false;
  VoidCallback? _ordersListener;
  VoidCallback? _authListener;

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 1,
      'orderNumber': 'DLM-2025-001',
      'service': 'مطعم الدلما التراثي',
      'items': ['كبسة لحم', 'سلطة فتوش', 'عصير برتقال'],
      'status': 'في انتظار الدفع',
      'statusType': 'pending_payment',
      'total': '85.00',
      'totalDisplay': '85 ريال',
      'date': 'اليوم 2:30 م',
      'estimatedTime': 'في انتظار الدفع',
      'icon': '🍽️',
      'needsPayment': true,
      'providerPhone': '+966501234567',
      'progress': 25,
      'priority': 'عالية',
    },
    {
      'id': 2,
      'orderNumber': 'DLM-2025-002',
      'service': 'ورشة الماهر للصيانة',
      'items': ['صيانة مكيف', 'تنظيف فلاتر'],
      'status': 'جاري العمل',
      'statusType': 'preparing',
      'total': '150.00',
      'totalDisplay': '150 ريال',
      'date': 'أمس 10:15 ص',
      'estimatedTime': '2 ساعة متبقية',
      'icon': '🔧',
      'needsPayment': false,
      'providerPhone': '+966502345678',
      'progress': 65,
      'priority': 'متوسطة',
    },
    {
      'id': 3,
      'orderNumber': 'DLM-2025-003',
      'service': 'خدمات التنظيف المنزلي',
      'items': ['تنظيف شامل', 'غسيل سجاد'],
      'status': 'مكتمل',
      'statusType': 'completed',
      'total': '200.00',
      'totalDisplay': '200 ريال',
      'date': '15 يناير 3:45 م',
      'estimatedTime': 'تم الانتهاء',
      'icon': '🧽',
      'needsPayment': false,
      'providerPhone': '+966503456789',
      'progress': 100,
      'priority': 'منخفضة',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerAnimation = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _cardsAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    _ordersListener = () { if (mounted) setState(() {}); };
    _authListener = () { if (mounted) setState(() {}); };
    OrdersService.instance.addListener(_ordersListener!);
    AuthState.instance.addListener(_authListener!);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimation.dispose();
    _cardsAnimation.dispose();
    if (_ordersListener != null) {
      OrdersService.instance.removeListener(_ordersListener!);
    }
    if (_authListener != null) {
      AuthState.instance.removeListener(_authListener!);
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> source) {
    List<Map<String, dynamic>> filtered;
    switch (_selectedTab) {
      case 1: // قيد التنفيذ
        filtered = source.where((order) => 
          order['statusType'] == 'pending_payment' || 
          order['statusType'] == 'preparing'
        ).toList();
        break;
      case 2: // مكتمل
        filtered = source.where((order) => order['statusType'] == 'completed').toList();
        break;
      case 3: // ملغي
        filtered = source.where((order) => order['statusType'] == 'cancelled').toList();
        break;
      default: // الكل
        filtered = source;
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) =>
        order['service'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
        order['orderNumber'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeConfig>(context);
    final auth = AuthState.instance;
    final userOrders = auth.isLoggedIn && (auth.phone?.isNotEmpty ?? false)
      ? OrdersService.instance.getOrdersForPhone(auth.phone!)
      : <Map<String, dynamic>>[];
    final filteredOrders = _filterOrders(userOrders);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header - مثل الصفحة الرئيسية تماماً
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _headerAnimation,
              child: _ModernHeader(themeConfig: themeConfig),
            ),
          ),
          
          // المحتوى
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -16, 0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // شريط البحث (إذا كان مفعل)
                  if (_showSearch) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SearchBar(
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // الإحصائيات المحسنة
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _cardsAnimation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(
                        opacity: _cardsAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                'إجمالي',
                                userOrders.length.toString(),
                                Icons.inventory_2_rounded,
                                themeConfig.primaryColor,
                                0.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                'نشطة',
                                userOrders.where((o) => 
                                  o['statusType'] != 'completed' && 
                                  o['statusType'] != 'cancelled'
                                ).length.toString(),
                                Icons.access_time_rounded,
                                Colors.orange.shade600,
                                0.1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                'مكتملة',
                                userOrders.where((o) => o['statusType'] == 'completed').length.toString(),
                                Icons.check_circle_rounded,
                                Colors.green.shade600,
                                0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // التبويبات المحسنة
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeConfig.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: themeConfig.primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeConfig.primaryColor,
                                themeConfig.primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: themeConfig.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: themeConfig.isDarkMode ? Colors.white60 : Colors.grey.shade600,
                          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 12),
                          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500, fontSize: 12),
                          tabs: const [
                            Tab(height: 46, child: Center(child: Text('الكل'))),
                            Tab(height: 46, child: Center(child: Text('نشطة'))),
                            Tab(height: 46, child: Center(child: Text('مكتملة'))),
                            Tab(height: 46, child: Center(child: Text('ملغية'))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // قائمة الطلبات
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: filteredOrders.isEmpty
                      ? _EmptyState(themeConfig: themeConfig)
                      : Column(
                          children: [
                            ...filteredOrders.asMap().entries.map((entry) {
                              final index = entry.key;
                              final order = entry.value;
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(0, 0.3 + (index * 0.1)),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _cardsAnimation,
                                  curve: Interval(
                                    index * 0.1,
                                    1.0,
                                    curve: Curves.easeOutCubic,
                                  ),
                                )),
                                child: FadeTransition(
                                  opacity: _cardsAnimation,
                                  child: _ModernOrderCard(
                                    order: order,
                                    themeConfig: themeConfig,
                                    onPayment: () => _handlePayment(order),
                                    onCancel: () => _cancelOrder(order),
                                    onTrack: () => _trackOrder(order),
                                    onContact: () => _contactProvider(order),
                                    onReorder: () => _reorderService(order),
                                    onRate: () => _rateService(order),
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                            _OrdersSummary(orders: filteredOrders, themeConfig: themeConfig),
                          ],
                        ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // باقي الدوال...
  void _handlePayment(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'دفع آمن',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security_rounded, size: 64, color: ThemeConfig.instance.primaryColor),
            const SizedBox(height: 16),
            Text(
              'سيتم تحويلك للدفع الآمن\nلدفع مبلغ ${order['totalDisplay']}',
              style: GoogleFonts.cairo(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('جاري تحويلك للدفع الآمن...', style: GoogleFonts.cairo()),
                  backgroundColor: ThemeConfig.instance.primaryColor,
                ),
              );
            },
            child: const Text('دفع آمن'),
          ),
        ],
      ),
    );
  }

  void _trackOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'تتبع مباشر',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.my_location_rounded, size: 64, color: Colors.orange.shade600),
            const SizedBox(height: 16),
            Text(
              'سيتم فتح نظام التتبع المباشر للطلب رقم ${order['orderNumber']}',
              style: GoogleFonts.cairo(fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تتبع الآن'),
          ),
        ],
      ),
    );
  }

  void _contactProvider(Map<String, dynamic> order) async {
    final Uri phoneUri = Uri.parse('tel:${order['providerPhone']}');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _reorderService(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'إعادة الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل تريد إعادة طلب نفس الخدمة من ${order['service']}؟\nسيتم إنشاء طلب جديد بنفس المواصفات',
          style: GoogleFonts.cairo(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إنشاء طلب جديد بنجاح!', style: GoogleFonts.cairo()),
                  backgroundColor: ThemeConfig.instance.primaryColor,
                ),
              );
            },
            child: const Text('إعادة الطلب'),
          ),
        ],
      ),
    );
  }

  void _rateService(Map<String, dynamic> order) {
    int selectedRating = 0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'تقييم الخدمة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'كيف كانت تجربتك مع ${order['service']}؟',
                style: GoogleFonts.cairo(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setDialogState(() {
                        selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      Icons.star_rounded,
                      color: index < selectedRating 
                        ? Colors.amber.shade400 
                        : Colors.grey.shade300,
                      size: 36,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0 ? () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('شكراً لك! تم إرسال تقييمك ($selectedRating نجوم)', style: GoogleFonts.cairo()),
                    backgroundColor: ThemeConfig.instance.primaryColor,
                  ),
                );
              } : null,
              child: const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'إلغاء الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من إلغاء الطلب رقم ${order['orderNumber']}؟\nلن يتم خصم أي مبلغ',
          style: GoogleFonts.cairo(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إلغاء الطلب بنجاح'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
  }
}

// Modern Header Widget - مطابق تماماً للصفحة الرئيسية
class _ModernHeader extends StatelessWidget {
  final ThemeConfig themeConfig;
  
  const _ModernHeader({required this.themeConfig});
  
  @override
  Widget build(BuildContext context) {
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
                        'الله حيّه $name',
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
                // Title
                Text(
                  'طلباتي',
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
                    'تتبع وإدارة جميع طلباتك بسهولة',
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
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double delay;
  
  const _StatCard(this.title, this.value, this.icon, this.color, this.delay);
  
  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeConfig>(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeConfig.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: themeConfig.isDarkMode ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// Search Bar Widget
class _SearchBar extends StatelessWidget {
  final Function(String) onChanged;
  
  const _SearchBar({required this.onChanged});
  
  @override
  Widget build(BuildContext context) {
    final themeConfig = Provider.of<ThemeConfig>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: themeConfig.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeConfig.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.cairo(),
        decoration: InputDecoration(
          hintText: 'ابحث في طلباتك...',
          hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
          suffixIcon: Icon(Icons.search_rounded, color: themeConfig.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        ),
      ),
    );
  }
}

// Modern Order Card Widget
class _ModernOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final ThemeConfig themeConfig;
  final VoidCallback onPayment;
  final VoidCallback onCancel;
  final VoidCallback onTrack;
  final VoidCallback onContact;
  final VoidCallback onReorder;
  final VoidCallback onRate;
  
  const _ModernOrderCard({
    required this.order,
    required this.themeConfig,
    required this.onPayment,
    required this.onCancel,
    required this.onTrack,
    required this.onContact,
    required this.onReorder,
    required this.onRate,
  });
  
  Color _getStatusColor(String statusType) {
    switch (statusType) {
      case 'pending_payment': return Colors.blue.shade600;
      case 'preparing': return Colors.orange.shade600;
      case 'completed': return Colors.green.shade600;
      case 'cancelled': return Colors.red.shade600;
      default: return Colors.grey.shade600;
    }
  }
  
  IconData _getStatusIcon(String statusType) {
    switch (statusType) {
      case 'pending_payment': return Icons.payment_rounded;
      case 'preparing': return Icons.engineering_rounded;
      case 'completed': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.inventory_2_rounded;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order['statusType']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeConfig.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.1),
                  statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          order['icon'],
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['service'],
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: themeConfig.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'طلب #${order['orderNumber']}',
                            style: GoogleFonts.cairo(
                              color: themeConfig.isDarkMode ? Colors.white60 : Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(order['statusType']),
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order['status'],
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Progress Bar
                if (order['statusType'] != 'cancelled') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'التقدم:',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: themeConfig.isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: themeConfig.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerRight,
                            widthFactor: (order['progress'] as int) / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [statusColor, statusColor.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${order['progress']}%',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Items
                Text(
                  'العناصر المطلوبة',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: themeConfig.isDarkMode ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (order['items'] as List).map((item) => 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeConfig.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeConfig.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        item,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: themeConfig.primaryColor,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Info Cards
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        'التاريخ',
                        order['date'],
                        Icons.access_time_rounded,
                        Colors.blue.shade600,
                        themeConfig,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        'المبلغ',
                        order['totalDisplay'],
                        Icons.payments_rounded,
                        Colors.green.shade600,
                        themeConfig,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                _ActionButtons(
                  order: order,
                  themeConfig: themeConfig,
                  onPayment: onPayment,
                  onCancel: onCancel,
                  onTrack: onTrack,
                  onContact: onContact,
                  onReorder: onReorder,
                  onRate: onRate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Info Card Widget
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeConfig themeConfig;
  
  const _InfoCard(this.title, this.value, this.icon, this.color, this.themeConfig);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: themeConfig.isDarkMode ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Action Buttons Widget
class _ActionButtons extends StatelessWidget {
  final Map<String, dynamic> order;
  final ThemeConfig themeConfig;
  final VoidCallback onPayment;
  final VoidCallback onCancel;
  final VoidCallback onTrack;
  final VoidCallback onContact;
  final VoidCallback onReorder;
  final VoidCallback onRate;
  
  const _ActionButtons({
    required this.order,
    required this.themeConfig,
    required this.onPayment,
    required this.onCancel,
    required this.onTrack,
    required this.onContact,
    required this.onReorder,
    required this.onRate,
  });
  
  @override
  Widget build(BuildContext context) {
    if (order['needsPayment'] == true) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPayment,
              icon: const Icon(Icons.payment_rounded, size: 20),
              label: Text(
                'ادفع الآن - ${order['totalDisplay']}',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                'إلغاء الطلب',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade600, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (order['statusType'] == 'preparing') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onTrack,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                'تتبع',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onContact,
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                'اتصال',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade600,
                side: BorderSide(color: Colors.green.shade600, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (order['statusType'] == 'completed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReorder,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'إعادة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: themeConfig.primaryColor,
                side: BorderSide(color: themeConfig.primaryColor, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onRate,
              icon: const Icon(Icons.star_rounded, size: 18),
              label: Text(
                'تقييم',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }
}

// Orders Summary Widget
class _OrdersSummary extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final ThemeConfig themeConfig;
  
  const _OrdersSummary({required this.orders, required this.themeConfig});
  
  @override
  Widget build(BuildContext context) {
    final totalAmount = orders.fold<double>(
      0.0, 
      (sum, order) => sum + double.parse(order['total'])
    );
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeConfig.primaryColor.withOpacity(0.1),
            themeConfig.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeConfig.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'ملخص الطلبات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: themeConfig.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem('عدد الطلبات', orders.length.toString(), Icons.receipt_long_rounded, themeConfig),
              _SummaryItem('إجمالي المبلغ', '${totalAmount.toStringAsFixed(0)} ريال', Icons.payments_rounded, themeConfig),
              _SummaryItem('متوسط الطلب', '${(totalAmount / orders.length).toStringAsFixed(0)} ريال', Icons.trending_up_rounded, themeConfig),
            ],
          ),
        ],
      ),
    );
  }
}

// Summary Item Widget
class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final ThemeConfig themeConfig;
  
  const _SummaryItem(this.title, this.value, this.icon, this.themeConfig);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: themeConfig.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: themeConfig.primaryColor,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: themeConfig.isDarkMode ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  final ThemeConfig themeConfig;
  
  const _EmptyState({required this.themeConfig});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeConfig.primaryColor.withOpacity(0.1),
                  themeConfig.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: themeConfig.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد طلبات',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: themeConfig.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ابدأ بطلب خدمة من الصفحة الرئيسية\nواستمتع بخدمات الدلما المميزة',
            style: GoogleFonts.cairo(
              color: themeConfig.isDarkMode ? Colors.white60 : Colors.grey.shade600,
              fontSize: 15,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Login Button Widget - مطابق للصفحة الرئيسية
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

// Theme Toggle Button Widget - مطابق للصفحة الرئيسية
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
