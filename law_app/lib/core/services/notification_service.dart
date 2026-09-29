import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/auth_repository.dart';
import '../constants/api_constants.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'law_hub_updates',
    'Law Hub Updates',
    description: 'Notifications for legal updates, posts, and connections.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const String _enabledKey = 'push_notifications_enabled';

  Future<void> initialize(AuthRepository authRepository) async {
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(const InitializationSettings(android: androidSettings));
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;

    messaging.onTokenRefresh.listen((newToken) {
      _registerToken(authRepository, newToken);
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<void> refreshToken(AuthRepository authRepository) async {
    if (!await isEnabled()) return;
    final token = await FirebaseMessaging.instance.getToken();
    await _registerToken(authRepository, token);
  }

  Future<void> requestPermissionAndRegister(AuthRepository authRepository) async {
    if (!await isEnabled()) return;
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    await refreshToken(authRepository);
  }

  Future<void> unregisterCurrentToken(AuthRepository authRepository) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _removeToken(authRepository, token);
    } catch (_) {
      // Sign-out should still complete if Firebase is unavailable.
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled, AuthRepository authRepository) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await requestPermissionAndRegister(authRepository);
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    await _removeToken(authRepository, token);
    await FirebaseMessaging.instance.deleteToken();
  }

  Future<void> _registerToken(AuthRepository authRepository, String? token) async {
    if (!await isEnabled()) return;
    if (token == null || token.isEmpty || !authRepository.isAuthenticated) return;

    try {
      await http.post(
        Uri.parse(ApiConstants.fcmToken),
        headers: authRepository.authHeaders,
        body: jsonEncode({'token': token}),
      );
    } catch (_) {
      // Non-blocking: auth and app startup should not fail if push registration is unavailable.
    }
  }

  Future<void> _removeToken(AuthRepository authRepository, String? token) async {
    if (token == null || token.isEmpty || !authRepository.isAuthenticated) return;

    try {
      await http.post(
        Uri.parse(ApiConstants.fcmTokenRemove),
        headers: authRepository.authHeaders,
        body: jsonEncode({'token': token}),
      );
    } catch (_) {
      // Non-blocking: toggling settings should not fail if the server is unavailable.
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title;
    final body = notification?.body;
    if (title == null && body == null) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
