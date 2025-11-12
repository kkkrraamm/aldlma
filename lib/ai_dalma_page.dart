import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'theme_config.dart';

class AIDalmaPage extends StatefulWidget {
  const AIDalmaPage({super.key});

  @override
  State<AIDalmaPage> createState() => _AIDalmaPageState();
}

class _AIDalmaPageState extends State<AIDalmaPage> with TickerProviderStateMixin {
  static const String _logoAsset = 'assets/img/aldlma.png';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  bool _loading = false;
  int? _streamMsgIndex;
  late final AnimationController _typingIndicatorController;

  final List<_Suggestion> _suggestions = const [
    _Suggestion(
      emoji: '📰',
      label: 'ملخص اليوم',
      prompt: 'ابيك تعطيني ملخص سريع لأبرز أخبار الشمال والسعودية اليوم بنبرة رسمية مختصرة.',
    ),
    _Suggestion(
      emoji: '📝',
      label: 'نقاش مجلس',
      prompt: 'خلنا نسولف كأننا بالمجلس عن آخر المستجدات وفر لي نقاط أقدر أتكلم فيها.',
    ),
    _Suggestion(
      emoji: '🎯',
      label: 'فكرة محتوى',
      prompt: 'ساعدني بفكرة محتوى أصيل باللهجة الشمالية يناسب جمهور الدلما.',
    ),
    _Suggestion(
      emoji: '🧭',
      label: 'تنسيق مناسبة',
      prompt: 'أحتاج جدول بسيط لمناسبة اجتماعية شمالية مع فقرات وملاحظات تراثية.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _typingIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingIndicatorController.dispose();
    super.dispose();
  }

  Future<void> _send({String? overridePrompt}) async {
    final String text = (overridePrompt ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'ts': DateTime.now()});
      _loading = true;
    });

    _controller.clear();
    _scrollDown();

    setState(() {
      _streamMsgIndex = _messages.length;
      _messages.add({'role': 'assistant', 'text': '', 'ts': DateTime.now()});
    });
    _scrollDown();

    String? streamResult;
    try {
      streamResult = await _askDalmaStream(text);
    } catch (error) {
      debugPrint('❌ [STREAM] Dalma error: $error');
    }

    if ((streamResult == null || streamResult.isEmpty) && mounted) {
      debugPrint('⚠️ [STREAM] empty buffer, fallback to regular response.');
      try {
        final answer = await _askDalma(text);
        _setAssistantMessage(answer);
      } catch (error) {
        debugPrint('❌ [REGULAR] Dalma error: $error');
        _setAssistantMessage('يا خوي، الظاهر الخادم مشغول شوي. جرب بعد لحظات.');
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
    _scrollDown();
  }

  void _setAssistantMessage(String text) {
    if (!mounted) return;
    setState(() {
      if (_streamMsgIndex != null && _streamMsgIndex! < _messages.length) {
        _messages[_streamMsgIndex!]['text'] = text;
      } else {
        _messages.add({'role': 'assistant', 'text': text, 'ts': DateTime.now()});
      }
    });
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeConfig.instance,
      builder: (context, _) {
        final theme = ThemeConfig.instance;
        final primary = theme.primaryColor;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: _buildAppBar(theme),
          body: Column(
            children: [
              Expanded(child: _buildChat(theme, primary)),
              _buildInput(theme, primary),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeConfig theme) {
    return AppBar(
      backgroundColor: theme.cardColor.withDalmaOpacity(theme.isDarkMode ? 0.94 : 0.88),
      elevation: 0,
      titleSpacing: 0,
      toolbarHeight: 64,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 12),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimaryColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.primaryColor.withDalmaOpacity(0.8),
                  theme.primaryColor.withDalmaOpacity(0.55),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withDalmaOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                _logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, _, __) {
                  return Icon(Icons.psychology_rounded, color: Colors.white.withDalmaOpacity(0.9));
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ذكاء الدلما',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.textPrimaryColor,
                ),
              ),
              Text(
                'خويك الشمالي يساعدك بكل ما تحتاجه',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimaryColor.withDalmaOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: IconButton(
            icon: Icon(theme.isDarkMode ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                color: theme.textPrimaryColor),
            onPressed: () => ThemeConfig.instance.toggleTheme(),
          ),
        ),
      ],
    );
  }

  Widget _buildChat(ThemeConfig theme, Color primary) {
    final totalItems = _messages.length + 1; // intro bubble + conversation
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withDalmaOpacity(theme.isDarkMode ? 0.92 : 0.86),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: theme.borderColor.withDalmaOpacity(0.12)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          itemCount: totalItems,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              final showSuggestions = _messages.isEmpty;
              return _buildIntroBubble(theme, primary, showSuggestions);
            }

            final message = _messages[index - 1];
            final isUser = message['role'] == 'user';
            final text = message['text'] as String? ?? '';
            return _buildMessageBubble(
              theme: theme,
              primary: primary,
              message: message,
              isUser: isUser,
              text: text,
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntroBubble(ThemeConfig theme, Color primary, bool showSuggestions) {
    final body = [
      Text(
        'حي الله من لفانا! أنا ذكاء الدلما، خوي المجلس اللي يسندك في كل سالفة، '
        'من تلخيص الأخبار لين كتابة المحتوى بلهجتنا الشمالية.',
        style: GoogleFonts.cairo(
          fontSize: 14.5,
          height: 1.6,
          color: theme.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'وش تبي نسوي اليوم؟ اكتب سؤالك أو اختَر من المقترحات الجاهزة تحت.',
        style: GoogleFonts.cairo(
          fontSize: 13.5,
          height: 1.55,
          color: theme.textPrimaryColor.withDalmaOpacity(0.7),
        ),
      ),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor.withDalmaOpacity(theme.isDarkMode ? 0.7 : 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primary.withDalmaOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: primary.withDalmaOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primary.withDalmaOpacity(0.3),
                        primary.withDalmaOpacity(0.12),
                      ],
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _logoAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.psychology_rounded, color: primary.withDalmaOpacity(0.85));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'ذكاء الدلما',
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...body,
            if (showSuggestions) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestions.map((suggestion) {
                  return _SuggestionChip(
                    suggestion: suggestion,
                    theme: theme,
                    onTap: () => _send(overridePrompt: suggestion.prompt),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ThemeConfig theme,
    required Color primary,
    required Map<String, dynamic> message,
    required bool isUser,
    required String text,
  }) {
    final timestamp = message['ts'];

    final bubbleColor = isUser
        ? LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              primary,
              primary.withDalmaOpacity(0.75),
            ],
          )
        : null;

    final assistantFill = theme.cardColor.withDalmaOpacity(theme.isDarkMode ? 0.9 : 0.96);

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: bubbleColor,
        color: bubbleColor == null ? assistantFill : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(isUser ? 22 : 10),
          bottomRight: Radius.circular(isUser ? 10 : 22),
        ),
        border: bubbleColor == null ? Border.all(color: primary.withDalmaOpacity(0.18)) : null,
        boxShadow: [
          BoxShadow(
            color: primary.withDalmaOpacity(bubbleColor == null ? 0.15 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primary.withDalmaOpacity(0.28),
                          primary.withDalmaOpacity(0.1),
                        ],
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _logoAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.psychology_alt_rounded, color: primary.withDalmaOpacity(0.88));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ذكاء الدلما',
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          if (!isUser && text.isEmpty && _loading)
            _buildTypingIndicator(primary)
          else
            SelectableText.rich(
              _buildFormattedText(
                text,
                isUser: isUser,
                theme: theme,
                primaryColor: primary,
              ),
              style: GoogleFonts.cairo(
                fontSize: 15.2,
                height: 1.7,
                fontWeight: FontWeight.w600,
                color: isUser ? Colors.white : theme.textPrimaryColor,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12.5,
                color: (isUser ? Colors.white : theme.textPrimaryColor).withDalmaOpacity(0.55),
              ),
              const SizedBox(width: 5),
              Text(
                _formatTime(timestamp),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: (isUser ? Colors.white : theme.textPrimaryColor).withDalmaOpacity(0.55),
                ),
              ),
              const Spacer(),
              if (!isUser && text.isNotEmpty)
                GestureDetector(
                  onTap: () => _copyToClipboard(text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withDalmaOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: primary),
                        const SizedBox(width: 6),
                        Text(
                          'نسخ',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(isUser ? 24 * (1 - value) : -24 * (1 - value), 0),
              child: child,
            ),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(Color primary) {
    final dots = List.generate(3, (index) => index);
    return AnimatedBuilder(
      animation: _typingIndicatorController,
      builder: (context, child) {
        final value = _typingIndicatorController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...dots.map((index) {
              final offsetValue = (value + (index * 0.2)) % 1.0;
              final scale = 0.78 + (0.22 * (0.5 - (offsetValue - 0.5).abs() * 2).abs());
              final opacity = 0.45 + (0.45 * offsetValue);
              return Padding(
                padding: EdgeInsets.only(right: index == dots.length - 1 ? 0 : 8),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary.withDalmaOpacity(opacity.clamp(0.4, 1.0)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 10),
            Text(
              'جاري الكتابة...',
              style: GoogleFonts.cairo(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: ThemeConfig.instance.textPrimaryColor.withDalmaOpacity(0.65),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInput(ThemeConfig theme, Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withDalmaOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primary.withDalmaOpacity(0.25), width: 1.4),
                ),
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك أو اطلب اللي بخاطرك...',
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 14.5,
                      color: theme.textPrimaryColor.withDalmaOpacity(0.45),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  style: GoogleFonts.cairo(
                    fontSize: 15.5,
                    color: theme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _loading ? null : _send,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      primary.withDalmaOpacity(0.82),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withDalmaOpacity(0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 21),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _askDalmaStream(String question) async {
    final headers = await ApiConfig.getHeaders();

    int loggedLines = 0;

    final request = http.Request(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/ai/dalma-chat'),
    )
      ..headers.addAll(headers)
      ..body = json.encode({'question': question, 'stream': true});

    final client = http.Client();
    try {
      final response = await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final bodyStr = await response.stream.bytesToString();
        debugPrint('❌ [AI DALMA] stream error: ${response.statusCode} => $bodyStr');
        throw Exception('خطأ من خادم الدلما: ${response.statusCode}');
      }

      String buffer = '';
      String carry = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final combined = carry.isEmpty ? chunk : '$carry$chunk';
        carry = '';

        final lines = const LineSplitter().convert(combined);
        for (var i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trim();
          if (trimmed.isEmpty || trimmed.startsWith('event:')) continue;

          final payload = trimmed.startsWith('data:')
              ? trimmed.substring(5).trim()
              : trimmed;

          if (payload == '[DONE]') continue;

          dynamic jsonObj;
          try {
            jsonObj = json.decode(payload);
            if (loggedLines < 6) {
              loggedLines++;
              debugPrint('🧩 [STREAM] chunk#$loggedLines: $payload');
            }
          } catch (_) {
            if (i == lines.length - 1) {
              carry = payload;
            }
            continue;
          }

          final delta = _extractStreamDelta(jsonObj);
          if (delta.isEmpty) continue;

          buffer += delta;
          _updateStreamMessage(buffer);
        }
      }

      if (carry.isNotEmpty) {
        try {
          final dynamic jsonObj = json.decode(carry);
        if (loggedLines < 6) {
          loggedLines++;
          debugPrint('🧩 [STREAM] carry#$loggedLines: $carry');
        }
          final delta = _extractStreamDelta(jsonObj);
          if (delta.isNotEmpty) {
            buffer += delta;
            _updateStreamMessage(buffer);
          }
        } catch (_) {}
      }

      if (buffer.isNotEmpty) {
        debugPrint('📥 [AI DALMA] stream buffer received (${buffer.length} chars).');
      }
      return buffer.isNotEmpty ? buffer : null;
    } finally {
      client.close();
    }
  }

  void _updateStreamMessage(String text) {
    if (!mounted) return;
    if (_streamMsgIndex == null || _streamMsgIndex! >= _messages.length) return;
    setState(() {
      _messages[_streamMsgIndex!]['text'] = text;
    });
    _scrollDown();
  }

  String _extractStreamDelta(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final response = data['response'];
        if (response is Map<String, dynamic>) {
          final outputText = _collectStreamText(response['output']);
          if (outputText.isNotEmpty) return outputText;
        }

        final type = data['type']?.toString();
        if (type == 'response.output_item.added' || type == 'response.output_item.delta') {
          final item = data['item'];
          if (item is Map<String, dynamic>) {
            final deltaContent = (item['delta'] as Map<String, dynamic>?)?['content'];
            final directContent = item['content'];

            final deltaText = _collectStreamText(deltaContent);
            if (deltaText.isNotEmpty) return deltaText;

            final contentText = _collectStreamText(directContent);
            if (contentText.isNotEmpty) return contentText;
          }
        }

        final message = data['message'];
        if (message is Map<String, dynamic>) {
          final messageText = _collectStreamText(message['content']);
          if (messageText.isNotEmpty) return messageText;
        } else {
          final direct = _collectStreamText(message);
          if (direct.isNotEmpty) return direct;
        }
      }
    } catch (error) {
      debugPrint('❌ [EXTRACT] Dalma stream parse error: $error');
    }
    return '';
  }

  String _collectStreamText(dynamic source) {
    final buffer = StringBuffer();

    void extract(dynamic value) {
      if (value == null) return;
      if (value is String) {
        if (value.isNotEmpty) buffer.write(value);
        return;
      }
      if (value is Map<String, dynamic>) {
        if (value['text'] is String) buffer.write(value['text']);
        if (value['content'] != null) extract(value['content']);
        if (value['delta'] != null) extract(value['delta']);
        return;
      }
      if (value is Iterable) {
        for (final item in value) {
          extract(item);
        }
      }
    }

    extract(source);
    return buffer.toString();
  }

  Future<String> _askDalma(String question) async {
    final headers = await ApiConfig.getHeaders();
    final body = json.encode({
      'question': question,
      'stream': false,
    });

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/ai/dalma-chat'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 25));
    } catch (error) {
      throw Exception('فشل الاتصال بخادم الدلما: $error');
    }

    if (response.statusCode != 200) {
      throw Exception('خطأ من خادم الدلما: ${response.statusCode}');
    }

    final data = json.decode(utf8.decode(response.bodyBytes));
    final answer = data['answer']?.toString().trim();
    if (answer == null || answer.isEmpty) {
      return 'عذراً، الدلما لم يستطع توليد إجابة حالياً. يرجى المحاولة مرة أخرى.';
    }
    
    return answer;
  }

  TextSpan _buildFormattedText(
    String text, {
    required bool isUser,
    required ThemeConfig theme,
    required Color primaryColor,
  }) {
    if (text.isEmpty) {
      return const TextSpan(text: '');
    }

    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('**') && trimmed.endsWith('**') && trimmed.length > 4) {
        final content = trimmed.substring(2, trimmed.length - 2);
        spans.add(TextSpan(
          text: content,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 16.5,
            color: isUser ? Colors.white : primaryColor,
          ),
        ));
      } else if (trimmed.startsWith('*') &&
          trimmed.endsWith('*') &&
          trimmed.length > 2 &&
          !trimmed.startsWith('**')) {
        final content = trimmed.substring(1, trimmed.length - 1);
        spans.add(TextSpan(
          text: content,
          style: GoogleFonts.cairo(
            fontStyle: FontStyle.italic,
            color: isUser
                ? Colors.white.withDalmaOpacity(0.92)
                : theme.textPrimaryColor.withDalmaOpacity(0.82),
          ),
        ));
      } else if (line.contains('`')) {
        final parts = line.split('`');
        for (var j = 0; j < parts.length; j++) {
          final segment = parts[j];
          if (j.isOdd) {
            spans.add(
              TextSpan(
                text: segment,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontFamilyFallback: const ['Courier New', 'monospace'],
                  fontSize: 14.5,
                  color: isUser ? Colors.white : primaryColor,
                  backgroundColor: primaryColor.withDalmaOpacity(isUser ? 0.12 : 0.08),
                ),
              ),
            );
          } else if (segment.isNotEmpty) {
            spans.add(TextSpan(text: segment));
          }
        }
      } else {
        spans.add(TextSpan(text: line));
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }

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
      if (difference.inMinutes < 1) return 'الآن';
      if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
      if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ رد ذكاء الدلما بنجاح ✅',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ThemeConfig.instance.primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.emoji,
    required this.label,
    required this.prompt,
  });

  final String emoji;
  final String label;
  final String prompt;
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.theme,
    required this.onTap,
  });

  final _Suggestion suggestion;
  final ThemeConfig theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = theme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.backgroundColor.withDalmaOpacity(theme.isDarkMode ? 0.6 : 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary.withDalmaOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: primary.withDalmaOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(suggestion.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              suggestion.label,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: theme.textPrimaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left_rounded, size: 16, color: primary),
          ],
        ),
      ),
    );
  }
}

extension _DalmaColorOpacity on Color {
  Color withDalmaOpacity(double opacity) => withValues(alpha: opacity);
}










