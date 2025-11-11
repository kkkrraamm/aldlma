import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'api_config.dart';

class AIDalmaPage extends StatefulWidget {
  const AIDalmaPage({super.key});

  @override
  State<AIDalmaPage> createState() => _AIDalmaPageState();
}

class _AIDalmaPageState extends State<AIDalmaPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  int? _streamMsgIndex;

  // API إعدادات ذكاء الدلما
  // يستخدم نفس الـ API Key المستخدم في أدوات الدلما الأخرى

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    
    setState(() {
      _messages.add({'role': 'user', 'text': text, 'ts': DateTime.now()});
      _loading = true;
    });
    _controller.clear();
    _scrollDown();

    // Streaming: أضف رسالة مساعد فارغة وابدأ البث
    setState(() {
      _streamMsgIndex = _messages.length;
      _messages.add({'role': 'assistant', 'text': '', 'ts': DateTime.now()});
    });
    _scrollDown();

    String? streamResult;
    try {
      streamResult = await _askDalmaStream(text);
    } catch (e) {
      debugPrint('❌ [STREAM] Error: $e');
    }
    
    // إذا كان الـ buffer فارغ أو فشل الـ streaming، نستخدم regular response
    if (streamResult == null || streamResult.isEmpty) {
      debugPrint('⚠️ [STREAM] Buffer empty, using regular response');
      try {
        final answer = await _askDalma(text);
        setState(() {
          if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
            _messages[_streamMsgIndex!]['text'] = answer;
          } else {
            _messages.add({'role': 'assistant', 'text': answer, 'ts': DateTime.now()});
          }
        });
      } catch (e2) {
        debugPrint('❌ [REGULAR] Error: $e2');
        setState(() {
          if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
            _messages[_streamMsgIndex!]['text'] = 'عذراً، الدلما غير متاح حالياً. يرجى المحاولة لاحقاً.';
          } else {
            _messages.add({'role': 'assistant', 'text': 'عذراً، الدلما غير متاح حالياً. يرجى المحاولة لاحقاً.', 'ts': DateTime.now()});
          }
        });
      }
    }
    
    setState(() {
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildQuickAction({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required ThemeConfig theme,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.15),
              primaryColor.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final theme = ThemeConfig.instance;
        final primaryColor = theme.primaryColor;
        final isDark = theme.isDarkMode;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.textPrimaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/img/aldlma.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.psychology, color: Colors.white, size: 20);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ذكاء اصطناعي الدلما',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              theme.backgroundColor,
                              theme.backgroundColor.withOpacity(0.95),
                            ]
                          : [
                              const Color(0xFFFEF3E2).withOpacity(0.3),
                              const Color(0xFFECFDF5).withOpacity(0.3),
                            ],
                    ),
                  ),
                  child: _messages.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // شعار الدلما مع انيميشن
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1500),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Transform.rotate(
                                        angle: (1 - value) * 0.5,
                                        child: Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                primaryColor.withOpacity(0.2),
                                                primaryColor.withOpacity(0.1),
                                                primaryColor.withOpacity(0.05),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.3),
                                                blurRadius: 30,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Image.asset(
                                            'assets/img/aldlma.png',
                                            width: 120,
                                            height: 120,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.psychology,
                                                size: 120,
                                                color: primaryColor.withOpacity(0.7),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 40),
                                // العنوان الرئيسي
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 800),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        'مرحباً! 👋',
                                        style: GoogleFonts.cairo(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: primaryColor,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'أنا ذكاء اصطناعي الدلما',
                                        style: GoogleFonts.cairo(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: theme.textPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // الوصف
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1000),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '💬 اسألني أي شيء',
                                          style: GoogleFonts.cairo(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: theme.textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'سأجيبك بكل دقة ووضوح',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: theme.textPrimaryColor.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // أيقونات سريعة
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1200),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: child,
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildQuickAction(
                                        icon: '💡',
                                        label: 'نصائح',
                                        onTap: () {
                                          _controller.text = 'أعطني نصائح مفيدة';
                                          _send();
                                        },
                                        theme: theme,
                                        primaryColor: primaryColor,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildQuickAction(
                                        icon: '❓',
                                        label: 'أسئلة',
                                        onTap: () {
                                          _controller.text = 'ما هي أفضل الممارسات؟';
                                          _send();
                                        },
                                        theme: theme,
                                        primaryColor: primaryColor,
                                      ),
                                      const SizedBox(width: 16),
                                      _buildQuickAction(
                                        icon: '📚',
                                        label: 'معلومات',
                                        onTap: () {
                                          _controller.text = 'أخبرني معلومات مفيدة';
                                          _send();
                                        },
                                        theme: theme,
                                        primaryColor: primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length + (_loading ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (_loading && i == _messages.length) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: 16,
                                    left: 8,
                                    right: 40,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isDark
                                            ? [
                                                Colors.grey.shade800,
                                                Colors.grey.shade700,
                                                Colors.grey.shade800,
                                              ]
                                            : [
                                                Colors.white,
                                                Colors.grey.shade50,
                                                Colors.white,
                                              ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(24),
                                        topRight: Radius.circular(24),
                                        bottomLeft: Radius.circular(8),
                                        bottomRight: Radius.circular(24),
                                      ),
                                      border: Border.all(
                                        color: primaryColor.withOpacity(0.15),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                primaryColor.withOpacity(0.25),
                                                primaryColor.withOpacity(0.15),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: primaryColor.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              'assets/img/aldlma.png',
                                              width: 22,
                                              height: 22,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.psychology_rounded,
                                                  size: 22,
                                                  color: primaryColor,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(milliseconds: 1200),
                                              tween: Tween(begin: 0.0, end: 1.0),
                                              curve: Curves.easeInOut,
                                              repeat: true,
                                              builder: (context, value, child) {
                                                return Transform.scale(
                                                  scale: 0.8 + (0.2 * (0.5 - (value - 0.5).abs() * 2).abs()),
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.6 + (0.4 * value)),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(milliseconds: 1200),
                                              tween: Tween(begin: 0.0, end: 1.0),
                                              curve: Curves.easeInOut,
                                              repeat: true,
                                              builder: (context, value, child) {
                                                final delay = 0.2;
                                                final adjustedValue = ((value - delay) % (1 - delay)) / (1 - delay);
                                                return Transform.scale(
                                                  scale: 0.8 + (0.2 * (0.5 - (adjustedValue - 0.5).abs() * 2).abs()),
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.6 + (0.4 * adjustedValue)),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            TweenAnimationBuilder<double>(
                                              duration: const Duration(milliseconds: 1200),
                                              tween: Tween(begin: 0.0, end: 1.0),
                                              curve: Curves.easeInOut,
                                              repeat: true,
                                              builder: (context, value, child) {
                                                final delay = 0.4;
                                                final adjustedValue = ((value - delay) % (1 - delay)) / (1 - delay);
                                                return Transform.scale(
                                                  scale: 0.8 + (0.2 * (0.5 - (adjustedValue - 0.5).abs() * 2).abs()),
                                                  child: Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: primaryColor.withOpacity(0.6 + (0.4 * adjustedValue)),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'جاري الكتابة...',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: theme.textPrimaryColor.withOpacity(0.6),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            final m = _messages[i];
                            final isUser = m['role'] == 'user';
                            return TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 400),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      isUser ? 20 * (1 - value) : -20 * (1 - value),
                                      0,
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              child: Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: 16,
                                    left: isUser ? 40 : 8,
                                    right: isUser ? 8 : 40,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // الرسالة الرئيسية
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isUser
                                              ? LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    primaryColor,
                                                    primaryColor.withOpacity(0.9),
                                                    primaryColor.withOpacity(0.85),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                )
                                              : LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: isDark
                                                      ? [
                                                          Colors.grey.shade800,
                                                          Colors.grey.shade700,
                                                          Colors.grey.shade800,
                                                        ]
                                                      : [
                                                          Colors.white,
                                                          Colors.grey.shade50,
                                                          Colors.white,
                                                        ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(24),
                                            topRight: const Radius.circular(24),
                                            bottomLeft: Radius.circular(isUser ? 24 : 8),
                                            bottomRight: Radius.circular(isUser ? 8 : 24),
                                          ),
                                          border: isUser
                                              ? null
                                              : Border.all(
                                                  color: primaryColor.withOpacity(0.15),
                                                  width: 1.5,
                                                ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isUser
                                                  ? primaryColor.withOpacity(0.4)
                                                  : Colors.black.withOpacity(0.1),
                                              blurRadius: 20,
                                              spreadRadius: isUser ? 2 : 0,
                                              offset: const Offset(0, 6),
                                            ),
                                            if (isUser)
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.2),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 2),
                                              ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!isUser) ...[
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      primaryColor.withOpacity(0.25),
                                                      primaryColor.withOpacity(0.15),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: primaryColor.withOpacity(0.3),
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: primaryColor.withOpacity(0.2),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    'assets/img/aldlma.png',
                                                    width: 22,
                                                    height: 22,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Icon(
                                                        Icons.psychology_rounded,
                                                        size: 22,
                                                        color: primaryColor,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // النص الرئيسي
                                                  SelectableText.rich(
                                                    _buildFormattedText(
                                                      m['text'],
                                                      isUser: isUser,
                                                      theme: theme,
                                                      primaryColor: primaryColor,
                                                    ),
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 16,
                                                      height: 1.75,
                                                      fontWeight: FontWeight.w500,
                                                      color: isUser ? Colors.white : theme.textPrimaryColor,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                  // Timestamp
                                                  if (!isUser) ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.access_time_rounded,
                                                          size: 12,
                                                          color: theme.textPrimaryColor.withOpacity(0.4),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _formatTime(m['ts']),
                                                          style: GoogleFonts.cairo(
                                                            fontSize: 11,
                                                            color: theme.textPrimaryColor.withOpacity(0.4),
                                                            fontWeight: FontWeight.w400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // تأثير إضافي للرسائل
                                      if (!isUser)
                                        Positioned(
                                          top: -2,
                                          left: -2,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryColor.withOpacity(0.5),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              // Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.backgroundColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'اكتب سؤالك هنا...',
                              hintStyle: GoogleFonts.cairo(
                                color: theme.textPrimaryColor.withOpacity(0.4),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            style: GoogleFonts.cairo(
                              color: theme.textPrimaryColor,
                              fontSize: 15,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.85),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _loading ? null : _send,
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: _loading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
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
      },
    );
  }


  Future<String?> _askDalmaStream(String question) async {
    final headers = await ApiConfig.getHeaders();
    
    final Map<String, dynamic> body = {
      'question': question,
      'stream': true,
    };

    debugPrint('🧠 [AI DALMA] إرسال طلب بث إلى خادم الدلما...');

    final req = http.Request('POST', Uri.parse('${ApiConfig.baseUrl}/api/ai/dalma-chat'));
    req.headers.addAll(headers);
    req.body = json.encode(body);
    http.StreamedResponse resp;
    try {
      resp = await http.Client().send(req).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('فشل الاتصال بخادم الدلما: $e');
    }

    if (resp.statusCode != 200) {
      final bodyStr = await resp.stream.bytesToString();
      debugPrint('❌ [AI DALMA] خطأ [${resp.statusCode}] $bodyStr');
      throw Exception('خطأ من خادم الدلما: ${resp.statusCode}');
    }

    String buffer = '';
    String currentDataLine = ''; // Buffer للـ data line غير المكتمل
    int chunkCount = 0;
    int dataLineCount = 0;
    int parsedCount = 0;
    int extractedCount = 0;
    
    await for (final chunk in resp.stream.transform(utf8.decoder)) {
      chunkCount++;
      
      // دمج الـ chunk مع الـ buffer السابق إذا كان هناك
      String fullChunk = currentDataLine.isEmpty ? chunk : currentDataLine + chunk;
      currentDataLine = '';
      
      final lines = const LineSplitter().convert(fullChunk);
      
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        final String ln = line.trim();
        if (ln.isEmpty) continue;
        
        // معالجة events
        if (ln.startsWith('event:')) {
          continue;
        }
        
        // معالجة data
        if (ln.startsWith('data:')) {
          dataLineCount++;
          final payload = ln.substring(5).trim();
          if (payload == '[DONE]') {
            continue;
          }
          
          // محاولة parse الـ JSON
          dynamic jsonObj;
          try {
            jsonObj = json.decode(payload);
            parsedCount++;
          } catch (e) {
            // JSON غير مكتمل - نحفظه للـ chunk التالي
            if (i == lines.length - 1) {
              // آخر سطر في الـ chunk، قد يكون غير مكتمل
              currentDataLine = payload;
            }
            continue;
          }
          
          // استخراج النص من الـ JSON
          final delta = _extractStreamDelta(jsonObj);
          if (delta.isNotEmpty) {
            extractedCount++;
            buffer += delta;
            
            if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
              setState(() {
                _messages[_streamMsgIndex!]['text'] = buffer;
              });
              _scrollDown();
            }
          }
        } else {
          // قد يكون JSON بدون prefix
          try {
            final dynamic jsonObj = json.decode(ln);
            parsedCount++;
            final delta = _extractStreamDelta(jsonObj);
            if (delta.isNotEmpty) {
              extractedCount++;
              buffer += delta;
              if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
                setState(() {
                  _messages[_streamMsgIndex!]['text'] = buffer;
                });
                _scrollDown();
              }
            }
          } catch (e) {
            // ليس JSON - نتجاهل
          }
        }
      }
    }
    
    // معالجة أي JSON غير مكتمل متبقي
    if (currentDataLine.isNotEmpty) {
      try {
        final dynamic jsonObj = json.decode(currentDataLine);
        final delta = _extractStreamDelta(jsonObj);
        if (delta.isNotEmpty) {
          buffer += delta;
          if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
            setState(() {
              _messages[_streamMsgIndex!]['text'] = buffer;
            });
            _scrollDown();
          }
        }
      } catch (e) {
        // فشل - نتجاهل
      }
    }
    
    debugPrint('✅ [STREAM] Summary:');
    debugPrint('   - Chunks: $chunkCount');
    debugPrint('   - Data lines: $dataLineCount');
    debugPrint('   - Parsed: $parsedCount');
    debugPrint('   - Extracted: $extractedCount');
    debugPrint('   - Final buffer length: ${buffer.length}');
    
    return buffer.isNotEmpty ? buffer : null;
  }

  String _extractStreamDelta(dynamic data) {
    try {
      if (data is Map) {
        final type = data['type']?.toString();
        debugPrint('🔍 [EXTRACT] Type: $type');
        debugPrint('🔍 [EXTRACT] Keys: ${data.keys.toList()}');
        
        // معالجة response object (response.created, response.in_progress, response.incomplete)
        final response = data['response'];
        if (response is Map) {
          // محاولة استخراج من response.output
          final responseOutput = response['output'];
          if (responseOutput is List) {
            final StringBuffer out = StringBuffer();
            for (final item in responseOutput) {
              if (item is Map) {
                final itemType = item['type']?.toString();
                if (itemType == 'message') {
                  final content = item['content'];
                  if (content is List) {
                    for (final c in content) {
                      if (c is Map) {
                        final ct = c['type']?.toString();
                        if ((ct == 'output_text' || ct == 'output_text.delta') && c['text'] is String) {
                          out.write(c['text']);
                        } else if (c['text'] is String) {
                          out.write(c['text']);
                        }
                      }
                    }
                  }
                }
              }
            }
            final s = out.toString();
            if (s.isNotEmpty) {
              debugPrint('✅ [EXTRACT] Found text in response.output');
              return s;
            }
          }
        }
        
        // معالجة response.output_item.added و response.output_item.delta
        if (type == 'response.output_item.added' || type == 'response.output_item.delta') {
          debugPrint('✅ [EXTRACT] Processing output_item event');
          final item = data['item'];
          if (item is Map) {
            final itemType = item['type']?.toString();
            
            // معالجة message type
            if (itemType == 'message') {
              // محاولة delta أولاً
              final delta = item['delta'];
              if (delta is Map) {
                final deltaContent = delta['content'];
                if (deltaContent is List) {
                  final StringBuffer out = StringBuffer();
                  for (final c in deltaContent) {
                    if (c is Map) {
                      final ct = c['type']?.toString();
                      if ((ct == 'output_text' || ct == 'output_text.delta') && c['text'] is String) {
                        out.write(c['text']);
                      } else if (c['text'] is String) {
                        out.write(c['text']);
                      }
                    }
                  }
                  final s = out.toString();
                  if (s.isNotEmpty) return s;
                }
              }
              
              // محاولة content مباشرة
              final content = item['content'];
              if (content is List) {
                final StringBuffer out = StringBuffer();
                for (final c in content) {
                  if (c is Map) {
                    final ct = c['type']?.toString();
                    if ((ct == 'output_text' || ct == 'output_text.delta') && c['text'] is String) {
                      out.write(c['text']);
                    } else if (c['text'] is String) {
                      out.write(c['text']);
                    }
                  }
                }
                final s = out.toString();
                if (s.isNotEmpty) return s;
              }
            }
          }
        }
        
        // 1. محاولة استخراج من output_text مباشرة
        if (data['output_text'] is String) {
          final text = data['output_text'] as String;
          if (text.isNotEmpty) return text;
        }
        
        // 2. محاولة استخراج من output array
        final output = data['output'];
        if (output is List) {
          final StringBuffer out = StringBuffer();
          for (final item in output) {
            if (item is Map) {
              final itemType = item['type']?.toString();
              
              // معالجة message type
              if (itemType == 'message') {
                // محاولة delta أولاً
                final delta = item['delta'];
                if (delta is Map) {
                  final deltaContent = delta['content'];
                  if (deltaContent is List) {
                    for (final c in deltaContent) {
                      if (c is Map) {
                        final ct = c['type']?.toString();
                        if ((ct == 'output_text' || ct == 'output_text.delta') && c['text'] is String) {
                          out.write(c['text']);
                        } else if (c['text'] is String) {
                          out.write(c['text']);
                        }
                      }
                    }
                  }
                }
                
                // محاولة content مباشرة
                final content = item['content'];
                if (content is List) {
                  for (final c in content) {
                    if (c is Map) {
                      final ct = c['type']?.toString();
                      if ((ct == 'output_text' || ct == 'output_text.delta') && c['text'] is String) {
                        out.write(c['text']);
                      } else if (c['text'] is String) {
                        out.write(c['text']);
                      }
                    }
                  }
                }
              }
              
              // معالجة output_text type مباشرة
              if (itemType == 'output_text' && item['text'] is String) {
                out.write(item['text']);
              }
            }
          }
          final s = out.toString();
          if (s.isNotEmpty) return s;
        }
        
        // 3. محاولة استخراج من message.content
        final message = data['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is List) {
            final StringBuffer out = StringBuffer();
            for (final c in content) {
              if (c is Map) {
                final text = c['text'] ?? c['content'];
                if (text is String && text.isNotEmpty) {
                  out.write(text);
                }
              } else if (c is String) {
                out.write(c);
              }
            }
            final s = out.toString();
            if (s.isNotEmpty) return s;
          } else if (content is String) {
            return content;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [EXTRACT] Error: $e');
    }
    return '';
  }

  Future<String> _askDalma(String question) async {
    final headers = await ApiConfig.getHeaders();
    
    final Map<String, dynamic> body = {
      'question': question,
      'stream': false,
    };

    debugPrint('🧠 [AI DALMA] إرسال طلب إلى خادم الدلما...');

    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/ai/dalma-chat'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      throw Exception('فشل الاتصال بخادم الدلما: $e');
    }

    debugPrint('✅ [AI DALMA] استجابة [${res.statusCode}]');

    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      
      // استخراج الإجابة من response
      if (data['answer'] != null && data['answer'].toString().trim().isNotEmpty) {
        return data['answer'].toString().trim();
      }
      
      // إذا لم تكن هناك إجابة مباشرة
      return 'عذراً، الدلما لم يستطع توليد إجابة حالياً. يرجى المحاولة مرة أخرى.';
    }
    
    throw Exception('خطأ من خادم الدلما: ${res.statusCode}');
  }

  // تنسيق النص مع دعم Markdown بسيط
  TextSpan _buildFormattedText(
    String text, {
    required bool isUser,
    required ThemeConfig theme,
    required Color primaryColor,
  }) {
    if (text.isEmpty) {
      return TextSpan(text: '');
    }

    final List<TextSpan> spans = [];
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // معالجة العناوين (**text**)
      if (line.trim().startsWith('**') && line.trim().endsWith('**')) {
        final content = line.trim().substring(2, line.trim().length - 2);
        spans.add(TextSpan(
          text: content,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isUser ? Colors.white : primaryColor,
          ),
        ));
      }
      // معالجة النص المائل (*text*)
      else if (line.trim().startsWith('*') && line.trim().endsWith('*') && !line.trim().startsWith('**')) {
        final content = line.trim().substring(1, line.trim().length - 1);
        spans.add(TextSpan(
          text: content,
          style: GoogleFonts.cairo(
            fontStyle: FontStyle.italic,
            color: isUser ? Colors.white.withOpacity(0.9) : theme.textPrimaryColor.withOpacity(0.8),
          ),
        ));
      }
      // معالجة الكود (`text`)
      else if (line.contains('`')) {
        final parts = line.split('`');
        for (int j = 0; j < parts.length; j++) {
          if (j % 2 == 0) {
            spans.add(TextSpan(text: parts[j]));
          } else {
            spans.add(TextSpan(
              text: parts[j],
              style: GoogleFonts.cairo(
                fontFamily: 'monospace',
                backgroundColor: isUser
                    ? Colors.white.withOpacity(0.2)
                    : primaryColor.withOpacity(0.1),
                color: isUser ? Colors.white : primaryColor,
              ),
            ));
          }
        }
      }
      // نص عادي
      else {
        spans.add(TextSpan(text: line));
      }
      
      // إضافة سطر جديد (ما عدا السطر الأخير)
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return TextSpan(children: spans);
  }

  // تنسيق الوقت
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime time;
      if (timestamp is DateTime) {
        time = timestamp;
      } else if (timestamp is String) {
        time = DateTime.parse(timestamp);
      } else {
        return '';
      }
      
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}










