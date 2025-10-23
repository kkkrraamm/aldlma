import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class AskDalmaDialog extends StatefulWidget {
  const AskDalmaDialog({super.key});

  @override
  State<AskDalmaDialog> createState() => _AskDalmaDialogState();
}

class _AskDalmaDialogState extends State<AskDalmaDialog> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  int? _streamMsgIndex;

  // OpenAI Responses API settings
  static const String _endpoint = 'https://api.openai.com/v1/responses';
  static const String _apiKey = Secrets.openAiApiKey; // محمي من Git
  static const String _promptId = 'pmpt_68d9e5897e508193a8362567a7e2b1b30556320da57d2e9c';
  static const String _promptVersion = '1';
  static const String _model = 'o4-mini';

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
            _messages[_streamMsgIndex!]['text'] = 'تعذر الحصول على رد حالياً. حاول لاحقاً.';
          } else {
            _messages.add({'role': 'assistant', 'text': 'تعذر الحصول على رد حالياً. حاول لاحقاً.', 'ts': DateTime.now()});
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3E2), Color(0xFFECFDF5), Color(0xFFFEF3E2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Text('اسأل الدلما', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: Colors.grey.shade600))
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_loading && i == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  }
                  final m = _messages[i];
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isUser ? Theme.of(context).colorScheme.primary.withOpacity(0.25) : Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Text(m['text'], style: GoogleFonts.cairo(fontSize: 14, height: 1.6)),
                    ),
                  );
                },
              ),
            ),
            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade300)),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'اكتب سؤالك هنا...',
                          hintStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _send,
                    mini: true,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  ({String model, int maxOut, String verbosity, bool includeTemp}) _pickSettings(String q) {
    final String qq = q.trim();
    final bool isLong = qq.length > 400;
    final bool isSimple = qq.length < 120 && !isLong;
    final String model = 'o4-mini';
    final int maxOut = isSimple ? 120 : (isLong ? 240 : 180);
    final String verbosity = isSimple ? 'low' : 'medium';
    final bool includeTemp = false;
    return (model: model, maxOut: maxOut, verbosity: verbosity, includeTemp: includeTemp);
  }

  Future<void> _askDalmaStream(String question) async {
    final s = _pickSettings(question);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };
    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': question}
        ]
      }
    ];
    final Map<String, dynamic> body = {
      'model': s.model,
      'prompt': {'id': _promptId, 'version': _promptVersion},
      'input': messages,
      'text': {'verbosity': s.verbosity},
      'max_output_tokens': s.maxOut,
      'store': true,
      'stream': true,
    };
    // لا نرسل temperature مع o4-mini

    debugPrint('ASK DALMA STREAM REQUEST → $_endpoint');
    debugPrint('Headers: {Content-Type: application/json, Authorization: Bearer ${_apiKey.substring(0, 8)}...}');
    debugPrint('Body: ${json.encode(body)}');

    final req = http.Request('POST', Uri.parse(_endpoint));
    req.headers.addAll(headers);
    req.body = json.encode(body);
    http.StreamedResponse resp;
    try {
      resp = await http.Client().send(req).timeout(const Duration(seconds: 30));
    } catch (e) {
      throw Exception('فشل بدء البث: $e');
    }

    if (resp.statusCode != 200) {
      final bodyStr = await resp.stream.bytesToString();
      debugPrint('STREAM ERROR [${resp.statusCode}] $bodyStr');
      throw Exception('خطأ من الخادم: ${resp.statusCode}');
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
    // Try delta-based format
    try {
      if (data is Map) {
        // New streaming event may include output array with partial message
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
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': question}
        ]
      }
    ];

    Map<String, dynamic> body = {
      'model': _model,
      'prompt': {'id': _promptId, 'version': _promptVersion},
      'input': messages,
      'text': {'verbosity': 'medium'},
      'max_output_tokens': 300,
      'store': true,
    };

    debugPrint('ASK DALMA REQUEST → $_endpoint');
    debugPrint('Headers: {Content-Type: application/json, Authorization: Bearer ${_apiKey.substring(0, 8)}...}');
    debugPrint('Body: ${json.encode(body)}');

    http.Response res;
    try {
      res = await http
          .post(Uri.parse(_endpoint), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 25));
    } catch (e) {
      throw Exception('فشل الاتصال بالخادم: $e');
    }

    debugPrint('ASK DALMA RESPONSE [${res.statusCode}] ${res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final ans = _parseResponsesAnswer(data);
      if (ans.isNotEmpty) return ans;

      // إذا الرجوع كان غير مكتمل بسبب حد التوكنات، جرّب بحد أعلى
      final status = data['status'];
      final incomplete = data['incomplete_details'];
      final reason = (incomplete is Map) ? (incomplete['reason']?.toString() ?? '') : '';
      if (status == 'incomplete' && reason == 'max_output_tokens') {
        final Map<String, dynamic> body2 = Map<String, dynamic>.from(body);
        body2['max_output_tokens'] = 480;
        debugPrint('Retry due to incomplete/max_output_tokens with higher cap...');
        debugPrint('Body2: ${json.encode(body2)}');
        try {
          final retry2 = await http
              .post(Uri.parse(_endpoint), headers: headers, body: json.encode(body2))
              .timeout(const Duration(seconds: 25));
          debugPrint('RETRY2 RESPONSE [${retry2.statusCode}] ${retry2.body}');
          if (retry2.statusCode == 200) {
            final d2 = json.decode(retry2.body);
            final a2 = _parseResponsesAnswer(d2);
            if (a2.isNotEmpty) return a2;
          }
        } catch (_) {}
      }
    }

    // Fallback: في حال رفض باراميتر أو عدم وجود نص
    final bool tempUnsupported =
        res.statusCode == 400 && res.body.toLowerCase().contains('temperature');
    if (tempUnsupported) {
      body.remove('temperature');
      debugPrint('Retry without temperature...');
      try {
        final retry = await http
            .post(Uri.parse(_endpoint), headers: headers, body: json.encode(body))
            .timeout(const Duration(seconds: 25));
        debugPrint('RETRY RESPONSE [${retry.statusCode}] ${retry.body}');
        if (retry.statusCode == 200) {
          final data = json.decode(retry.body);
          final ans = _parseResponsesAnswer(data);
          if (ans.isNotEmpty) return ans;
        }
      } catch (e) {
        // ignore, will fall through to error
      }
    }

    if (res.statusCode == 200) {
      return 'لم أستطع توليد إجابة حالياً.';
    }
    throw Exception('خطأ من الخادم: ${res.statusCode}');
  }

  String _parseResponsesAnswer(dynamic data) {
    try {
      // 1) Direct convenience field if present
      if (data is Map<String, dynamic>) {
        final direct = data['output_text'];
        if (direct is String && direct.trim().isNotEmpty) return direct.trim();

        // 2) Responses API: iterate over output[] items to find assistant message content
        final output = data['output'];
        if (output is List && output.isNotEmpty) {
          final List<String> chunks = [];
          for (final item in output) {
            if (item is Map) {
              // Prefer assistant messages
              final role = item['role']?.toString();
              final type = item['type']?.toString();
              if (type == 'message' && (role == null || role == 'assistant')) {
                final content = item['content'];
                if (content is List) {
                  for (final c in content) {
                    if (c is Map) {
                      final ct = c['type']?.toString();
                      // Most reliable: output_text
                      if (ct == 'output_text' && c['text'] is String) {
                        final t = (c['text'] as String).trim();
                        if (t.isNotEmpty) chunks.add(t);
                      } else {
                        // Fallback to any textual fields
                        final t = (c['text'] ?? c['content'] ?? '').toString().trim();
                        if (t.isNotEmpty) chunks.add(t);
                      }
                    }
                  }
                }
              }
            }
          }
          if (chunks.isNotEmpty) return chunks.join('\n').trim();
        }

        // 3) Some variants: data['message']['content']
        final msg = data['message'];
        if (msg is Map && msg['content'] is List) {
          final List content = msg['content'];
          final parts = content
              .whereType<Map>()
              .map((m) => (m['text'] ?? m['content'] ?? '').toString())
              .where((s) => s.trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) return parts.join('\n').trim();
        }

        // 4) Legacy chat completions style (rare on responses)
        final choices = data['choices'];
        if (choices is List && choices.isNotEmpty) {
          final c0 = choices.first;
          final msg = c0['message'];
          if (msg is Map && msg['content'] is String) return (msg['content'] as String).trim();
        }
      }
    } catch (_) {}
    return '';
  }
}


