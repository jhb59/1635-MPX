import 'package:shared_preferences/shared_preferences.dart';
import 'spotify_service.dart';

class AuthService {
  final SpotifyService spotify = SpotifyService();

  // Start Spotify OAuth (opens login page)
  Future<void> startLogin() async {
    await spotify.authenticate();
  }

  // Handle the authorization code returned after redirect
  Future<void> handleCallback(String code) async {
    await spotify.exchangeCodeForToken(code);
  }

  // Return true if we have a valid access token
  Future<bool> isAuthenticated() async {
    final token = await spotify.getAccessToken();
    return token != null;
  }

  // Get the logged-in user's Spotify profile
  Future<Map<String, dynamic>?> getUserInfo() async {
    return await spotify.getUserProfile();
  }

  // Clear all tokens
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
    await prefs.remove("expires_at");
  }
}
