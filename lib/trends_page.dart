import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ask_dalma_dialog.dart';
import 'login_page.dart';
import 'auth.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({Key? key}) : super(key: key);

  @override
  _TrendsPageState createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredJournalists = [];
  List<String> _followingList = []; // قائمة معرفات الإعلاميين المتابعين
  bool _isLoggedIn = false; // محاكاة حالة تسجيل الدخول
  final Set<String> _likedPosts = {}; // منشورات تم الإعجاب بها
  final Set<String> _savedPosts = {}; // منشورات تم حفظها
  
  // مفتاح المستخدم الحالي للحفظ المحلي
  String? _userKey;
  String? _token;
  final String _baseUrl = ApiConfig.baseUrl;
  
  // بيانات من Backend
  List<Map<String, dynamic>> verifiedJournalists = [];
  List<Map<String, dynamic>> journalistPosts = [];
  bool _isLoadingMedia = true;
  bool _isLoadingPosts = true;

  // بيانات الإعلاميين المعتمدين (backup - سيتم استبدالها بالبيانات من Backend)
  final List<Map<String, dynamic>> _backupJournalists = [
    {
      'id': '1',
      'name': 'أحمد العتيبي',
      'username': '@ahmed_alotaibi',
      'specialty': 'مراسل سياسي',
      'avatar': 'assets/img/arar.png',
      'followers': 15420,
      'following': 892,
      'posts': 1247,
      'bio': 'مراسل سياسي متخصص في الشؤون المحلية والدولية',
      'phone': '+966501234567',
      'email': 'ahmed@news.com',
      'isVerified': true,
    },
    {
      'id': '2',
      'name': 'فاطمة الزهراني',
      'username': '@fatima_alzahrani',
      'specialty': 'مراسلة اقتصادية',
      'avatar': 'assets/img/arar.png',
      'followers': 12890,
      'following': 654,
      'posts': 892,
      'bio': 'مراسلة اقتصادية متخصصة في الأسواق المالية',
      'phone': '+966507654321',
      'email': 'fatima@business.com',
      'isVerified': true,
    },
    {
      'id': '3',
      'name': 'محمد الشمري',
      'username': '@mohammed_alshamri',
      'specialty': 'مراسل رياضي',
      'avatar': 'assets/img/arar.png',
      'followers': 22150,
      'following': 1203,
      'posts': 1567,
      'bio': 'مراسل رياضي متخصص في كرة القدم المحلية',
      'phone': '+966509876543',
      'email': 'mohammed@sports.com',
      'isVerified': true,
    },
  ];

  // ═══════════════════════════════════════════════════════════════
  // 🌐 Backend API Functions
  // ═══════════════════════════════════════════════════════════════
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      // تحميل قائمة المتابعين المحفوظة محلياً (backup)
      _followingList = prefs.getStringList('following_list') ?? [];
    });
    
    // تحميل قائمة المتابعة من Backend (الأحدث)
    if (_token != null) {
      await _loadFollowingFromBackend();
    }
  }
  
  Future<void> _loadFollowingFromBackend() async {
    if (_token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/trends/following'),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-API-Key': ApiConfig.apiKey,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final followingIds = List<String>.from(data['following'] ?? []);
        
        setState(() {
          _followingList = followingIds;
        });
        
        // حفظ محلياً للاستخدام في المرة القادمة
        await _saveFollowingList();
        
        print('✅ [FOLLOWING] تم تحميل ${followingIds.length} إعلامي من Backend');
      }
    } catch (e) {
      print('❌ [FOLLOWING] Error loading from backend: $e');
      // الاحتفاظ بالقائمة المحلية في حالة الفشل
    }
  }
  
  Future<void> _saveFollowingList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('following_list', _followingList);
  }

  Future<void> _loadMediaFromBackend() async {
    setState(() => _isLoadingMedia = true);
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/trends/media'),
        headers: {'X-API-Key': ApiConfig.apiKey},
      );

      print('📺 [TRENDS] Response status: ${response.statusCode}');
      print('📺 [TRENDS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // التحقق من نوع البيانات المرجعة
        List<dynamic> mediaList = [];
        if (responseData is List) {
          // إذا كانت البيانات array مباشرة
          mediaList = responseData;
        } else if (responseData is Map && responseData['media'] != null) {
          // إذا كانت البيانات object يحتوي على media
          mediaList = responseData['media'];
        }
        
        print('📺 [TRENDS] Raw media data: ${mediaList.length} items');
        if (mediaList.isNotEmpty) {
          print('📺 [TRENDS] First item: ${mediaList[0]}');
        }
        
        setState(() {
          verifiedJournalists = mediaList.map((media) {
            try {
              // تحويل آمن للأرقام
              int followersCount = 0;
              if (media['followers_count'] != null) {
                if (media['followers_count'] is int) {
                  followersCount = media['followers_count'];
                } else {
                  followersCount = int.tryParse(media['followers_count'].toString()) ?? 0;
                }
              }
              
              int postsCount = 0;
              if (media['posts_count'] != null) {
                if (media['posts_count'] is int) {
                  postsCount = media['posts_count'];
                } else {
                  postsCount = int.tryParse(media['posts_count'].toString()) ?? 0;
                }
              }
              
              return {
                'id': '${media['id'] ?? ''}',
                'name': media['name'] ?? 'غير معروف',
                'username': '@${media['phone'] ?? 'unknown'}',
                'specialty': 'إعلامي موثق',
                'avatar': media['profile_picture'] ?? media['profile_image'],
                'followers': followersCount,
                'following': 0,
                'posts': postsCount,
                'bio': media['bio'] ?? '',
                'phone': media['phone'] ?? '',
                'email': '',
                'isVerified': true,
              };
            } catch (e) {
              print('❌ [TRENDS] Error parsing media item: $e');
              print('❌ [TRENDS] Problematic item: $media');
              return null;
            }
          }).where((m) => m != null).cast<Map<String, dynamic>>().toList();
          
          _filteredJournalists = List.from(verifiedJournalists);
        });
        
        print('📺 [TRENDS] تم جلب ${verifiedJournalists.length} إعلامي من Backend');
      } else {
        print('❌ [TRENDS] Bad status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [TRENDS] Error loading media: $e');
      print('❌ [TRENDS] Stack trace: $stackTrace');
      // استخدام البيانات الاحتياطية
      setState(() {
        verifiedJournalists = List.from(_backupJournalists);
        _filteredJournalists = List.from(verifiedJournalists);
      });
    } finally {
      setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _loadPostsFromBackend() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/trends/posts'),
        headers: {'X-API-Key': ApiConfig.apiKey},
      );

      print('📰 [TRENDS] Response status: ${response.statusCode}');
      print('📰 [TRENDS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // التحقق من نوع البيانات المرجعة
        List<dynamic> postsList = [];
        if (responseData is List) {
          // إذا كانت البيانات array مباشرة
          postsList = responseData;
        } else if (responseData is Map && responseData['posts'] != null) {
          // إذا كانت البيانات object يحتوي على posts
          postsList = responseData['posts'];
        }
        
        print('📰 [TRENDS] Raw posts data: ${postsList.length} items');
        if (postsList.isNotEmpty) {
          print('📰 [TRENDS] First post: ${postsList[0]}');
        }
        
        setState(() {
          journalistPosts = postsList.map((post) {
            try {
              // تحويل آمن للأرقام
              int likesCount = 0;
              if (post['likes_count'] != null) {
                if (post['likes_count'] is int) {
                  likesCount = post['likes_count'];
                } else {
                  likesCount = int.tryParse(post['likes_count'].toString()) ?? 0;
                }
              }
              
              int commentsCount = 0;
              if (post['comments_count'] != null) {
                if (post['comments_count'] is int) {
                  commentsCount = post['comments_count'];
                } else {
                  commentsCount = int.tryParse(post['comments_count'].toString()) ?? 0;
                }
              }
              
              int sharesCount = 0;
              if (post['shares_count'] != null) {
                if (post['shares_count'] is int) {
                  sharesCount = post['shares_count'];
                } else {
                  sharesCount = int.tryParse(post['shares_count'].toString()) ?? 0;
                }
              }
              
              // استخراج media_urls (مصفوفة صور)
              List<String> mediaUrls = [];
              if (post['media_urls'] != null) {
                if (post['media_urls'] is String) {
                  // إذا كانت JSON string
                  try {
                    final decoded = json.decode(post['media_urls']);
                    if (decoded is List) {
                      mediaUrls = decoded.cast<String>();
                    }
                  } catch (e) {
                    print('❌ Error parsing media_urls: $e');
                  }
                } else if (post['media_urls'] is List) {
                  mediaUrls = (post['media_urls'] as List).cast<String>();
                }
              }
              
              // استخراج hashtags
              List<String> hashtags = [];
              if (post['hashtags'] != null && post['hashtags'] is List) {
                hashtags = (post['hashtags'] as List).cast<String>();
              }
              
              // استخراج mentions
              List<String> mentions = [];
              if (post['mentions'] != null && post['mentions'] is List) {
                mentions = (post['mentions'] as List).cast<String>();
              }
              
              return {
                'id': '${post['id'] ?? ''}',
                'journalistId': '${post['user_id'] ?? ''}',
                'content': post['description'] ?? '',
                'media_type': post['media_type'] ?? 'text',
                'media_urls': mediaUrls, // مصفوفة صور
                'video_url': post['video_url'], // فيديو
                'video_thumbnail': post['video_thumbnail'],
                'type': post['media_type'] ?? 'text',
                'likes': likesCount,
                'comments': commentsCount,
                'shares': sharesCount,
                'timestamp': _formatTime(post['created_at']),
                'hashtags': hashtags,
                'mentions': mentions,
                'journalistName': post['user_name'] ?? '',
                'journalistUsername': post['user_username'] ?? '',
                'journalistAvatar': post['user_avatar'] ?? post['user_profile_image'],
                'isVerified': true,
              };
            } catch (e) {
              print('❌ [TRENDS] Error parsing post: $e');
              print('❌ [TRENDS] Problematic post: $post');
              return null;
            }
          }).where((p) => p != null).cast<Map<String, dynamic>>().toList();
        });
        
        print('📰 [TRENDS] تم جلب ${journalistPosts.length} منشور من Backend');
      } else {
        print('❌ [TRENDS] Bad status code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [TRENDS] Error loading posts: $e');
      print('❌ [TRENDS] Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoadingPosts = false);
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'منذ وقت قصير';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
    } catch (e) {
      return 'منذ وقت قصير';
    }
  }

  Future<void> _toggleFollow(String mediaId) async {
    if (_token == null) {
      NotificationsService.instance.toast('يجب تسجيل الدخول أولاً', color: Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trends/media/$mediaId/follow'),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-API-Key': ApiConfig.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final following = data['following'] ?? false;
        
        setState(() {
          if (following) {
            _followingList.add(mediaId);
          } else {
            _followingList.remove(mediaId);
          }
        });
        
        // حفظ قائمة المتابعين
        await _saveFollowingList();
        
        NotificationsService.instance.toast(
          following ? 'تمت المتابعة بنجاح! ✅' : 'تم إلغاء المتابعة',
          color: following ? Colors.green : Colors.grey,
        );
        
        _loadMediaFromBackend(); // تحديث البيانات
      }
    } catch (e) {
      print('❌ [FOLLOW] Error: $e');
      NotificationsService.instance.toast('فشل في المتابعة', color: Colors.red);
    }
  }

  Future<void> _toggleLike(String postId) async {
    if (_token == null) {
      NotificationsService.instance.toast('يجب تسجيل الدخول أولاً', color: Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/trends/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-API-Key': ApiConfig.apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final liked = data['liked'] ?? false;
        
        setState(() {
          if (liked) {
            _likedPosts.add(postId);
          } else {
            _likedPosts.remove(postId);
          }
        });
        
        _loadPostsFromBackend(); // تحديث البيانات
      }
    } catch (e) {
      print('❌ [LIKE] Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadMediaFromBackend();
    _loadPostsFromBackend();
    _searchController.addListener(_onSearchChanged);
    // استمع لحالة الدخول العالمية
    AuthState.instance.addListener(_authListener);
    _isLoggedIn = AuthState.instance.isLoggedIn;
    _userKey = AuthState.instance.phone;
    if (_isLoggedIn) {
      _loadInteractions();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🔄 تحديث تلقائي عند العودة للصفحة
    if (mounted) {
      _loadFollowingFromBackend(); // تحديث قائمة المتابعة
      _loadMediaFromBackend();
      _loadPostsFromBackend();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    AuthState.instance.removeListener(_authListener);
    super.dispose();
  }

  void _authListener() {
    if (!mounted) return;
    setState(() {
      _isLoggedIn = AuthState.instance.isLoggedIn;
      _userKey = AuthState.instance.phone;
      if (_isLoggedIn) {
        // حمّل تفاعلات المستخدم من التخزين المحلي
        _loadInteractions();
      } else {
        // صفّر الحالة عند تسجيل الخروج
        _followingList = [];
        _likedPosts.clear();
        _savedPosts.clear();
      }
    });
  }

  Future<void> _loadInteractions() async {
    if (!_isLoggedIn) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey ?? 'user';
    final likes = prefs.getStringList('likes_' + key) ?? <String>[];
    final saves = prefs.getStringList('saves_' + key) ?? <String>[];
    final follows = prefs.getStringList('follows_' + key) ?? <String>[];
    if (!mounted) return;
    setState(() {
      _likedPosts
        ..clear()
        ..addAll(likes);
      _savedPosts
        ..clear()
        ..addAll(saves);
      _followingList = List<String>.from(follows);
    });
  }

  Future<void> _persistInteractions() async {
    if (!_isLoggedIn) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _userKey ?? 'user';
    await prefs.setStringList('likes_' + key, _likedPosts.toList());
    await prefs.setStringList('saves_' + key, _savedPosts.toList());
    await prefs.setStringList('follows_' + key, _followingList);
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredJournalists = List.from(verifiedJournalists);
      } else {
        _filteredJournalists = verifiedJournalists.where((journalist) {
          return journalist['name'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
                 journalist['username'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
                 journalist['specialty'].toLowerCase().contains(_searchController.text.toLowerCase());
        }).toList();
      }
    });
  }

  void _requireLogin(VoidCallback action) {
    if (_isLoggedIn) {
      action();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء تسجيل الدخول للتفاعل مع المنشورات', style: GoogleFonts.cairo()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFollowingList() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? ThemeConfig.kNightSoft : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'قائمة المتابعين (${_followingList.length})',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            Expanded(
              child: _followingList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 64,
                            color: theme.textSecondaryColor.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لم تتابع أي إعلامي بعد',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: theme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _followingList.length,
                      itemBuilder: (context, index) {
                        final journalistId = _followingList[index];
                        final journalist = verifiedJournalists.firstWhere(
                          (j) => j['id']?.toString() == journalistId,
                        );
                        return _buildJournalistCard(journalist);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return AnimatedBuilder(
      animation: theme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroHeader()),
          SliverToBoxAdapter(child: _AskDalmaTrendsButton()),
          SliverToBoxAdapter(child: _buildSearchSection()),
          SliverToBoxAdapter(child: _buildJournalistsList()),
          // مكان طلب المستخدم: اجعل "كيف أسجل كإعلامي؟" فوق المنشورات
          SliverToBoxAdapter(child: _buildJournalistRegistrationSection()),
          SliverToBoxAdapter(child: _buildPostsFeed()),
        ],
      ),
        );
      },
    );
  }

  Widget _buildSearchSection() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث عن الإعلاميين...',
                    hintStyle: GoogleFonts.cairo(),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF10B981)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.textSecondaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF10B981)),
                    ),
                    filled: true,
                    fillColor: (isDark ? ThemeConfig.kNightAccent : Colors.white),
                  ),
                  style: GoogleFonts.cairo(),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showFollowingList,
                icon: Icon(Icons.people, size: 18),
                label: Text(
                  'قائمة المتابعين',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJournalistsList() {
    return Container(
      height: 180,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'الإعلاميون المعتمدون',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: _isLoadingMedia
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.instance.primaryColor),
                    ),
                  )
                : _filteredJournalists.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد إعلاميون حالياً',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredJournalists.length,
                        itemBuilder: (context, index) {
                          return _buildJournalistCard(_filteredJournalists[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalistCard(Map<String, dynamic> journalist) {
    final journalistId = journalist['id']?.toString() ?? '';
    final isFollowing = _followingList.contains(journalistId);
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.cardShadow,
        border: Border.all(
          color: isDark ? ThemeConfig.kNightAccent.withOpacity(0.3) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: (journalist['profile_picture'] != null && journalist['profile_picture'].toString().isNotEmpty)
                      ? NetworkImage(journalist['profile_picture'])
                      : (journalist['profile_image'] != null && journalist['profile_image'].toString().isNotEmpty)
                          ? NetworkImage(journalist['profile_image'])
                          : null,
                  child: (journalist['profile_picture'] == null || journalist['profile_picture'].toString().isEmpty) &&
                          (journalist['profile_image'] == null || journalist['profile_image'].toString().isEmpty)
                      ? Text(
                          journalist['name']?.toString().substring(0, 1) ?? '?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                          ),
                        )
                      : null,
                  backgroundColor: isDark ? ThemeConfig.kNightSoft : Colors.grey[200],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            journalist['name'],
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    if (journalist['bio'] != null && journalist['bio'].toString().isNotEmpty)
                      Text(
                        journalist['bio'],
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: theme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 12,
                          color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${journalist['followers_count'] ?? 0} متابع',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.article_outlined,
                          size: 12,
                          color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${journalist['posts_count'] ?? 0} منشور',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Contact buttons (if available)
          if (journalist['contact_email'] != null || journalist['contact_whatsapp'] != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (journalist['contact_email'] != null && journalist['contact_email'].toString().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        // Open email app
                        // TODO: Add url_launcher
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? ThemeConfig.kNightAccent : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                        ),
                      ),
                    ),
                  if (journalist['contact_email'] != null && journalist['contact_whatsapp'] != null)
                    SizedBox(width: 8),
                  if (journalist['contact_whatsapp'] != null && journalist['contact_whatsapp'].toString().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        // Open WhatsApp
                        // TODO: Add url_launcher
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? ThemeConfig.kNightAccent : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.phone,
                          size: 18,
                          color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showJournalistProfile(journalist),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? ThemeConfig.kNightAccent : Colors.grey[100],
                    foregroundColor: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'عرض الملف',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleFollow(journalistId),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFollowing 
                      ? (isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981))
                      : (isDark ? ThemeConfig.kNightAccent : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isFollowing ? Icons.person_remove : Icons.person_add,
                    size: 18,
                    color: isFollowing 
                      ? (isDark ? ThemeConfig.kNightDeep : Colors.white)
                      : (isDark ? theme.textSecondaryColor : Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsFeed() {
    // التحقق من وجود منشورات
    if (_isLoadingPosts) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.instance.primaryColor),
          ),
        ),
      );
    }
    
    if (journalistPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'لا توجد منشورات حالياً',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    final List<Map<String, dynamic>> repeatedPosts = List.generate(
      12,
      (index) => journalistPosts[index % journalistPosts.length],
    );
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آخر المنشورات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: repeatedPosts.length,
            itemBuilder: (context, index) {
              return _buildPostCard(repeatedPosts[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final journalist = verifiedJournalists.firstWhere(
      (j) => j['id'] == post['journalistId'],
    );
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(journalist['avatar']),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            journalist['name'],
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ],
                      ),
                      Text(
                        journalist['username'],
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  post['timestamp'],
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // محتوى المنشور
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الوصف مع هاشتاقات ومنشنات
                _buildRichDescription(post['content'] ?? '', post['hashtags'] ?? [], post['mentions'] ?? []),
                SizedBox(height: 12),
                
                // الوسائط
                if (post['media_type'] == 'video')
                  _buildVideoPost(post)
                else if (post['media_type'] == 'carousel' && post['media_urls'] != null && (post['media_urls'] as List).isNotEmpty)
                  _buildCarouselPost(post)
                else if (post['media_type'] == 'image' && post['media_urls'] != null && (post['media_urls'] as List).isNotEmpty)
                  _buildSingleImagePost(post),
              ],
            ),
          ),
          
          // أزرار التفاعل (بدون تعليقات) مع اشتراط تسجيل الدخول وتأثيرات أنيميشن
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLikeButton(post),
                _buildShareButton(post),
                _buildSaveButton(post),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // وصف غني مع هاشتاقات ومنشنات
  Widget _buildRichDescription(String text, List hashtags, List mentions) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    // تقسيم النص وتلوين الهاشتاقات والمنشنات
    final List<TextSpan> spans = [];
    final words = text.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.startsWith('#')) {
        spans.add(TextSpan(
          text: word + (i < words.length - 1 ? ' ' : ''),
          style: TextStyle(
            color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (word.startsWith('@')) {
        spans.add(TextSpan(
          text: word + (i < words.length - 1 ? ' ' : ''),
          style: TextStyle(
            color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
            fontWeight: FontWeight.w600,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: word + (i < words.length - 1 ? ' ' : ''),
        ));
      }
    }
    
    return RichText(
      text: TextSpan(
        style: GoogleFonts.cairo(
          fontSize: 14,
          height: 1.5,
          color: theme.textPrimaryColor,
        ),
        children: spans,
      ),
    );
  }

  // صورة واحدة
  Widget _buildSingleImagePost(Map<String, dynamic> post) {
    final mediaUrls = post['media_urls'] as List;
    if (mediaUrls.isEmpty) return SizedBox.shrink();
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        mediaUrls[0],
        width: double.infinity,
        height: 400,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 400,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, size: 50),
          );
        },
      ),
    );
  }

  // Carousel للصور (حتى 5 صور)
  Widget _buildCarouselPost(Map<String, dynamic> post) {
    final mediaUrls = post['media_urls'] as List;
    if (mediaUrls.isEmpty) return SizedBox.shrink();
    
    return _ImageCarousel(images: mediaUrls.cast<String>());
  }

  // فيديو بحجم TikTok/Reels
  Widget _buildVideoPost(Map<String, dynamic> post) {
    final videoUrl = post['video_url'];
    final thumbnail = post['video_thumbnail'];
    
    if (videoUrl == null) return SizedBox.shrink();
    
    return _TikTokVideoPlayer(
      videoUrl: videoUrl,
      thumbnail: thumbnail,
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = ThemeConfig.instance;
    
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.textSecondaryColor,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(Map<String, dynamic> post) {
    final String id = post['id']?.toString() ?? '';
    final bool isLiked = _likedPosts.contains(id);
    final theme = ThemeConfig.instance;
    
    return GestureDetector(
      onTap: () => _requireLogin(() {
        setState(() {
          if (isLiked) {
            _likedPosts.remove(id);
            post['likes'] = (post['likes'] as int) - 1;
          } else {
            _likedPosts.add(id);
            post['likes'] = (post['likes'] as int) + 1;
          }
        });
        _persistInteractions();
      }),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isLiked ? 1.2 : 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        onEnd: () => setState(() {}),
        child: Row(
          children: [
            Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? const Color(0xFFEF4444) : theme.textSecondaryColor, size: 22),
            const SizedBox(width: 4),
            Text('${post['likes']}', style: GoogleFonts.cairo(fontSize: 12, color: theme.textPrimaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(Map<String, dynamic> post) {
    final String id = post['id']?.toString() ?? '';
    final bool isSaved = _savedPosts.contains(id);
    final theme = ThemeConfig.instance;
    
    return GestureDetector(
      onTap: () => _requireLogin(() {
        setState(() {
          if (isSaved) {
            _savedPosts.remove(id);
          } else {
            _savedPosts.add(id);
          }
        });
        _persistInteractions();
      }),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isSaved ? 1.15 : 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        onEnd: () => setState(() {}),
        child: Row(
          children: [
            Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? const Color(0xFF10B981) : theme.textSecondaryColor, size: 22),
            const SizedBox(width: 4),
            Text(isSaved ? 'محفوظ' : 'حفظ', style: GoogleFonts.cairo(fontSize: 12, color: theme.textPrimaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(Map<String, dynamic> post) {
    return _buildInteractionButton(
      icon: Icons.share_outlined,
      label: '${post['shares']}',
      onTap: () => _requireLogin(() {
        // مشاركة مستقبلية
        NotificationsService.instance.toast('تم نسخ رابط المنشور', icon: Icons.link, color: const Color(0xFF059669));
        NotificationsService.instance.add(AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'تمت المشاركة',
          body: post['title'] ?? 'منشور',
        ));
      }),
    );
  }

  void _openTikTokVideoPlayer(Map<String, dynamic> videoData) {
    // يمكن إضافة مشغل فيديو خارجي هنا في المستقبل
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مشغل الفيديو'),
        content: Text('سيتم فتح مشغل الفيديو قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

// _AutoPlayVideo declared below after _TrendsPageState

  void _showJournalistProfile(Map<String, dynamic> journalist) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    // 🔄 تحديث البيانات عند فتح البروفايل
    _loadMediaFromBackend();
    _loadPostsFromBackend();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? ThemeConfig.kNightSoft : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.textSecondaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _loadMediaFromBackend();
                    await _loadPostsFromBackend();
                    setModalState(() {}); // 🔄 تحديث UI البروفايل
                  },
                  color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // صورة الملف الشخصي (مثل صفحة حسابي)
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [ThemeConfig.kGoldNight, ThemeConfig.kGoldNight.withOpacity(0.6)]
                                : [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981)).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? ThemeConfig.kNightSoft : Colors.white,
                          ),
                          padding: EdgeInsets.all(4),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: (journalist['profile_picture'] != null && journalist['profile_picture'].toString().isNotEmpty)
                                ? NetworkImage(journalist['profile_picture'])
                                : (journalist['profile_image'] != null && journalist['profile_image'].toString().isNotEmpty)
                                    ? NetworkImage(journalist['profile_image'])
                                    : null,
                            child: (journalist['profile_picture'] == null || journalist['profile_picture'].toString().isEmpty) &&
                                    (journalist['profile_image'] == null || journalist['profile_image'].toString().isEmpty)
                                ? Text(
                                    journalist['name']?.toString().substring(0, 1) ?? '?',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                                    ),
                                  )
                                : null,
                            backgroundColor: isDark ? ThemeConfig.kNightSoft : Colors.grey[200],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // الاسم والتحقق
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          journalist['name'],
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          size: 24,
                          color: Color(0xFF10B981),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    Text(
                      journalist['bio'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 24),
                    
                    // الإحصائيات (منشورات + متابعون فقط)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTwitterStat('المنشورات', (journalist['posts'] ?? 0).toString()),
                        _buildTwitterStat('المتابعون', (journalist['followers'] ?? 0).toString()),
                      ],
                    ),
                    SizedBox(height: 20),

                    // زر المتابعة (متاح فقط عند تسجيل الدخول)
                    Row(
                      children: [
                        Expanded(
                          child: (_isLoggedIn)
                              ? ElevatedButton.icon(
                                  onPressed: () {
                                    final journalistId = journalist['id']?.toString() ?? '';
                                    _toggleFollow(journalistId);
                                    setModalState(() {}); // تحديث UI
                                  },
                                  icon: Icon(
                                    () {
                                      final journalistId = journalist['id']?.toString() ?? '';
                                      return _followingList.contains(journalistId)
                                          ? Icons.person_remove
                                          : Icons.person_add;
                                    }(),
                                  ),
                                  label: Text(
                                    () {
                                      final journalistId = journalist['id']?.toString() ?? '';
                                      return _followingList.contains(journalistId)
                                          ? 'إلغاء المتابعة'
                                          : 'متابعة';
                                    }(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: () {
                                      final journalistId = journalist['id']?.toString() ?? '';
                                      final isFollowing = _followingList.contains(journalistId);
                                      return isFollowing
                                          ? (isDark ? ThemeConfig.kNightSoft : Colors.grey[300])
                                          : (isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981));
                                    }(),
                                    foregroundColor: () {
                                      final journalistId = journalist['id']?.toString() ?? '';
                                      final isFollowing = _followingList.contains(journalistId);
                                      return isFollowing
                                          ? (isDark ? theme.textSecondaryColor : Colors.grey[700])
                                          : (isDark ? ThemeConfig.kNightDeep : Colors.white);
                                    }(),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )
                              : OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    'سجل الدخول لمتابعة الحساب',
                                    style: GoogleFonts.cairo(
                                      color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // طرق التواصل (فقط المفعلة)
                    if (journalist['contact_email'] != null || journalist['contact_whatsapp'] != null) ...[
                      Text(
                        'طرق التواصل',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          if (journalist['contact_whatsapp'] != null && journalist['contact_whatsapp'].toString().isNotEmpty)
                            Expanded(
                              child: _buildContactMethod(
                                icon: Icons.phone,
                                label: 'واتساب',
                                onTap: () => _contactJournalist(journalist['contact_whatsapp'], 'whatsapp'),
                              ),
                            ),
                          if (journalist['contact_whatsapp'] != null && journalist['contact_email'] != null &&
                              journalist['contact_whatsapp'].toString().isNotEmpty && journalist['contact_email'].toString().isNotEmpty)
                            SizedBox(width: 12),
                          if (journalist['contact_email'] != null && journalist['contact_email'].toString().isNotEmpty)
                            Expanded(
                              child: _buildContactMethod(
                                icon: Icons.email,
                                label: 'بريد إلكتروني',
                                onTap: () => _contactJournalist(journalist['contact_email'], 'email'),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 24),
                    ],

                    // جميع منشورات الإعلامي
                    Text(
                      'منشورات ${journalist['name']}',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(height: 12),
                    ...journalistPosts
                        .where((p) => p['journalistId']?.toString() == (journalist['id']?.toString() ?? ''))
                        .map((p) => _buildPostCard(p))
                        .toList(),
                  ],
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

  Widget _buildTwitterStat(String label, String value) {
    final theme = ThemeConfig.instance;
    
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: theme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: (isDark ? ThemeConfig.kNightAccent : Colors.grey[50]!),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.textSecondaryColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Color(0xFF10B981),
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactJournalist(String contact, String type) {
    if (type == 'phone') {
      launchUrl(Uri.parse('tel:$contact'));
    } else if (type == 'whatsapp') {
      launchUrl(Uri.parse('https://wa.me/966${contact.replaceFirst('0', '')}'));
    } else if (type == 'email') {
      launchUrl(Uri.parse('mailto:$contact'));
    }
  }

  Widget _buildJournalistRegistrationSection() {
    final theme = ThemeConfig.instance;
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981).withOpacity(0.1),
            Color(0xFF059669).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF10B981).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: Color(0xFF10B981),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'كيف أسجل كإعلامي؟',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'انضم إلى منصة الدلما كإعلامي معتمد وشارك أخبارك مع المجتمع',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textPrimaryColor,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showJournalistRegistrationInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'عرض التفاصيل',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJournalistRegistrationInfo() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? ThemeConfig.kNightSoft : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التسجيل كإعلامي معتمد',
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    _buildPolicySection(),
                    SizedBox(height: 24),
                    _buildRequirementsSection(),
                    SizedBox(height: 24),
                    _buildContactSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سياسة الاستخدام والأخلاقيات',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? ThemeConfig.kNightAccent : Colors.grey[50]!),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.textSecondaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPolicyItem('الالتزام بالدقة والموضوعية في نقل الأخبار'),
              _buildPolicyItem('احترام الخصوصية وحقوق الآخرين'),
              _buildPolicyItem('عدم نشر محتوى مسيء أو مخالف للقيم'),
              _buildPolicyItem('الالتزام بالقوانين والأنظمة المحلية'),
              _buildPolicyItem('المحافظة على المهنية في التعامل مع المصادر'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'متطلبات التسجيل',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? ThemeConfig.kNightAccent : Colors.grey[50]!),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.textSecondaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequirementItem('شهادة صحفية أو خبرة في مجال الإعلام'),
              _buildRequirementItem('هوية شخصية سارية المفعول'),
              _buildRequirementItem('عينة من الأعمال الصحفية السابقة'),
              _buildRequirementItem('خطاب توصية من جهة عمل معتمدة'),
              _buildRequirementItem('التوقيع على سياسة الاستخدام والأخلاقيات'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.assignment,
            color: Color(0xFF10B981),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'طرق التواصل للتسجيل',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildContactMethod(
                icon: Icons.phone,
                label: 'اتصال هاتفي',
                onTap: () => _contactGeneral('tel:+966501234567'),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildContactMethod(
                icon: Icons.email,
                label: 'بريد إلكتروني',
                onTap: () => _contactGeneral('mailto:info@aldlma.com'),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          child: _buildContactMethod(
            icon: Icons.location_on,
            label: 'زيارة المكتب',
            onTap: () => _contactGeneral('https://maps.google.com'),
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'معلومات التواصل',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'الهاتف: +966 50 123 4567\nالبريد الإلكتروني: info@aldlma.com\nالعنوان: مدينة عرعر، المملكة العربية السعودية',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _contactGeneral(String url) {
    launchUrl(Uri.parse(url));
  }
}

// زر اسأل الدلما عن الترندات
class _AskDalmaTrendsButton extends StatelessWidget {
  const _AskDalmaTrendsButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog(context: context, builder: (_) => const AskDalmaDialog());
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology_outlined, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text('اسأل الدلما عن الترندات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Standalone auto-play video declared after the page to avoid context mixups
class _TrendsAutoPlayVideo extends StatefulWidget {
  final String assetPath;
  const _TrendsAutoPlayVideo({required this.assetPath});

  @override
  State<_TrendsAutoPlayVideo> createState() => _TrendsAutoPlayVideoState();
}

class _TrendsAutoPlayVideoState extends State<_TrendsAutoPlayVideo> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _muted = true;
  bool _visible = false;

  Future<void> _initIfNeeded() async {
    if (_controller != null) return;
    final c = VideoPlayerController.asset(widget.assetPath);
    await c.initialize();
    await c.setLooping(true);
    await c.setVolume(0.0);
    setState(() {
      _controller = c;
      _initialized = true;
    });
    if (_visible) await c.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height * 0.62;
    return VisibilityDetector(
      key: ValueKey('auto-video-${widget.assetPath}-${hashCode}'),
      onVisibilityChanged: (info) async {
        _visible = info.visibleFraction > 0.6;
        if (_visible) {
          await _initIfNeeded();
          if (_controller != null && _controller!.value.isInitialized) {
            await _controller!.play();
          }
        } else {
          if (_controller != null && _controller!.value.isInitialized) {
            await _controller!.pause();
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: h,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_initialized && _controller != null && _controller!.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                Image.asset('assets/img/تنزيل.jpeg', fit: BoxFit.cover),

              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: () async {
                    if (_controller == null || !_initialized) return;
                    final nowMuted = !_muted;
                    setState(() => _muted = nowMuted);
                    await _controller!.setVolume(nowMuted ? 0.0 : 1.0);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      _muted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
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
}

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final color = Theme.of(context).colorScheme.primary;
    
    return AnimatedBuilder(
      animation: theme,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          decoration: BoxDecoration(
            gradient: theme.headerGradient,
          ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                // Top row with login button and icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _LoginButton(),
                    Row(
                      children: [
                        _ThemeToggleButton(),
                        const SizedBox(width: 8),
                        const NotificationsBell(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Logo with glow effect
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Soft radial glow exactly like in the image
                      Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              color.withOpacity(0.25),
                              color.withOpacity(0.15),
                              color.withOpacity(0.08),
                              color.withOpacity(0.03),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Logo
                      Image.asset('assets/img/aldlma.png', width: 176, height: 176),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Title - exactly as in reference
                Text(
                  'الدلما... زرعها طيب، وخيرها باقٍ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'الدلما منصة مجتمعية تقنية تربطك بخدمات مدينتك، من أهل عرعر إلى أهلها، نوصلك بالأفضل… بضغطة زر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({super.key});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      onTap: () async {
        if (AuthState.instance.isLoggedIn) {
          await AuthState.instance.logout();
          NotificationsService.instance.toast('تم تسجيل الخروج', icon: Icons.logout, color: const Color(0xFFEF4444));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFF059669)]),
          borderRadius: BorderRadius.all(Radius.circular(6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: AnimatedBuilder(
          animation: AuthState.instance,
          builder: (context, _) {
            final isIn = AuthState.instance.isLoggedIn;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isIn ? Icons.logout : Icons.person_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(isIn ? 'تسجيل الخروج' : 'تسجيل الدخول', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, child) {
        final theme = ThemeConfig.instance;
        final isDark = theme.isDarkMode;
        
        return GestureDetector(
          onTap: () async {
            await theme.toggleTheme();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? ThemeConfig.kNightSoft : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: theme.cardShadow,
            ),
            child: Center(
              child: Text(
                isDark ? '☀️' : '🌙',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.cardShadow,
      ),
      child: Center(
        child: Icon(
          icon, 
          color: const Color(0xFF6B7280), 
          size: 20,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final String? count;
  final Color badgeColor;
  const _IconBadge({required this.icon, this.count, this.badgeColor = Colors.red});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? ThemeConfig.kNightSoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              icon, 
              color: const Color(0xFF6B7280), 
              size: 20,
            ),
          ),
          if (count != null)
            Positioned(
              top: -4,
              left: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    count!, 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ========================
// Image Carousel Widget
// ========================
class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  const _ImageCarousel({required this.images});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Column(
      children: [
        // الصور
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.images[index],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
              );
            },
          ),
        ),
        
        // دوائر التوضيح (مثل Instagram)
        if (widget.images.length > 1) ...[
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                width: _currentIndex == index ? 8 : 6,
                height: _currentIndex == index ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? (isDark ? ThemeConfig.kGoldNight : Color(0xFF10B981))
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ========================
// TikTok/Reels Video Player
// ========================
class _TikTokVideoPlayer extends StatelessWidget {
  final String videoUrl;
  final String? thumbnail;
  
  const _TikTokVideoPlayer({
    required this.videoUrl,
    this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    
    return Container(
      height: 500, // حجم TikTok/Reels
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // صورة مصغرة
          if (thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumbnail!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          
          // زر التشغيل
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              size: 40,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
