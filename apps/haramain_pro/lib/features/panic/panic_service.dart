import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../services/location_service.dart';

/// Panic alert status enum
enum PanicStatus {
  pending,
  sent,
  acknowledged,
  responded, // maps to 'call'/'sms'/'location' response_type
  resolved,
  failed,
}

/// Panic response action enum — Indonesian labels for UI clarity
enum PanicResponseAction {
  // Indonesian response actions (used in UI)
  stayJemput,  // "Stay, saya jemput" — muthawif will pick up
  sayaDiSini, // "Saya di sini" — share location
  telepon,     // Phone call
  dismiss,     // Dismiss alert
}

/// Converts string status from DB to PanicStatus enum
PanicStatus _stringToStatus(String? status) {
  switch (status) {
    case 'sent': return PanicStatus.sent;
    case 'acknowledged': return PanicStatus.acknowledged;
    case 'call': case 'sms': case 'location': return PanicStatus.responded;
    case 'resolved': return PanicStatus.resolved;
    case 'failed': return PanicStatus.failed;
    default: return PanicStatus.pending;
  }
}

/// Converts PanicStatus enum to string for DB
String _statusToString(PanicStatus status) {
  switch (status) {
    case PanicStatus.pending: return 'pending';
    case PanicStatus.sent: return 'sent';
    case PanicStatus.acknowledged: return 'acknowledged';
    case PanicStatus.responded: return 'responded';
    case PanicStatus.resolved: return 'resolved';
    case PanicStatus.failed: return 'failed';
  }
}

/// Result of a panic alert send operation
class PanicResult {
  final bool success;
  final String? error;
  final String? alertId;
  final bool usedSmsFallback;

  const PanicResult({
    required this.success,
    this.error,
    this.alertId,
    this.usedSmsFallback = false,
  });
}

/// Panic alert model — schema matches DB `panic_alerts` table
class PanicAlert {
  final String id;
  final String jamaaahId; // maps to user_id in DB
  final String? grupId; // maps to agency_id in DB
  final String? responseType; // raw response_type from DB: 'call','sms','location','dismiss'
  final String? responderId;
  final double latitude; // maps to lat in DB
  final double longitude; // maps to lng in DB
  final double? accuracy;
  final double? altitude;
  final String? message;
  final DateTime timestamp; // maps to created_at in DB
  final PanicStatus status; // derived from response_type

  const PanicAlert({
    required this.id,
    required this.jamaaahId,
    this.grupId,
    this.responseType,
    this.responderId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.message,
    required this.timestamp,
    this.status = PanicStatus.pending,
  });

  factory PanicAlert.create({
    required String jamaaahId,
    String? grupId,
    required LocationData location,
    String? message,
  }) {
    return PanicAlert(
      id: const Uuid().v4(),
      jamaaahId: jamaaahId,
      grupId: grupId,
      latitude: location.latitude ?? 0,
      longitude: location.longitude ?? 0,
      accuracy: location.accuracy,
      altitude: location.altitude,
      message: message,
      timestamp: DateTime.now(),
      status: PanicStatus.pending,
    );
  }

  factory PanicAlert.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['response_type'] as String?;
    return PanicAlert(
      id: json['id'] as String? ?? '',
      jamaaahId: (json['user_id'] ?? json['jamaaah_id'] ?? '') as String,
      grupId: json['rombongan_id'] as String? ?? json['agency_id'] as String?,
      responseType: rawStatus,
      responderId: json['responder_id'] as String?,
      latitude: (json['lat'] ?? json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['lng'] ?? json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      message: json['message'] as String?,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      status: _stringToStatus(rawStatus),
    );
  }

  PanicAlert copyWith({
    String? responseType,
    String? responderId,
    PanicStatus? status,
  }) {
    return PanicAlert(
      id: id,
      jamaaahId: jamaaahId,
      grupId: grupId,
      responseType: responseType ?? this.responseType,
      responderId: responderId ?? this.responderId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      message: message,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': jamaaahId,
        'rombongan_id': grupId,
        'lat': latitude,
        'lng': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'message': message,
        'created_at': timestamp.toIso8601String(),
        'response_type': responseType,
        'responder_id': responderId,
      };

  Map<String, dynamic> toEdgeFunctionPayload() => {
        'alert_id': id,
        'jamaaah_id': jamaaahId,
        'rombongan_id': grupId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Panic service — rate limit, history, and offline queue all stored in Supabase `panic_alerts`
/// FCM sending requires backend Edge Function (not called directly from client)
class PanicService {
  static final PanicService _instance = PanicService._internal();
  static PanicService get instance => _instance;

  PanicService._internal();

  SupabaseClient get _sb => Supabase.instance.client;

  static const int _maxRetries = 3;
  static const int _rateLimitSeconds = 300; // 5 minutes

  // Exponential backoff delays: 1s, 2s, 4s
  static const List<int> _backoffDelays = [1000, 2000, 4000];

  final LocationService _locationService = LocationService.instance;

  // Connectivity subscription for offline queue processing
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize connectivity listener — call at app startup
  Future<void> initialize() async {
    await _startConnectivityListener();
  }

  /// Start listening to connectivity changes to process offline queue when online
  Future<void> _startConnectivityListener() async {
    await _connectivitySubscription?.cancel();

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        debugPrint('PanicService: Connectivity restored, processing offline queue...');
        processOfflineQueue().catchError((e) {
          debugPrint('PanicService: Error processing offline queue: $e');
        });
      }
    }, onError: (e) {
      debugPrint('PanicService: Connectivity listener error: $e');
    });

    debugPrint('PanicService: Connectivity listener started');
  }

  /// Stop connectivity listener — call when service is disposed
  Future<void> stopConnectivityListener() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    debugPrint('PanicService: Connectivity listener stopped');
  }

  /// Check if user can send panic (rate limit via Supabase)
  Future<bool> _checkRateLimit(String jamaaahId) async {
    final result = await _sb
        .from('panic_alerts')
        .select('created_at')
        .eq('user_id', jamaaahId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (result == null) return true;

    final lastSent = DateTime.parse(result['created_at'] as String);
    final elapsed = DateTime.now().difference(lastSent);
    return elapsed.inSeconds >= _rateLimitSeconds;
  }

  /// Get remaining cooldown seconds for UI display
  Future<int> getRemainingCooldownSeconds(String jamaaahId) async {
    final result = await _sb
        .from('panic_alerts')
        .select('created_at')
        .eq('user_id', jamaaahId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (result == null) return 0;

    final lastSent = DateTime.parse(result['created_at'] as String);
    final elapsed = DateTime.now().difference(lastSent);
    final remaining = _rateLimitSeconds - elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Send panic alert with retry logic and offline queue
  /// Returns PanicResult indicating success or failure
  Future<PanicResult> sendPanic({
    required String jamaaahId,
    required String? caravanaId,
    LocationData? coordinates,
    String? message,
  }) async {
    // Rate limit check
    final canSend = await _checkRateLimit(jamaaahId);
    if (!canSend) {
      return const PanicResult(
        success: false,
        error: 'Please wait 5 minutes before sending another panic alert.',
      );
    }

    // Get current location if not provided
    LocationData? location = coordinates;
    if (location == null) {
      location = await _locationService.getCurrentLocation();
      if (location == null) {
        return const PanicResult(
          success: false,
          error: 'Failed to get location. Please enable location services.',
        );
      }
    }

    // Create panic alert
    final alert = PanicAlert.create(
      jamaaahId: jamaaahId,
      grupId: caravanaId,
      location: location,
      message: message,
    );

    debugPrint('PanicService: Sending panic alert: ${alert.id}');

    // Try to send with retries
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final sent = await _sendViaFcm(alert);

        if (sent) {
          debugPrint('PanicService: Panic alert sent successfully via FCM');
          // Update status in Supabase
          await _sb
              .from('panic_alerts')
              .update({'response_type': 'sent'})
              .eq('id', alert.id);
          return PanicResult(success: true, alertId: alert.id);
        }
      } catch (e) {
        debugPrint('PanicService: FCM send attempt $attempt failed: $e');
      }

      if (attempt < _maxRetries) {
        final delayMs = _backoffDelays[attempt];
        debugPrint('PanicService: Retrying in ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    // All FCM attempts failed, try SMS fallback
    debugPrint('PanicService: FCM failed after $_maxRetries retries, attempting SMS fallback');

    try {
      final smsResult = await _sendViaSms(alert);
      if (smsResult) {
        return PanicResult(
          success: true,
          alertId: alert.id,
          usedSmsFallback: true,
        );
      }
    } catch (e) {
      debugPrint('PanicService: SMS fallback also failed: $e');
    }

    // Both FCM and SMS failed, insert to Supabase as pending for later retry
    debugPrint('PanicService: Adding panic alert to offline queue in Supabase');
    await _insertPanicAlert(alert);

    return PanicResult(
      success: false,
      alertId: alert.id,
      error: 'Failed to send panic alert. Added to offline queue and will retry automatically.',
    );
  }

  /// Insert panic alert into Supabase
  Future<void> _insertPanicAlert(PanicAlert alert) async {
    await _sb.from('panic_alerts').insert(alert.toJson());
    debugPrint('PanicService: Inserted alert ${alert.id} into panic_alerts');
  }

  /// Send panic via Supabase Edge Function (FCM)
  Future<bool> _sendViaFcm(PanicAlert alert) async {
    try {
      final payload = alert.toEdgeFunctionPayload();
      debugPrint('PanicService: Sending panic alert to edge function: ${jsonEncode(payload)}');

      final response = await _sb.functions.invoke(
        'fcm-panic-alert',
        body: payload,
      );

      if (response.data == null) {
        debugPrint('PanicService: Edge function returned null data');
        return false;
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('PanicService: Edge function response: $data');

      return data['status'] == 'success';
    } catch (e) {
      debugPrint('PanicService: Edge function call failed: $e');
      return false;
    }
  }

  /// Send panic via SMS fallback using Twilio
  Future<bool> _sendViaSms(PanicAlert alert) async {
    try {
      final googleMapsUrl = 'https://maps.google.com/?q=${alert.latitude},${alert.longitude}';
      final smsMessage = alert.message ?? 'PANIC ALERT!';
      final fullMessage = '$smsMessage\nJamaah ID: ${alert.jamaaahId}\nLocation: $googleMapsUrl';

      debugPrint('PanicService: SMS fallback payload: $fullMessage');

      final response = await _sb.functions.invoke(
        'twilio-voice-fallback',
        body: {
          'jamaaah_id': alert.jamaaahId,
          'rombongan_id': alert.grupId,
          'latitude': alert.latitude,
          'longitude': alert.longitude,
          'timestamp': alert.timestamp.toIso8601String(),
          'alert_id': alert.id,
          'nama_jamaah': null,
        },
      );

      if (response.data == null) {
        debugPrint('PanicService: SMS fallback returned null data');
        return false;
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('PanicService: SMS fallback response: $data');

      return data['status'] == 'success';
    } catch (e) {
      debugPrint('PanicService: SMS fallback failed: $e');
      return false;
    }
  }

  /// Process offline queue — retry all pending alerts
  Future<void> processOfflineQueue() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return;

    final queue = await getOfflineQueue();

    if (queue.isEmpty) {
      debugPrint('PanicService: Offline queue is empty, nothing to process');
      return;
    }

    debugPrint('PanicService: Processing offline queue with ${queue.length} alerts');

    for (final alert in queue) {
      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        try {
          final sent = await _sendViaFcm(alert);
          if (sent) {
            await _sb.from('panic_alerts').delete().eq('id', alert.id);
            debugPrint('PanicService: Successfully resent offline alert: ${alert.id}');
            break;
          }
        } catch (e) {
          debugPrint('PanicService: Resend attempt $attempt failed for ${alert.id}: $e');
        }

        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: _backoffDelays[attempt]));
        }
      }
    }
  }

  /// Get all pending panic alerts for current user from Supabase
  Future<List<PanicAlert>> getOfflineQueue() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return [];

    final result = await _sb
        .from('panic_alerts')
        .select()
        .eq('user_id', userId)
        .filter('sync_status', 'is', 'null');

    return (result as List)
        .map((e) => PanicAlert.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get panic history for current user
  Future<List<PanicAlert>> getPanicHistory({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _sb
        .from('panic_alerts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    final result = await query;

    var alerts = (result as List)
        .map((e) => PanicAlert.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Filter by date if provided
    if (fromDate != null) {
      alerts = alerts.where((a) => a.timestamp.isAfter(fromDate)).toList();
    }
    if (toDate != null) {
      alerts = alerts.where((a) => a.timestamp.isBefore(toDate)).toList();
    }

    return alerts;
  }

  /// Respond to a panic alert — Indonesian response actions
  Future<void> respondToPanic({
    required String alertId,
    required PanicResponseAction action,
    String? responderId,
  }) async {
    final actionMap = {
      PanicResponseAction.stayJemput: 'stay',
      PanicResponseAction.sayaDiSini: 'here',
      PanicResponseAction.telepon: 'call',
      PanicResponseAction.dismiss: 'dismiss',
    };

    await _sb.from('panic_alerts').update({
      'response_type': actionMap[action],
      'responder_id': responderId,
    }).eq('id', alertId);

    debugPrint('PanicService: Responded to alert $alertId with action ${actionMap[action]}');
  }

  /// Update panic alert status
  Future<void> updatePanicStatus({
    required String alertId,
    required PanicStatus status,
    String? responderId,
    String? responseType,
  }) async {
    await _sb.from('panic_alerts').update({
      'response_type': responseType ?? _statusToString(status),
      'responder_id': responderId,
    }).eq('id', alertId);

    debugPrint('PanicService: Updated alert $alertId status to ${_statusToString(status)}');
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[PanicService] $message');
}
