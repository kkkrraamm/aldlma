import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme_config.dart';
import 'auth.dart';
import 'media_add_post_page.dart';
import 'media_posts_page.dart';
import 'media_profile_edit_page.dart';
import 'media_followers_page.dart';
import 'media_detailed_stats_page.dart';
import 'media_notifications_page.dart';

/// 📺 صفحة إدارة الإعلامي - Dalma Media Dashboard
/// تعرض إحصائيات الإعلامي، إدارة المحتوى، والإعدادات
class DalmaMediaDashboard extends StatefulWidget {
  const DalmaMediaDashboard({Key? key}) : super(key: key);

  @override
  State<DalmaMediaDashboard> createState() => _DalmaMediaDashboardState();
}

class _DalmaMediaDashboardState extends State<DalmaMediaDashboard> {
  bool _isLoading = true;
  String _userName = '';
  String _userPhone = '';
  String? _profileImageUrl;
  
  // إحصائيات الإعلامي
  int _totalViews = 0;
  int _totalFollowers = 0;
  int _totalPosts = 0;
  int _monthlyReach = 0;

  @override
  void initState() {
    super.initState();
    _loadMediaData();
  }

  Future<void> _loadMediaData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final baseUrl = 'https://dalma-api.onrender.com';

      if (token == null) {
        throw Exception('No token found');
      }

      // جلب بيانات الإعلامي
      final response = await http.get(
        Uri.parse('$baseUrl/api/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userName = data['name'] ?? '';
          _userPhone = data['phone'] ?? '';
          _profileImageUrl = data['profile_image'];
        });

        // جلب إحصائيات الإعلامي الحقيقية
        final statsResponse = await http.get(
          Uri.parse('$baseUrl/api/media/stats'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
          },
        );

        if (statsResponse.statusCode == 200) {
          final statsData = json.decode(statsResponse.body);
          final stats = statsData['stats'];
          setState(() {
            _totalViews = stats['totalViews'] ?? 0;
            _totalFollowers = stats['totalFollowers'] ?? 0;
            _totalPosts = stats['totalPosts'] ?? 0;
            _monthlyReach = stats['monthlyReach'] ?? 0;
          });
        } else {
          print('❌ [MEDIA STATS] Error: ${statsResponse.statusCode}');
          // استخدام قيم افتراضية في حالة الخطأ
          setState(() {
            _totalViews = 0;
            _totalFollowers = 0;
            _totalPosts = 0;
            _monthlyReach = 0;
          });
        }
      }
    } catch (e) {
      print('❌ [MEDIA DASHBOARD] Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.instance;
    final isDarkMode = themeConfig.isDarkMode;
    final primaryColor = themeConfig.primaryColor;
    final accentColor = themeConfig.accentColor;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverToBoxAdapter(
            child: _buildHeroHeader(isDarkMode, primaryColor, accentColor),
          ),
          
          // المحتوى الرئيسي
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildDashboardContent(isDarkMode, primaryColor, accentColor),
          ),
        ],
      ),
    );
  }

  /// 🎭 بناء Hero Header
  Widget _buildHeroHeader(bool isDarkMode, Color primaryColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDarkMode 
              ? [const Color(0xFF1a1a1a), const Color(0xFF2d2d2d)]
              : [primaryColor, accentColor],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            children: [
              // الصورة الشخصية والمعلومات
              Row(
                children: [
                  // Profile Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
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
                  
                  const SizedBox(width: 16),
                  
                  // Name & Phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // شارة التوثيق
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'إعلامي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Settings Button
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MediaProfileEditPage()),
                      ).then((value) {
                        if (value == true) {
                          _loadMediaData(); // إعادة تحميل البيانات
                        }
                      });
                    },
                    icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 👤 بناء Avatar افتراضي
  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF10B981),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : '؟',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 📊 بناء محتوى Dashboard
  Widget _buildDashboardContent(bool isDarkMode, Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          const Text(
            '📊 لوحة التحكم',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // الإحصائيات (2x2 Grid)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                icon: Icons.visibility,
                title: 'المشاهدات',
                value: _formatNumber(_totalViews),
                color: const Color(0xFF10B981),
                isDarkMode: isDarkMode,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MediaFollowersPage()),
                  );
                },
                child: _buildStatCard(
                  icon: Icons.people,
                  title: 'المتابعون',
                  value: _formatNumber(_totalFollowers),
                  color: const Color(0xFF3B82F6),
                  isDarkMode: isDarkMode,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MediaPostsPage()),
                  ).then((value) => _loadMediaData());
                },
                child: _buildStatCard(
                  icon: Icons.article,
                  title: 'المنشورات',
                  value: _formatNumber(_totalPosts),
                  color: const Color(0xFFF59E0B),
                  isDarkMode: isDarkMode,
                ),
              ),
              _buildStatCard(
                icon: Icons.trending_up,
                title: 'الوصول الشهري',
                value: _formatNumber(_monthlyReach),
                color: const Color(0xFFEC4899),
                isDarkMode: isDarkMode,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // الإجراءات السريعة
          const Text(
            '⚡ إجراءات سريعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActionButton(
            icon: Icons.add_circle,
            title: 'إضافة منشور جديد',
            subtitle: 'شارك محتوى مع جمهورك',
            color: const Color(0xFF10B981),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MediaAddPostPage()),
              ).then((value) {
                if (value == true) {
                  _loadMediaData(); // إعادة تحميل البيانات
                }
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            icon: Icons.bar_chart,
            title: 'الإحصائيات التفصيلية',
            subtitle: 'تحليل الأداء والتفاعل',
            color: const Color(0xFF3B82F6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MediaDetailedStatsPage()),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            icon: Icons.notifications,
            title: 'الإشعارات',
            subtitle: 'إدارة التنبيهات والرسائل',
            color: const Color(0xFFF59E0B),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MediaNotificationsPage()),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // زر تسجيل الخروج
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('تسجيل الخروج'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await AuthState.instance.logout();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 📈 بناء بطاقة إحصائية
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2d2d2d) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.6) 
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔘 بناء زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2d2d2d) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.6) 
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.3) 
                    : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔢 تنسيق الأرقام
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

