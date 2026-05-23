import 'package:flutter/foundation.dart';

class AppLogger {
  static void panic(String message) => debugPrint('[PANIC] ');
  static void group(String message) => debugPrint('[GROUP] ');
  static void location(String message) => debugPrint('[LOCATION] ');
  static void ibadah(String message) => debugPrint('[IBADAH] ');
  static void fcm(String message) => debugPrint('[FCM] ');
  static void error(String message) => debugPrint('[ERROR] ');
}