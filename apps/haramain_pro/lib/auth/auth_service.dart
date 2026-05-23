import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal();

  GoTrueClient get _authClient => Supabase.instance.client.auth;

  Session? get currentSession => _authClient.currentSession;

  User? get currentUser => _authClient.currentUser;

  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get onAuthStateChange => _authClient.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _authClient.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _authClient.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _authClient.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authClient.resetPasswordForEmail(email);
  }

  Future<User?> updateUserMetadata(Map<String, dynamic> data) async {
    final response = await _authClient.updateUser(
      UserAttributes(data: data),
    );
    return response.user;
  }
}
