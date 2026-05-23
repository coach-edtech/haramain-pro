import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/location_service.dart';
import '../../config/constants.dart';

/// Panic alert status
enum PanicStatus {
  pending,
  sent,
  failed,
  responded,
  resolved,
}

/// Panic alert data model
class PanicAlert {
  final String id;
  final String jamaaahId;
  final String rombonganId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final String? message;
  final DateTime timestamp;
  final PanicStatus status;
  final String? responderId;
  final String? responseType;

  String get grupId => rombonganId;

  const PanicAlert({
    required this.id,
    required this.jamaaahId,
    required this.rombonganId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.message,
    required this.timestamp,
    this.status = PanicStatus.pending,
    this.responderId,
    this.responseType,
  });

  factory PanicAlert.create({
    required String jamaaahId,
    required String rombonganId,
    required LocationData location,
    String? message,
  }) {
    return PanicAlert(
      id: const Uuid().v4(),
      jamaaahId: jamaaahId,
      rombonganId: rombonganId,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      altitude: location.altitude,
      message: message,
      timestamp: location.timestamp,
      status: PanicStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jamaah_id': jamaaahId,
      'rombongan_id': rombonganId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'responder_id': responderId,
      'response_type': responseType,
    };
  }

  Map<String, dynamic> toEdgeFunctionPayload() {
    return {
      'rombonganId': rombonganId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PanicAlert.fromJson(Map<String, dynamic> json) {
    return PanicAlert(
      id: json['id'] as String,
      jamaaahId: json['jamaah_id'] as String,
      rombonganId: json['rombongan_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      message: json['message'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: PanicStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PanicStatus.pending,
      ),
      responderId: json['responder_id'] as String?,
      responseType: json['response_type'] as String?,
    );
  }

  PanicAlert copyWith({
    String? id,
    String? jamaaahId,
    String? rombonganId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    String? message,
    DateTime? timestamp,
    PanicStatus? status,
    String? responderId,
    String? responseType,
  }) {
    return PanicAlert(
      id: id ?? this.id,
      jamaaahId: jamaaahId ?? this.jamaaahId,
      rombonganId: rombonganId ?? this.rombonganId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      responderId: responderId ?? this.responderId,
      responseType: responseType ?? this.responseType,
    );
  }

  @override
  String toString() {
    return 'PanicAlert(id: $id, jamaah: $jamaaahId, rombongan: $rombonganId, lat: $latitude, lng: $longitude, status: ${status.name})';
  }
}

/// Panic service result
class PanicResult {
  final bool success;
  final String? alertId;
  final String? error;
  final bool usedSmsFallback;

  const PanicResult({
    required this.success,
    this.alertId,
    this.error,
    this.usedSmsFallback = false,
  });
}

/// Response action types
class PanicResponseAction {
  static const String stayJemput = 'stay_jemput';
  static const String sayaDiSini = 'saya_di_sini';
  static const String telepon = 'telepon';
}

/// Panic service for sending and managing panic alerts
class PanicService {
  static final PanicService _instance = PanicService._internal();
  static PanicService get instance => _instance;

  PanicService._internal();

  static const String _offlineQueueKey = 'panic_offline_queue';
  static const String _lastPanicKey = 'panic_last_sent';
  static const int _maxRetries = 3;
  static const int _rateLimitSeconds = 300; // 5 minutes
  
  // Exponential backoff delays: 1s, 2s, 4s
  static const List<int> _backoffDelays = [1000, 2000, 4000];

  final LocationService _locationService = LocationService.instance;

  // Cached SharedPreferences instance for synchronous access
  static SharedPreferences? _prefs;

  // Connectivity subscription for offline queue processing
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Initialize SharedPreferences and connectivity listener - call this at app startup
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await instance._startConnectivityListener();
  }

  /// Start listening to connectivity changes to process offline queue when online
  Future<void> _startConnectivityListener() async {
    // Cancel any existing subscription
    await _connectivitySubscription?.cancel();

    // Subscribe to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      // If any connectivity is available (not none), process the offline queue
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        debugPrint('Connectivity restored, processing offline queue...');
        processOfflineQueue().catchError((e) {
          debugPrint('Error processing offline queue: $e');
        });
      }
    }, onError: (e) {
      debugPrint('Connectivity listener error: $e');
    });

    debugPrint('PanicService connectivity listener started');
  }

  /// Stop connectivity listener - call when service is disposed
  Future<void> stopConnectivityListener() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    debugPrint('PanicService connectivity listener stopped');
  }

  Future<bool> _checkRateLimit(String jamaaahId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final lastSentStr = prefs.getString('${_lastPanicKey}_$jamaaahId');
    
    if (lastSentStr == null) return true;
    
    final lastSent = DateTime.tryParse(lastSentStr);
    if (lastSent == null) return true;
    
    final elapsed = DateTime.now().difference(lastSent);
    if (elapsed.inSeconds >= _rateLimitSeconds) {
      return true;
    }
    
    return false;
  }

  Future<void> _updateRateLimit(String jamaaahId) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
      '${_lastPanicKey}_$jamaaahId',
      DateTime.now().toIso8601String(),
    );
  }

  /// Returns the remaining cooldown seconds for a user.
  /// Returns 0 if no cooldown is active or SharedPreferences is not initialized.
  /// This is a sync helper - for async check use _checkRateLimit.
  int getRemainingCooldownSeconds(String jamaaahId) {
    final prefs = _prefs;
    if (prefs == null) return 0;

    final lastSentStr = prefs.getString('${_lastPanicKey}_$jamaaahId');
    if (lastSentStr == null) return 0;

    final lastSent = DateTime.tryParse(lastSentStr);
    if (lastSent == null) return 0;

    final elapsed = DateTime.now().difference(lastSent);
    final remaining = _rateLimitSeconds - elapsed.inSeconds;
    
    return remaining > 0 ? remaining : 0;
  }

  /// Send panic alert with retry logic and offline queue
  /// Returns PanicResult indicating success or failure
  Future<PanicResult> sendPanic({
    required String jamaaahId,
    required String rombonganId,
    LocationData? coordinates,
    String? message,
  }) async {
    // Check rate limit
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
      rombonganId: rombonganId,
      location: location,
      message: message,
    );

    debugPrint('Sending panic alert: ${alert.id}');

    // Try to send with retries
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        // Attempt to send via FCM/Critical Alert
        final sent = await _sendViaFcm(alert);
        
        if (sent) {
          debugPrint('Panic alert sent successfully via FCM');
          await _updateRateLimit(jamaaahId);
          await _removeFromOfflineQueue(alert.id);
          await savePanicHistory(alert);
          return PanicResult(success: true, alertId: alert.id);
        }
      } catch (e) {
        debugPrint('FCM send attempt $attempt failed: $e');
      }

      // If not last attempt, wait with exponential backoff
      if (attempt < _maxRetries) {
        final delayMs = _backoffDelays[attempt];
        debugPrint('Retrying in ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    // All FCM attempts failed, try SMS fallback
    debugPrint('FCM failed after $_maxRetries retries, attempting SMS fallback');
    
    try {
      final smsResult = await _sendViaSms(alert);
      if (smsResult) {
        await _updateRateLimit(jamaaahId);
        await _removeFromOfflineQueue(alert.id);
        await savePanicHistory(alert);
        return PanicResult(
          success: true,
          alertId: alert.id,
          usedSmsFallback: true,
        );
      }
    } catch (e) {
      debugPrint('SMS fallback also failed: $e');
    }

    // Both FCM and SMS failed, add to offline queue
    debugPrint('Adding panic alert to offline queue');
    await _addToOfflineQueue(alert);
    await savePanicHistory(alert);
    
    return PanicResult(
      success: false,
      alertId: alert.id,
      error: 'Failed to send panic alert. Added to offline queue and will retry automatically.',
    );
  }

  /// Send panic via Supabase Edge Function
  Future<bool> _sendViaFcm(PanicAlert alert) async {
    try {
      final payload = alert.toEdgeFunctionPayload();
      debugPrint('Sending panic alert to edge function: ${jsonEncode(payload)}');

      final response = await Supabase.instance.client.functions.invoke(
        'fcm-panic-alert',
        body: payload,
      );

      if (response.data == null) {
        debugPrint('Edge function returned null data');
        return false;
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('Edge function response: $data');

      return data['status'] == 'success';
    } catch (e) {
      debugPrint('Edge function call failed: $e');
      return false;
    }
  }

  /// Send panic via SMS fallback using Twilio/Nexmo
  Future<bool> _sendViaSms(PanicAlert alert) async {
    try {
      final googleMapsUrl = 'https://maps.google.com/?q=${alert.latitude},${alert.longitude}';
      final smsMessage = alert.message ?? 'PANIC ALERT!';
      final fullMessage = '$smsMessage\nJamaah ID: ${alert.jamaaahId}\nLocation: $googleMapsUrl';

      debugPrint('SMS fallback payload: $fullMessage');

      final response = await Supabase.instance.client.functions.invoke(
        'twilio-voice-fallback',
        body: {
          'jamaaah_id': alert.jamaaahId,
          'grup_id': alert.rombonganId,
          'latitude': alert.latitude,
          'longitude': alert.longitude,
          'timestamp': alert.timestamp.toIso8601String(),
          'alert_id': alert.id,
          'nama_jamaah': null,
        },
      );

      if (response.data == null) {
        debugPrint('SMS fallback returned null data');
        return false;
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('SMS fallback response: $data');

      return data['status'] == 'success';
    } catch (e) {
      debugPrint('SMS fallback failed: $e');
      return false;
    }
  }

  /// Add alert to offline queue for later retry
  Future<void> _addToOfflineQueue(PanicAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_offlineQueueKey);
    
    List<PanicAlert> queue = [];
    if (queueJson != null) {
      final List<dynamic> decoded = jsonDecode(queueJson);
      queue = decoded.map((e) => PanicAlert.fromJson(e)).toList();
    }
    
    // Check if already in queue
    if (queue.any((a) => a.id == alert.id)) return;
    
    queue.add(alert);
    await prefs.setString(
      _offlineQueueKey,
      jsonEncode(queue.map((a) => a.toJson()).toList()),
    );
    
    debugPrint('Added alert ${alert.id} to offline queue. Queue size: ${queue.length}');
  }

  /// Remove alert from offline queue
  Future<void> _removeFromOfflineQueue(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_offlineQueueKey);
    
    if (queueJson == null) return;
    
    final List<dynamic> decoded = jsonDecode(queueJson);
    List<PanicAlert> queue = decoded.map((e) => PanicAlert.fromJson(e)).toList();
    
    queue.removeWhere((a) => a.id == alertId);
    
    await prefs.setString(
      _offlineQueueKey,
      jsonEncode(queue.map((a) => a.toJson()).toList()),
    );
    
    debugPrint('Removed alert $alertId from offline queue');
  }

  /// Get all alerts in offline queue
  Future<List<PanicAlert>> getOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_offlineQueueKey);
    
    if (queueJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(queueJson);
    return decoded.map((e) => PanicAlert.fromJson(e)).toList();
  }

  /// Process offline queue - retry all pending alerts
  Future<void> processOfflineQueue() async {
    final queue = await getOfflineQueue();
    
    if (queue.isEmpty) {
      debugPrint('Offline queue is empty, nothing to process');
      return;
    }
    
    debugPrint('Processing offline queue with ${queue.length} alerts');
    
    for (final alert in queue) {
      // Try to resend each alert
      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        try {
          final sent = await _sendViaFcm(alert);
          if (sent) {
            await _removeFromOfflineQueue(alert.id);
            debugPrint('Successfully resent offline alert: ${alert.id}');
            break;
          }
        } catch (e) {
          debugPrint('Resend attempt $attempt failed for ${alert.id}: $e');
        }
        
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: _backoffDelays[attempt]));
        }
      }
    }
  }

  /// Save panic history
  Future<void> savePanicHistory(PanicAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'panic_history';
    
    final historyJson = prefs.getString(historyKey);
    List<PanicAlert> history = [];
    
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      history = decoded.map((e) => PanicAlert.fromJson(e)).toList();
    }
    
    // Add or update alert in history
    final existingIndex = history.indexWhere((a) => a.id == alert.id);
    if (existingIndex >= 0) {
      history[existingIndex] = alert;
    } else {
      history.insert(0, alert); // Add to beginning
    }
    
    // Keep only last 100 entries
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }
    
    await prefs.setString(
      historyKey,
      jsonEncode(history.map((a) => a.toJson()).toList()),
    );
  }

  /// Get panic history
  Future<List<PanicAlert>> getPanicHistory({DateTime? fromDate, DateTime? toDate}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'panic_history';
    
    final historyJson = prefs.getString(historyKey);
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(historyJson);
    List<PanicAlert> history = decoded.map((e) => PanicAlert.fromJson(e)).toList();
    
    // Filter by date if provided
    if (fromDate != null) {
      history = history.where((a) => a.timestamp.isAfter(fromDate)).toList();
    }
    if (toDate != null) {
      history = history.where((a) => a.timestamp.isBefore(toDate)).toList();
    }
    
    return history;
  }

  /// Update panic status
  Future<void> updatePanicStatus(String alertId, PanicStatus status, {String? responderId, String? responseType}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = 'panic_history';
    
    final historyJson = prefs.getString(historyKey);
    if (historyJson == null) return;
    
    final List<dynamic> decoded = jsonDecode(historyJson);
    List<PanicAlert> history = decoded.map((e) => PanicAlert.fromJson(e)).toList();
    
    final index = history.indexWhere((a) => a.id == alertId);
    if (index >= 0) {
      history[index] = history[index].copyWith(
        status: status,
        responderId: responderId,
        responseType: responseType,
      );
      
      await prefs.setString(
        historyKey,
        jsonEncode(history.map((a) => a.toJson()).toList()),
      );
    }
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[PanicService] $message');
}
