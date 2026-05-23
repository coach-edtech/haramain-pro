import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper around Supabase for type-safe access
class SupabaseClientWrapper {
  static final SupabaseClientWrapper _instance = SupabaseClientWrapper._internal();
  static SupabaseClientWrapper get instance => _instance;

  SupabaseClientWrapper._internal();

  /// The underlying SupabaseClient
  SupabaseClient get client => Supabase.instance.client;

  /// Get auth
  GoTrueClient get auth => client.auth as GoTrueClient;

  /// Initialize Supabase client
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  /// Get current session
  Session? get currentSession => client.auth.currentSession;

  /// Get current user
  User? get currentUser => client.auth.currentUser;
}
