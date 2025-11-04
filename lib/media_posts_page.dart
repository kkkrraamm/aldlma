// lib/media_posts_page.dart
// قائمة المنشورات - تصميم فخم متكامل مع هوية الدلما
// by Abdulkarim ✨

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';
import 'media_edit_post_page.dart';

class MediaPostsPage extends StatefulWidget {
  const MediaPostsPage({super.key});

  @override
  State<MediaPostsPage> createState() => _MediaPostsPageState();
}

class _MediaPostsPageState extends State<MediaPostsPage> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  final String _baseUrl = ApiConfig.baseUrl;

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
          'X-API-Key': ApiConfig.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _posts = data['posts'] ?? [];
        });
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل تحميل المنشورات: $e', color: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(int postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/media/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-API-Key': ApiConfig.apiKey,
        },
      );

      if (response.statusCode == 200) {
        NotificationsService.instance.toast('تم حذف المنشور بنجاح! ✅', color: Colors.green);
        _loadPosts();
      } else {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      NotificationsService.instance.toast('فشل حذف المنشور: $e', color: Colors.red);
    }
  }

  Widget _buildDeleteConfirmDialog() {
    final theme = Provider.of<ThemeConfig>(context, listen: false);
    
    return AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'تأكيد الحذف',
        style: GoogleFonts.cairo(
          color: theme.textPrimaryColor,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        'هل أنت متأكد من حذف هذا المنشور؟',
        style: GoogleFonts.cairo(
          color: theme.textSecondaryColor,
          fontSize: 15,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'إلغاء',
            style: GoogleFonts.cairo(
              color: theme.textSecondaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'حذف',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);
    final isDark = theme.isDarkMode;
    final primaryColor = isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'منشوراتي',
          style: GoogleFonts.cairo(
            color: theme.textPrimaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.textPrimaryColor),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : _posts.isEmpty
              ? _buildEmptyState(theme, primaryColor)
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return _buildPostCard(post, theme, isDark, primaryColor);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: theme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منشورات بعد',
            style: GoogleFonts.cairo(
              color: theme.textSecondaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة منشورك الأول!',
            style: GoogleFonts.cairo(
              color: theme.textSecondaryColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post, ThemeConfig theme, bool isDark, Color primaryColor) {
    // استخراج البيانات من المنشور
    final mediaType = post['media_type'] ?? 'text';
    final description = post['description'] ?? '';
    final mediaUrls = post['media_urls'] is List ? List<String>.from(post['media_urls']) : <String>[];
    final videoUrl = post['video_url'];
    final int postId = post['id'] is int ? post['id'] : int.tryParse(post['id'].toString()) ?? 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عرض الميديا حسب النوع
            if (mediaType == 'image' && mediaUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mediaUrls.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.image_not_supported, color: primaryColor, size: 40),
                  ),
                ),
              ),
            if (mediaType == 'carousel' && mediaUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      mediaUrls.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: primaryColor.withOpacity(0.1),
                        child: Icon(Icons.image_not_supported, color: primaryColor, size: 40),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.collections, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${mediaUrls.length}',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (mediaType == 'video' && videoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.black,
                      child: post['video_thumbnail'] != null
                          ? Image.network(
                              post['video_thumbnail'],
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.videocam, color: Colors.white, size: 60),
                    ),
                    Icon(Icons.play_circle_outline, color: Colors.white, size: 60),
                  ],
                ),
              ),
            if (mediaType != 'text') const SizedBox(height: 12),
            
            // الوصف
            if (description.isNotEmpty)
              Text(
                description,
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                  fontSize: 15,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),
            
            // الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MediaEditPostPage(post: post),
                        ),
                      );
                      if (result == true) _loadPosts();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text(
                      'تعديل',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deletePost(postId),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: Text(
                      'حذف',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎨 Glass Card Widget
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
