import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_config.dart';
import 'api_config.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadConversations(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null) {
        setState(() {
          _conversations = [];
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(data['conversations'] ?? []);
          _isLoading = false;
        });
        debugPrint('✅ [CHAT LIST] تم جلب ${_conversations.length} محادثة');
      } else {
        throw Exception('فشل جلب المحادثات');
      }
    } catch (e) {
      debugPrint('❌ [CHAT LIST] خطأ: $e');
      setState(() {
        if (!silent) {
          _conversations = [];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf8fafc),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        title: Text(
          'المحادثات',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'جاري التحميل...',
                    style: GoogleFonts.cairo(
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
          : _conversations.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: () => _loadConversations(),
                  color: theme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationCard(conversation, theme);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeConfig theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: theme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد محادثات',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'ابدأ محادثة مع المكاتب العقارية من صفحة تفاصيل العقار',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation, ThemeConfig theme) {
    final officeName = conversation['office_name'] ?? 'مكتب عقاري';
    final officeLogo = conversation['office_logo'];
    final lastMessage = conversation['last_message'] ?? '';
    final lastSender = conversation['last_sender'];
    final lastMessageAt = conversation['last_message_at'];
    final unreadCount = conversation['unread_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: unreadCount > 0
            ? BorderSide(color: theme.primaryColor.withOpacity(0.3), width: 2)
            : BorderSide.none,
      ),
      elevation: theme.isDarkMode ? 0 : 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                officeId: conversation['office_id'],
                officeName: officeName,
                officeLogo: officeLogo,
              ),
            ),
          ).then((_) {
            // تحديث القائمة بعد الرجوع
            _loadConversations();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // صورة المكتب
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: unreadCount > 0
                            ? theme.primaryColor
                            : theme.textSecondaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: officeLogo != null
                        ? CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(officeLogo),
                            backgroundColor: Colors.white,
                          )
                        : CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.business,
                              color: theme.primaryColor,
                              size: 28,
                            ),
                          ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.isDarkMode
                                ? const Color(0xFF1a1f2e)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // معلومات المحادثة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            officeName,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(lastMessageAt),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: theme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (lastSender == 'user')
                          Icon(
                            Icons.check,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                        if (lastSender == 'user') const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: unreadCount > 0
                                  ? theme.textPrimaryColor
                                  : theme.textSecondaryColor,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // سهم
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return '${diff.inMinutes} د';
      if (diff.inHours < 24) return '${diff.inHours} س';
      if (diff.inDays < 7) return '${diff.inDays} يوم';

      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}


