import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration
/// All values loaded from .env file via flutter_dotenv
class SupabaseConstants {
  SupabaseConstants._();

  static String get supabaseUrl {
    final val = dotenv.get('SUPABASE_URL', fallback: '');
    if (val.isEmpty) {
      throw UnsupportedError(
        'SUPABASE_URL is not set.\n'
        'Add SUPABASE_URL=https://your-project.supabase.co to .env\n'
        'See .env.example for the full list of variables.',
      );
    }
    return val;
  }

  static String get supabaseKey {
    final val = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
    if (val.isEmpty) {
      throw UnsupportedError(
        'SUPABASE_ANON_KEY is not set.\n'
        'Add SUPABASE_ANON_KEY=your-anon-key to .env\n'
        'See .env.example for the full list of variables.',
      );
    }
    return val;
  }

  /// Auth callback URL (deep linking)
  static const String authCallbackUrl = 'haramainpro://auth-callback';
}

/// Firebase configuration
/// Loaded from .env via flutter_dotenv
class FirebaseConstants {
  FirebaseConstants._();

  static String get apiKey => dotenv.get('FIREBASE_API_KEY', fallback: '');

  static String get projectId => dotenv.get('FIREBASE_PROJECT_ID', fallback: 'haramain-pro');

  static String get messagingSenderId => dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '');

  static String get iosBundleId => dotenv.get('FIREBASE_IOS_BUNDLE_ID', fallback: 'com.haramain.pro');

  static String get iosAppId => dotenv.get('FIREBASE_IOS_APP_ID', fallback: '');

  static String get androidAppId => dotenv.get('FIREBASE_ANDROID_APP_ID', fallback: '');

  /// Returns true only if Firebase is fully configured
  static bool get isConfigured =>
      apiKey.isNotEmpty && messagingSenderId.isNotEmpty;
}

/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Haramain Pro';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  /// App debug mode — set via DEBUG=true in .env
  static bool get isDebug => dotenv.get('DEBUG', fallback: 'false') == 'true';
}

/// Xendit configuration (TIER23 — Umrah Mandiri payment)
class XenditConstants {
  XenditConstants._();

  /// Price: Rp 120,000 — Safety Pass lifetime
  static const int paymentAmount = 120000;

  static const String paymentDescription = 'Haramain Pro Safety Pass - Umrah Mandiri';

  /// Payment expiry in minutes (24 hours)
  static const int paymentExpiryMinutes = 1440;
}

/// Emergency contacts — loaded from .env
class EmergencyConstants {
  EmergencyConstants._();

  /// Comma-separated phone numbers
  /// Example: +628****6789,+628****4321
  static List<String> get contacts {
    final raw = dotenv.get(
      'EMERGENCY_CONTACTS',
      fallback: '+628****6789',
    );
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

/// Twilio configuration
class TwilioConstants {
  TwilioConstants._();

  static String get accountSid => dotenv.get('TWILIO_ACCOUNT_SID', fallback: '');
  static String get authToken => dotenv.get('TWILIO_AUTH_TOKEN', fallback: '');
  static String get phoneNumber => dotenv.get('TWILIO_PHONE_NUMBER', fallback: '');

  static bool get isConfigured => accountSid.isNotEmpty && authToken.isNotEmpty;
}

/// FCM configuration
class FcmConstants {
  FcmConstants._();

  static String get serverKey => dotenv.get('FCM_SERVER_KEY', fallback: '');
  static bool get isConfigured => serverKey.isNotEmpty;
}

/// AI Service configuration (Virtual Muthawif)
class AiConstants {
  AiConstants._();

  static String get apiKey => dotenv.get('AI_API_KEY', fallback: '');
  static String get endpoint => dotenv.get('AI_API_ENDPOINT', fallback: '');
  static bool get isConfigured => apiKey.isNotEmpty && endpoint.isNotEmpty;
}
