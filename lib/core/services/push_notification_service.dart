import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

/// Manages FCM token lifecycle and push notification handling.
///
/// - Requests notification permission on [initialize]
/// - Saves/refreshes FCM token to Supabase [fcm_tokens] table
/// - Handles foreground and background tap events
/// - Provides [onNotificationTap] callback for navigation
class PushNotificationService {
  PushNotificationService(this._client);

  final SupabaseClient _client;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;
  String? _cachedDeviceId;

  // Subscriptions stored for clean cancellation on dispose.
  // ignore: cancel_subscriptions
  final _subscriptions = <dynamic>[];

  /// Called when user taps a notification. Receives type and payload data.
  void Function(String type, Map<String, dynamic> data)? onNotificationTap;

  /// Initialize FCM: request permissions, save token, listen for refresh.
  /// Idempotent — safe to call multiple times (only runs once).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[Push] Permission denied');
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    _subscriptions
      ..add(_messaging.onTokenRefresh.listen(_saveToken))
      ..add(FirebaseMessaging.onMessage.listen(_handleForegroundMessage))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap));

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Remove token on sign-out to stop receiving notifications.
  Future<void> removeToken() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final deviceId = await _getOrCreateDeviceId();
    try {
      await _client
          .from(AppConstants.fcmTokensTable)
          .delete()
          .eq('user_id', userId)
          .eq('device_id', deviceId);
      debugPrint('[Push] Token removed');
    } catch (e) {
      debugPrint('[Push] Token remove error: $e');
    }
  }

  /// Cancel all stream subscriptions (call on sign-out / service teardown).
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
  }

  Future<void> _saveToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final deviceId = await _getOrCreateDeviceId();
    try {
      await _client.from(AppConstants.fcmTokensTable).upsert(
        {
          'user_id': userId,
          'token': token,
          'device_id': deviceId,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
        onConflict: 'user_id,device_id',
      );
      debugPrint('[Push] Token saved');
    } catch (e) {
      debugPrint('[Push] Token save error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[Push] Foreground: ${message.notification?.title}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String? ?? 'unknown';
    onNotificationTap?.call(type, message.data);
  }

  /// Returns a stable, unique device identifier persisted across app sessions.
  /// Generated once as a UUID v4 and stored in SharedPreferences.
  Future<String> _getOrCreateDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('push_device_id');
    if (existing != null) {
      _cachedDeviceId = existing;
      return existing;
    }
    final newId = const Uuid().v4();
    await prefs.setString('push_device_id', newId);
    _cachedDeviceId = newId;
    return newId;
  }
}
