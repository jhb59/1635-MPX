import 'package:shared_preferences/shared_preferences.dart';
import 'spotify_service.dart';

class AuthService {
  final SpotifyService _spotifyService = SpotifyService();

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _spotifyService.getAccessToken();
    return token != null;
  }

  // Get user info
  Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await _spotifyService.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _spotifyService.getUserProfile();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
    await prefs.remove('spotify_token_expiry');
  }

  SpotifyService get spotifyService => _spotifyService;
}

