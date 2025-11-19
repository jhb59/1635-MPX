import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyService {
  // Spotify API credentials
  // Get these from https://developer.spotify.com/dashboard

  //THIS ARE MY KEYS lol create your own :)
  static const String clientId = 'bdcbe03f502b4870a4596d3598b2c59a';
  static const String clientSecret = '7d733a82ce1848d7a374cf7b901d2d06';

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
  static const String redirectUri = 'http://127.0.0.1:8080/callback';
  
  // TODO: Update the port above to match your actual Flutter web port
  // TODO: Also update the same URI in your Spotify Dashboard
  
  static const String authUrl = 'https://accounts.spotify.com/authorize';
  static const String tokenUrl = 'https://accounts.spotify.com/api/token';
  static const String apiBaseUrl = 'https://api.spotify.com/v1';

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('spotify_access_token');
    final expiryTime = prefs.getInt('spotify_token_expiry');
    
    if (token != null && expiryTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < expiryTime) {
        return token;
      }
    }
    
    return null;
  }

  // Save access token
  Future<void> saveAccessToken(String token, int expiresIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('spotify_access_token', token);
    final expiryTime = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
    await prefs.setInt('spotify_token_expiry', expiryTime);
  }

  // Authenticate with Spotify
  Future<void> authenticate() async {
    // Validate credentials are set
    if (clientId == 'YOUR_SPOTIFY_CLIENT_ID' || clientSecret == 'YOUR_SPOTIFY_CLIENT_SECRET') {
      throw Exception(
        'Spotify credentials not configured!\n\n'
        'Please:\n'
        '1. Go to https://developer.spotify.com/dashboard\n'
        '2. Create an app and get your Client ID and Client Secret\n'
        '3. Update lib/services/spotify_service.dart with your credentials\n'
        '4. Make sure the Redirect URI in your Spotify app matches: $redirectUri'
      );
    }
    
    final scopes = [
      'user-read-private',
      'user-read-email',
      'playlist-read-private',
      'playlist-modify-public',
      'playlist-modify-private',
      'user-library-read',
      'user-read-recently-played',
    ].join(' ');
    
    final authUri = Uri.parse(
      '$authUrl?client_id=$clientId&response_type=code&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=${Uri.encodeComponent(scopes)}'
    );
    
    if (await canLaunchUrl(authUri)) {
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open Spotify authentication URL');
    }
  }

  // Exchange authorization code for access token
  Future<bool> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await saveAccessToken(data['access_token'], data['expires_in']);
        return true;
      } else {
        // Parse error response
        final errorBody = response.body;
        print('Token exchange failed: ${response.statusCode}');
        print('Error response: $errorBody');
        
        String errorMessage = 'Failed to exchange code';
        try {
          final errorData = json.decode(errorBody);
          final error = errorData['error'] ?? 'unknown_error';
          final errorDescription = errorData['error_description'] ?? '';
          
          // Provide user-friendly error messages
          switch (error) {
            case 'invalid_grant':
              errorMessage = 'Invalid authorization code. This usually means:\n'
                  '• The code has expired (get a fresh one)\n'
                  '• The redirect URI doesn\'t match exactly\n'
                  '• The code was already used\n\n'
                  'Please try getting a new authorization code.';
              break;
            case 'invalid_client':
              errorMessage = 'Invalid client credentials. Please check:\n'
                  '• Client ID is correct\n'
                  '• Client Secret is correct\n'
                  '• Both are set in lib/services/spotify_service.dart';
              break;
            case 'invalid_request':
              errorMessage = 'Invalid request. Please check:\n'
                  '• Redirect URI matches exactly: $redirectUri\n'
                  '• Authorization code is correct\n'
                  '• Code hasn\'t expired';
              break;
            default:
              errorMessage = 'Error: $error\n$errorDescription';
          }
        } catch (e) {
          errorMessage = 'Failed to exchange code: ${response.statusCode}\n$errorBody';
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Token exchange error: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error exchanging code: $e');
    }
  }

  // Search for tracks by mood
  Future<List<Map<String, dynamic>>> searchTracksByMood(String mood) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify');
    }

    // Map moods to search terms
    final moodMap = {
      'MELLOW': 'chill ambient relaxing',
      'UPBEAT': 'happy energetic upbeat',
      'SAD': 'sad melancholic emotional',
    };

    final searchQuery = moodMap[mood] ?? mood.toLowerCase();
    
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/search?q=${Uri.encodeComponent(searchQuery)}&type=track&limit=20'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = (data['tracks']['items'] as List)
            .map((track) => {
                  'id': track['id'],
                  'name': track['name'],
                  'artist': track['artists'][0]['name'],
                  'album': track['album']['name'],
                  'preview_url': track['preview_url'],
                  'external_url': track['external_urls']['spotify'],
                })
            .toList();
        return tracks;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create a playlist
  Future<String?> createPlaylist(String name, String description, List<String> trackUris) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify');
    }

    try {
      // Get current user ID
      final userResponse = await http.get(
        Uri.parse('$apiBaseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode != 200) {
        return null;
      }

      final userData = json.decode(userResponse.body);
      final userId = userData['id'];

      // Create playlist
      final createResponse = await http.post(
        Uri.parse('$apiBaseUrl/users/$userId/playlists'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'public': false,
        }),
      );

      if (createResponse.statusCode == 201) {
        final playlistData = json.decode(createResponse.body);
        final playlistId = playlistData['id'];

        // Add tracks to playlist
        if (trackUris.isNotEmpty) {
          await http.post(
            Uri.parse('$apiBaseUrl/playlists/$playlistId/tracks'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'uris': trackUris,
            }),
          );
        }

        return playlistData['external_urls']['spotify'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user profile - Get Current User's Profile endpoint
  // Similar to: GET https://api.spotify.com/v1/me
  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify. Please login first.');
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        throw Exception('Authentication expired. Please login again.');
      } else {
        throw Exception('Failed to get user profile: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error fetching user profile: $e');
    }
  }

  // Get track information - Get a track endpoint
  // Similar to: GET https://api.spotify.com/v1/tracks/{id}
  Future<Map<String, dynamic>?> getTrack(String trackId) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify. Please login first.');
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/tracks/$trackId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Track not found.');
      } else {
        throw Exception('Failed to get track: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error fetching track: $e');
    }
  }

  // Generate mood-balancing playlist
  Future<String?> generateMoodPlaylist(String mood) async {
    final tracks = await searchTracksByMood(mood);
    if (tracks.isEmpty) {
      return null;
    }

    final trackUris = tracks.map((track) => 'spotify:track:${track['id']}').toList();
    final playlistName = '$mood Mood-Balancing Playlist';
    final description = 'A curated playlist to help balance your $mood mood';

    return await createPlaylist(playlistName, description, trackUris);
  }

  // Get recently played tracks
  // GET https://api.spotify.com/v1/me/player/recently-played
  Future<List<Map<String, dynamic>>> getRecentlyPlayedTracks({int limit = 50}) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify. Please login first.');
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/me/player/recently-played?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['items'] as List? ?? []);
        return items.map((item) {
          final track = item['track'] ?? {};
          return {
            'id': track['id'],
            'name': track['name'],
            'artist': track['artists'] != null && (track['artists'] as List).isNotEmpty
                ? track['artists'][0]['name']
                : 'Unknown',
            'album': track['album']?['name'] ?? 'Unknown',
            'played_at': item['played_at'],
          };
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired. Please login again.');
      } else {
        throw Exception('Failed to get recently played tracks: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error fetching recently played tracks: $e');
    }
  }

  // Get audio features for multiple tracks
  // GET https://api.spotify.com/v1/audio-features?ids=...
  Future<List<Map<String, dynamic>>> getAudioFeatures(List<String> trackIds) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify. Please login first.');
    }

    if (trackIds.isEmpty) {
      return [];
    }

    try {
      // Spotify API allows up to 100 track IDs per request
      final ids = trackIds.take(100).join(',');
      final response = await http.get(
        Uri.parse('$apiBaseUrl/audio-features?ids=$ids'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['audio_features'] as List? ?? [])
            .where((features) => features != null)
            .map((features) => features as Map<String, dynamic>)
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired. Please login again.');
      } else {
        throw Exception('Failed to get audio features: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error fetching audio features: $e');
    }
  }

  // Analyze audio features to determine mood
  // Returns: 'UPBEAT', 'MELLOW', or 'SAD'
  String _determineMoodFromFeatures(List<Map<String, dynamic>> audioFeatures) {
    if (audioFeatures.isEmpty) {
      return 'MELLOW'; // Default mood
    }

    // Calculate averages
    double avgEnergy = 0;
    double avgValence = 0;
    double avgDanceability = 0;
    int validFeatures = 0;

    for (final features in audioFeatures) {
      final energy = features['energy'] as double? ?? 0.5;
      final valence = features['valence'] as double? ?? 0.5; // Positivity/happiness
      final danceability = features['danceability'] as double? ?? 0.5;

      avgEnergy += energy;
      avgValence += valence;
      avgDanceability += danceability;
      validFeatures++;
    }

    if (validFeatures == 0) {
      return 'MELLOW';
    }

    avgEnergy /= validFeatures;
    avgValence /= validFeatures;
    avgDanceability /= validFeatures;

    // Mood determination logic:
    // - UPBEAT: High energy, high valence, high danceability
    // - SAD: Low valence (sadness), low energy
    // - MELLOW: Medium values, or low energy but not sad
    if (avgValence > 0.6 && avgEnergy > 0.6 && avgDanceability > 0.6) {
      return 'UPBEAT';
    } else if (avgValence < 0.4 && avgEnergy < 0.5) {
      return 'SAD';
    } else {
      return 'MELLOW';
    }
  }

  // Get current mood based on recently played tracks
  Future<String> getCurrentMood() async {
    try {
      // Get recently played tracks (last 20 tracks)
      final recentTracks = await getRecentlyPlayedTracks(limit: 20);
      
      if (recentTracks.isEmpty) {
        return 'MELLOW'; // Default if no listening history
      }

      // Get track IDs
      final trackIds = recentTracks
          .where((track) => track['id'] != null)
          .map((track) => track['id'] as String)
          .toList();

      if (trackIds.isEmpty) {
        return 'MELLOW';
      }

      // Get audio features
      final audioFeatures = await getAudioFeatures(trackIds);
      
      // Determine mood
      return _determineMoodFromFeatures(audioFeatures);
    } catch (e) {
      // If there's an error, return default mood
      print('Error determining mood: $e');
      return 'MELLOW';
    }
  }

  // Get mood for different time periods
  Future<Map<String, String>> getMoodAnalysis() async {
    try {
      // Get more tracks for analysis (last 50)
      final recentTracks = await getRecentlyPlayedTracks(limit: 50);
      
      if (recentTracks.isEmpty) {
        return {
          'current': 'MELLOW',
          'morning': 'MELLOW',
          'forecast': 'MELLOW',
        };
      }

      // Get track IDs
      final trackIds = recentTracks
          .where((track) => track['id'] != null)
          .map((track) => track['id'] as String)
          .toList();

      if (trackIds.isEmpty) {
        return {
          'current': 'MELLOW',
          'morning': 'MELLOW',
          'forecast': 'MELLOW',
        };
      }

      // Get audio features
      final audioFeatures = await getAudioFeatures(trackIds);
      
      // Current mood: based on most recent tracks (last 10)
      final recentFeatures = audioFeatures.take(10).toList();
      final currentMood = _determineMoodFromFeatures(recentFeatures);

      // Morning mood: based on tracks from earlier today (if available)
      // For now, use a subset of tracks
      final morningFeatures = audioFeatures.length > 20 
          ? audioFeatures.sublist(20, audioFeatures.length > 30 ? 30 : audioFeatures.length)
          : audioFeatures.take(5).toList();
      final morningMood = _determineMoodFromFeatures(morningFeatures);

      // Forecast: based on overall trend
      final forecastMood = _determineMoodFromFeatures(audioFeatures);

      return {
        'current': currentMood,
        'morning': morningMood,
        'forecast': forecastMood,
      };
    } catch (e) {
      print('Error analyzing mood: $e');
      return {
        'current': 'MELLOW',
        'morning': 'MELLOW',
        'forecast': 'MELLOW',
      };
    }
  }

  // Get song recommendations based on recently played tracks
  // GET https://api.spotify.com/v1/recommendations
  Future<List<Map<String, dynamic>>> getSongRecommendations({int limit = 20}) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify. Please login first.');
    }

    try {
      // Get recently played tracks to use as seed
      final recentTracks = await getRecentlyPlayedTracks(limit: 5);
      
      if (recentTracks.isEmpty) {
        // If no recent tracks, use default recommendations
        return await _getDefaultRecommendations(token, limit);
      }

      // Get seed track IDs (Spotify allows up to 5 seed tracks)
      final seedTracks = recentTracks
          .take(5)
          .where((track) => track['id'] != null)
          .map((track) => track['id'] as String)
          .toList();

      if (seedTracks.isEmpty) {
        return await _getDefaultRecommendations(token, limit);
      }

      // Get audio features to determine target values
      final audioFeatures = await getAudioFeatures(seedTracks);
      if (audioFeatures.isEmpty) {
        return await _getDefaultRecommendations(token, limit);
      }

      // Calculate average audio features
      double avgEnergy = 0;
      double avgValence = 0;
      double avgDanceability = 0;
      int validFeatures = 0;

      for (final features in audioFeatures) {
        avgEnergy += features['energy'] as double? ?? 0.5;
        avgValence += features['valence'] as double? ?? 0.5;
        avgDanceability += features['danceability'] as double? ?? 0.5;
        validFeatures++;
      }

      if (validFeatures > 0) {
        avgEnergy /= validFeatures;
        avgValence /= validFeatures;
        avgDanceability /= validFeatures;
      }

      // Build recommendations query
      final seedTracksParam = seedTracks.join(',');
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/recommendations?'
          'seed_tracks=$seedTracksParam&'
          'limit=$limit&'
          'target_energy=${avgEnergy.toStringAsFixed(2)}&'
          'target_valence=${avgValence.toStringAsFixed(2)}&'
          'target_danceability=${avgDanceability.toStringAsFixed(2)}'
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = (data['tracks'] as List? ?? []);
        return tracks.map((track) {
          return {
            'id': track['id'],
            'name': track['name'],
            'artist': track['artists'] != null && (track['artists'] as List).isNotEmpty
                ? track['artists'][0]['name']
                : 'Unknown',
            'album': track['album']?['name'] ?? 'Unknown',
            'preview_url': track['preview_url'],
            'external_url': track['external_urls']?['spotify'],
            'image_url': track['album']?['images'] != null && 
                        (track['album']?['images'] as List).isNotEmpty
                ? (track['album']?['images'] as List)[0]['url']
                : null,
          };
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired. Please login again.');
      } else {
        return await _getDefaultRecommendations(token, limit);
      }
    } catch (e) {
      print('Error getting recommendations: $e');
      // Fallback to default recommendations
      final token = await getAccessToken();
      if (token != null) {
        return await _getDefaultRecommendations(token, limit);
      }
      return [];
    }
  }

  // Get default recommendations when no listening history
  Future<List<Map<String, dynamic>>> _getDefaultRecommendations(String token, int limit) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/recommendations?'
          'seed_genres=pop,indie,alternative&'
          'limit=$limit'
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = (data['tracks'] as List? ?? []);
        return tracks.map((track) {
          return {
            'id': track['id'],
            'name': track['name'],
            'artist': track['artists'] != null && (track['artists'] as List).isNotEmpty
                ? track['artists'][0]['name']
                : 'Unknown',
            'album': track['album']?['name'] ?? 'Unknown',
            'preview_url': track['preview_url'],
            'external_url': track['external_urls']?['spotify'],
            'image_url': track['album']?['images'] != null && 
                        (track['album']?['images'] as List).isNotEmpty
                ? (track['album']?['images'] as List)[0]['url']
                : null,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get user's playlists
  // GET https://api.spotify.com/v1/me/playlists
  Future<List<Map<String, dynamic>>> getUserPlaylists({int limit = 20}) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify. Please login first.');
    }

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/me/playlists?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlists = (data['items'] as List? ?? []);
        return playlists.map((playlist) {
          return {
            'id': playlist['id'],
            'name': playlist['name'],
            'description': playlist['description'] ?? '',
            'image_url': playlist['images'] != null && 
                        (playlist['images'] as List).isNotEmpty
                ? (playlist['images'] as List)[0]['url']
                : null,
            'external_url': playlist['external_urls']?['spotify'],
            'tracks_count': playlist['tracks']?['total'] ?? 0,
            'owner': playlist['owner']?['display_name'] ?? 'Unknown',
          };
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired. Please login again.');
      } else {
        throw Exception('Failed to get playlists: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error fetching playlists: $e');
    }
  }

  // Get detailed emotional forecast with weekly breakdown
  Future<Map<String, dynamic>> getDetailedEmotionalForecast() async {
    try {
      final moodAnalysis = await getMoodAnalysis();
      final recentTracks = await getRecentlyPlayedTracks(limit: 50);
      
      // Create weekly forecast based on listening patterns
      final weeklyForecast = <Map<String, String>>[];
      if (recentTracks.isNotEmpty) {
        // Group tracks by approximate time periods and analyze
        final chunkSize = (recentTracks.length / 7).ceil();
        for (int i = 0; i < 7 && i * chunkSize < recentTracks.length; i++) {
          final startIdx = i * chunkSize;
          final endIdx = (startIdx + chunkSize < recentTracks.length) 
              ? startIdx + chunkSize 
              : recentTracks.length;
          final chunk = recentTracks.sublist(startIdx, endIdx);
          
          final trackIds = chunk
              .where((track) => track['id'] != null)
              .map((track) => track['id'] as String)
              .toList();
          
          if (trackIds.isNotEmpty) {
            final features = await getAudioFeatures(trackIds);
            final mood = _determineMoodFromFeatures(features);
            
            final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
            weeklyForecast.add({
              'day': days[i % 7],
              'mood': mood,
            });
          }
        }
      }

      // Fill remaining days with forecast mood if needed
      final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      while (weeklyForecast.length < 7) {
        final dayIndex = weeklyForecast.length;
        weeklyForecast.add({
          'day': days[dayIndex % 7],
          'mood': moodAnalysis['forecast'] ?? 'MELLOW',
        });
      }

      return {
        'overall_mood': moodAnalysis['forecast'] ?? 'MELLOW',
        'current_mood': moodAnalysis['current'] ?? 'MELLOW',
        'morning_mood': moodAnalysis['morning'] ?? 'MELLOW',
        'weekly_forecast': weeklyForecast,
        'total_tracks_analyzed': recentTracks.length,
      };
    } catch (e) {
      print('Error getting detailed forecast: $e');
      return {
        'overall_mood': 'MELLOW',
        'current_mood': 'MELLOW',
        'morning_mood': 'MELLOW',
        'weekly_forecast': [
          {'day': 'MON', 'mood': 'MELLOW'},
          {'day': 'TUE', 'mood': 'MELLOW'},
          {'day': 'WED', 'mood': 'MELLOW'},
          {'day': 'THU', 'mood': 'MELLOW'},
        ],
        'total_tracks_analyzed': 0,
      };
    }
  }
}

