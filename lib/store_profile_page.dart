import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoreProfilePage extends StatefulWidget {
  final String storeId;
  final String storeName;

  const StoreProfilePage({Key? key, required this.storeId, required this.storeName}) : super(key: key);

  @override
  State<StoreProfilePage> createState() => _StoreProfilePageState();
}

class _StoreProfilePageState extends State<StoreProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _storeData;
  List<dynamic> _products = [];
  List<dynamic> _videos = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================
  // جلب بيانات المتجر
  // ============================================
  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthState>(context, listen: false);
      final token = authProvider.token;

      // جلب معلومات المتجر
      final storeUrl = 'https://dalma-api.onrender.com/api/stores/${widget.storeId}';
      final storeResponse = await http.get(
        Uri.parse(storeUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (storeResponse.statusCode == 200) {
        final data = json.decode(storeResponse.body);
        setState(() {
          _storeData = data['store'];
          _followersCount = _storeData?['followers_count'] ?? 0;
        });

        // جلب المنتجات
        final productsUrl =
            'https://dalma-api.onrender.com/api/stores/${widget.storeId}/products?limit=50';
        final productsResponse = await http.get(
          Uri.parse(productsUrl),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (productsResponse.statusCode == 200) {
          final productsData = json.decode(productsResponse.body);
          setState(() => _products = productsData['products'] ?? []);
        }

        // جلب الفيديوهات
        final videosUrl =
            'https://dalma-api.onrender.com/api/stores/${widget.storeId}/videos?limit=50';
        final videosResponse = await http.get(
          Uri.parse(videosUrl),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (videosResponse.statusCode == 200) {
          final videosData = json.decode(videosResponse.body);
          setState(() => _videos = videosData['videos'] ?? []);
        }

        // التحقق من المتابعة
        await _checkFollowingStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================
  // التحقق من حالة المتابعة
  // ============================================
  Future<void> _checkFollowingStatus() async {
    try {
      final authProvider = Provider.of<AuthState>(context, listen: false);
      final token = authProvider.token;
      final url =
          'https://dalma-api.onrender.com/api/stores/${widget.storeId}/following-status';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _isFollowing = data['is_following'] ?? false);
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  // ============================================
  // متابعة/إلغاء متابعة
  // ============================================
  Future<void> _toggleFollow() async {
    try {
      final authProvider = Provider.of<AuthState>(context, listen: false);
      final token = authProvider.token;
      final url =
          'https://dalma-api.onrender.com/api/stores/${widget.storeId}/follow';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isFollowing = !_isFollowing;
          _followersCount += _isFollowing ? 1 : -1;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isFollowing ? 'تمت المتابعة ✅' : 'تم إلغاء المتابعة'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDarkMode ? const Color(0xFFD4AF37) : const Color(0xFF10b981);

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (_storeData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المتجر')),
        body: const Center(child: Text('المتجر غير موجود')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header مع Banner
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildStoreHeader(accentColor),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: accentColor,
                indicatorColor: accentColor,
                tabs: [
                  Tab(text: 'المنتجات (${_products.length})'),
                  Tab(text: 'الفيديوهات (${_videos.length})'),
                ],
              ),
            ),
          ),

          // Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsGrid(),
                _buildVideosGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Header المتجر
  // ============================================
  Widget _buildStoreHeader(Color accentColor) {
    final storeBanner = _storeData?['store_banner'];
    final storeLogo = _storeData?['store_logo'];
    final storeName = _storeData?['store_name'] ?? 'متجر';
    final storeDescription = _storeData?['store_description'] ?? '';
    final storeRating = _storeData?['store_rating']?.toDouble() ?? 0.0;
    final isVerified = _storeData?['is_verified'] ?? false;

    return Stack(
      children: [
        // Banner
        if (storeBanner != null)
          CachedNetworkImage(
            imageUrl: storeBanner,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) =>
                Container(color: Colors.grey[300]),
          )
        else
          Container(
            height: 180,
            color: accentColor.withOpacity(0.2),
          ),

        // Gradient Overlay
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
            ),
          ),
        ),

        // Logo + Info
        Positioned(
          bottom: 0,
          left: 16,
          right: 16,
          child: Column(
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: storeLogo != null
                      ? CachedNetworkImage(
                          imageUrl: storeLogo,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.store, size: 50, color: accentColor),
                        )
                      : Icon(Icons.store, size: 50, color: accentColor),
                ),
              ),

              const SizedBox(height: 12),

              // Store Name + Verified
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.verified, color: accentColor, size: 20),
                    ),
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Rating + Followers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text('$storeRating', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  Icon(Icons.people, color: accentColor, size: 20),
                  const SizedBox(width: 4),
                  Text('$_followersCount متابع', style: const TextStyle(fontSize: 16)),
                ],
              ),

              const SizedBox(height: 12),

              // Follow Button
              ElevatedButton.icon(
                onPressed: _toggleFollow,
                icon: Icon(_isFollowing ? Icons.check : Icons.add),
                label: Text(_isFollowing ? 'متابَع' : 'متابعة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.grey : accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Description
              if (storeDescription.isNotEmpty)
                Text(
                  storeDescription,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // Products Grid
  // ============================================
  Widget _buildProductsGrid() {
    if (_products.isEmpty) {
      return const Center(child: Text('لا توجد منتجات'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  // ============================================
  // Product Card
  // ============================================
  Widget _buildProductCard(Map<String, dynamic> product) {
    final images = product['images'] as List<dynamic>?;
    final thumbnail = images != null && images.isNotEmpty ? images[0] : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: thumbnail != null
                  ? CachedNetworkImage(
                      imageUrl: thumbnail,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.image),
                    )
                  : Container(color: Colors.grey[300]),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name_ar'] ?? 'منتج',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product['final_price']} ر.س',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10b981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // Videos Grid
  // ============================================
  Widget _buildVideosGrid() {
    if (_videos.isEmpty) {
      return const Center(child: Text('لا توجد فيديوهات'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  // ============================================
  // Video Card
  // ============================================
  Widget _buildVideoCard(Map<String, dynamic> video) {
    final thumbnail = video['thumbnail_url'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumbnail != null
                ? CachedNetworkImage(
                    imageUrl: thumbnail,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.grey[300]),
                  )
                : Container(color: Colors.grey[300]),
          ),

          // Play Icon
          Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          // Views Count
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${video['views_count'] ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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

// ============================================
// SliverTabBarDelegate
// ============================================
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
