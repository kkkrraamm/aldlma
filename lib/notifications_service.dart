import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 [FCM] Background Message: ${message.notification?.title}');
}

class NotificationsService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static bool _initialized = false;
  
  // Initialize FCM
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ [FCM] Already initialized');
      return;
    }
    
    try {
      print('🔔 [FCM] Initializing...');
      
      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📩 [FCM] Notification clicked: ${response.payload}');
        },
      );
      
      // Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [FCM] Permission granted');
        
        // Get FCM token
        _fcmToken = await _fcm.getToken();
        print('📱 [FCM] Token: $_fcmToken');
        
        // Send token to backend
        if (_fcmToken != null) {
          await _sendTokenToBackend(_fcmToken!);
        }
        
        // Listen for token refresh
        _fcm.onTokenRefresh.listen(_sendTokenToBackend);
        
        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        
        // Listen for notification taps
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        // Setup background handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        _initialized = true;
        print('✅ [FCM] Initialization complete');
      } else {
        print('❌ [FCM] Permission denied');
      }
    } catch (e) {
      print('❌ [FCM] Initialization error: $e');
    }
  }
  
  // Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      final apiKey = prefs.getString('api_key');
      
      if (authToken == null) {
        print('⚠️ [FCM] User not logged in, skipping token upload');
        return;
      }
      
      print('📤 [FCM] Sending token to backend...');
      
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
        print('✅ [FCM] Token sent successfully');
      } else {
        print('❌ [FCM] Failed to send token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FCM] Error sending token: $e');
    }
  }
  
  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 [FCM] Foreground message: ${message.notification?.title}');
    
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
      payload: jsonEncode(message.data),
    );
  }
  
  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 [FCM] Notification tapped: ${message.data}');
    // يمكن إضافة navigation هنا حسب نوع الإشعار
  }
  
  // Get current FCM token
  static String? get fcmToken => _fcmToken;
  
  // Check if initialized
  static bool get isInitialized => _initialized;
}

