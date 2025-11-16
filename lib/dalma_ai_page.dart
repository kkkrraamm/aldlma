import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'theme_config.dart';
import 'api_config.dart';

class DalmaAIPage extends StatefulWidget {
  const DalmaAIPage({super.key});

  @override
  State<DalmaAIPage> createState() => _DalmaAIPageState();
}

class _DalmaAIPageState extends State<DalmaAIPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('dalma_ai_messages');
    if (savedMessages != null) {
      setState(() {
        _messages.addAll(List<Map<String, dynamic>>.from(jsonDecode(savedMessages)));
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dalma_ai_messages', jsonEncode(_messages));
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'من الشمال.. للعالم، بعقلٍ فيه خير 🌟 يا هلا بالقرابة! وش علومك اليوم؟ 😎🔥',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      _saveMessages();
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isTyping) return;

    // إضافة رسالة المستخدم
    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();
    _saveMessages();

    try {
      // إرسال للباك إند مع Prompt ID
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/dalma-ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'history': _messages.take(_messages.length - 1).toList(),
          'prompt_id': 'pmpt_68d9e5897e508193a8362567a7e2b1b30556320da57d2e9c',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': data['reply'],
            'timestamp': DateTime.now().toIso8601String(),
          });
          _isTyping = false;
        });
        _saveMessages();
        _scrollToBottom();
      } else {
        throw Exception('فشل الاتصال');
      }
    } catch (e) {
      debugPrint('❌ [DALMA AI] خطأ: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'عذراً يا وجه الخير، صار عندي مشكلة بالاتصال. جرب مرة ثانية 😅',
          'timestamp': DateTime.now().toIso8601String(),
        });
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'مسح المحادثة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'هل تريد مسح جميع الرسائل؟',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              _saveMessages();
              _addWelcomeMessage();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('مسح', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeConfig>(context);

    return Scaffold(
      backgroundColor: theme.isDarkMode ? const Color(0xFF0b0f14) : const Color(0xFFf5f7fa),
      body: Stack(
        children: [
          // الخلفية المتدرجة
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10b981).withOpacity(0.1),
                    const Color(0xFF059669).withOpacity(0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // المحتوى
          Column(
            children: [
              // الهيدر
              _buildHeader(theme),
              
              // الرسائل
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator(theme);
                          }
                          return _buildMessageBubble(_messages[index], theme);
                        },
                      ),
              ),

              // حقل الإدخال
              _buildInputField(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeConfig theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10b981),
            const Color(0xFF059669),
            const Color(0xFF047857),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            children: [
              // الصف الأول: زر الرجوع واللوقو والحذف
              Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  
                  const Spacer(),
                  
                  // لوقو الدلما مع تأثير
                  Hero(
                    tag: 'dalma_logo',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                    ),
                    onPressed: _clearChat,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // العنوان والوصف
              Text(
                'ذكاء الدلما',
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'من الشمال.. للعالم، بعقلٍ فيه خير',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
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
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'مرحباً بك في ذكاء الدلما',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'من الشمال.. للعالم، بعقلٍ فيه خير\nابدأ المحادثة الآن!',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, ThemeConfig theme) {
    final isUser = message['role'] == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10b981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10b981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF10b981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : (theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 4),
                  topRight: Radius.circular(isUser ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF10b981).withOpacity(0.3)
                        : Colors.black.withOpacity(theme.isDarkMode ? 0.2 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message['content'],
                style: GoogleFonts.cairo(
                  fontSize: 15.5,
                  color: isUser ? Colors.white : theme.textPrimaryColor,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.3),
                    theme.primaryColor.withOpacity(0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(theme.isDarkMode ? 0.3 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(theme, 0),
                const SizedBox(width: 4),
                _buildDot(theme, 200),
                const SizedBox(width: 4),
                _buildDot(theme, 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ThemeConfig theme, int delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Opacity(
          opacity: (value * 2).clamp(0, 1),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(ThemeConfig theme) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: theme.isDarkMode ? const Color(0xFF1e293b) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: theme.isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFf5f7fa),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.isDarkMode 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.cairo(
                  color: theme.textPrimaryColor,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: GoogleFonts.cairo(
                    color: theme.textSecondaryColor.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10b981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: _sendMessage,
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

