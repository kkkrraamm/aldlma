import 'dart:async';
import 'theme_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String? body;
  final DateTime timestamp;

  AppNotification({required this.id, required this.title, this.body, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotificationsService extends ChangeNotifier {
  static final NotificationsService instance = NotificationsService._internal();
  NotificationsService._internal();

  static const String _storeKey = 'notifications_items_v1';
  GlobalKey<NavigatorState>? _navigatorKey;
  final List<AppNotification> _items = <AppNotification>[];

  List<AppNotification> get items => List.unmodifiable(_items);

  Future<void> attachNavigatorKey(GlobalKey<NavigatorState> key) async {
    _navigatorKey = key;
    await _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storeKey) ?? <String>[];
    _items
      ..clear()
      ..addAll(raw.map((e) => AppNotification.fromJson(json.decode(e) as Map<String, dynamic>)));
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items.take(100).map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_storeKey, raw);
  }

  Future<void> add(AppNotification n, {bool silent = false}) async {
    _items.insert(0, n);
    await _persist();
    if (!silent) notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _persist();
    notifyListeners();
  }

  void toast(String message, {IconData icon = Icons.check_circle, Color color = const Color(0xFF059669), bool top = true}) {
    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (context) {
        final media = MediaQuery.of(context);
        final banner = _ToastBanner(message: message, icon: icon, color: color);
        return SafeArea(
          child: Stack(
            children: [
              if (top)
                Positioned(
                  top: media.padding.top + 8,
                  left: 12,
                  right: 12,
                  child: banner,
                )
              else
                Positioned(
                  bottom: media.padding.bottom + 12,
                  left: 12,
                  right: 12,
                  child: banner,
                ),
            ],
          ),
        );
      },
    );
    overlay.insert(entry);
    Timer(const Duration(milliseconds: 2000), () {
      entry.remove();
    });
  }

  void showNotificationsSheet(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? ThemeConfig.kNightSoft : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: theme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: theme.textSecondaryColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('الإشعارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textPrimaryColor)),
                  const Spacer(),
                  TextButton(
                    onPressed: clearAll, 
                    child: Text('مسح الكل', style: TextStyle(color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: this,
                builder: (context, _) {
                  if (_items.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.notifications_none, size: 48, color: theme.textSecondaryColor),
                        const SizedBox(height: 8),
                        Text('لا توجد إشعارات', style: TextStyle(color: theme.textSecondaryColor)),
                      ]),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: theme.borderColor),
                    itemBuilder: (context, index) {
                      final n = _items[index];
                      return ListTile(
                        leading: Icon(Icons.notifications, color: isDark ? ThemeConfig.kGoldNight : ThemeConfig.kGreen),
                        title: Text(n.title, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textPrimaryColor)),
                        subtitle: n.body == null ? null : Text(n.body!, style: TextStyle(color: theme.textSecondaryColor)),
                        trailing: Text(_fmtTime(n.timestamp), style: TextStyle(fontSize: 12, color: theme.textSecondaryColor)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes} د';
    if (diff.inHours < 24) return '${diff.inHours} س';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

class _ToastBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  const _ToastBanner({required this.message, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeConfig.instance;
    final isDark = theme.isDarkMode;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? ThemeConfig.kNightSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: theme.cardShadow,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.15 : 0.1), 
                borderRadius: BorderRadius.circular(8)
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsBell extends StatelessWidget {
  const NotificationsBell({super.key});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => NotificationsService.instance.showNotificationsSheet(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(child: Icon(Icons.notifications_none, color: Color(0xFF6B7280), size: 20)),
            Positioned(
              top: -4,
              left: -4,
              child: AnimatedBuilder(
                animation: NotificationsService.instance,
                builder: (context, _) {
                  final count = NotificationsService.instance.items.length;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
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
}

