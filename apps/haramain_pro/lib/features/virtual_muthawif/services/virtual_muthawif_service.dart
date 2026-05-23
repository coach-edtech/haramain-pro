import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:haramain_pro/features/virtual_muthawif/data/doa_repository.dart';
import 'package:haramain_pro/services/location_service.dart';

class VirtualMuthawifService {
  static final VirtualMuthawifService _instance = VirtualMuthawifService._internal();
  static VirtualMuthawifService get instance => _instance;
  VirtualMuthawifService._internal();

  final DoaRepository _doaRepository = DoaRepository.instance;
  final LocationService _locationService = LocationService.instance;

  // Stream controller for zone changes
  final _zoneController = StreamController<String?>.broadcast();
  Stream<String?> get onZoneChanged => _zoneController.stream;

  // Current detected zone
  String? _currentZone;
  String? get currentZone => _currentZone;

  // Location tracking
  StreamSubscription? _locationSubscription;
  bool _isTracking = false;

  /// Start tracking location for zone detection
  Future<void> startTracking() async {
    if (_isTracking) return;
    _isTracking = true;

    // Check initial location
    await _checkCurrentLocation();

    // Start continuous tracking
    _locationSubscription = _locationService.onLocationChanged.listen((location) {
      _checkZone(location.latitude, location.longitude);
    });
  }

  /// Stop tracking
  void stopTracking() {
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Check current location
  Future<void> _checkCurrentLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _checkZone(location.latitude, location.longitude);
      }
    } catch (e) {
      debugPrint('Error checking current location: $e');
    }
  }

  /// Check if coordinates are within a zone
  void _checkZone(double lat, double lng) {
    final zone = _doaRepository.detectZone(lat, lng);
    
    if (zone != _currentZone) {
      _currentZone = zone;
      _zoneController.add(zone);
      debugPrint('Zone changed to: ${zone ?? 'none'}');
    }
  }

  /// Get current zone's doa
  Map<String, dynamic>? getCurrentDoa() {
    if (_currentZone == null) return null;
    return _doaRepository.getDoaData(_currentZone!);
  }

  /// Get all available zones
  List<Map<String, dynamic>> getAllZones() {
    return _doaRepository.getAllZones();
  }

  /// Get prayer suggestion based on current zone
  String getPrayerSuggestion() {
    if (_currentZone == null) {
      return 'Tetaplah tenang dan mengingat Allah di mana pun Anda berada.';
    }

    final doa = getCurrentDoa();
    if (doa == null) {
      return 'Tetaplah tenang dan mengingat Allah.';
    }

    return '''Di ${doa['name']}, luangkan waktu untuk berdoa dengan khusyuk.

${doa['indonesian']}

${doa['description']}''';
  }

  /// Generate AI response (placeholder for actual AI integration)
  /// 
  /// TODO: Integrate with Nadhira AI API for contextual Quranic duas
  /// 
  /// Expected API interface:
  /// POST {AI_API_ENDPOINT}/v1/chat/completions
  /// Headers: Authorization: Bearer {AI_API_KEY}
  /// Body: {
  ///   "model": "nadhira-ai-2.0",
  ///   "messages": [
  ///     {"role": "system", "content": "You are Virtual Muthawif AI assistant..."},
  ///     {"role": "user", "content": userMessage}
  ///   ],
  ///   "context": {
  ///     "location": _currentZone,  // "makkah", "madinah", dll
  ///     "time_of_day": "after_fajr" | "morning" | "zuhr" | dll
  ///   }
  /// }
  /// 
  /// Expected response format:
  /// {
  ///   "choices": [{"message": {"content": "AI response text..."}}]
  /// }
  String generateAIResponse(String userMessage) {
    // Placeholder - in production, call AI API via Supabase Edge Function
    // AI edge function at: supabase/functions/ai-muthawif/index.ts
    final currentDoa = getCurrentDoa();
    
    if (userMessage.toLowerCase().contains('doa') || 
        userMessage.toLowerCase().contains('pray')) {
      if (currentDoa != null) {
        return '''Berdasarkan lokasi Anda di ${currentDoa['name']}, berikut doa yang cocok:

"${currentDoa['indonesian']}"

${currentDoa['arabic']}

Transliterasi: ${currentDoa['latin']}''';
      }
    }

    if (userMessage.toLowerCase().contains('where') || 
        userMessage.toLowerCase().contains('di mana')) {
      if (_currentZone != null) {
        final zoneData = _doaRepository.getDoaData(_currentZone!);
        return 'Anda saat ini berada di ${zoneData?['name']} di ${zoneData?['mosque']}.';
      }
      return 'Anda saat ini tidak berada di zona suci manapun.';
    }

    // Default response
    return '''Saya Muthawif Virtual Anda. Saya bisa membantu:

1. 📍 memberitahu Anda doa sesuai lokasi Anda
2. 🗺️ menjelaskan tempat suci di sekitar Anda
3. 📖 memberikan informasi tentang ritual Umrah/Haji

Silakan tanyakan sesuatu!''';
  }

  void dispose() {
    stopTracking();
    _zoneController.close();
  }
}
