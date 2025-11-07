# 📱 دليل ربط لوحة التحكم بتطبيق Dalma
## Admin Dashboard to Flutter App Integration Guide

---

## 🎯 نظرة عامة

هذا الدليل الشامل يوضح **جميع الميزات** في لوحة التحكم (Admin Dashboard) التي تحتاج إلى ربط مع تطبيق Dalma Flutter، وكيفية تنفيذ هذا الربط بشكل واقعي وكامل.

---

## 📋 جدول المحتويات

1. [نظام الإشعارات (Push Notifications)](#1-نظام-الإشعارات)
2. [إدارة الإعلانات (Ads Management)](#2-إدارة-الإعلانات)
3. [إدارة الشركاء (Partners Management)](#3-إدارة-الشركاء)
4. [إدارة الفئات (Categories Management)](#4-إدارة-الفئات)
5. [إدارة المستخدمين (Users Management)](#5-إدارة-المستخدمين)
6. [إدارة الطلبات (Requests Management)](#6-إدارة-الطلبات)
7. [الإعدادات العامة (App Settings)](#7-الإعدادات-العامة)
8. [التقارير والإحصائيات (Reports & Analytics)](#8-التقارير-والإحصائيات)

---

## 1. نظام الإشعارات
### 📧 Push Notifications System

### ❌ الوضع الحالي:
- Admin Dashboard يمكنه إرسال إشعارات لكن التطبيق **لا يستقبلها**
- لا يوجد FCM Token مسجل للمستخدمين
- الإشعارات تُرسل لكن لا أحد يراها!

### ✅ المطلوب:

#### 1.1 إضافة Firebase Cloud Messaging للتطبيق

**الخطوة 1: إعداد Firebase**
```bash
# في مجلد التطبيق
cd aldlma
flutter pub add firebase_core
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications
```

**الخطوة 2: تهيئة Firebase في `main.dart`**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global notification handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background Message: ${message.notification?.title}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('📩 Notification clicked: ${response.payload}');
    },
  );
  
  runApp(MyApp());
}
```

**الخطوة 3: إنشاء `NotificationsService`**
```dart
// lib/notifications_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  
  // Initialize and get FCM token
  static Future<void> initialize() async {
    print('🔔 [NOTIFICATIONS] Initializing...');
    
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ [NOTIFICATIONS] Permission granted');
      
      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('📱 [NOTIFICATIONS] FCM Token: $_fcmToken');
      
      // Send token to backend
      await _sendTokenToBackend(_fcmToken!);
      
      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_sendTokenToBackend);
      
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Listen for notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
    } else {
      print('❌ [NOTIFICATIONS] Permission denied');
    }
  }
  
  // Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      final apiKey = prefs.getString('api_key');
      
      if (authToken == null) {
        print('⚠️ [NOTIFICATIONS] User not logged in, skipping token upload');
        return;
      }
      
      print('📤 [NOTIFICATIONS] Sending FCM token to backend...');
      
      final response = await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/user/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'x-api-key': apiKey ?? '',
        },
        body: jsonEncode({'fcm_token': token}),
      );
      
      if (response.statusCode == 200) {
        print('✅ [NOTIFICATIONS] FCM token sent successfully');
      } else {
        print('❌ [NOTIFICATIONS] Failed to send token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error sending token: $e');
    }
  }
  
  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 [NOTIFICATIONS] Foreground message: ${message.notification?.title}');
    
    // Show local notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dalma_channel',
      'Dalma Notifications',
      channelDescription: 'إشعارات تطبيق دلما',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }
  
  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 [NOTIFICATIONS] Notification tapped: ${message.data}');
    // Navigate to specific page based on message.data
  }
  
  // Get current FCM token
  static String? get fcmToken => _fcmToken;
}
```

**الخطوة 4: إضافة endpoint في Backend**
```javascript
// في dalma-api/index.js

// Update user FCM token
app.post('/api/user/fcm-token', authenticateToken, async (req, res) => {
  try {
    console.log('📱 [FCM] Updating token for user:', req.user.id);
    const { fcm_token } = req.body;
    
    if (!fcm_token) {
      return res.status(400).json({ error: 'FCM token required' });
    }
    
    // Update user's FCM token
    await pool.query(
      'UPDATE users SET fcm_token = $1, updated_at = NOW() WHERE id = $2',
      [fcm_token, req.user.id]
    );
    
    console.log('✅ [FCM] Token updated successfully');
    res.json({ success: true, message: 'FCM token updated' });
  } catch (error) {
    console.error('❌ [FCM] Error updating token:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add fcm_token column if not exists
app.get('/api/admin/setup-fcm', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS fcm_token TEXT
    `);
    res.json({ success: true, message: 'FCM column added' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

**الخطوة 5: استدعاء NotificationsService عند تسجيل الدخول**
```dart
// في login_page.dart بعد تسجيل الدخول الناجح
await NotificationsService.initialize();
```

---

## 2. إدارة الإعلانات
### 📢 Ads Management

### ❌ الوضع الحالي:
- Admin يمكنه إضافة إعلانات (Banners)
- التطبيق **لا يعرض** هذه الإعلانات
- البيانات موجودة في Database لكن غير مستخدمة!

### ✅ المطلوب:

#### 2.1 إنشاء API endpoint لجلب الإعلانات

```javascript
// في dalma-api/index.js

// Get active ads for specific page
app.get('/api/ads/:page', async (req, res) => {
  try {
    const { page } = req.params;
    console.log(`📢 [ADS] Fetching ads for page: ${page}`);
    
    const result = await pool.query(`
      SELECT * FROM ads 
      WHERE page_location = $1 AND is_active = true
      ORDER BY display_order ASC
    `, [page]);
    
    console.log(`✅ [ADS] Found ${result.rows.length} ads`);
    res.json(result.rows);
  } catch (error) {
    console.error('❌ [ADS] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create ads table if not exists
app.get('/api/admin/setup-ads', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS ads (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        image_url TEXT NOT NULL,
        link_url TEXT,
        page_location TEXT NOT NULL,
        position TEXT DEFAULT 'top',
        display_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### 2.2 إنشاء AdBanner Widget في Flutter

```dart
// lib/widgets/ad_banner.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class AdBanner extends StatefulWidget {
  final String pageLocation;
  final String position;
  
  const AdBanner({
    Key? key,
    required this.pageLocation,
    this.position = 'top',
  }) : super(key: key);
  
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  List<dynamic> _ads = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAds();
  }
  
  Future<void> _loadAds() async {
    try {
      print('📢 [ADS] Loading ads for ${widget.pageLocation}...');
      
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/ads/${widget.pageLocation}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> ads = jsonDecode(response.body);
        setState(() {
          _ads = ads.where((ad) => ad['position'] == widget.position).toList();
          _loading = false;
        });
        print('✅ [ADS] Loaded ${_ads.length} ads');
      }
    } catch (e) {
      print('❌ [ADS] Error: $e');
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
    }
    
    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: PageView.builder(
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return GestureDetector(
            onTap: () async {
              if (ad['link_url'] != null) {
                final url = Uri.parse(ad['link_url']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: ad['image_url'],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

#### 2.3 استخدام AdBanner في الصفحات

```dart
// في main.dart (الصفحة الرئيسية)
Column(
  children: [
    // Banner في الأعلى
    AdBanner(pageLocation: 'home', position: 'top'),
    
    // محتوى الصفحة
    // ...
    
    // Banner في الأسفل
    AdBanner(pageLocation: 'home', position: 'bottom'),
  ],
)

// في services_page.dart
AdBanner(pageLocation: 'services', position: 'top'),

// في trends_page.dart
AdBanner(pageLocation: 'trends', position: 'top'),
```

---

## 3. إدارة الشركاء
### 🤝 Partners Management

### ❌ الوضع الحالي:
- Admin يمكنه إضافة شركاء
- التطبيق يعرض شركاء **ثابتة (Hardcoded)**
- لا يوجد ربط مع Database!

### ✅ المطلوب:

#### 3.1 API Endpoint للشركاء

```javascript
// Get active partners
app.get('/api/partners', async (req, res) => {
  try {
    console.log('🤝 [PARTNERS] Fetching partners...');
    
    const result = await pool.query(`
      SELECT * FROM partners 
      WHERE is_active = true
      ORDER BY display_order ASC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('❌ [PARTNERS] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Setup partners table
app.get('/api/admin/setup-partners', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS partners (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        logo_url TEXT NOT NULL,
        website_url TEXT,
        description TEXT,
        display_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### 3.2 تحديث عرض الشركاء في التطبيق

```dart
// في main.dart - استبدال القائمة الثابتة بـ API
class _PartnersSection extends StatefulWidget {
  @override
  State<_PartnersSection> createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<_PartnersSection> {
  List<dynamic> _partners = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPartners();
  }
  
  Future<void> _loadPartners() async {
    try {
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/partners'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _partners = jsonDecode(response.body);
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading partners: $e');
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CircularProgressIndicator();
    }
    
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _partners.length,
        itemBuilder: (context, index) {
          final partner = _partners[index];
          return GestureDetector(
            onTap: () async {
              if (partner['website_url'] != null) {
                final url = Uri.parse(partner['website_url']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CachedNetworkImage(
                imageUrl: partner['logo_url'],
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## 4. إدارة الفئات
### 🗂️ Categories Management

### ❌ الوضع الحالي:
- الفئات **ثابتة** في كود التطبيق
- Admin يمكنه إضافة فئات لكن التطبيق لا يراها
- لا يمكن تحديث الفئات بدون تحديث التطبيق!

### ✅ المطلوب:

#### 4.1 API Endpoint للفئات

```javascript
// Get active categories
app.get('/api/categories', async (req, res) => {
  try {
    console.log('🗂️ [CATEGORIES] Fetching categories...');
    
    const result = await pool.query(`
      SELECT * FROM categories 
      WHERE is_active = true
      ORDER BY display_order ASC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('❌ [CATEGORIES] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Setup categories table
app.get('/api/admin/setup-categories', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        icon_emoji TEXT NOT NULL,
        color TEXT DEFAULT '#6366f1',
        display_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### 4.2 تحديث ServicesPage

```dart
// في services_page.dart
class _ServicesPageState extends State<ServicesPage> {
  List<dynamic> _categories = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    try {
      print('🗂️ [CATEGORIES] Loading from API...');
      
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/categories'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _categories = jsonDecode(response.body);
          _loading = false;
        });
        print('✅ [CATEGORIES] Loaded ${_categories.length} categories');
      }
    } catch (e) {
      print('❌ [CATEGORIES] Error: $e');
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }
  
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        // Navigate to category services
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse(category['color'].replaceAll('#', '0xff'))),
              Color(int.parse(category['color'].replaceAll('#', '0xff'))).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category['icon_emoji'],
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 10),
            Text(
              category['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. إدارة المستخدمين
### 👥 Users Management

### ✅ المطلوب:

#### 5.1 إضافة إمكانية حظر/تفعيل المستخدمين

```javascript
// Block/Unblock user
app.post('/api/admin/users/:id/toggle-block', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { is_blocked } = req.body;
    
    await pool.query(
      'UPDATE users SET is_blocked = $1 WHERE id = $2',
      [is_blocked, id]
    );
    
    console.log(`${is_blocked ? '🔒' : '🔓'} User ${id} ${is_blocked ? 'blocked' : 'unblocked'}`);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add is_blocked column
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
```

#### 5.2 التحقق من الحظر عند تسجيل الدخول

```dart
// في auth.dart
Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    // Check if user is blocked
    if (data['is_blocked'] == true) {
      throw Exception('تم حظر حسابك. يرجى التواصل مع الإدارة.');
    }
    
    return data;
  }
  
  throw Exception('فشل تسجيل الدخول');
}
```

---

## 6. إدارة الطلبات
### 📋 Requests Management

### ✅ المطلوب:

#### 6.1 إشعار المستخدم بتغيير حالة الطلب

```javascript
// Update request status and send notification
app.post('/api/admin/requests/:id/update-status', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, type } = req.body; // type: 'media' or 'provider'
    
    const table = type === 'media' ? 'media_requests' : 'provider_requests';
    
    // Update status
    const result = await pool.query(
      `UPDATE ${table} SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING user_id`,
      [status, id]
    );
    
    if (result.rows.length > 0) {
      const userId = result.rows[0].user_id;
      
      // Get user's FCM token
      const userResult = await pool.query(
        'SELECT fcm_token, username FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows[0]?.fcm_token) {
        // Send push notification
        const message = {
          token: userResult.rows[0].fcm_token,
          notification: {
            title: 'تحديث حالة الطلب',
            body: status === 'approved' 
              ? '🎉 تم قبول طلبك!' 
              : '❌ تم رفض طلبك',
          },
          data: {
            type: 'request_update',
            request_id: id.toString(),
            status: status,
          },
        };
        
        // Send via FCM (requires Firebase Admin SDK)
        console.log('📤 Sending notification to user:', userId);
      }
    }
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## 7. الإعدادات العامة
### ⚙️ App Settings

### ✅ المطلوب:

#### 7.1 جلب الإعدادات من Backend

```dart
// lib/services/app_config.dart
class AppConfig {
  static Map<String, dynamic>? _settings;
  
  static Future<void> loadSettings() async {
    try {
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/app/settings'),
      );
      
      if (response.statusCode == 200) {
        _settings = jsonDecode(response.body);
        print('✅ [CONFIG] Settings loaded');
      }
    } catch (e) {
      print('❌ [CONFIG] Error: $e');
    }
  }
  
  static String get appName => _settings?['app_name'] ?? 'دلما';
  static String get primaryColor => _settings?['primary_color'] ?? '#6366f1';
  static bool get maintenanceMode => _settings?['maintenance_mode'] ?? false;
}

// في main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadSettings();
  
  // Check maintenance mode
  if (AppConfig.maintenanceMode) {
    runApp(MaintenanceApp());
  } else {
    runApp(MyApp());
  }
}
```

---

## 8. التقارير والإحصائيات
### 📊 Reports & Analytics

### ✅ المطلوب:

#### 8.1 تتبع نشاط المستخدم

```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  static Future<void> trackEvent(String eventName, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return;
      
      await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/analytics/event'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_name': eventName,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('❌ [ANALYTICS] Error: $e');
    }
  }
  
  // Track page view
  static Future<void> trackPageView(String pageName) async {
    await trackEvent('page_view', {'page': pageName});
  }
  
  // Track button click
  static Future<void> trackButtonClick(String buttonName) async {
    await trackEvent('button_click', {'button': buttonName});
  }
}

// الاستخدام في التطبيق
AnalyticsService.trackPageView('home');
AnalyticsService.trackButtonClick('browse_services');
```

---

## 🚀 خطوات التنفيذ

### المرحلة 1: الإعداد الأساسي (يوم واحد)
1. ✅ إضافة Firebase إلى المشروع
2. ✅ إنشاء جداول Database الجديدة
3. ✅ إضافة API endpoints الأساسية

### المرحلة 2: نظام الإشعارات (يومان)
1. ✅ تهيئة FCM في التطبيق
2. ✅ ربط FCM tokens مع Backend
3. ✅ اختبار إرسال الإشعارات

### المرحلة 3: الإعلانات والشركاء (يوم واحد)
1. ✅ إنشاء AdBanner widget
2. ✅ تحديث عرض الشركاء
3. ✅ اختبار التكامل

### المرحلة 4: الفئات والإعدادات (يوم واحد)
1. ✅ تحديث ServicesPage
2. ✅ إضافة AppConfig
3. ✅ اختبار التكامل

### المرحلة 5: التحليلات والتقارير (يوم واحد)
1. ✅ إضافة AnalyticsService
2. ✅ تتبع الأحداث
3. ✅ اختبار شامل

---

## 📝 ملاحظات مهمة

1. **Firebase Setup**: تحتاج إلى إنشاء مشروع Firebase وتنزيل ملفات التكوين
2. **Database Migration**: قد تحتاج لتشغيل scripts لإضافة الأعمدة الجديدة
3. **Testing**: اختبر كل ميزة على حدة قبل الدمج الكامل
4. **Performance**: استخدم caching للبيانات التي لا تتغير كثيراً

---

## ✅ Checklist

- [ ] إعداد Firebase
- [ ] تهيئة FCM
- [ ] إضافة جداول Database
- [ ] إنشاء API endpoints
- [ ] تحديث Flutter app
- [ ] اختبار الإشعارات
- [ ] اختبار الإعلانات
- [ ] اختبار الشركاء
- [ ] اختبار الفئات
- [ ] اختبار الإعدادات
- [ ] اختبار التحليلات
- [ ] اختبار شامل
- [ ] نشر التحديثات

---

## 🎯 النتيجة النهائية

بعد تنفيذ هذا الدليل، سيكون لديك:

✅ تطبيق متكامل 100% مع لوحة التحكم
✅ إشعارات حقيقية تصل للمستخدمين
✅ إعلانات ديناميكية من Admin Panel
✅ شركاء وفئات قابلة للتحديث
✅ إعدادات مركزية
✅ تحليلات وتقارير دقيقة
✅ تجربة مستخدم احترافية

---

**تم إعداد هذا الدليل بواسطة:** Dalma Development Team  
**التاريخ:** 2025-10-23  
**الإصدار:** 1.0.0



## Admin Dashboard to Flutter App Integration Guide

---

## 🎯 نظرة عامة

هذا الدليل الشامل يوضح **جميع الميزات** في لوحة التحكم (Admin Dashboard) التي تحتاج إلى ربط مع تطبيق Dalma Flutter، وكيفية تنفيذ هذا الربط بشكل واقعي وكامل.

---

## 📋 جدول المحتويات

1. [نظام الإشعارات (Push Notifications)](#1-نظام-الإشعارات)
2. [إدارة الإعلانات (Ads Management)](#2-إدارة-الإعلانات)
3. [إدارة الشركاء (Partners Management)](#3-إدارة-الشركاء)
4. [إدارة الفئات (Categories Management)](#4-إدارة-الفئات)
5. [إدارة المستخدمين (Users Management)](#5-إدارة-المستخدمين)
6. [إدارة الطلبات (Requests Management)](#6-إدارة-الطلبات)
7. [الإعدادات العامة (App Settings)](#7-الإعدادات-العامة)
8. [التقارير والإحصائيات (Reports & Analytics)](#8-التقارير-والإحصائيات)

---

## 1. نظام الإشعارات
### 📧 Push Notifications System

### ❌ الوضع الحالي:
- Admin Dashboard يمكنه إرسال إشعارات لكن التطبيق **لا يستقبلها**
- لا يوجد FCM Token مسجل للمستخدمين
- الإشعارات تُرسل لكن لا أحد يراها!

### ✅ المطلوب:

#### 1.1 إضافة Firebase Cloud Messaging للتطبيق

**الخطوة 1: إعداد Firebase**
```bash
# في مجلد التطبيق
cd aldlma
flutter pub add firebase_core
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications
```

**الخطوة 2: تهيئة Firebase في `main.dart`**
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global notification handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background Message: ${message.notification?.title}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('📩 Notification clicked: ${response.payload}');
    },
  );
  
  runApp(MyApp());
}
```

**الخطوة 3: إنشاء `NotificationsService`**
```dart
// lib/notifications_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  
  // Initialize and get FCM token
  static Future<void> initialize() async {
    print('🔔 [NOTIFICATIONS] Initializing...');
    
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ [NOTIFICATIONS] Permission granted');
      
      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('📱 [NOTIFICATIONS] FCM Token: $_fcmToken');
      
      // Send token to backend
      await _sendTokenToBackend(_fcmToken!);
      
      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_sendTokenToBackend);
      
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Listen for notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
    } else {
      print('❌ [NOTIFICATIONS] Permission denied');
    }
  }
  
  // Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      final apiKey = prefs.getString('api_key');
      
      if (authToken == null) {
        print('⚠️ [NOTIFICATIONS] User not logged in, skipping token upload');
        return;
      }
      
      print('📤 [NOTIFICATIONS] Sending FCM token to backend...');
      
      final response = await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/user/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'x-api-key': apiKey ?? '',
        },
        body: jsonEncode({'fcm_token': token}),
      );
      
      if (response.statusCode == 200) {
        print('✅ [NOTIFICATIONS] FCM token sent successfully');
      } else {
        print('❌ [NOTIFICATIONS] Failed to send token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [NOTIFICATIONS] Error sending token: $e');
    }
  }
  
  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 [NOTIFICATIONS] Foreground message: ${message.notification?.title}');
    
    // Show local notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dalma_channel',
      'Dalma Notifications',
      channelDescription: 'إشعارات تطبيق دلما',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }
  
  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 [NOTIFICATIONS] Notification tapped: ${message.data}');
    // Navigate to specific page based on message.data
  }
  
  // Get current FCM token
  static String? get fcmToken => _fcmToken;
}
```

**الخطوة 4: إضافة endpoint في Backend**
```javascript
// في dalma-api/index.js

// Update user FCM token
app.post('/api/user/fcm-token', authenticateToken, async (req, res) => {
  try {
    console.log('📱 [FCM] Updating token for user:', req.user.id);
    const { fcm_token } = req.body;
    
    if (!fcm_token) {
      return res.status(400).json({ error: 'FCM token required' });
    }
    
    // Update user's FCM token
    await pool.query(
      'UPDATE users SET fcm_token = $1, updated_at = NOW() WHERE id = $2',
      [fcm_token, req.user.id]
    );
    
    console.log('✅ [FCM] Token updated successfully');
    res.json({ success: true, message: 'FCM token updated' });
  } catch (error) {
    console.error('❌ [FCM] Error updating token:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add fcm_token column if not exists
app.get('/api/admin/setup-fcm', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS fcm_token TEXT
    `);
    res.json({ success: true, message: 'FCM column added' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

**الخطوة 5: استدعاء NotificationsService عند تسجيل الدخول**
```dart
// في login_page.dart بعد تسجيل الدخول الناجح
await NotificationsService.initialize();
```

---

## 2. إدارة الإعلانات
### 📢 Ads Management

### ❌ الوضع الحالي:
- Admin يمكنه إضافة إعلانات (Banners)
- التطبيق **لا يعرض** هذه الإعلانات
- البيانات موجودة في Database لكن غير مستخدمة!

### ✅ المطلوب:

#### 2.1 إنشاء API endpoint لجلب الإعلانات

```javascript
// في dalma-api/index.js

// Get active ads for specific page
app.get('/api/ads/:page', async (req, res) => {
  try {
    const { page } = req.params;
    console.log(`📢 [ADS] Fetching ads for page: ${page}`);
    
    const result = await pool.query(`
      SELECT * FROM ads 
      WHERE page_location = $1 AND is_active = true
      ORDER BY display_order ASC
    `, [page]);
    
    console.log(`✅ [ADS] Found ${result.rows.length} ads`);
    res.json(result.rows);
  } catch (error) {
    console.error('❌ [ADS] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Create ads table if not exists
app.get('/api/admin/setup-ads', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS ads (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        image_url TEXT NOT NULL,
        link_url TEXT,
        page_location TEXT NOT NULL,
        position TEXT DEFAULT 'top',
        display_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### 2.2 إنشاء AdBanner Widget في Flutter

```dart
// lib/widgets/ad_banner.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class AdBanner extends StatefulWidget {
  final String pageLocation;
  final String position;
  
  const AdBanner({
    Key? key,
    required this.pageLocation,
    this.position = 'top',
  }) : super(key: key);
  
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  List<dynamic> _ads = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAds();
  }
  
  Future<void> _loadAds() async {
    try {
      print('📢 [ADS] Loading ads for ${widget.pageLocation}...');
      
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/ads/${widget.pageLocation}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> ads = jsonDecode(response.body);
        setState(() {
          _ads = ads.where((ad) => ad['position'] == widget.position).toList();
          _loading = false;
        });
        print('✅ [ADS] Loaded ${_ads.length} ads');
      }
    } catch (e) {
      print('❌ [ADS] Error: $e');
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
    }
    
    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: PageView.builder(
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return GestureDetector(
            onTap: () async {
              if (ad['link_url'] != null) {
                final url = Uri.parse(ad['link_url']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: ad['image_url'],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

#### 2.3 استخدام AdBanner في الصفحات

```dart
// في main.dart (الصفحة الرئيسية)
Column(
  children: [
    // Banner في الأعلى
    AdBanner(pageLocation: 'home', position: 'top'),
    
    // محتوى الصفحة
    // ...
    
    // Banner في الأسفل
    AdBanner(pageLocation: 'home', position: 'bottom'),
  ],
)

// في services_page.dart
AdBanner(pageLocation: 'services', position: 'top'),

// في trends_page.dart
AdBanner(pageLocation: 'trends', position: 'top'),
```

---

## 3. إدارة الشركاء
### 🤝 Partners Management

### ❌ الوضع الحالي:
- Admin يمكنه إضافة شركاء
- التطبيق يعرض شركاء **ثابتة (Hardcoded)**
- لا يوجد ربط مع Database!

### ✅ المطلوب:

#### 3.1 API Endpoint للشركاء

```javascript
// Get active partners
app.get('/api/partners', async (req, res) => {
  try {
    console.log('🤝 [PARTNERS] Fetching partners...');
    
    const result = await pool.query(`
      SELECT * FROM partners 
      WHERE is_active = true
      ORDER BY display_order ASC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('❌ [PARTNERS] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Setup partners table
app.get('/api/admin/setup-partners', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS partners (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        logo_url TEXT NOT NULL,
        website_url TEXT,
        description TEXT,
        display_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### 3.2 تحديث عرض الشركاء في التطبيق

```dart
// في main.dart - استبدال القائمة الثابتة بـ API
class _PartnersSection extends StatefulWidget {
  @override
  State<_PartnersSection> createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<_PartnersSection> {
  List<dynamic> _partners = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPartners();
  }
  
  Future<void> _loadPartners() async {
    try {
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/partners'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _partners = jsonDecode(response.body);
          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading partners: $e');
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CircularProgressIndicator();
    }
    
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _partners.length,
        itemBuilder: (context, index) {
          final partner = _partners[index];
          return GestureDetector(
            onTap: () async {
              if (partner['website_url'] != null) {
                final url = Uri.parse(partner['website_url']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: CachedNetworkImage(
                imageUrl: partner['logo_url'],
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## 4. إدارة الفئات
### 🗂️ Categories Management

### ❌ الوضع الحالي:
- الفئات **ثابتة** في كود التطبيق
- Admin يمكنه إضافة فئات لكن التطبيق لا يراها
- لا يمكن تحديث الفئات بدون تحديث التطبيق!

### ✅ المطلوب:

#### 4.1 API Endpoint للفئات

```javascript
// Get active categories
app.get('/api/categories', async (req, res) => {
  try {
    console.log('🗂️ [CATEGORIES] Fetching categories...');
    
    const result = await pool.query(`
      SELECT * FROM categories 
      WHERE is_active = true
      ORDER BY display_order ASC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('❌ [CATEGORIES] Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Setup categories table
app.get('/api/admin/setup-categories', authenticateAdmin, async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        icon_emoji TEXT NOT NULL,
        color TEXT DEFAULT '#6366f1',
        display_order INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

#### 4.2 تحديث ServicesPage

```dart
// في services_page.dart
class _ServicesPageState extends State<ServicesPage> {
  List<dynamic> _categories = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    try {
      print('🗂️ [CATEGORIES] Loading from API...');
      
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/categories'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _categories = jsonDecode(response.body);
          _loading = false;
        });
        print('✅ [CATEGORIES] Loaded ${_categories.length} categories');
      }
    } catch (e) {
      print('❌ [CATEGORIES] Error: $e');
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }
  
  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        // Navigate to category services
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse(category['color'].replaceAll('#', '0xff'))),
              Color(int.parse(category['color'].replaceAll('#', '0xff'))).withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category['icon_emoji'],
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 10),
            Text(
              category['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. إدارة المستخدمين
### 👥 Users Management

### ✅ المطلوب:

#### 5.1 إضافة إمكانية حظر/تفعيل المستخدمين

```javascript
// Block/Unblock user
app.post('/api/admin/users/:id/toggle-block', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { is_blocked } = req.body;
    
    await pool.query(
      'UPDATE users SET is_blocked = $1 WHERE id = $2',
      [is_blocked, id]
    );
    
    console.log(`${is_blocked ? '🔒' : '🔓'} User ${id} ${is_blocked ? 'blocked' : 'unblocked'}`);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add is_blocked column
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT false;
```

#### 5.2 التحقق من الحظر عند تسجيل الدخول

```dart
// في auth.dart
Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    // Check if user is blocked
    if (data['is_blocked'] == true) {
      throw Exception('تم حظر حسابك. يرجى التواصل مع الإدارة.');
    }
    
    return data;
  }
  
  throw Exception('فشل تسجيل الدخول');
}
```

---

## 6. إدارة الطلبات
### 📋 Requests Management

### ✅ المطلوب:

#### 6.1 إشعار المستخدم بتغيير حالة الطلب

```javascript
// Update request status and send notification
app.post('/api/admin/requests/:id/update-status', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, type } = req.body; // type: 'media' or 'provider'
    
    const table = type === 'media' ? 'media_requests' : 'provider_requests';
    
    // Update status
    const result = await pool.query(
      `UPDATE ${table} SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING user_id`,
      [status, id]
    );
    
    if (result.rows.length > 0) {
      const userId = result.rows[0].user_id;
      
      // Get user's FCM token
      const userResult = await pool.query(
        'SELECT fcm_token, username FROM users WHERE id = $1',
        [userId]
      );
      
      if (userResult.rows[0]?.fcm_token) {
        // Send push notification
        const message = {
          token: userResult.rows[0].fcm_token,
          notification: {
            title: 'تحديث حالة الطلب',
            body: status === 'approved' 
              ? '🎉 تم قبول طلبك!' 
              : '❌ تم رفض طلبك',
          },
          data: {
            type: 'request_update',
            request_id: id.toString(),
            status: status,
          },
        };
        
        // Send via FCM (requires Firebase Admin SDK)
        console.log('📤 Sending notification to user:', userId);
      }
    }
    
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## 7. الإعدادات العامة
### ⚙️ App Settings

### ✅ المطلوب:

#### 7.1 جلب الإعدادات من Backend

```dart
// lib/services/app_config.dart
class AppConfig {
  static Map<String, dynamic>? _settings;
  
  static Future<void> loadSettings() async {
    try {
      final response = await http.get(
        Uri.parse('https://dalma-api.onrender.com/api/app/settings'),
      );
      
      if (response.statusCode == 200) {
        _settings = jsonDecode(response.body);
        print('✅ [CONFIG] Settings loaded');
      }
    } catch (e) {
      print('❌ [CONFIG] Error: $e');
    }
  }
  
  static String get appName => _settings?['app_name'] ?? 'دلما';
  static String get primaryColor => _settings?['primary_color'] ?? '#6366f1';
  static bool get maintenanceMode => _settings?['maintenance_mode'] ?? false;
}

// في main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadSettings();
  
  // Check maintenance mode
  if (AppConfig.maintenanceMode) {
    runApp(MaintenanceApp());
  } else {
    runApp(MyApp());
  }
}
```

---

## 8. التقارير والإحصائيات
### 📊 Reports & Analytics

### ✅ المطلوب:

#### 8.1 تتبع نشاط المستخدم

```dart
// lib/services/analytics_service.dart
class AnalyticsService {
  static Future<void> trackEvent(String eventName, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return;
      
      await http.post(
        Uri.parse('https://dalma-api.onrender.com/api/analytics/event'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_name': eventName,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('❌ [ANALYTICS] Error: $e');
    }
  }
  
  // Track page view
  static Future<void> trackPageView(String pageName) async {
    await trackEvent('page_view', {'page': pageName});
  }
  
  // Track button click
  static Future<void> trackButtonClick(String buttonName) async {
    await trackEvent('button_click', {'button': buttonName});
  }
}

// الاستخدام في التطبيق
AnalyticsService.trackPageView('home');
AnalyticsService.trackButtonClick('browse_services');
```

---

## 🚀 خطوات التنفيذ

### المرحلة 1: الإعداد الأساسي (يوم واحد)
1. ✅ إضافة Firebase إلى المشروع
2. ✅ إنشاء جداول Database الجديدة
3. ✅ إضافة API endpoints الأساسية

### المرحلة 2: نظام الإشعارات (يومان)
1. ✅ تهيئة FCM في التطبيق
2. ✅ ربط FCM tokens مع Backend
3. ✅ اختبار إرسال الإشعارات

### المرحلة 3: الإعلانات والشركاء (يوم واحد)
1. ✅ إنشاء AdBanner widget
2. ✅ تحديث عرض الشركاء
3. ✅ اختبار التكامل

### المرحلة 4: الفئات والإعدادات (يوم واحد)
1. ✅ تحديث ServicesPage
2. ✅ إضافة AppConfig
3. ✅ اختبار التكامل

### المرحلة 5: التحليلات والتقارير (يوم واحد)
1. ✅ إضافة AnalyticsService
2. ✅ تتبع الأحداث
3. ✅ اختبار شامل

---

## 📝 ملاحظات مهمة

1. **Firebase Setup**: تحتاج إلى إنشاء مشروع Firebase وتنزيل ملفات التكوين
2. **Database Migration**: قد تحتاج لتشغيل scripts لإضافة الأعمدة الجديدة
3. **Testing**: اختبر كل ميزة على حدة قبل الدمج الكامل
4. **Performance**: استخدم caching للبيانات التي لا تتغير كثيراً

---

## ✅ Checklist

- [ ] إعداد Firebase
- [ ] تهيئة FCM
- [ ] إضافة جداول Database
- [ ] إنشاء API endpoints
- [ ] تحديث Flutter app
- [ ] اختبار الإشعارات
- [ ] اختبار الإعلانات
- [ ] اختبار الشركاء
- [ ] اختبار الفئات
- [ ] اختبار الإعدادات
- [ ] اختبار التحليلات
- [ ] اختبار شامل
- [ ] نشر التحديثات

---

## 🎯 النتيجة النهائية

بعد تنفيذ هذا الدليل، سيكون لديك:

✅ تطبيق متكامل 100% مع لوحة التحكم
✅ إشعارات حقيقية تصل للمستخدمين
✅ إعلانات ديناميكية من Admin Panel
✅ شركاء وفئات قابلة للتحديث
✅ إعدادات مركزية
✅ تحليلات وتقارير دقيقة
✅ تجربة مستخدم احترافية

---

**تم إعداد هذا الدليل بواسطة:** Dalma Development Team  
**التاريخ:** 2025-10-23  
**الإصدار:** 1.0.0



