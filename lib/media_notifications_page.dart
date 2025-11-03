import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme_config.dart';

/// 🔔 صفحة الإشعارات للإعلامي
class MediaNotificationsPage extends StatefulWidget {
  const MediaNotificationsPage({Key? key}) : super(key: key);

  @override
  State<MediaNotificationsPage> createState() => _MediaNotificationsPageState();
}

class _MediaNotificationsPageState extends State<MediaNotificationsPage> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  final String _baseUrl = 'https://dalma-api.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/api/media/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> notifications = json.decode(response.body);
        setState(() {
          _notifications = notifications;
        });
      } else {
        print('❌ [NOTIFICATIONS] Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error loading: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      await http.post(
        Uri.parse('$_baseUrl/api/media/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
        },
      );

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error marking as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.instance;
    final isDarkMode = themeConfig.isDarkMode;
    final primaryColor = isDarkMode ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    final unreadCount = _notifications.where((n) => n['is_read'] == false || n['is_read'] == null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('🔔 الإشعارات${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                // TODO: Mark all as read
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تعليم الكل كمقروء')),
                );
              },
              child: const Text(
                'تعليم الكل كمقروء',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index], isDarkMode);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'لا توجد إشعارات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا جميع إشعاراتك',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notification, bool isDarkMode) {
    final isRead = notification['is_read'] == true;
    final title = notification['title'] ?? 'إشعار جديد';
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? 'general';
    final createdAt = notification['created_at'] ?? '';

    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'follow':
        icon = Icons.person_add;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'like':
        icon = Icons.favorite;
        iconColor = const Color(0xFFEC4899);
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = const Color(0xFF8B5CF6);
        break;
      case 'view':
        icon = Icons.visibility;
        iconColor = const Color(0xFF10B981);
        break;
      case 'approval':
        icon = Icons.check_circle;
        iconColor = const Color(0xFF10B981);
        break;
      case 'rejection':
        icon = Icons.cancel;
        iconColor = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.notifications;
        iconColor = const Color(0xFFF59E0B);
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead
              ? (isDarkMode ? Colors.grey[850] : Colors.white)
              : (isDarkMode ? Colors.grey[800] : Colors.blue[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[300]! : ThemeConfig.instance.primaryColor.withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: ThemeConfig.instance.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'الآن';
          }
          return 'منذ ${difference.inMinutes} دقيقة';
        }
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else if (difference.inDays < 30) {
        return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
      } else {
        return 'منذ ${(difference.inDays / 30).floor()} شهر';
      }
    } catch (e) {
      return '';
    }
  }
}

