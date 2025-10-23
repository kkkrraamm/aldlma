import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> with TickerProviderStateMixin {
  PageController? _bannerController;
  late AnimationController _fadeController;
  Animation<double>? _fadeAnimation;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredJournalists = [];
  List<Map<String, dynamic>> _followingList = [];
  bool _isSearching = false;

  // بيانات الإعلاميين المعتمدين
  final List<Map<String, dynamic>> verifiedJournalists = [
    {
      'name': 'محمد الحدود',
      'username': '@mohammed_borders',
      'avatar': 'img/aldlma.png',
      'specialty': 'صحفي سياسي',
      'followers': '12.5K',
      'phone': '+966501234567',
      'email': 'mohammed@example.com',
      'bio': 'صحفي متخصص في الشؤون السياسية والاقتصادية',
      'posts': 156,
      'following': 89,
    },
    {
      'name': 'فاطمة النور',
      'username': '@fatima_light',
      'avatar': 'img/aldlma.png',
      'specialty': 'مراسلة ثقافية',
      'followers': '8.2K',
      'phone': '+966507654321',
      'email': 'fatima@example.com',
      'bio': 'مراسلة متخصصة في الشؤون الثقافية والفنية',
      'posts': 98,
      'following': 67,
    },
    {
      'name': 'أحمد الشمال',
      'username': '@ahmed_north',
      'avatar': 'img/aldlma.png',
      'specialty': 'مصور صحفي',
      'followers': '15.3K',
      'phone': '+966509876543',
      'email': 'ahmed@example.com',
      'bio': 'مصور صحفي متخصص في التغطية الميدانية',
      'posts': 234,
      'following': 45,
    },
  ];

  // منشورات الإعلاميين
  final List<Map<String, dynamic>> journalistPosts = [
    {
      'type': 'video',
      'videoUrl': 'assets/videos/Download.mp4',
      'videoTitle': 'مهرجان عرعر الثقافي',
      'videoDuration': '2:15',
      'content': 'تغطية مباشرة من افتتاح مهرجان عرعر الثقافي، بمشاركة واسعة من أهالي المنطقة وضيوف من المملكة.',
      'author': 'محمد الحدود',
      'authorUsername': '@mohammed_borders',
      'authorAvatar': 'img/aldlma.png',
      'timeAgo': 'منذ 6 ساعات',
      'likes': 312,
      'comments': 67,
      'shares': 23,
      'hashtags': ['#مهرجان_عرعر', '#ثقافة_محلية'],
    },
    {
      'type': 'image',
      'imageUrl': 'img/تنزيل.jpeg',
      'content': 'صورة من داخل قاعة المؤتمرات خلال الجلسة الافتتاحية للمؤتمر الصحفي.',
      'author': 'فاطمة النور',
      'authorUsername': '@fatima_light',
      'authorAvatar': 'img/aldlma.png',
      'timeAgo': 'منذ 4 ساعات',
      'likes': 189,
      'comments': 34,
      'shares': 12,
      'hashtags': ['#مؤتمر_صحفي', '#تغطية_مباشرة'],
    },
    {
      'type': 'text',
      'content': 'تقرير شامل عن التطورات الأخيرة في المشاريع التنموية بالمنطقة الشمالية، مع إبراز دور القطاع الخاص في دعم الاقتصاد المحلي.',
      'author': 'أحمد الشمال',
      'authorUsername': '@ahmed_north',
      'authorAvatar': 'img/aldlma.png',
      'timeAgo': 'منذ ساعتين',
      'likes': 156,
      'comments': 28,
      'shares': 8,
      'hashtags': ['#تنمية_محلية', '#اقتصاد_محلي'],
    },
  ];

  // بيانات الترندات
  final List<Map<String, dynamic>> trendingBanners = [
    {
      'title': 'مهرجان عرعر الثقافي',
      'subtitle': 'تغطية حصرية مباشرة',
      'color': Color(0xFF10B981),
    },
    {
      'title': 'مؤتمر التنمية المستدامة',
      'subtitle': 'أحدث التطورات',
      'color': Color(0xFF3B82F6),
    },
    {
      'title': 'قمة الشباب العربي',
      'subtitle': 'رؤى مستقبلية',
      'color': Color(0xFF8B5CF6),
    },
  ];

  final List<String> trendingHashtags = [
    '#مهرجان_عرعر',
    '#ثقافة_محلية',
    '#تنمية_محلية',
    '#اقتصاد_محلي',
    '#مؤتمر_صحفي',
    '#تغطية_مباشرة',
  ];

  final List<Map<String, dynamic>> trendingTopics = [
    {
      'title': 'السياحة الثقافية',
      'posts': 1250,
      'trend': '+15%',
    },
    {
      'title': 'الاستثمار المحلي',
      'posts': 890,
      'trend': '+8%',
    },
    {
      'title': 'التنمية المستدامة',
      'posts': 2100,
      'trend': '+22%',
    },
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
    _filteredJournalists = List.from(verifiedJournalists);
    _searchController.addListener(_onSearchChanged);
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

  @override
  void dispose() {
    _bannerController?.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
              child: Column(
                children: [
                  _buildSearchSection(),
                  _buildJournalistsList(),
                  _buildPostsFeed(),
                  _buildJournalistRegistrationSection(),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _HeroHeader(),
          // زر اسأل الدلما عن الترندات
          Container(
            transform: Matrix4.translationValues(0, -16, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AskDalmaTrendsButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'البحث عن الإعلاميين',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن اسم أو تخصص الإعلامي...',
              hintStyle: GoogleFonts.cairo(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: Color(0xFF10B981)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
              ),
            ),
            style: GoogleFonts.cairo(fontSize: 14),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_searchController.text.isNotEmpty)
                Text(
                  'نتائج البحث (${_filteredJournalists.length})',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                )
              else
                Text(
                  'الإعلاميين المعتمدين',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _showFollowingList,
                icon: Icon(Icons.people, size: 16),
                label: Text(
                  'قائمة المتابعين (${_followingList.length})',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
      height: 140,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredJournalists.length,
        itemBuilder: (context, index) {
          final journalist = _filteredJournalists[index];
          return Container(
            width: 260,
            margin: EdgeInsets.only(right: 12),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // صورة الإعلامي
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF10B981),
                      child: Image.asset(
                        journalist['avatar'],
                        width: 28,
                        height: 28,
                      ),
                    ),
                    // معلومات الإعلامي
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    journalist['name'],
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.verified,
                                  color: Color(0xFF10B981),
                                  size: 10,
                                ),
                              ],
                            ),
                            SizedBox(height: 1),
                            Text(
                              journalist['username'],
                              style: GoogleFonts.cairo(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1),
                            Text(
                              journalist['specialty'],
                              style: GoogleFonts.cairo(
                                fontSize: 7,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1),
                            Text(
                              '${journalist['followers']} متابع',
                              style: GoogleFonts.cairo(
                                fontSize: 6,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // زر عرض البروفايل
                    SizedBox(
                      width: double.infinity,
                        child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showJournalistProfile(journalist),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'عرض',
                                style: GoogleFonts.cairo(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _toggleFollow(journalist),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _followingList.contains(journalist) 
                                    ? Colors.grey[400] 
                                    : Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _followingList.contains(journalist) ? 'متابع' : 'متابعة',
                                style: GoogleFonts.cairo(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsFeed() {
    return Column(
      children: journalistPosts.map((post) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // هيدر المنشور
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF10B981),
                        child: Image.asset(
                          post['authorAvatar'],
                          width: 30,
                          height: 30,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  post['author'],
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  color: Color(0xFF10B981),
                                  size: 16,
                                ),
                              ],
                            ),
                            Text(
                              post['authorUsername'],
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        post['timeAgo'],
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.more_vert,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // محتوى المنشور
                  Text(
                    post['content'],
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // الفيديو أو الصورة
                  if (post['type'] == 'video')
                    _buildTikTokStyleVideo(post)
                  else if (post['type'] == 'image')
                    _buildImagePost(post),
                  
                  SizedBox(height: 16),
                  
                  // الهاشتاغات
                  if (post['hashtags'] != null && (post['hashtags'] as List).isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: (post['hashtags'] as List<String>).map((hashtag) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            hashtag,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  SizedBox(height: 16),
                  
                  // أزرار التفاعل
                  Row(
                    children: [
                      Expanded(
                        child: _buildInteractionButton(
                          icon: Icons.favorite_border,
                          label: post['likes'].toString(),
                          onTap: () {},
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInteractionButton(
                          icon: Icons.comment_outlined,
                          label: post['comments'].toString(),
                          onTap: () {},
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInteractionButton(
                          icon: Icons.share_outlined,
                          label: post['shares'].toString(),
                          onTap: () {},
                        ),
                      ),
                      SizedBox(width: 8),
                      _buildInteractionButton(
                        icon: Icons.bookmark_border,
                        label: '',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTikTokStyleVideo(Map<String, dynamic> post) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // 70% من ارتفاع الشاشة مثل تيك توك
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 3,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildVideoThumbnail(post),
      ),
    );
  }

  Widget _buildVideoThumbnail(Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () => _openTikTokVideoPlayer({
        'videoTitle': post['title'] ?? 'فيديو إعلامي',
        'duration': post['duration'] ?? '2:15',
      }),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('img/تنزيل.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePost(Map<String, dynamic> post) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(post['imageUrl']),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _toggleFollow(Map<String, dynamic> journalist) {
    setState(() {
      if (_followingList.contains(journalist)) {
        _followingList.remove(journalist);
      } else {
        _followingList.add(journalist);
      }
    });
  }

  void _showFollowingList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF10B981), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'قائمة المتابعين',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: _followingList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لم تتابع أي إعلامي بعد',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'ابدأ بمتابعة الإعلاميين المعتمدين',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _followingList.length,
                      itemBuilder: (context, index) {
                        final journalist = _followingList[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFF10B981),
                              child: Image.asset(
                                journalist['avatar'],
                                width: 30,
                                height: 30,
                              ),
                            ),
                            title: Text(
                              journalist['name'],
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              journalist['specialty'],
                              style: GoogleFonts.cairo(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${journalist['followers']} متابع',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _toggleFollow(journalist),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    'إلغاء المتابعة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showJournalistProfile(journalist);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey[600],
              size: 18,
            ),
            if (label.isNotEmpty) ...[
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showJournalistProfile(Map<String, dynamic> journalist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // مقبض السحب
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // محتوى البروفايل
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // صورة الإعلامي
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFF10B981),
                      child: Image.asset(
                        journalist['avatar'],
                        width: 80,
                        height: 80,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // اسم الإعلامي
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          journalist['name'],
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 8),
                    
                    // اسم المستخدم
                    Text(
                      journalist['username'],
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // السيرة الذاتية
                    Text(
                      journalist['bio'],
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 24),
                    
                    // الإحصائيات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTwitterStat('المنشورات', journalist['posts'].toString()),
                        _buildTwitterStat('المتابعون', journalist['followers']),
                        _buildTwitterStat('المتابعون', journalist['following'].toString()),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // أزرار التواصل
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _contactJournalist(journalist, 'phone'),
                            icon: Icon(Icons.phone, color: Colors.white),
                            label: Text(
                              'اتصال',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _contactJournalist(journalist, 'email'),
                            icon: Icon(Icons.email, color: Colors.white),
                            label: Text(
                              'إيميل',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwitterStat(String label, String value) {
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
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _openTikTokVideoPlayer(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TikTokStyleVideoPlayer(
          videoTitle: post['videoTitle'] ?? 'مهرجان عرعر الثقافي',
          duration: post['duration'] ?? '2:15',
        ),
      ),
    );
  }

  void _contactJournalist(Map<String, dynamic> journalist, String method) {
    if (method == 'phone') {
      launchUrl(Uri.parse('tel:${journalist['phone']}'));
    } else if (method == 'email') {
      launchUrl(Uri.parse('mailto:${journalist['email']}'));
    }
  }

  void _contactGeneral(String url) async {
    launchUrl(Uri.parse(url));
  }

  Widget _buildJournalistRegistrationSection() {
    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10B981),
                Color(0xFF059669),
              ],
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.verified_user,
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'كيف أسجل كإعلامي؟',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'انضم إلى منصة الدلما للإعلاميين المعتمدين',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _showJournalistRegistrationInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF10B981),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'عرض شروط التسجيل',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJournalistRegistrationInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xFF10B981), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'التسجيل كإعلامي معتمد',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // سياسة الاستخدام والأخلاق
                    _buildPolicySection(),
                    SizedBox(height: 24),
                    // طرق التواصل
                    _buildContactSection(),
                    SizedBox(height: 24),
                    // متطلبات التسجيل
                    _buildRequirementsSection(),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.policy, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'سياسة الاستخدام والأخلاق',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• الالتزام بالمهنية والموضوعية في النشر\n'
              '• احترام حقوق الملكية الفكرية\n'
              '• تجنب نشر المحتوى المسيء أو الكاذب\n'
              '• الحفاظ على سرية المصادر عند الحاجة\n'
              '• الالتزام بالقوانين والأنظمة المحلية',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'طرق التواصل',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildContactMethod(
              icon: Icons.phone,
              title: 'الهاتف',
              subtitle: '+966 11 123 4567',
              onTap: () => _contactGeneral('tel:+966111234567'),
            ),
            SizedBox(height: 12),
            _buildContactMethod(
              icon: Icons.email,
              title: 'البريد الإلكتروني',
              subtitle: 'journalists@aldlma.com',
              onTap: () => _contactGeneral('mailto:journalists@aldlma.com'),
            ),
            SizedBox(height: 12),
            _buildContactMethod(
              icon: Icons.location_on,
              title: 'الزيارة المباشرة',
              subtitle: 'مكتب الدلما - الرياض، المملكة العربية السعودية',
              onTap: () => _contactGeneral('https://maps.google.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Color(0xFF10B981), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  'متطلبات التسجيل',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• شهادة صحفية أو خبرة في مجال الإعلام\n'
              '• عينة من الأعمال المنشورة\n'
              '• صورة شخصية حديثة\n'
              '• نسخة من الهوية الوطنية\n'
              '• خطاب توصية من جهة عمل سابقة (اختياري)',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF10B981).withOpacity(0.1),
            Color(0xFF059669).withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Text(
            'منصة الدلما للترندات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'منصة إعلامية متخصصة للصحفيين المعتمدين',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.copyright, size: 16, color: Colors.grey[500]),
              SizedBox(width: 4),
              Text(
                '2024 الدلما. جميع الحقوق محفوظة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// مشغل فيديو كامل الشاشة
class _TikTokStyleVideoPlayer extends StatefulWidget {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = true;
  bool _showControls = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  Animation<double>? _fadeAnimation;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
  }

  Future<void> _initializeVideo() async {
    try {
      print('بدء تحميل الفيديو: ${widget.videoUrl}');
      
      // التأكد من أن المسار صحيح
      String videoPath = widget.videoUrl;
      if (!videoPath.startsWith('assets/')) {
        videoPath = 'assets/videos/Download.mp4';
        print('تم تصحيح مسار الفيديو إلى: $videoPath');
      }
      
      _controller = VideoPlayerController.asset(videoPath);
      
      await _controller!.initialize();
      print('تم تحميل الفيديو بنجاح');
      print('أبعاد الفيديو: ${_controller!.value.size}');
      
      // إضافة listener لتتبع حالة الفيديو
      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // تشغيل الفيديو بدون صوت
        _controller!.setVolume(0.0);
        _controller!.setLooping(true);
        
        // تأخير بسيط قبل التشغيل
        await Future.delayed(Duration(milliseconds: 100));
        await _controller!.play();
        
        setState(() {
          _isPlaying = true;
        });
        
        print('تم تشغيل الفيديو بنجاح');
        print('حالة التشغيل: ${_controller!.value.isPlaying}');
      }
    } catch (e) {
      print('خطأ في تحميل الفيديو: $e');
      print('مسار الفيديو: ${widget.videoUrl}');
      print('نوع الخطأ: ${e.runtimeType}');
      
      // في حالة الخطأ، نعرض صورة بديلة
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
        });
      }
    }
  }

  void _togglePlayPause() async {
    if (_controller != null && _isInitialized) {
      try {
        if (_isPlaying) {
          await _controller!.pause();
          print('تم إيقاف الفيديو');
        } else {
          await _controller!.play();
          print('تم تشغيل الفيديو');
        }
        setState(() {
          _isPlaying = !_isPlaying;
        });
      } catch (e) {
        print('خطأ في تشغيل/إيقاف الفيديو: $e');
      }
    }
  }

  void _toggleMute() {
    if (_controller != null && _isInitialized) {
      if (_isMuted) {
        _controller!.setVolume(1.0);
      } else {
        _controller!.setVolume(0.0);
      }
      setState(() {
        _isMuted = !_isMuted;
      });
    }
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _fadeController.forward();
    
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showControls = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isInitialized && !_isPlaying) {
          // إذا كان الفيديو محمل لكن لا يعمل، حاول تشغيله
          _togglePlayPause();
        } else if (_showControls) {
          widget.onTap();
        } else {
          _showControlsTemporarily();
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // الفيديو
            if (_isInitialized && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('img/تنزيل.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_hasError) ...[
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'جاري تحميل الفيديو...',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'خطأ في تحميل الفيديو',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                            });
                            _initializeVideo();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'إعادة المحاولة',
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // زر التشغيل المركزي (إذا لم يكن الفيديو يعمل)
            if (_isInitialized && !_isPlaying)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // أزرار التحكم
            if (_showControls)
              FadeTransition(
                opacity: _fadeAnimation ?? AlwaysStoppedAnimation(1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // زر التشغيل/الإيقاف المركزي
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),

                      // زر الكتم
                      Positioned(
                        top: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: _toggleMute,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // زر فتح كامل الشاشة
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: widget.onTap,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // مؤشر التشغيل
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isPlaying ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '2:15',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// مشغل فيديو كامل الشاشة
class TikTokStyleVideoPlayer extends StatefulWidget {
  final String videoTitle;
  final String duration;

  const TikTokStyleVideoPlayer({
    Key? key,
    required this.videoTitle,
    required this.duration,
  }) : super(key: key);

  @override
  _TikTokStyleVideoPlayerState createState() => _TikTokStyleVideoPlayerState();
}

class _TikTokStyleVideoPlayerState extends State<TikTokStyleVideoPlayer>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showControls = true;
  late AnimationController _fadeController;
  Animation<double>? _fadeAnimation;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/Download.mp4');
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        _controller!.play();
        _controller!.setLooping(true);
        
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print('خطأ في تحميل الفيديو: $e');
    }
  }

  void _togglePlayPause() async {
    if (_controller != null && _isInitialized) {
      try {
        if (_isPlaying) {
          await _controller!.pause();
          print('تم إيقاف الفيديو');
        } else {
          await _controller!.play();
          print('تم تشغيل الفيديو');
        }
        setState(() {
          _isPlaying = !_isPlaying;
        });
      } catch (e) {
        print('خطأ في تشغيل/إيقاف الفيديو: $e');
      }
    }
  }

  void _toggleMute() {
    if (_controller != null && _isInitialized) {
      if (_isMuted) {
        _controller!.setVolume(1.0);
      } else {
        _controller!.setVolume(0.0);
      }
      setState(() {
        _isMuted = !_isMuted;
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),

          // أزرار التحكم
          Positioned(
            bottom: 50,
            right: 20,
            child: Column(
              children: [
                _buildTikTokButton(
                  icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                  onTap: _togglePlayPause,
                ),
                SizedBox(height: 20),
                _buildTikTokButton(
                  icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                  onTap: _toggleMute,
                ),
              ],
            ),
          ),

          // زر الإغلاق
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // عنوان الفيديو
          Positioned(
            bottom: 50,
            left: 20,
            right: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.videoTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'مدة الفيديو: ${widget.duration}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTikTokButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0xFF10B981).withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// زر اسأل الدلما عن الترندات
class _AskDalmaTrendsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
            _showAskDalmaTrendsDialog(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'اسأل الدلما عن الترندات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAskDalmaTrendsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'اسأل الدلما عن الترندات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ما هو الترند الذي تريد معرفة المزيد عنه؟',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'اكتب سؤالك هنا...',
                hintStyle: GoogleFonts.cairo(
                  color: Colors.grey[500],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: GoogleFonts.cairo(),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showTrendsResponse(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'اسأل',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrendsResponse(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.psychology,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'إجابة الدلما',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '📈 الترندات الحالية في عرعر:',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildTrendItem(context, 'مهرجان عرعر الثقافي', '🔥 ترندينغ الآن'),
                  _buildTrendItem(context, 'التنمية المستدامة', '📊 +22% هذا الأسبوع'),
                  _buildTrendItem(context, 'الاستثمار المحلي', '💼 +8% نمو'),
                  _buildTrendItem(context, 'السياحة الثقافية', '🎭 +15% اهتمام'),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'هذه هي أحدث الترندات في مدينتك. هل تريد معرفة المزيد عن أي منها؟',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'شكراً لك',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(BuildContext context, String title, String status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            status,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// هيدر الصفحة الرئيسية - نسخة مطابقة
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFEF3E2), Color(0xFFECFDF5), Color(0xFFFEF3E2)],
        ),
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
                        const _IconButton(icon: Icons.nightlight_round_outlined),
                        SizedBox(width: 8),
                        const _IconBadge(
                          icon: Icons.people,
                          count: '0',
                          badgeColor: Color(0xFF10B981),
                        ),
                        SizedBox(width: 8),
                        const _IconBadge(icon: Icons.notifications_none, count: '3', badgeColor: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        const _IconBadge(icon: Icons.chat_bubble_outline, count: '2', badgeColor: Color(0xFF3B82F6)),
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
                      Image.asset('img/aldlma.png', width: 176, height: 176),
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
  }
}

// زر تسجيل الدخول
class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'تسجيل الدخول',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// زر الأيقونة
class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// زر الأيقونة مع العداد
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color badgeColor;
  final VoidCallback? onPressed;
  const _IconBadge({
    required this.icon,
    required this.count,
    required this.badgeColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
      ),
    );
  }
}