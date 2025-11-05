// lib/media_dashboard.dart
// Dalma Media Dashboard – لوحة تحكم الإعلامي (Luxury, Glass, Dynamic Theme)
// بيانات حقيقية من API + تكامل كامل + تصميم فخم مثل صفحة حسابي
// by Abdulkarim ✨

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';
import 'auth.dart';
import 'media_add_post_page.dart';
import 'media_posts_page.dart';
import 'my_account_oasis.dart';
import 'media_profile_edit_page.dart';
import 'media_followers_page.dart';
import 'media_detailed_stats_page.dart';
import 'media_notifications_page.dart';
import 'media_public_profile_page.dart';

class DalmaMediaDashboard extends StatefulWidget {
  const DalmaMediaDashboard({super.key});

  @override
  State<DalmaMediaDashboard> createState() => _DalmaMediaDashboardState();
}

class _DalmaMediaDashboardState extends State<DalmaMediaDashboard> with TickerProviderStateMixin {
  final String _baseUrl = ApiConfig.baseUrl;
  String? _token;
  bool _isLoading = true;
  
  // بيانات المستخدم
  String _userName = '';
  String _userPhone = '';
  String? _profileImageUrl;
  
  // إحصائيات الإعلامي
  int _totalViews = 0;
  int _totalFollowers = 0;
  int _totalPosts = 0;
  int _monthlyReach = 0;
  double _engagementRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMediaData();
  }

  Future<void> _loadMediaData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      if (_token == null) {
        throw Exception('No token found');
      }

      // جلب بيانات المستخدم
      final userResponse = await http.get(
        Uri.parse('$_baseUrl/api/me'),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-API-Key': ApiConfig.apiKey,
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        setState(() {
          _userName = userData['name'] ?? '';
          _userPhone = userData['phone'] ?? '';
          _profileImageUrl = userData['profile_image'];
        });
      }

      // جلب إحصائيات الإعلامي
      final statsResponse = await http.get(
        Uri.parse('$_baseUrl/api/media/stats'),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-API-Key': ApiConfig.apiKey,
        },
      );

      if (statsResponse.statusCode == 200) {
        final statsData = json.decode(statsResponse.body);
        final stats = statsData['stats'];
        if (mounted) {
          setState(() {
            _totalViews = stats['totalViews'] ?? 0;
            _totalFollowers = stats['totalFollowers'] ?? 0;
            _totalPosts = stats['totalPosts'] ?? 0;
            _monthlyReach = stats['monthlyReach'] ?? 0;
            // تحويل engagementRate من String إلى double
            if (stats['engagementRate'] is String) {
              _engagementRate = double.tryParse(stats['engagementRate']) ?? 0.0;
            } else {
              _engagementRate = (stats['engagementRate'] ?? 0.0).toDouble();
            }
          });
        }
      }
    } catch (e) {
      print('❌ [MEDIA DASHBOARD] Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // AppBar فخم مع Glass Effect
                SliverAppBar(
                  expandedHeight: 280,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    // زر العودة لحساب المستخدم
                    IconButton(
                      icon: Icon(Icons.person_outline_rounded, color: theme.textPrimaryColor),
                      onPressed: () {
                        // العودة لصفحة My Account
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DalmaMyAccountOasis()),
                        );
                      },
                      tooltip: 'العودة لحسابي',
                    ),
                    IconButton(
                      icon: Icon(Icons.settings_rounded, color: theme.textPrimaryColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MediaProfileEditPage()),
                        );
                      },
                      tooltip: 'إعدادات الحساب',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // خلفية متدرجة
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                primaryColor.withOpacity(0.3),
                                theme.backgroundColor,
                              ],
                            ),
                          ),
                        ),
                        // Glass Effect
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: theme.backgroundColor.withOpacity(0.3),
                          ),
                        ),
                        // محتوى الـ Header
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // صورة البروفايل
                                Hero(
                                  tag: 'profile_image',
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryColor,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _profileImageUrl != null
                                          ? Image.network(
                                              _profileImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                                            )
                                          : _buildDefaultAvatar(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // اسم المستخدم
                                Text(
                                  _userName,
                                  style: GoogleFonts.cairo(
                                    color: theme.textPrimaryColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // شارة "إعلامي موثق"
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'إعلامي موثق',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // الإحصائيات الرئيسية (2x2 Grid)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard(
                          icon: Icons.visibility_rounded,
                          label: 'المشاهدات',
                          value: _formatNumber(_totalViews),
                          color: Colors.blue,
                          onTap: null,
                        ),
                        _buildStatCard(
                          icon: Icons.people_rounded,
                          label: 'المتابعين',
                          value: _formatNumber(_totalFollowers),
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MediaFollowersPage()),
                            );
                          },
                        ),
                        _buildStatCard(
                          icon: Icons.article_rounded,
                          label: 'المنشورات',
                          value: _formatNumber(_totalPosts),
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MediaPostsPage()),
                            );
                          },
                        ),
                        _buildStatCard(
                          icon: Icons.trending_up_rounded,
                          label: 'الوصول الشهري',
                          value: _formatNumber(_monthlyReach),
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MediaDetailedStatsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // معدل التفاعل
                if (_engagementRate > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: Colors.pink,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'معدل التفاعل',
                                    style: GoogleFonts.cairo(
                                      color: Provider.of<ThemeConfig>(context).textSecondaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${_engagementRate.toStringAsFixed(1)}%',
                                    style: GoogleFonts.cairo(
                                      color: Provider.of<ThemeConfig>(context).textPrimaryColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Provider.of<ThemeConfig>(context).textSecondaryColor,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // الإجراءات السريعة
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _SectionCard(
                      title: 'إجراءات سريعة',
                      icon: Icons.bolt_rounded,
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.add_circle_rounded,
                            label: 'إضافة منشور جديد',
                            color: primaryColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MediaAddPostPage()),
                              ).then((_) => _loadMediaData());
                            },
                          ),
                          _ActionRow(
                            icon: Icons.article_rounded,
                            label: 'إدارة المنشورات',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MediaPostsPage()),
                              );
                            },
                          ),
                          _ActionRow(
                            icon: Icons.bar_chart_rounded,
                            label: 'الإحصائيات التفصيلية',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MediaDetailedStatsPage()),
                              );
                            },
                          ),
                          _ActionRow(
                            icon: Icons.notifications_rounded,
                            label: 'الإشعارات',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MediaNotificationsPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // إعدادات الحساب
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _SectionCard(
                      title: 'إعدادات الحساب',
                      icon: Icons.settings_rounded,
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.public_rounded,
                            label: 'إدارة البروفايل العام',
                            subtitle: 'البايو وطرق التواصل',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MediaPublicProfilePage()),
                              ).then((_) => _loadMediaData());
                            },
                          ),
                          _ActionRow(
                            icon: Icons.edit_rounded,
                            label: 'تعديل الملف الشخصي',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MediaProfileEditPage()),
                              ).then((_) => _loadMediaData());
                            },
                          ),
                          _ActionRow(
                            icon: Icons.people_rounded,
                            label: 'قائمة المتابعين',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MediaFollowersPage()),
                              );
                            },
                          ),
                          _ActionRow(
                            icon: isDark ? Icons.wb_sunny : Icons.nightlight_round,
                            label: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
                            onTap: () async {
                              await ThemeConfig.instance.toggleTheme();
                            },
                          ),
                          const Divider(height: 1, thickness: 1),
                          _ActionRow(
                            icon: Icons.exit_to_app_rounded,
                            label: 'العودة لحسابي الشخصي',
                            subtitle: 'عرض كمستخدم عادي',
                            color: primaryColor,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const DalmaMyAccountOasis()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // مساحة إضافية في الأسفل
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
    );
  }

  Widget _buildDefaultAvatar() {
    final theme = Provider.of<ThemeConfig>(context, listen: false);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;
    
    return Container(
      color: primaryColor.withOpacity(0.2),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : '📺',
          style: GoogleFonts.cairo(
            color: primaryColor,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return GestureDetector(
      onTap: onTap,
      child: _GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(
                color: theme.textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: theme.textSecondaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 Reusable Widgets (Glass Card, Section Card, Action Row)
// ═══════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.borderColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ActionRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = color ?? (isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      color: theme.textPrimaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.cairo(
                        color: theme.textSecondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
