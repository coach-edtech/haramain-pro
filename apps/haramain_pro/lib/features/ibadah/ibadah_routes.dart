import 'package:flutter/material.dart';
import 'screens/prayer_time_screen.dart';
import 'screens/ibadah_mode_screen.dart';

/// Ibadah feature routes
class IbadahRoutes {
  IbadahRoutes._();

  static const String prayerTimes = '/ibadah';
  static const String ibadahMode = '/ibadah/mode';

  /// Get all routes for ibadah feature
  static Map<String, WidgetBuilder> get routes => {
        prayerTimes: (context) => const PrayerTimeScreen(),
        ibadahMode: (context) => const IbadahModeScreen(),
      };
}
