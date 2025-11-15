import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_config.dart';
import 'api_config.dart';

class ChatPage extends StatefulWidget {
  final int officeId;
  final String officeName;
  final String? officeLogo;
  
  const ChatPage({
    super.key,
    required this.officeId,
    required this.officeName,
    this.officeLogo,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOnline = true;
  bool _isTyping = false;
  Timer? _autoRefreshTimer;
  Timer? _typingTimer;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startAutoRefresh();
    _messageController.addListener(_onTyping);
  }
  
  void _startAutoRefresh() {
    // تحديث تلقائي كل 3 ثوان
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isSending && mounted) {
        _loadMessages(silent: true);
        _checkOnlineStatus();
      }
    });
  }
  
  Future<void> _checkOnlineStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/office/online-status/${widget.officeId}'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isOnline = data['is_online'] ?? false;
          });
        }
      }
    } catch (e) {
      // لا نعرض خطأ، فقط نترك الحالة كما هي
    }
  }
  
  void _onTyping() {
    // TODO: إرسال حالة "جاري الكتابة" للسيرفر
    // الآن فقط نعرض محلياً
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _typingTimer?.cancel();
    _messageController.removeListener(_onTyping);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null) {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/${widget.officeId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('📡 [CHAT] Response status: ${response.statusCode}');
      debugPrint('📡 [CHAT] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newMessages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
        final hasNewMessages = newMessages.length > _lastMessageCount;
        
        setState(() {
          _messages = newMessages;
          _isLoading = false;
          _isOnline = true; // متصل بنجاح
        });
        
        // التمرير للأسفل فقط عند رسالة جديدة
        if (hasNewMessages || _lastMessageCount == 0) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
        
        _lastMessageCount = newMessages.length;
        debugPrint('✅ [CHAT] تم جلب ${_messages.length} رسالة');
      } else {
        debugPrint('❌ [CHAT] خطأ ${response.statusCode}: ${response.body}');
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CHAT] خطأ: $e');
      setState(() {
        if (!silent) {
          _messages = [];
        }
        _isLoading = false;
        _isOnline = false; // غير متصل
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يجب تسجيل الدخول أولاً',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
        setState(() => _isSending = false);
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'office_id': widget.officeId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        _messageController.clear();
        setState(() => _isSending = false);
        
        // إعادة تحميل الرسائل
        await _loadMessages();
      } else {
        throw Exception('فشل إرسال الرسالة');
      }
    } catch (e) {
      debugPrint('❌ [CHAT] خطأ في الإرسال: $e');
      setState(() => _isSending = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل إرسال الرسالة',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
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
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: widget.officeLogo != null
                  ? CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(widget.officeLogo!),
                      backgroundColor: Colors.white,
                    )
                  : CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.business,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.officeName,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline ? const Color(0xFF00ff88) : Colors.grey,
                          shape: BoxShape.circle,
                          boxShadow: _isOnline
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF00ff88).withOpacity(0.6),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? 'متصل الآن' : 'غير متصل',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            onPressed: () {
              _showOptionsMenu(theme);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // الرسائل
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message['sender_type'] == 'user';
                          return _buildMessageBubble(message, isUser, theme);
                        },
                      ),
          ),

          // مؤشر "جاري الكتابة"
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: theme.isDarkMode
                  ? const Color(0xFF1a1f2e).withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: widget.officeLogo != null
                        ? CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(widget.officeLogo!),
                            backgroundColor: Colors.white,
                          )
                        : CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.business,
                              color: theme.primaryColor,
                              size: 14,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'جاري الكتابة',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // حقل الإدخال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: theme.isDarkMode
                      ? const Color(0xFF2a2f3e)
                      : const Color(0xFFe2e8f0),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.isDarkMode
                            ? const Color(0xFF2a2f3e)
                            : const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.isDarkMode
                              ? const Color(0xFF3a3f4e)
                              : const Color(0xFFe2e8f0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        maxLength: 500,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: GoogleFonts.cairo(
                          color: theme.textPrimaryColor,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك هنا...',
                          hintStyle: GoogleFonts.cairo(
                            color: theme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          counterText: '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                      onPressed: _isSending ? null : _sendMessage,
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

  void _showOptionsMenu(ThemeConfig theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.isDarkMode ? const Color(0xFF1a1f2e) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.info_outline, color: theme.primaryColor),
              title: Text(
                'معلومات المكتب',
                style: GoogleFonts.cairo(color: theme.textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: معلومات المكتب
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'مسح المحادثة',
                style: GoogleFonts.cairo(color: theme.textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: مسح المحادثة
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.orange),
              title: Text(
                'حظر المكتب',
                style: GoogleFonts.cairo(color: theme.textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: حظر المكتب
              },
            ),
          ],
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
            'ابدأ المحادثة مع ${widget.officeName}',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'اكتب رسالتك الأولى واحصل على رد سريع من المكتب',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: theme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'رسائلك آمنة ومشفرة',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isUser,
    ThemeConfig theme,
  ) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              // صورة المكتب
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: widget.officeLogo != null
                    ? CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(widget.officeLogo!),
                        backgroundColor: Colors.white,
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.business,
                          color: theme.primaryColor,
                          size: 16,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
            ],
            // الفقاعة
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? LinearGradient(
                          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.85)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        )
                      : null,
                  color: isUser
                      ? null
                      : (theme.isDarkMode
                          ? const Color(0xFF1a1f2e)
                          : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? theme.primaryColor.withOpacity(0.3)
                          : Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: isUser
                      ? null
                      : Border.all(
                          color: theme.isDarkMode
                              ? const Color(0xFF2a2f3e)
                              : const Color(0xFFe2e8f0),
                          width: 1,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message['message'] ?? '',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        height: 1.5,
                        color: isUser ? Colors.white : theme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isUser
                              ? Colors.white.withOpacity(0.7)
                              : theme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(message['created_at']),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isUser
                                ? Colors.white.withOpacity(0.7)
                                : theme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              // أيقونة المستخدم
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.transparent,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
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

      if (diff.inDays > 0) {
        return '${diff.inDays} يوم';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} ساعة';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return '';
    }
  }
}

