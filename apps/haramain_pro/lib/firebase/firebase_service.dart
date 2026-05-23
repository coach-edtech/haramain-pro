import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase message handler type
typedef FirebaseMessageHandler = void Function(RemoteMessage message);

/// Firebase service for FCM handling
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;

  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseMessaging? _messaging;
  FirebaseMessaging get messaging {
    if (_messaging == null) {
      throw StateError('FirebaseService not initialized. Call initialize() first.');
    }
    return _messaging!;
  }

  // Message handlers for panic alerts
  final List<FirebaseMessageHandler> _panicAlertHandlers = [];

  /// Initialize Firebase
  /// Call this before runApp()
  Future<void> initialize({
    FirebaseOptions? options,
  }) async {
    if (_isInitialized) return;

    await Firebase.initializeApp(
      options: options,
    );

    // Initialize messaging
    _messaging = FirebaseMessaging.instance;

    // Request permission for iOS
    await _requestNotificationPermission();

    // Set up message handlers
    await _setupMessageHandlers();

    _isInitialized = true;
    debugPrint('FirebaseService initialized');
  }

  /// Request notification permission
  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // Required for panic alerts
        provisional: false,
        sound: true,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  /// Set up FCM message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened via notification)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }

  /// Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Message data: ${message.data}');

    // Check if this is a panic alert
    if (message.data['type'] == 'panic_alert') {
      _handlePanicAlert(message);
    }

    // Show local notification for panic alerts
    if (message.notification != null) {
      debugPrint('Message notification: ${message.notification!.title}');
    }
  }

  /// Handle when app is opened via notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');

    if (message.data['type'] == 'panic_alert') {
      _handlePanicAlert(message);
    }
  }

  /// Handle initial message (app opened from terminated state via notification)
  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('Initial message: ${message.messageId}');

    if (message.data['type'] == 'panic_alert') {
      _handlePanicAlert(message);
    }
  }

  /// Handle panic alert message
  void _handlePanicAlert(RemoteMessage message) {
    debugPrint('Handling panic alert: ${message.messageId}');

    // Parse panic alert data
    try {
      final alertData = message.data;
      
      // Notify all registered handlers
      for (final handler in _panicAlertHandlers) {
        handler(message);
      }
    } catch (e) {
      debugPrint('Error handling panic alert: $e');
    }
  }

  /// Register a handler for panic alert messages
  void registerPanicAlertHandler(FirebaseMessageHandler handler) {
    _panicAlertHandlers.add(handler);
    debugPrint('Registered panic alert handler. Total handlers: ${_panicAlertHandlers.length}');
  }

  /// Unregister a panic alert handler
  void unregisterPanicAlertHandler(FirebaseMessageHandler handler) {
    _panicAlertHandlers.remove(handler);
  }

  /// Get FCM token for this device
  Future<String?> getToken() async {
    try {
      return await messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Get FCM token with auto-refresh
  Future<void> getTokenStream(void Function(String? token) onTokenUpdate) async {
    messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM token refreshed');
      onTokenUpdate(token);
    });

    // Also get current token
    final token = await getToken();
    onTokenUpdate(token);
  }

  /// Subscribe to a topic (for group notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Send a panic alert notification locally (for testing)
  Future<void> showLocalPanicNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // In production, this would use flutter_local_notifications
    // For now, we just log it
    debugPrint('Local panic notification - Title: $title, Body: $body, Payload: $payload');
  }

  /// Parse panic alert from FCM data
  static Map<String, dynamic>? parsePanicAlertData(Map<String, dynamic> data) {
    if (data['type'] != 'panic_alert') return null;

    return {
      'id': data['alert_id'] ?? data['id'],
      'jamaah_id': data['jamaah_id'],
      'grup_id': data['grup_id'],
      'lat': double.tryParse(data['lat']?.toString() ?? ''),
      'lng': double.tryParse(data['lng']?.toString() ?? ''),
      'timestamp': data['timestamp'],
      'jamaah_name': data['jamaah_name'],
    };
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[FirebaseService] $message');
}
