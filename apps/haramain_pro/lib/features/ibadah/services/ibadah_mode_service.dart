import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'geofence_service.dart';
import 'prayer_time_service.dart';

/// Ibadah mode state
enum IbadahModeState {
  disabled,
  enabled,
  entering, // Transitioning to enabled
  exiting, // Transitioning to disabled
}

/// Ibadah mode service
/// Manages silent/ibadah mode: silences all notifications except Panic
class IbadahModeService {
  static final IbadahModeService _instance = IbadahModeService._internal();
  static IbadahModeService get instance => _instance;

  IbadahModeService._internal();

  // State
  IbadahModeState _state = IbadahModeState.disabled;
  StreamSubscription<GeofenceEventData>? _geofenceSubscription;
  Timer? _prayerReminderTimer;
  DateTime? _lastReminderTime;

  // SharedPreferences key
  static const String _ibadahModeKey = 'ibadah_mode_enabled';
  static const String _dontShowGeofenceAlertKey = 'dont_show_geofence_alert';

  // Getters
  IbadahModeState get state => _state;
  bool get isEnabled => _state == IbadahModeState.enabled;
  bool get isDisabled => _state == IbadahModeState.disabled;
  bool get isTransitioning =>
      _state == IbadahModeState.entering || _state == IbadahModeState.exiting;

  /// Enable Ibadah Mode - silence all notifications except Panic
  Future<void> enableIbadahMode() async {
    if (_state == IbadahModeState.enabled) return;

    debugPrint('Enabling Ibadah Mode...');
    setState(IbadahModeState.entering);

    try {
      // 1. Silence all notification channels
      await _silenceAllNotifications();

      // 2. Start geofence monitoring
      await _startGeofenceMonitoring();

      // 3. Start prayer reminder timer
      _startPrayerReminderTimer();

      // 4. Save state
      await _saveState(true);

      setState(IbadahModeState.enabled);
      debugPrint('Ibadah Mode enabled successfully');
    } catch (e) {
      debugPrint('Error enabling Ibadah Mode: $e');
      setState(IbadahModeState.disabled);
      rethrow;
    }
  }

  /// Disable Ibadah Mode - restore normal notifications
  Future<void> disableIbadahMode() async {
    if (_state == IbadahModeState.disabled) return;

    debugPrint('Disabling Ibadah Mode...');
    setState(IbadahModeState.exiting);

    try {
      // 1. Restore all notification channels
      await _restoreAllNotifications();

      // 2. Stop geofence monitoring (but still listen for enter events)
      _stopGeofenceMonitoring();

      // 3. Stop prayer reminder timer
      _stopPrayerReminderTimer();

      // 4. Save state
      await _saveState(false);

      setState(IbadahModeState.disabled);
      debugPrint('Ibadah Mode disabled successfully');
    } catch (e) {
      debugPrint('Error disabling Ibadah Mode: $e');
      setState(IbadahModeState.enabled);
      rethrow;
    }
  }

  /// Toggle Ibadah Mode
  Future<void> toggleIbadahMode() async {
    if (isEnabled) {
      await disableIbadahMode();
    } else {
      await enableIbadahMode();
    }
  }

  /// Check if geofence alert should be shown
  Future<bool> shouldShowGeofenceAlert() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_dontShowGeofenceAlertKey) ?? false);
  }

  /// Set don't show geofence alert preference
  Future<void> setDontShowGeofenceAlert(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dontShowGeofenceAlertKey, value);
  }

  /// Restore state from storage on app start
  Future<void> restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final wasEnabled = prefs.getBool(_ibadahModeKey) ?? false;

    if (wasEnabled) {
      debugPrint('Restoring Ibadah Mode state from storage');
      await enableIbadahMode();
    }
  }

  /// Silence all notification channels (except panic)
  Future<void> _silenceAllNotifications() async {
    // Use platform channel to silence notifications
    // For now, we'll use method channel to communicate with native code
    try {
      const platform = MethodChannel('com.haramain.pro/notifications');
      await platform.invokeMethod('setAllChannelsSilent', {'silent': true});
      debugPrint('All notification channels silenced');
    } catch (e) {
      // If platform channel not available, log warning
      debugPrint('Could not silence notifications via platform channel: $e');
      // Continue anyway - the mode will still work
    }
  }

  /// Restore all notification channels
  Future<void> _restoreAllNotifications() async {
    try {
      const platform = MethodChannel('com.haramain.pro/notifications');
      await platform.invokeMethod('setAllChannelsSilent', {'silent': false});
      debugPrint('All notification channels restored');
    } catch (e) {
      debugPrint('Could not restore notifications via platform channel: $e');
      // Continue anyway
    }
  }

  /// Start geofence monitoring
  Future<void> _startGeofenceMonitoring() async {
    _geofenceSubscription?.cancel();
    _geofenceSubscription = GeofenceService.instance.onGeofenceEvent.listen(
      _onGeofenceEvent,
    );
    await GeofenceService.instance.startMonitoring();
  }

  /// Stop geofence monitoring
  void _stopGeofenceMonitoring() {
    _geofenceSubscription?.cancel();
    _geofenceSubscription = null;
    GeofenceService.instance.stopMonitoring();
  }

  /// Handle geofence events
  void _onGeofenceEvent(GeofenceEventData event) {
    if (event.event == GeofenceEvent.enter) {
      debugPrint('Entered ${event.mosque.name} area');
      // The UI should show the geofence alert dialog
      // This is handled by listening to the geofence stream in the app
    } else if (event.event == GeofenceEvent.exit) {
      debugPrint('Exited ${event.mosque.name} area');
      // Optionally auto-disable ibadah mode when leaving mosque area
      // But we'll let user manually disable it for better UX
    }
  }

  /// Start prayer reminder timer
  void _startPrayerReminderTimer() {
    _stopPrayerReminderTimer();

    // Check every minute if we should send a reminder
    _prayerReminderTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndTriggerReminder(),
    );
  }

  /// Stop prayer reminder timer
  void _stopPrayerReminderTimer() {
    _prayerReminderTimer?.cancel();
    _prayerReminderTimer = null;
  }

  /// Check if we should trigger a reminder and do so
  Future<void> _checkAndTriggerReminder() async {
    final now = DateTime.now();
    final prayerService = PrayerTimeService.instance;
    final nextPrayer = prayerService.getNextPrayer();

    if (nextPrayer == null) return;

    // Check if we're within 5 minutes of the next prayer
    final timeRemaining = nextPrayer.timeRemaining;
    if (timeRemaining.inMinutes <= 5 && timeRemaining.inMinutes > 0) {
      // Check if we haven't already reminded in the last 5 minutes
      if (_lastReminderTime == null ||
          now.difference(_lastReminderTime!).inMinutes >= 5) {
        debugPrint(
          'Triggering prayer reminder for ${nextPrayer.prayer.name.english}',
        );
        await prayerService.triggerPrayerReminder();
        _lastReminderTime = now;
      }
    }
  }

  /// Save state to storage
  Future<void> _saveState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ibadahModeKey, enabled);
  }

  /// Set state and notify listeners
  void setState(IbadahModeState newState) {
    _state = newState;
    // Could notify listeners here if needed
  }

  /// Dispose resources
  void dispose() {
    _geofenceSubscription?.cancel();
    _prayerReminderTimer?.cancel();
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[IbadahModeService] $message');
}
