import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme_config.dart';

/// 📊 صفحة الإحصائيات التفصيلية للإعلامي
class MediaDetailedStatsPage extends StatefulWidget {
  const MediaDetailedStatsPage({Key? key}) : super(key: key);

  @override
  State<MediaDetailedStatsPage> createState() => _MediaDetailedStatsPageState();
}

class _MediaDetailedStatsPageState extends State<MediaDetailedStatsPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  final String _baseUrl = 'https://dalma-api.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadDetailedStats();
  }

  Future<void> _loadDetailedStats() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/media/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _stats = json.decode(response.body);
        });
      }
    } catch (e) {
      print('❌ [STATS] Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.instance;
    final isDarkMode = themeConfig.isDarkMode;
    final primaryColor = isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 الإحصائيات التفصيلية'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetailedStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // إحصائيات عامة
                  _buildSectionTitle('📈 الإحصائيات العامة', isDarkMode),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('المشاهدات', _stats['total_views'] ?? 0, Icons.visibility, const Color(0xFF10B981), isDarkMode)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('المتابعون', _stats['total_followers'] ?? 0, Icons.people, const Color(0xFF3B82F6), isDarkMode)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('المنشورات', _stats['total_posts'] ?? 0, Icons.article, const Color(0xFFF59E0B), isDarkMode)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('الوصول الشهري', _stats['monthly_reach'] ?? 0, Icons.trending_up, const Color(0xFFEC4899), isDarkMode)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // معدل التفاعل
                  _buildSectionTitle('💬 معدل التفاعل', isDarkMode),
                  const SizedBox(height: 12),
                  _buildEngagementCard(isDarkMode),

                  const SizedBox(height: 24),

                  // أفضل المحتويات
                  _buildSectionTitle('🏆 أفضل المحتويات', isDarkMode),
                  const SizedBox(height: 12),
                  ..._buildTopContentList(isDarkMode),

                  const SizedBox(height: 24),

                  // النشاط الأخير
                  _buildSectionTitle('🕒 النشاط الأخير', isDarkMode),
                  const SizedBox(height: 12),
                  ..._buildRecentActivityList(isDarkMode),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(bool isDarkMode) {
    final engagementRate = _stats['engagement_rate'] ?? 0.0;
    final percentage = (engagementRate * 100).toStringAsFixed(1);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.instance.primaryColor,
            ThemeConfig.instance.accentColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.instance.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.white, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معدل التفاعل',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'من إجمالي المتابعين',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopContentList(bool isDarkMode) {
    final topContent = _stats['top_content'] as List? ?? [];
    
    if (topContent.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'لا توجد محتويات بعد',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ];
    }
    
    return topContent.map((content) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: content['media_url'] != null && content['media_url'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        content['media_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey[600]),
                      ),
                    )
                  : Icon(Icons.article, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content['title'] ?? 'بدون عنوان',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatNumber(content['views'] ?? 0)} مشاهدة',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.emoji_events, color: Colors.amber[600], size: 28),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecentActivityList(bool isDarkMode) {
    final recentActivity = _stats['recent_activity'] as List? ?? [];
    
    if (recentActivity.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'لا يوجد نشاط حديث',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ];
    }
    
    return recentActivity.map((activity) {
      IconData icon;
      Color iconColor;
      
      switch (activity['type']) {
        case 'post':
          icon = Icons.article;
          iconColor = const Color(0xFFF59E0B);
          break;
        case 'follow':
          icon = Icons.person_add;
          iconColor = const Color(0xFF3B82F6);
          break;
        case 'view':
          icon = Icons.visibility;
          iconColor = const Color(0xFF10B981);
          break;
        default:
          icon = Icons.notifications;
          iconColor = Colors.grey;
      }
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(activity['created_at'] ?? ''),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _formatNumber(dynamic value) {
    final num = value is int ? value : (value is double ? value.toInt() : 0);
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}م';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}ك';
    }
    return num.toString();
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return 'منذ ${difference.inMinutes} دقيقة';
        }
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
      }
    } catch (e) {
      return '';
    }
  }
}

