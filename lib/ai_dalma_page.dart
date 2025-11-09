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

    try {
      await _askDalmaStream(text);
    } catch (e) {
      // إن فشل البث، نجرب طلب عادي كنسخة احتياطية
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
        setState(() {
          if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
            _messages[_streamMsgIndex!]['text'] = 'عذراً، الدلما غير متاح حالياً. يرجى المحاولة لاحقاً.';
          } else {
            _messages.add({'role': 'assistant', 'text': 'عذراً، الدلما غير متاح حالياً. يرجى المحاولة لاحقاً.', 'ts': DateTime.now()});
          }
        });
      }
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollDown();
    }
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
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'جاري الكتابة...',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          color: theme.textPrimaryColor.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
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
                                  margin: const EdgeInsets.only(bottom: 16),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: isUser
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              primaryColor,
                                              primaryColor.withOpacity(0.85),
                                            ],
                                          )
                                        : null,
                                    color: isUser ? null : theme.cardColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                                      bottomRight: Radius.circular(isUser ? 4 : 20),
                                    ),
                                    border: isUser
                                        ? null
                                        : Border.all(
                                            color: primaryColor.withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isUser
                                            ? primaryColor.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.08),
                                        blurRadius: 15,
                                        spreadRadius: isUser ? 1 : 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isUser) ...[
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                primaryColor.withOpacity(0.2),
                                                primaryColor.withOpacity(0.1),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Image.asset(
                                            'assets/img/aldlma.png',
                                            width: 20,
                                            height: 20,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.psychology,
                                                size: 20,
                                                color: primaryColor,
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: Text(
                                          m['text'],
                                          style: GoogleFonts.cairo(
                                            fontSize: 15.5,
                                            height: 1.7,
                                            fontWeight: FontWeight.w500,
                                            color: isUser ? Colors.white : theme.textPrimaryColor,
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


  Future<void> _askDalmaStream(String question) async {
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
    await for (final chunk in resp.stream.transform(utf8.decoder)) {
      for (final line in const LineSplitter().convert(chunk)) {
        final String ln = line.trim();
        if (ln.isEmpty) continue;
        if (ln.startsWith('data:')) {
          final payload = ln.substring(5).trim();
          if (payload == '[DONE]') {
            continue;
          }
          try {
            final dynamic jsonObj = json.decode(payload);
            final delta = _extractStreamDelta(jsonObj);
            if (delta.isNotEmpty) {
              buffer += delta;
              if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
                setState(() => _messages[_streamMsgIndex!]['text'] = buffer);
                _scrollDown();
              }
            }
          } catch (_) {
            // ignore malformed chunks
          }
        }
      }
    }
  }

  String _extractStreamDelta(dynamic data) {
    try {
      if (data is Map) {
        final output = data['output'];
        if (output is List) {
          final StringBuffer out = StringBuffer();
          for (final item in output) {
            if (item is Map) {
              final type = item['type']?.toString();
              if (type == 'message') {
                final delta = item['delta'];
                final content = (delta is Map) ? delta['content'] : item['content'];
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
          if (s.isNotEmpty) return s;
        }
      }
    } catch (_) {}
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

}

