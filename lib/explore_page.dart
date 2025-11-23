import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'theme_config.dart';
import 'api_config.dart';
import 'auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ============================================
// صفحة Explore - فيديوهات TikTok Style
// ============================================
class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = Provider.of<AuthState>(context, listen: false).token;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/explore/videos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _videos = List<Map<String, dynamic>>.from(data['videos'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      print('❌ Error loading videos: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'استكشف',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: فتح صفحة البحث
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981),
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.white70),
                      SizedBox(height: 16),
                      Text(
                        'حدث خطأ في تحميل الفيديوهات',
                        style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVideos,
                        child: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _videos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library_outlined, size: 64, color: Colors.white70),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد فيديوهات حالياً',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _videos.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return VideoPlayerItem(
                          video: _videos[index],
                          isActive: index == _currentIndex,
                        );
                      },
                    ),
    );
  }
}

// ============================================
// مشغل الفيديو الفردي
// ============================================
class VideoPlayerItem extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isActive;

  const VideoPlayerItem({
    Key? key,
    required this.video,
    required this.isActive,
  }) : super(key: key);

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;
  int _viewsCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.video['likes_count'] ?? 0;
    _viewsCount = widget.video['views_count'] ?? 0;
    if (widget.isActive) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeVideo();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.video['video_url'] ?? widget.video['stream_url'];
    
    if (videoUrl == null || videoUrl.isEmpty) {
      print('❌ No video URL found');
      return;
    }

    _controller = VideoPlayerController.network(videoUrl);
    
    try {
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller!.play();
      _controller!.setLooping(true);
      _recordView();
    } catch (e) {
      print('❌ Error initializing video: $e');
    }
  }

  Future<void> _recordView() async {
    try {
      final token = Provider.of<AuthState>(context, listen: false).token;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/explore/videos/${widget.video['id']}/view'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      print('❌ Error recording view: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      final token = Provider.of<AuthState>(context, listen: false).token;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/explore/videos/${widget.video['id']}/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
    } catch (e) {
      print('❌ Error toggling like: $e');
    }
  }

  Future<void> _toggleSave() async {
    try {
      final token = Provider.of<AuthState>(context, listen: false).token;
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/explore/videos/${widget.video['id']}/save'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _isSaved = !_isSaved;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved ? 'تم الحفظ ✓' : 'تم إلغاء الحفظ',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling save: $e');
    }
  }

  Future<void> _shareVideo() async {
    try {
      final videoUrl = widget.video['video_url'];
      final title = widget.video['title'] ?? 'شاهد هذا الفيديو على الدلما';
      
      await Share.share(
        '$title\n\n$videoUrl',
        subject: 'فيديو من الدلما',
      );

      // تسجيل المشاركة
      final token = Provider.of<AuthState>(context, listen: false).token;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/explore/videos/${widget.video['id']}/share'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      print('❌ Error sharing video: $e');
    }
  }

  void _showProductDetails() {
    final product = widget.video['linked_product'];
    if (product == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductBottomSheet(product: product),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasProduct = widget.video['linked_product_id'] != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // الفيديو
        if (_isInitialized && _controller != null)
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981),
              ),
            ),
          ),

        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // معلومات الفيديو (أسفل اليسار)
        Positioned(
          bottom: 100,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم المتجر
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.video['store_logo'] != null
                        ? CachedNetworkImageProvider(widget.video['store_logo'])
                        : null,
                    child: widget.video['store_logo'] == null
                        ? Icon(Icons.store, color: Colors.white)
                        : null,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.video['store_name'] ?? 'متجر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              
              // عنوان الفيديو
              if (widget.video['title'] != null)
                Text(
                  widget.video['title'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              SizedBox(height: 8),
              
              // المشاهدات
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    '${_viewsCount} مشاهدة',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // أزرار التفاعل (أسفل اليمين)
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(
            children: [
              // إعجاب
              _buildActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: _formatCount(_likesCount),
                color: _isLiked ? Colors.red : Colors.white,
                onTap: _toggleLike,
              ),
              SizedBox(height: 24),
              
              // حفظ
              _buildActionButton(
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                label: 'حفظ',
                color: _isSaved 
                    ? (isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981))
                    : Colors.white,
                onTap: _toggleSave,
              ),
              SizedBox(height: 24),
              
              // مشاركة
              _buildActionButton(
                icon: Icons.share,
                label: 'مشاركة',
                color: Colors.white,
                onTap: _shareVideo,
              ),
              
              // المنتج المرتبط
              if (hasProduct) ...[
                SizedBox(height: 24),
                _buildActionButton(
                  icon: Icons.shopping_bag,
                  label: 'المنتج',
                  color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981),
                  onTap: _showProductDetails,
                ),
              ],
            ],
          ),
        ),

        // بطاقة المنتج المرتبط (أسفل)
        if (hasProduct)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: _showProductDetails,
              child: ProductLinkCard(product: widget.video['linked_product']),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// ============================================
// بطاقة المنتج المرتبط
// ============================================
class ProductLinkCard extends StatelessWidget {
  final Map<String, dynamic>? product;

  const ProductLinkCard({Key? key, this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (product == null) return SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981)).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product!['thumbnail'] != null
                ? CachedNetworkImage(
                    imageUrl: product!['thumbnail'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.image, color: Colors.white54),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[800],
                    child: Icon(Icons.shopping_bag, color: Colors.white54),
                  ),
          ),
          SizedBox(width: 12),
          
          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product!['name_ar'] ?? 'منتج',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${product!['final_price'] ?? product!['price']} ريال',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (product!['discount_value'] != null) ...[
                      SizedBox(width: 8),
                      Text(
                        '${product!['price']} ريال',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // سهم
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white70,
            size: 16,
          ),
        ],
      ),
    );
  }
}

// ============================================
// Bottom Sheet لتفاصيل المنتج
// ============================================
class ProductBottomSheet extends StatelessWidget {
  final Map<String, dynamic>? product;

  const ProductBottomSheet({Key? key, this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (product == null) return SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = product!['images'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صور المنتج
                  if (images.isNotEmpty)
                    Container(
                      height: 300,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                  
                  SizedBox(height: 20),
                  
                  // اسم المنتج
                  Text(
                    product!['name_ar'] ?? 'منتج',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // السعر
                  Row(
                    children: [
                      Text(
                        '${product!['final_price'] ?? product!['price']} ريال',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      if (product!['discount_value'] != null) ...[
                        SizedBox(width: 12),
                        Text(
                          '${product!['price']} ريال',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product!['discount_value']}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // الوصف
                  if (product!['description_ar'] != null) ...[
                    Text(
                      'الوصف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      product!['description_ar'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'Cairo',
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  
                  // زر الشراء
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: فتح صفحة تفاصيل المنتج الكاملة
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFD4AF37) : const Color(0xFF10b981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'عرض التفاصيل الكاملة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
