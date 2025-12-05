import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  /// Start the Spotify login flow
  Future<void> login() async {
    await _auth.startLogin();
  }

  /// Handle redirect callback after Spotify login
  Future<void> handleCallback(String code) async {
    await _auth.handleCallback(code);
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Check whether the stored token is still valid
  Future<bool> checkStatus() async {
    final ok = await _auth.isAuthenticated();
    _isAuthenticated = ok;
    notifyListeners();
    return ok;
  }

  /// Log out and remove stored tokens
  Future<void> logout() async {
    await _auth.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Optional: fetch the user's Spotify profile
  Future<Map<String, dynamic>?> getUserInfo() async {
    return await _auth.getUserInfo();
  }
}
