// lib/provider_dashboard_integration_example.dart
// مثال عملي كامل لـ integration ProviderDashboardNew

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'provider_dashboard_new.dart';
import 'api_config.dart';
import 'notifications.dart';
import 'theme_config.dart';

class ProviderDashboardIntegrationExample extends StatefulWidget {
  const ProviderDashboardIntegrationExample({super.key});

  @override
  State<ProviderDashboardIntegrationExample> createState() =>
      _ProviderDashboardIntegrationExampleState();
}

class _ProviderDashboardIntegrationExampleState
    extends State<ProviderDashboardIntegrationExample> {
  
  Map<String, dynamic>? _providerRequest;
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadProviderStatus();
  }

  Future<void> _loadProviderStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLoginDialog();
        }
        return;
      }

      // استدعاء API لجلب حالة الطلب
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/provider/request'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _providerRequest = data['request'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ خطأ في تحميل حالة المزود: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    if (_providerRequest == null) {
      NotificationsService.instance.toast('لم يتم العثور على بيانات المزود');
      return;
    }

    if (_providerRequest!['status'] != 'approved') {
      NotificationsService.instance.toast(
        'لا يمكن الدخول: حالة الطلب ${_providerRequest!['status']}',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProviderDashboardNew(),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تسجيل الدخول مطلوب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'يجب تسجيل الدخول أولاً للوصول إلى لوحة التحكم',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // اذهب إلى صفحة تسجيل الدخول
              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              'تسجيل الدخول',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'لوحة التحكم',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.textPrimaryColor,
          ),
        ),
      );
    }

    if (_providerRequest == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'لوحة التحكم',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_rounded,
                size: 80,
                color: theme.textSecondaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'لم يتم العثور على البيانات',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى المحاولة لاحقاً',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: theme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status = _providerRequest!['status'] ?? 'pending';
    final isApproved = status == 'approved';
    final storeName = _providerRequest!['business_name'] ?? 'متجري';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'لوحة التحكم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card - Status
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.borderColor),
                gradient: LinearGradient(
                  colors: [
                    isApproved
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: isApproved ? Colors.green : Colors.orange,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: theme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isApproved
                                  ? 'حالة: موافق عليه ✅'
                                  : 'حالة: ${_getStatusInArabic(status)}',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: isApproved
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card - Dashboard Button
            if (isApproved)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ThemeConfig.kGreen,
                      ThemeConfig.kGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeConfig.kGreen.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _navigateToDashboard,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'دخول لوحة التحكم',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'إدارة منتجاتك وفيديوهاتك وإحصائياتك',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'اضغط للمتابعة',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderColor),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: Colors.orange,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري المراجعة',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يتم مراجعة طلبك من قبل الفريق\nسيتم إخطارك عند الموافقة',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: theme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Info Section
            Text(
              'معلومات الطلب',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Info Items
            _InfoItem(
              icon: Icons.store_rounded,
              label: 'نوع الخدمة',
              value: _providerRequest!['service_type'] ?? 'غير محدد',
            ),
            _InfoItem(
              icon: Icons.email_rounded,
              label: 'البريد الإلكتروني',
              value: _providerRequest!['email'] ?? 'غير محدد',
            ),
            _InfoItem(
              icon: Icons.phone_rounded,
              label: 'رقم الهاتف',
              value: _providerRequest!['phone'] ?? 'غير محدد',
            ),
            if (_providerRequest!['location_address'] != null)
              _InfoItem(
                icon: Icons.location_on_rounded,
                label: 'الموقع',
                value: _providerRequest!['location_address'] is String
                    ? _parseLocation(_providerRequest!['location_address'])
                    : 'غير محدد',
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusInArabic(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'موافق عليه';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  String _parseLocation(String locationJson) {
    try {
      final data = json.decode(locationJson);
      return data['location'] ?? 'غير محدد';
    } catch (_) {
      return 'غير محدد';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: theme.textPrimaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: theme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: theme.textPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
