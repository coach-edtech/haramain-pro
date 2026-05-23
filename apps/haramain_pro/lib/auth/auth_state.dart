import 'package:flutter/material.dart';

/// Authentication state enum
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

/// Authentication state class
class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.email,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, userId: $userId, email: $email, error: $error)';
  }
}

/// Auth StateNotifier for state management
class AuthStateNotifier extends ChangeNotifier {
  AuthState _state = const AuthState();
  AuthState get state => _state;

  void setAuthenticated({required String userId, String? email}) {
    _state = AuthState(
      status: AuthStatus.authenticated,
      userId: userId,
      email: email,
    );
    notifyListeners();
  }

  void setUnauthenticated() {
    _state = const AuthState(status: AuthStatus.unauthenticated);
    notifyListeners();
  }

  void setUnknown() {
    _state = const AuthState(status: AuthStatus.unknown);
    notifyListeners();
  }

  void setError(String error) {
    _state = _state.copyWith(status: AuthStatus.unauthenticated, error: error);
    notifyListeners();
  }
}
