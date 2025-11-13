import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_config.dart';
import 'api_config.dart';

class MyRfpsPage extends StatefulWidget {
  const MyRfpsPage({super.key});

  @override
  State<MyRfpsPage> createState() => _MyRfpsPageState();
}

class _MyRfpsPageState extends State<MyRfpsPage> {
  List<dynamic> _rfps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRfps();
  }

  Future<void> _loadRfps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/realty/my-rfps'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rfps = data['rfps'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('فشل تحميل الطلبات');
      }
    } catch (e) {
      debugPrint('❌ [MY RFPS] خطأ: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      appBar: AppBar(
        title: Text(
          'طلباتي',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            )
          : _rfps.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rfps.length,
                  itemBuilder: (context, index) {
                    return _buildRfpCard(_rfps[index], theme);
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قدم طلب خاص واحصل على عروض من المكاتب',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRfpCard(dynamic rfp, ThemeConfig theme) {
    final bidsCount = rfp['bids_count'] ?? 0;
    final status = rfp['status'] ?? 'open';
    final createdAt = DateTime.parse(rfp['created_at']);
    final timeAgo = _getTimeAgo(createdAt);

    return GestureDetector(
      onTap: () => _showBids(rfp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_getTypeLabel(rfp['type'])} ${_getStatusLabel(rfp['status'])}',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status == 'open' ? 'مفتوح' : status == 'closed' ? 'مغلق' : 'ملغي',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // التفاصيل
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: theme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  rfp['city'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: theme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // الميزانية
            if (rfp['budget_min'] != null || rfp['budget_max'] != null)
              Text(
                'الميزانية: ${_formatBudget(rfp['budget_min'], rfp['budget_max'])}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: theme.textSecondaryColor,
                ),
              ),
            const SizedBox(height: 12),

            // العروض
            Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 18,
                  color: bidsCount > 0 ? theme.primaryColor : theme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '$bidsCount ${bidsCount == 1 ? 'عرض' : 'عروض'}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: bidsCount > 0 ? theme.primaryColor : theme.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                if (bidsCount > 0)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.textSecondaryColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBids(dynamic rfp) {
    // TODO: عرض العروض في صفحة منفصلة أو bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Provider.of<ThemeConfig>(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'العروض المستلمة',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Text(
                    'جاري تحميل العروض...',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
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

  String _getTypeLabel(String? type) {
    const types = {
      'apartment': 'شقة',
      'villa': 'فيلا',
      'land': 'أرض',
      'building': 'عمارة',
      'farm': 'مزرعة',
      'warehouse': 'مستودع',
      'office': 'مكتب',
      'shop': 'محل',
    };
    return types[type] ?? type ?? '';
  }

  String _getStatusLabel(String? status) {
    if (status == 'for_sale') return 'للبيع';
    if (status == 'for_rent') return 'للإيجار';
    return '';
  }

  Color _getStatusColor(String status) {
    if (status == 'open') return Colors.green;
    if (status == 'closed') return Colors.grey;
    return Colors.red;
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return 'منذ ${diff.inDays} ${diff.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (diff.inHours > 0) {
      return 'منذ ${diff.inHours} ${diff.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (diff.inMinutes > 0) {
      return 'منذ ${diff.inMinutes} ${diff.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  String _formatBudget(dynamic min, dynamic max) {
    if (min == null && max == null) return 'غير محدد';
    
    final minStr = min != null ? _formatPrice(min) : '';
    final maxStr = max != null ? _formatPrice(max) : '';
    
    if (min != null && max != null) {
      return '$minStr - $maxStr ر.س';
    } else if (min != null) {
      return 'من $minStr ر.س';
    } else {
      return 'حتى $maxStr ر.س';
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
}


