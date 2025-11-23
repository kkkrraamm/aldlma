import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/theme_config.dart';
import 'config/api_config.dart';
import 'auth.dart';
import 'notifications_service.dart';

/// صفحة لوحة تحكم مقدم الخدمة
class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({Key? key}) : super(key: key);

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  late final AuthState _authState;
  bool _isLoading = true;
  Map<String, dynamic>? _providerData;

  @override
  void initState() {
    super.initState();
    _authState = AuthState.instance;
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      final token = _authState.token;
      if (token == null) {
        NotificationsService.instance.toast('برجاء تسجيل الدخول أولاً');
        return;
      }

      final response = await ApiConfig.dio.get(
        '/api/me',
        options: ApiConfig.authorizedOptions(token),
      );

      if (response.statusCode == 200) {
        setState(() {
          _providerData = response.data['user'];
          _isLoading = false;
        });
      }
    } catch (e) {
      NotificationsService.instance.toast('خطأ في تحميل بيانات المتجر');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 2,
        title: Text(
          'لوحة تحكم المتجر',
          style: GoogleFonts.cairo(
            color: theme.textPrimaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس المتجر
                  _buildStoreHeader(isDark),
                  const SizedBox(height: 20),

                  // الإحصائيات
                  _buildStats(isDark),
                  const SizedBox(height: 20),

                  // الخيارات الرئيسية
                  _buildMenuOptions(isDark),
                  const SizedBox(height: 20),

                  // معلومات إضافية
                  _buildAdditionalInfo(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildStoreHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  ThemeConfig.kGoldNight.withOpacity(0.2),
                  ThemeConfig.kGoldNight.withOpacity(0.05),
                ]
              : [
                  ThemeConfig.kGreen.withOpacity(0.2),
                  ThemeConfig.kGreen.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ThemeConfig.kGoldNight.withOpacity(0.2)
              : ThemeConfig.kGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _providerData?['name'] ?? 'متجري',
                      style: GoogleFonts.cairo(
                        color: ThemeConfig.instance.textPrimaryColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'حالة: نشط ✓',
                      style: GoogleFonts.cairo(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('المنتجات', '0', Icons.shopping_bag_rounded, isDark),
        _buildStatCard('الطلبات', '0', Icons.receipt_long_rounded, isDark),
        _buildStatCard('الزيارات', '0', Icons.visibility_rounded, isDark),
        _buildStatCard('التقييم', '5.0', Icons.star_rounded, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? ThemeConfig.kGoldNight.withOpacity(0.1)
            : ThemeConfig.kGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? ThemeConfig.kGoldNight.withOpacity(0.2)
              : ThemeConfig.kGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              color: ThemeConfig.instance.textPrimaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: ThemeConfig.instance.textSecondaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخيارات',
          style: GoogleFonts.cairo(
            color: ThemeConfig.instance.textPrimaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        _buildMenuOption('إدارة المنتجات', Icons.shopping_bag_rounded, isDark, () {
          NotificationsService.instance.toast('سيتم إضافة إدارة المنتجات قريبًا');
        }),
        const SizedBox(height: 8),
        _buildMenuOption('إدارة الطلبات', Icons.receipt_long_rounded, isDark, () {
          NotificationsService.instance.toast('سيتم إضافة إدارة الطلبات قريبًا');
        }),
        const SizedBox(height: 8),
        _buildMenuOption('التحليلات', Icons.bar_chart_rounded, isDark, () {
          NotificationsService.instance.toast('سيتم إضافة التحليلات قريبًا');
        }),
        const SizedBox(height: 8),
        _buildMenuOption('إعدادات المتجر', Icons.settings_rounded, isDark, () {
          NotificationsService.instance.toast('سيتم إضافة الإعدادات قريبًا');
        }),
      ],
    );
  }

  Widget _buildMenuOption(String label, IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? ThemeConfig.kGoldNight.withOpacity(0.08)
              : ThemeConfig.kGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? ThemeConfig.kGoldNight.withOpacity(0.15)
                : ThemeConfig.kGreen.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  color: ThemeConfig.instance.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: ThemeConfig.instance.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات المتجر',
            style: GoogleFonts.cairo(
              color: ThemeConfig.instance.textPrimaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('البريد الإلكتروني', _providerData?['email'] ?? '---'),
          const SizedBox(height: 10),
          _buildInfoRow('الهاتف', _providerData?['phone'] ?? '---'),
          const SizedBox(height: 10),
          _buildInfoRow('الموقع', _providerData?['city'] ?? '---'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: ThemeConfig.instance.textSecondaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: ThemeConfig.instance.textPrimaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
