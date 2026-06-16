import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// IMPORTANT:
/// Call NotificationService.instance.init() after Firebase.initializeApp()
/// and AFTER user login call NotificationService.instance.syncFcmTokenToUserDoc()
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNoti =
      FlutterLocalNotificationsPlugin();

  Map<String, dynamic>? _pendingTapData;
  Map<String, dynamic>? consumePendingTapData() {
    final d = _pendingTapData;
    _pendingTapData = null;
    return d;
  }

  void cacheTapData(Map<String, dynamic> data) {
    _pendingTapData = Map<String, dynamic>.from(data);
  }

  bool _initialized = false;

  /// Android notification channel
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Used for important notifications.',
        importance: Importance.high,
      );

  /// Background handler must be a top-level function (see bottom)
  static Future<void> _onBackgroundMessage(RemoteMessage message) async {
    // You can log or do minimal processing here.
    // Deep-links will be handled when app opens from notification.
    debugPrint('🔔 BG message: ${message.messageId} data=${message.data}');
  }

  Future<void> init({
    required void Function(Map<String, dynamic> data) onNotificationTap,
  }) async {
    if (_initialized) return;

    // 1) iOS permission
    await _requestPermission();

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNoti
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Create channel
      await androidPlugin?.createNotificationChannel(_androidChannel);

     
    }

    // 2) Register background handler
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3) Init local notifications (for foreground display)
    await _initLocalNotifications(onNotificationTap);

    // 4) Foreground message -> show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🔔 FG message: ${message.messageId} data=${message.data}');
      await _showLocalNotification(message);
    });

    // 5) When app opened from background by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Opened from BG tap: data=${message.data}');
      onNotificationTap(message.data);
    });

    // 6) When app opened from terminated state by tapping notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      debugPrint('🔔 Opened from terminated tap: data=${initial.data}');
      onNotificationTap(initial.data);
    }

    // 7) Token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔁 FCM token refreshed');
      await _saveTokenToFirestore(newToken);
    });

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    // iOS/macOS only really asks, Android auto-grants pre-13
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      provisional: false,
      criticalAlert: false,
      carPlay: false,
    );

    debugPrint('✅ Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications(
    void Function(Map<String, dynamic> data) onNotificationTap,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNoti.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Payload contains JSON-ish string if you want; we’ll keep it simple:
        // We'll store data in a simple key-value format in payload if needed.
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNoti
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    log('message : ${message.notification}');
    final notification = message.notification;
    // if (notification == null) return;
    log('title : ${notification?.title}');

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,

      presentBanner: true, // REQUIRED for iOS 14+ foreground banners
      presentList: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    log('===step 3=====');

    await _localNoti.show(
      id: notification.hashCode,
      title: notification?.title,
      body: notification?.body,
      notificationDetails: details,
    );
  }

  /// Call this after login (when user is known)
  // Future<void> syncFcmTokenToUserDoc() async {
  //   final token = await _messaging.getToken();
  //   if (token == null) {
  //     debugPrint('⚠️ No FCM token yet');
  //     return;
  //   }
  //   await _saveTokenToFirestore(token);
  // }

  Future<void> syncFcmTokenToUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? token;

    // iOS-safe retry (APNs can be late)
    for (int i = 0; i < 6; i++) {
      token = await _messaging.getToken();
      if (token != null) break;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (token == null) {
      debugPrint('⚠️ FCM token not ready yet (APNs delay)');
      return;
    }

    log('token : $token');

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmTokens': {token: true},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('✅ FCM token saved');
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.set({
      'fcmTokens': {token: true},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('✅ Saved FCM token to users/$uid');
  }
}
