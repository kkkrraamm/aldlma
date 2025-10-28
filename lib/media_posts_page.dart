import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme_config.dart';
import 'media_add_post_page.dart';

/// 📝 صفحة عرض المنشورات للإعلامي
class MediaPostsPage extends StatefulWidget {
  const MediaPostsPage({Key? key}) : super(key: key);

  @override
  State<MediaPostsPage> createState() => _MediaPostsPageState();
}

class _MediaPostsPageState extends State<MediaPostsPage> {
  bool _isLoading = true;
  List<dynamic> _posts = [];
  final String _baseUrl = 'https://dalma-api.onrender.com';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/media/posts'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> posts = json.decode(response.body);
        setState(() {
          _posts = posts;
        });
      } else {
        print('❌ [POSTS] Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [POSTS] Error loading posts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(int postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنشور'),
        content: const Text('هل أنت متأكد من حذف هذا المنشور؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/media/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': 'FKSOE445DF8F44F3BA62C9084DBBC023E3E3F',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم حذف المنشور بنجاح')),
        );
        _loadPosts(); // إعادة تحميل القائمة
      } else {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ فشل حذف المنشور')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ThemeConfig.instance;
    final isDarkMode = themeConfig.isDarkMode;
    final primaryColor = themeConfig.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 منشوراتي'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_posts[index], isDarkMode, primaryColor);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MediaAddPostPage()),
          ).then((value) {
            if (value == true) {
              _loadPosts(); // إعادة تحميل المنشورات بعد الإضافة
            }
          });
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('منشور جديد', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'لا توجد منشورات بعد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منشورك الأول!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post, bool isDarkMode, Color primaryColor) {
    final title = post['title'] ?? 'بدون عنوان';
    final description = post['description'] ?? '';
    final viewsCount = post['views_count'] ?? 0;
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final createdAt = post['created_at'] ?? '';
    final mediaUrl = post['media_url'];
    final isActive = post['is_active'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنشور (إن وجدت)
          if (mediaUrl != null && mediaUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                mediaUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image, size: 50)),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'غير نشط',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                  ],
                ),

                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // الإحصائيات
                Row(
                  children: [
                    _buildStat(Icons.visibility, viewsCount.toString()),
                    const SizedBox(width: 16),
                    _buildStat(Icons.favorite, likesCount.toString()),
                    const SizedBox(width: 16),
                    _buildStat(Icons.comment, commentsCount.toString()),
                    const Spacer(),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          // TODO: تعديل المنشور
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ميزة التعديل قيد التطوير...')),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _deletePost(post['id']),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('حذف', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  String _formatDate(String dateString) {
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
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}

