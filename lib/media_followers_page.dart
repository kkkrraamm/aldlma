import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme_config.dart';

/// 👥 صفحة عرض المتابعين للإعلامي
class MediaFollowersPage extends StatefulWidget {
  const MediaFollowersPage({Key? key}) : super(key: key);

  @override
  State<MediaFollowersPage> createState() => _MediaFollowersPageState();
}

class _MediaFollowersPageState extends State<MediaFollowersPage> {
  bool _isLoading = true;
  List<dynamic> _followers = [];
  final String _baseUrl = 'https://dalma-api.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/media/followers'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> followers = json.decode(response.body);
        setState(() {
          _followers = followers;
        });
      } else {
        print('❌ [FOLLOWERS] Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FOLLOWERS] Error loading: $e');
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
        title: Text('👥 المتابعون (${_followers.length})'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFollowers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _followers.length,
                    itemBuilder: (context, index) {
                      return _buildFollowerCard(_followers[index], isDarkMode);
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
          Icon(Icons.people_outline, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'لا يوجد متابعون بعد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'شارك محتوى رائع لجذب المتابعين!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCard(dynamic follower, bool isDarkMode) {
    final name = follower['name'] ?? 'مستخدم';
    final phone = follower['phone'] ?? '';
    final profileImage = follower['profile_image'];
    final bio = follower['bio'] ?? '';
    final followedAt = follower['followed_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ThemeConfig.instance.primaryColor, width: 2),
          ),
          child: ClipOval(
            child: profileImage != null && profileImage.isNotEmpty
                ? Image.network(
                    profileImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(name),
                  )
                : _buildDefaultAvatar(name),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                phone,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                bio,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'تابعك ${_formatTimeAgo(followedAt)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.verified_user,
          color: ThemeConfig.instance.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: ThemeConfig.instance.primaryColor,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '؟',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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

