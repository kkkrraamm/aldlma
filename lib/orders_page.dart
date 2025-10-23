import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trends_page.dart';
import 'auth.dart';
import 'orders_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersPage extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;
  
  const OrdersPage({Key? key, this.showAppBar = true, this.showBottomNav = false}) : super(key: key);
  
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _searchController;
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
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // استمع لتغييرات الطلبات وحالة الدخول لتحديث العرض ديناميكيًا
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
    _searchController.dispose();
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
    final auth = AuthState.instance;
    final userOrders = auth.isLoggedIn && (auth.phone?.isNotEmpty ?? false)
      ? OrdersService.instance.getOrdersForPhone(auth.phone!)
      : <Map<String, dynamic>>[];
    final filteredOrders = _filterOrders(userOrders);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9ED),
      body: CustomScrollView(
        slivers: [
          // Header بسيط ونظيف (فقط عند عرض AppBar)
          if (widget.showAppBar)
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
            title: Row(
              children: [
                Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'طلباتي',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _searchQuery = '';
                  });
                },
              ),
            ],
          ),
          
          // هيدر بسيط عند عدم عرض AppBar
          if (!widget.showAppBar)
            SliverToBoxAdapter(
              child: Container(
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
                          width: 150,
                          height: 150,
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
                          width: 120,
                          height: 120,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/img/lbaty.png',
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'طلباتي',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تتبع وإدارة جميع طلباتك بسهولة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // شريط البحث (إذا كان مفعل)
                if (_showSearch) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SearchBar(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // الإحصائيات في مكان مثالي
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          'إجمالي',
                          userOrders.length.toString(),
                          Icons.inventory_2,
                          Colors.blue.shade600,
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
                          Icons.access_time,
                          Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          'مكتملة',
                          userOrders.where((o) => o['statusType'] == 'completed').length.toString(),
                          Icons.check_circle,
                          Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // التبويبات المحسنة
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Container(
                    height: 50,
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 11),
                      unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500, fontSize: 11),
                      tabs: const [
                        Tab(
                          height: 42,
                          child: Center(child: Text('الكل')),
                        ),
                        Tab(
                          height: 42,
                          child: Center(child: Text('نشطة')),
                        ),
                        Tab(
                          height: 42,
                          child: Center(child: Text('مكتملة')),
                        ),
                        Tab(
                          height: 42,
                          child: Center(child: Text('ملغية')),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // قائمة الطلبات المحسنة
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: filteredOrders.isEmpty
                    ? _EmptyState()
                    : Column(
                        children: [
                          ...filteredOrders.map((order) => _AdvancedOrderCard(order)),
                          const SizedBox(height: 20),
                          _OrdersSummary(filteredOrders),
                        ],
                      ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.showBottomNav ? null : FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        label: Text('طلب جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _StatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _SearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'ابحث في طلباتك...',
          suffixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _AdvancedOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(order['statusType']).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _getStatusColor(order['statusType']).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // هيدر الطلب المتقدم
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(order['statusType']).withOpacity(0.1),
                  _getStatusColor(order['statusType']).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // أيقونة الخدمة المحسنة
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(order['statusType']).withOpacity(0.2),
                            _getStatusColor(order['statusType']).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(order['statusType']).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          order['icon'],
                          style: const TextStyle(fontSize: 24),
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
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'طلب #${order['orderNumber']}',
                                style: GoogleFonts.cairo(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(order['priority']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  order['priority'],
                                  style: GoogleFonts.cairo(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: _getPriorityColor(order['priority']),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // شارة الحالة المتقدمة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['statusType']),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(order['statusType']).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIconData(order['statusType']),
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order['status'],
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // شريط التقدم المتقدم
                if (order['statusType'] != 'cancelled') ...[
                  Row(
                    children: [
                      Text(
                        'التقدم:',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerRight,
                            widthFactor: (order['progress'] as int) / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getStatusColor(order['statusType']),
                                    _getStatusColor(order['statusType']).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${order['progress']}%',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(order['statusType']),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // محتوى الطلب
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العناصر المطلوبة
                _SectionTitle('العناصر المطلوبة'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (order['items'] as List).map((item) => 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // معلومات الطلب
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        'التاريخ',
                        order['date'],
                        Icons.access_time,
                        Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoCard(
                        'المبلغ',
                        order['totalDisplay'],
                        Icons.payments,
                        Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // أزرار العمليات المتقدمة
                _ActionButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _SectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _InfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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

  Widget _ActionButtons(Map<String, dynamic> order) {
    if (order['needsPayment'] == true) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handlePayment(order),
              icon: const Icon(Icons.payment, size: 20),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelOrder(order),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(
                'إلغاء الطلب',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade600),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
              onPressed: () => _trackOrder(order),
              icon: const Icon(Icons.my_location, size: 18),
              label: Text(
                'تتبع مباشر',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
              onPressed: () => _contactProvider(order),
              icon: const Icon(Icons.phone, size: 18),
              label: Text(
                'اتصال',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade600,
                side: BorderSide(color: Colors.green.shade600),
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
              onPressed: () => _reorderService(order),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'إعادة الطلب',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
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
              onPressed: () => _rateService(order),
              icon: const Icon(Icons.star, size: 18),
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

  Widget _OrdersSummary(List<Map<String, dynamic>> orders) {
    final totalAmount = orders.fold<double>(
      0.0, 
      (sum, order) => sum + double.parse(order['total'])
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'ملخص الطلبات',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem('عدد الطلبات', orders.length.toString(), Icons.receipt_long),
              _SummaryItem('إجمالي المبلغ', '${totalAmount.toStringAsFixed(0)} ريال', Icons.payments),
              _SummaryItem('متوسط الطلب', '${(totalAmount / orders.length).toStringAsFixed(0)} ريال', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _SummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _EmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد طلبات',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بطلب خدمة من الصفحة الرئيسية\nواستمتع بخدمات الدلما المميزة',
            style: GoogleFonts.cairo(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getStatusIconData(String statusType) {
    switch (statusType) {
      case 'pending_payment': return Icons.payment;
      case 'preparing': return Icons.engineering;
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.inventory_2;
    }
  }

  Color _getStatusColor(String statusType) {
    switch (statusType) {
      case 'pending_payment': return Colors.blue.shade600;
      case 'preparing': return Colors.orange.shade600;
      case 'completed': return Colors.green.shade600;
      case 'cancelled': return Colors.red.shade600;
      default: return Colors.grey.shade600;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'عالية': return Colors.red.shade600;
      case 'متوسطة': return Colors.orange.shade600;
      case 'منخفضة': return Colors.green.shade600;
      default: return Colors.grey.shade600;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'فلترة الطلبات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'استخدم التبويبات أعلاه لفلترة الطلبات حسب الحالة',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _handlePayment(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'دفع آمن',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'سيتم تحويلك للدفع الآمن من شركة كارمار\nلدفع مبلغ ${order['totalDisplay']}',
              style: GoogleFonts.cairo(),
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
                  content: Text('جاري تحويلك للدفع الآمن من كارمار...'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تتبع مباشر',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.my_location, size: 48, color: Colors.orange.shade600),
            const SizedBox(height: 16),
            Text(
              'سيتم فتح نظام التتبع المباشر المطور من شركة كارمار للطلب رقم ${order['orderNumber']}',
              style: GoogleFonts.cairo(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'إعادة الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل تريد إعادة طلب نفس الخدمة من ${order['service']}؟\nسيتم إنشاء طلب جديد بنفس المواصفات',
          style: GoogleFonts.cairo(),
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
                  content: Text('تم إنشاء طلب جديد بنجاح!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تقييم الخدمة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'كيف كانت تجربتك مع ${order['service']}؟',
                style: GoogleFonts.cairo(),
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
                      Icons.star,
                      color: index < selectedRating 
                        ? Colors.amber.shade400 
                        : Colors.grey.shade300,
                      size: 32,
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
                    content: Text('شكراً لك! تم إرسال تقييمك ($selectedRating نجوم)'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'إلغاء الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من إلغاء الطلب رقم ${order['orderNumber']}؟\nلن يتم خصم أي مبلغ',
          style: GoogleFonts.cairo(),
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