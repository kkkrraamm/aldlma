// lib/videos_management_page.dart
// صفحة إدارة الفيديوهات المحسّنة - Enhanced Videos Management Page

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'theme_config.dart';
import 'notifications.dart';
import 'api_config.dart';

class VideosManagementPage extends StatefulWidget {
  const VideosManagementPage({super.key});

  @override
  State<VideosManagementPage> createState() => _VideosManagementPageState();
}

class _VideosManagementPageState extends State<VideosManagementPage> {
  final theme = ThemeConfig.instance;
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _filteredVideos = [];
  List<Map<String, dynamic>> _products = [];
  String? _token;
  String _searchQuery = '';
  String _sortBy = 'الأحدث';
  late Timer _loadingTimeout;

  @override
  void initState() {
    super.initState();
    _loadingTimeout = Timer(const Duration(seconds: 15), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        NotificationsService.instance.toast('⏱️ انتهت مهلة التحميل');
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('authToken');

      if (_token == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        NotificationsService.instance.toast('❌ التوكن غير موجود');
        return;
      }

      // تحميل الفيديوهات
      final videosResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/provider/videos'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      // تحميل المنتجات
      final productsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/provider/products'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 10));

      if (videosResponse.statusCode == 200 && productsResponse.statusCode == 200) {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(
            jsonDecode(videosResponse.body)['data'] ?? [],
          );
          _products = List<Map<String, dynamic>>.from(
            jsonDecode(productsResponse.body)['data'] ?? [],
          );
          _filteredVideos = _videos;
          _isLoading = false;
          _hasError = false;
        });
        _loadingTimeout.cancel();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print('Error loading videos: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _filterAndSortVideos() {
    setState(() {
      _filteredVideos = _videos.where((video) {
        final matchesSearch = (video['title'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        return matchesSearch;
      }).toList();

      // الترتيب
      if (_sortBy == 'الأحدث') {
        _filteredVideos.sort((a, b) =>
            (b['uploadedAt'] as DateTime?)?.compareTo(a['uploadedAt'] as DateTime? ?? DateTime.now()) ?? 0);
      } else if (_sortBy == 'الأكثر مشاهدة') {
        _filteredVideos.sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
      } else if (_sortBy == 'الأقدم') {
        _filteredVideos.sort((a, b) =>
            (a['uploadedAt'] as DateTime?)?.compareTo(b['uploadedAt'] as DateTime? ?? DateTime.now()) ?? 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text(
          'إدارة الفيديوهات',
          style: GoogleFonts.cairo(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: theme.textPrimaryColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Text(
                  '${_videos.length} فيديو',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : Column(
                  children: [
                    _buildFilterBar(),
                    Expanded(
                      child: _filteredVideos.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredVideos.length,
                              itemBuilder: (context, index) {
                                return _VideoItemCard(
                                  video: _filteredVideos[index],
                                  theme: theme,
                                  onEdit: () => _showEditVideoSheet(_filteredVideos[index]),
                                  onDelete: () => _showDeleteConfirmation(_filteredVideos[index]),
                                  onView: () => _showVideoPreview(_filteredVideos[index]),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadVideoSheet(),
        label: Text(
          'رفع فيديو',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.videocam_rounded),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: theme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل الفيديوهات...',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى الانتظار قليلاً',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'حدث خطأ في التحميل',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تأكد من الاتصال بالإنترنت وحاول مجدداً',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('حاول مجدداً'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterAndSortVideos();
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن فيديو...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchQuery = '';
                              _filterAndSortVideos();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: PopupMenuButton(
                  onSelected: (value) {
                    _sortBy = value;
                    _filterAndSortVideos();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'الأحدث',
                      child: Text('الأحدث'),
                    ),
                    const PopupMenuItem(
                      value: 'الأكثر مشاهدة',
                      child: Text('الأكثر مشاهدة'),
                    ),
                    const PopupMenuItem(
                      value: 'الأقدم',
                      child: Text('الأقدم'),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.sort_rounded),
                        const SizedBox(width: 4),
                        Text(
                          'الترتيب',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // شريط الإحصائيات
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'إجمالي المشاهدات',
                  value: _videos.isEmpty
                      ? '0'
                      : '${_videos.fold<int>(0, (sum, v) => sum + ((v['views'] as int?) ?? 0))}',
                  icon: Icons.remove_red_eye_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  label: 'عدد الفيديوهات',
                  value: _videos.length.toString(),
                  icon: Icons.videocam_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            size: 80,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد فيديوهات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'لم نجد نتائج البحث'
                : 'ابدأ برفع فيديوهات لعرض منتجاتك',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadVideoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UploadVideoSheet(
        products: _products,
        theme: theme,
        onSave: (video) {
          setState(() {
            _videos.insert(0, video);
            _filterAndSortVideos();
          });
          Navigator.pop(context);
          NotificationsService.instance.toast('✅ تم رفع الفيديو بنجاح!');
        },
      ),
    );
  }

  void _showEditVideoSheet(Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditVideoSheet(
        video: video,
        products: _products,
        theme: theme,
        onSave: (updatedVideo) {
          final index = _videos.indexWhere((v) => v['id'] == video['id']);
          if (index != -1) {
            setState(() {
              _videos[index] = updatedVideo;
              _filterAndSortVideos();
            });
          }
          Navigator.pop(context);
          NotificationsService.instance.toast('✅ تم تحديث الفيديو!');
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'حذف الفيديو؟',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${video['title']}"؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _videos.removeWhere((v) => v['id'] == video['id']);
                _filterAndSortVideos();
              });
              Navigator.pop(context);
              NotificationsService.instance.toast('🗑️ تم حذف الفيديو!');
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showVideoPreview(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              color: Colors.black,
              child: const Icon(
                Icons.play_circle_outline_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'] ?? 'فيديو',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video['description'] ?? '',
                    style: GoogleFonts.cairo(
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadingTimeout.cancel();
    super.dispose();
  }
}

// ============================================
// Stat Pill Widget
// ============================================
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Video Item Card
// ============================================
class _VideoItemCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final ThemeConfig theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _VideoItemCard({
    required this.video,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onView,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // صورة الفيديو
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.borderColor),
                      ),
                      child: Icon(
                        Icons.videocam_rounded,
                        color: theme.textSecondaryColor,
                        size: 60,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video['duration'] ?? '2:30',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onView,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          margin: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.35,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // معلومات الفيديو
                Text(
                  video['title'] ?? 'فيديو',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  video['description'] ?? 'بدون وصف',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: theme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                // الإحصائيات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      icon: Icons.remove_red_eye_rounded,
                      label: 'المشاهدات',
                      value: '${video['views'] ?? 0}',
                      theme: theme,
                    ),
                    _StatItem(
                      icon: Icons.thumb_up_rounded,
                      label: 'الإعجابات',
                      value: '${video['likes'] ?? 0}',
                      theme: theme,
                    ),
                    _StatItem(
                      icon: Icons.share_rounded,
                      label: 'المشاركات',
                      value: '${video['shares'] ?? 0}',
                      theme: theme,
                    ),
                    _StatItem(
                      icon: Icons.comment_rounded,
                      label: 'التعليقات',
                      value: '${video['comments'] ?? 0}',
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // الأزرار
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: Text(
                          'تعديل',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor.withOpacity(0.15),
                          foregroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: Text(
                          'حذف',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.15),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// Stat Item Widget
// ============================================
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeConfig theme;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: theme.primaryColor, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: theme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: theme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

// ============================================
// Upload Video Sheet
// ============================================
class _UploadVideoSheet extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final ThemeConfig theme;
  final Function(Map<String, dynamic>) onSave;

  const _UploadVideoSheet({
    required this.products,
    required this.theme,
    required this.onSave,
  });

  @override
  State<_UploadVideoSheet> createState() => _UploadVideoSheetState();
}

class _UploadVideoSheetState extends State<_UploadVideoSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String? _selectedProduct;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'رفع فيديو جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: widget.theme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () => NotificationsService.instance.toast('📹 اختر فيديو من الجهاز'),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: widget.theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.theme.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 50,
                        color: widget.theme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'اختر فيديو',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: widget.theme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط لاختيار ملف فيديو',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: widget.theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الفيديو',
                  hintText: 'مثال: طريقة صنع القهوة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  hintText: 'اكتب وصفاً تفصيلياً للفيديو...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String?>(
                value: _selectedProduct,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('لا يوجد منتج محدد'),
                  ),
                  ...widget.products.map((product) {
                    return DropdownMenuItem<String?>(
                      value: product['id'].toString(),
                      child: Text(product['name'] ?? 'منتج'),
                    );
                  }).toList(),
                ],
                onChanged: (value) => setState(() => _selectedProduct = value),
                decoration: InputDecoration(
                  labelText: 'المنتج المرتبط (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.shopping_bag_rounded),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isProcessing ? null : _uploadVideo,
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'رفع الفيديو',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _uploadVideo() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isProcessing = true);

      Future.delayed(const Duration(seconds: 2), () {
        final video = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': _titleController.text,
          'description': _descController.text,
          'product_id': _selectedProduct,
          'duration': '2:30',
          'views': 0,
          'likes': 0,
          'shares': 0,
          'comments': 0,
          'uploadedAt': DateTime.now(),
        };

        widget.onSave(video);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

// ============================================
// Edit Video Sheet
// ============================================
class _EditVideoSheet extends StatefulWidget {
  final Map<String, dynamic> video;
  final List<Map<String, dynamic>> products;
  final ThemeConfig theme;
  final Function(Map<String, dynamic>) onSave;

  const _EditVideoSheet({
    required this.video,
    required this.products,
    required this.theme,
    required this.onSave,
  });

  @override
  State<_EditVideoSheet> createState() => _EditVideoSheetState();
}

class _EditVideoSheetState extends State<_EditVideoSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.video['title']);
    _descController = TextEditingController(text: widget.video['description'] ?? '');
    _selectedProduct = widget.video['product_id'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تعديل الفيديو',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: widget.theme.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final updatedVideo = {
                        ...widget.video,
                        'title': _titleController.text,
                        'description': _descController.text,
                        'product_id': _selectedProduct,
                      };

                      widget.onSave(updatedVideo);
                    }
                  },
                  child: Text(
                    'حفظ التغييرات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
