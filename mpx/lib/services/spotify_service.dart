import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyService {
  // Spotify API credentials
  // Get these from https://developer.spotify.com/dashboard

  //THIS ARE MY KEYS lol create your own :)
  // static const String clientId = 'bdcbe03f502b4870a4596d3598b2c59a';
  // static const String clientSecret = '7d733a82ce1848d7a374cf7b901d2d06';

  static const String clientId = '0b3e4123d27f445ea87bd7636f48c3db';
  static const String clientSecret = '854da81104eb4e8296fd535f1fcf0fca';

  // static const String clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  // static const String clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';

  // Redirect URI - MUST match exactly what's in your Spotify Dashboard
  // 
  // IMPORTANT: Spotify requirements:
  // - Use http://127.0.0.1:PORT (NOT localhost)
  // - Must match EXACTLY what's in your Spotify Dashboard
  //
  // To find your Flutter web port:
  // 1. Look at the terminal when you run `flutter run -d chrome`
  // 2. It will show: "Running on http://localhost:XXXXX" 
  // 3. Replace localhost with 127.0.0.1 and use that port
  // 4. Update BOTH this code AND your Spotify Dashboard
  //
  // Example: If Flutter shows "http://localhost:54321", use "http://127.0.0.1:54321/callback"
  // static const String redirectUri = 'http://127.0.0.1:49374/callback';

  //dyanmic redirect port (doesnt work rn....)
  // static String get redirectUri {
  //   if (kIsWeb) {
  //     // EXAMPLE: http://127.0.0.1:59621 or http://localhost:59621
  //     final origin = Uri.base.origin;
  //     return "$origin/callback";
  //   }
  //   // For iOS/Android
  //   return "mpx://callback";
  // }

  // static const String redirectUri = 'https://music-vibe-718b5.web.app/callback'; //uncomment when you are ready to deploy to firebase
// Localhost for testing / Firebase for production
  static const String redirectUri = kIsWeb
      ? "https://music-vibe-718b5.web.app/callback"
      : "http://127.0.0.1:49374/callback";

  static const String authUrl = "https://accounts.spotify.com/authorize";
  static const String tokenUrl = "https://accounts.spotify.com/api/token";
  static const String apiBase = "https://api.spotify.com/v1";

  // ---------------------------------------------------------
  // Authentication URL
  // ---------------------------------------------------------

  Future<void> authenticate() async {
    final scopes = [
      "user-read-private",
      "user-read-email",
      "playlist-read-private",
      "playlist-modify-public",
      "playlist-modify-private",
      "user-library-read",
      "user-read-recently-played",
      "user-top-read",
      "user-read-playback-position",
    ].join(" ");

    final url = Uri.parse(
      "$authUrl?"
      "client_id=$clientId"
      "&response_type=code"
      "&redirect_uri=${Uri.encodeComponent(redirectUri)}"
      "&scope=${Uri.encodeComponent(scopes)}",
    );

    // Open in same browser tab on web
    if (kIsWeb) {
      await launchUrl(url, webOnlyWindowName: "_self");
      return;
    }

    // Mobile
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Could not launch Spotify login");
    }
  }

  // ---------------------------------------------------------
  //  EXCHANGE AUTH CODE FOR TOKENS
  // ---------------------------------------------------------
  Future<void> exchangeCodeForToken(String code) async {
    final creds = base64Encode(utf8.encode("$clientId:$clientSecret"));

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        "Authorization": "Basic $creds",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirectUri,
      },
    );

    if (response.statusCode != 200) {
      debugPrint("TOKEN ERROR: ${response.body}");
      throw Exception("Failed to exchange Spotify code.");
    }

    final json = jsonDecode(response.body);

    await _saveTokens(
      access: json["access_token"],
      refresh: json["refresh_token"],
      expiresIn: json["expires_in"],
    );
  }

  // ---------------------------------------------------------
  // REFRESH TOKEN
  // ---------------------------------------------------------
  Future<String?> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString("refresh_token");
    if (refreshToken == null) return null;

    final creds = base64Encode(utf8.encode("$clientId:$clientSecret"));

    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        "Authorization": "Basic $creds",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "grant_type": "refresh_token",
        "refresh_token": refreshToken,
      },
    );

    if (response.statusCode != 200) {
      debugPrint("REFRESH FAILED: ${response.body}");
      return null;
    }

    final json = jsonDecode(response.body);

    await _saveTokens(
      access: json["access_token"],
      refresh: json["refresh_token"] ?? refreshToken,
      expiresIn: json["expires_in"],
    );

    return json["access_token"];
  }

  // ---------------------------------------------------------
  // GET ACCESS TOKEN (auto-refresh if expired)
  // ---------------------------------------------------------
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");
    final expiresAt = prefs.getInt("expires_at");

    if (token == null || expiresAt == null) return null;

    // Still valid?
    if (DateTime.now().millisecondsSinceEpoch < expiresAt) {
      return token;
    }

    // Token expired → refresh
    return await refreshAccessToken();
  }

  // ---------------------------------------------------------
  // SAVE TOKENS
  // ---------------------------------------------------------
  Future<void> _saveTokens({
    required String access,
    required String refresh,
    required int expiresIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiry = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;

    await prefs.setString("access_token", access);
    await prefs.setString("refresh_token", refresh);
    await prefs.setInt("expires_at", expiry);
  }

  // ---------------------------------------------------------
  // API: Get User Profile
  // ---------------------------------------------------------
  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$apiBase/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // ---------------------------------------------------------
  // API: Recently Played Tracks
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getRecentlyPlayedTracks({int limit = 10}) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$apiBase/me/player/recently-played?limit=$limit"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body);
    final items = json["items"] as List;

    return items.map<Map<String, dynamic>>((item) {
      final track = item["track"];
      return {
        "name": track["name"],
        "artist": track["artists"][0]["name"],
        "image_url": track["album"]["images"].isNotEmpty
            ? track["album"]["images"][0]["url"]
            : "",
        "external_url": track["external_urls"]["spotify"],
      };
    }).toList();
  }

  // ---------------------------------------------------------
  // API: Playlists
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getUserPlaylists({int limit = 10}) async {
    final token = await getAccessToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$apiBase/me/playlists?limit=$limit"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body);
    final items = json["items"] as List;

    return items.map<Map<String, dynamic>>((p) {
      return {
        "name": p["name"],
        "tracks_count": p["tracks"]["total"],
        "image_url":
            p["images"].isNotEmpty ? p["images"][0]["url"] : null,
        "external_url": p["external_urls"]["spotify"],
      };
    }).toList();
  }

  // ---------------------------------------------------------
  // API: Emotional Forecast (custom)
  // ---------------------------------------------------------
  Future<Map<String, dynamic>> getDetailedEmotionalForecast() async {
    // Placeholder — customize however you compute mood
    return {
      "overall_mood": "EMPTY",
      "weekly_forecast": [
        {"day": "Mon", "mood": "EMPTY"},
        {"day": "Tue", "mood": "EMPTY"},
        {"day": "Wed", "mood": "EMPTY"},
        {"day": "Thu", "mood": "EMPTY"},
        {"day": "Fri", "mood": "EMPTY"},
      ],
      "total_tracks_analyzed": 0,
    };
  }
}