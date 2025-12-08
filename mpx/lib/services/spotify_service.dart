import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyService {
//Client ID and Client Secret for Spotify API

//REPLACE HERE WITH YOUR OWN KEYS
static const String clientId = 'YOUR_SPOTIFY_CLIENT_ID';
static const String clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';

//REDIRECT URLS (SHOULD BE IN YOUR SPOTIFY API AS WELL)
static const String redirectUri = kIsWeb
  ? "https://music-vibe-718b5.web.app/callback"
  : "http://127.0.0.1:49374/callback";

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
    'user-top-read',
  ].join(' ');

  final authUri = Uri.parse(
    '$authUrl?client_id=$clientId&response_type=code&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=${Uri.encodeComponent(scopes)}'
  );

  // On web, use platformDefault to open in same window/tab
  // On mobile, use externalApplication to open in browser
  if (kIsWeb) {
    // For web, open in the same window
    await launchUrl(authUri, mode: LaunchMode.platformDefault);
  } else {
    if (await canLaunchUrl(authUri)) {
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open Spotify authentication URL');
    }
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

    print('Recently played tracks API response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = (data['items'] as List? ?? []);
      print('Found ${items.length} recently played tracks');

      if (items.isEmpty) {
        print('No recently played tracks found');
        return [];
      }

      return items.map((item) {
        final track = item['track'] ?? {};
        final artists = track['artists'] as List? ?? [];
        final album = track['album'] as Map<String, dynamic>?;
        final images = album?['images'] as List? ?? [];

        return {
          'id': track['id'],
          'name': track['name'],
          'artist': artists.isNotEmpty ? artists[0]['name'] : 'Unknown',
          'artist_id': artists.isNotEmpty ? artists[0]['id'] : null,

          //REQUIRED FOR UI
          'image_url': images.isNotEmpty
              ? images[0]['url']?.toString().replaceFirst('http://', 'https://')
              : null,

          //REQUIRED FOR CLICK
          'external_url': track['external_urls']?['spotify'],

          'album': album?['name'] ?? 'Unknown',
          'played_at': item['played_at'],
        };
      }).toList();

    } else if (response.statusCode == 401) {
      print('Authentication expired for recently played tracks');
      throw Exception('Authentication expired. Please login again.');
    } else {
      print('Failed to get recently played tracks: ${response.statusCode} - ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error fetching recently played tracks: $e');
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
    // Filter out null/empty IDs
    final validIds = trackIds.where((id) => id != null && id.isNotEmpty).take(100).toList();

    if (validIds.isEmpty) {
      print('No valid track IDs for audio features');
      return [];
    }

    final ids = validIds.join(',');
    print('Getting audio features for ${validIds.length} tracks');

    final response = await http.get(
      Uri.parse('$apiBaseUrl/audio-features?ids=$ids'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Audio features API response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = (data['audio_features'] as List? ?? [])
          .where((features) => features != null)
          .map((features) => features as Map<String, dynamic>)
          .toList();
      print('Retrieved ${features.length} audio features');
      return features;
    } else if (response.statusCode == 401) {
      throw Exception('Authentication expired. Please login again.');
    } else if (response.statusCode == 403) {
      print('403 Forbidden - Audio features endpoint may require different permissions');
      print('Response body: ${response.body}');
      // Return empty list instead of throwing - allow app to continue with genre-based analysis
      return [];
    } else {
      print('Audio features error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to get audio features: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching audio features: $e');
    // Return empty list to allow genre-based fallback
    return [];
  }
}

  // Get artist genres
  // GET https://api.spotify.com/v1/artists?ids=...
  Future<List<String>> getArtistGenres(List<String> artistIds) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated with Spotify. Please login first.');
    }

    if (artistIds.isEmpty) {
      return [];
    }

    try {
      // Spotify API allows up to 50 artist IDs per request
      final ids = artistIds.take(50).where((id) => id != null).join(',');
      if (ids.isEmpty) {
        return [];
}

      final response = await http.get(
        Uri.parse('$apiBaseUrl/artists?ids=$ids'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final artists = (data['artists'] as List? ?? []);
        final allGenres = <String>[];
        for (final artist in artists) {
          final genres = (artist['genres'] as List? ?? [])
              .map((g) => g.toString().toLowerCase())
              .toList();
          allGenres.addAll(genres);
        }
        return allGenres.toSet().toList(); // Remove duplicates
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired. Please login again.');
      } else {
        print('Failed to get artist genres: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching artist genres: $e');
      return [];
    }
  }

  // Map genres to moods
  String _genreToMood(String genre) {
    final genreLower = genre.toLowerCase();
    
    // UPBEAT genres
    if (genreLower.contains('pop') || 
        genreLower.contains('dance') || 
        genreLower.contains('electronic') ||
        genreLower.contains('house') ||
        genreLower.contains('edm') ||
        genreLower.contains('disco') ||
        genreLower.contains('funk') ||
        genreLower.contains('reggaeton') ||
        genreLower.contains('hip-hop') ||
        genreLower.contains('rap')) {
      return 'UPBEAT';
    }
    
    // SAD genres
    if (genreLower.contains('blues') || 
        genreLower.contains('sad') ||
        genreLower.contains('emo') ||
        genreLower.contains('goth') ||
        genreLower.contains('dark') ||
        genreLower.contains('melancholic')) {
      return 'SAD';
    }
    
    // MELLOW genres (default)
    if (genreLower.contains('ambient') || 
        genreLower.contains('chill') ||
        genreLower.contains('acoustic') ||
        genreLower.contains('folk') ||
        genreLower.contains('indie') ||
        genreLower.contains('jazz') ||
        genreLower.contains('lounge') ||
        genreLower.contains('meditation') ||
        genreLower.contains('sleep')) {
      return 'MELLOW';
}
    
    // Default to MELLOW 
    return 'MELLOW';
}

  // Analyze audio features and genres to determine mood
  // Returns: 'UPBEAT', 'MELLOW', or 'SAD'
  String _determineMoodFromFeatures(List<Map<String, dynamic>> audioFeatures, {List<String> genres = const []}) {
    // Count mood votes from genres
    int upbeatVotes = 0;
    int sadVotes = 0;
    int mellowVotes = 0;

    for (final genre in genres) {
      final mood = _genreToMood(genre);
      if (mood == 'UPBEAT') upbeatVotes++;
      else if (mood == 'SAD') sadVotes++;
      else mellowVotes++;
    }

    if (audioFeatures.isEmpty) {
      // If no audio features, use genre-based determination
      if (genres.isEmpty) {
        return 'MELLOW'; // Default mood
      }
      // Return mood with most votes, defaulting to MELLOW on tie
      if (upbeatVotes > sadVotes && upbeatVotes > mellowVotes) {
        return 'UPBEAT';
      } else if (sadVotes > upbeatVotes && sadVotes > mellowVotes) {
        return 'SAD';
      }
      return 'MELLOW';
    }

    // Calculate averages from audio features
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
      // Fallback to genre-based if no valid features
      if (upbeatVotes > sadVotes && upbeatVotes > mellowVotes) {
        return 'UPBEAT';
      } else if (sadVotes > upbeatVotes && sadVotes > mellowVotes) {
        return 'SAD';
      }
      return 'MELLOW';
    }

    avgEnergy /= validFeatures;
    avgValence /= validFeatures;
    avgDanceability /= validFeatures;

    // Mood determination from audio features:
    // - UPBEAT: High energy, high valence, high danceability
    // - SAD: Low valence (sadness), low energy
    // - MELLOW: Medium values, or low energy but not sad
    String featureBasedMood = 'MELLOW';
    if (avgValence > 0.6 && avgEnergy > 0.6 && avgDanceability > 0.6) {
      featureBasedMood = 'UPBEAT';
    } else if (avgValence < 0.4 && avgEnergy < 0.5) {
      featureBasedMood = 'SAD';
    }

    // Combine genre and feature-based moods
    // If genres are available, give them some weight
    if (genres.isNotEmpty) {
      final totalGenreVotes = upbeatVotes + sadVotes + mellowVotes;
      if (totalGenreVotes > 0) {
        // If genre votes are strong (more than 2 votes for a mood), use genre
        if (upbeatVotes >= 3 && upbeatVotes > sadVotes && upbeatVotes > mellowVotes) {
          return 'UPBEAT';
        } else if (sadVotes >= 3 && sadVotes > upbeatVotes && sadVotes > mellowVotes) {
          return 'SAD';
        }
        // Otherwise, use feature-based mood but genre can influence
        if (featureBasedMood == 'MELLOW' && upbeatVotes > sadVotes && upbeatVotes > 0) {
          return 'UPBEAT';
        } else if (featureBasedMood == 'MELLOW' && sadVotes > upbeatVotes && sadVotes > 0) {
          return 'SAD';
        }
      }
    }

    return featureBasedMood;
  }

// Get current mood based on recently played tracks
Future<String> getCurrentMood() async {
  try {
    // Get recently played tracks (last 20 tracks)
    final recentTracks = await getRecentlyPlayedTracks(limit: 20);

    if (recentTracks.isEmpty) {
      print('No recent tracks found, defaulting to UNREADABLE');
      return 'UNREADABLE'; // Default if no listening history
    }

    // Get track IDs and artist IDs
    final trackIds = recentTracks
        .where((track) => track['id'] != null)
        .map((track) => track['id'] as String)
        .toList();

    final artistIds = recentTracks
        .where((track) => track['artist_id'] != null)
        .map((track) => track['artist_id'] as String)
        .toList();

    if (trackIds.isEmpty) {
      print('No valid track IDs found, defaulting to UNREADABLE');
      return 'UNREADABLE';
    }

    // Get audio features and genres in parallel
    final results = await Future.wait([
      getAudioFeatures(trackIds),
      artistIds.isNotEmpty ? getArtistGenres(artistIds) : Future.value(<String>[]),
    ]);

    final audioFeatures = results[0] as List<Map<String, dynamic>>;
    final genres = results[1] as List<String>;

    print('Analyzing mood: ${audioFeatures.length} tracks, ${genres.length} genres');

    // Determine mood
    final mood = _determineMoodFromFeatures(audioFeatures, genres: genres);
    print('Determined mood: $mood');
    return mood;
  } catch (e) {
    // If there's an error
    print('Error determining mood: $e');
    return 'UNREADABLE';
  }
}

// Get mood for different time periods
Future<Map<String, String>> getMoodAnalysis() async {
  try {
    // Get more tracks for analysis (last 50)
    final recentTracks = await getRecentlyPlayedTracks(limit: 50);

    if (recentTracks.isEmpty) {
      print('No tracks for mood analysis, defaulting to UNREADABLE');
      return {
        'current': 'UNREADABLE',
        'morning': 'UNREADABLE',
        'forecast': 'UNREADABLE',
      };
    }

    // Get track IDs and artist IDs
    final trackIds = recentTracks
        .where((track) => track['id'] != null)
        .map((track) => track['id'] as String)
        .toList();

    final artistIds = recentTracks
        .where((track) => track['artist_id'] != null)
        .map((track) => track['artist_id'] as String)
        .toList();

    if (trackIds.isEmpty) {
      print('No valid track IDs for mood analysis, defaulting to UNREADABLE');
      return {
        'current': 'UNREADABLE',
        'morning': 'UNREADABLE',
        'forecast': 'UNREADABLE',
      };
    }

    // Get audio features and genres in parallel
    final results = await Future.wait([
      getAudioFeatures(trackIds),
      artistIds.isNotEmpty ? getArtistGenres(artistIds) : Future.value(<String>[]),
    ]);

    final audioFeatures = results[0] as List<Map<String, dynamic>>;
    final allGenres = results[1] as List<String>;

    print('Mood analysis: ${audioFeatures.length} tracks, ${allGenres.length} genres');

    // Current mood: based on most recent tracks (last 10)
    final recentFeatures = audioFeatures.take(10).toList();
    final recentArtistIds = recentTracks.take(10)
        .where((track) => track['artist_id'] != null)
        .map((track) => track['artist_id'] as String)
        .toList();
    final recentGenres = recentArtistIds.isNotEmpty
        ? await getArtistGenres(recentArtistIds)
        : <String>[];
    final currentMood = _determineMoodFromFeatures(recentFeatures, genres: recentGenres);

    // Morning mood: based on tracks from earlier today (if available)
    // For now, use a subset of tracks
    final morningStartIdx = audioFeatures.length > 20 ? 20 : 0;
    final morningEndIdx = audioFeatures.length > 30 ? 30 : audioFeatures.length;
    final morningFeatures = audioFeatures.sublist(
      morningStartIdx,
      morningEndIdx > morningStartIdx ? morningEndIdx : audioFeatures.length
    );
    final morningArtistIds = recentTracks.length > 20
        ? recentTracks.sublist(20, recentTracks.length > 30 ? 30 : recentTracks.length)
            .where((track) => track['artist_id'] != null)
            .map((track) => track['artist_id'] as String)
            .toList()
        : <String>[];
    final morningGenres = morningArtistIds.isNotEmpty
        ? await getArtistGenres(morningArtistIds)
        : <String>[];
    final morningMood = _determineMoodFromFeatures(morningFeatures, genres: morningGenres);

    // Forecast: based on overall trend
    final forecastMood = _determineMoodFromFeatures(audioFeatures, genres: allGenres);

    print('Mood analysis results: current=$currentMood, morning=$morningMood, forecast=$forecastMood');

    return {
      'current': currentMood,
      'morning': morningMood,
      'forecast': forecastMood,
    };
  } catch (e) {
    print('Error analyzing mood: $e');
    return {
      'current': 'UNREADABLE',
      'morning': 'UNREADABLE',
      'forecast': 'UNREADABLE',
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

        final artistIds = chunk
            .where((track) => track['artist_id'] != null)
            .map((track) => track['artist_id'] as String)
            .toList();

        if (trackIds.isNotEmpty) {
          final results = await Future.wait([
            getAudioFeatures(trackIds),
            artistIds.isNotEmpty ? getArtistGenres(artistIds) : Future.value(<String>[]),
          ]);
          final features = results[0] as List<Map<String, dynamic>>;
          final genres = results[1] as List<String>;
          final mood = _determineMoodFromFeatures(features, genres: genres);

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
        'mood': moodAnalysis['forecast'] ?? 'UNREADABLE',
      });
    }

    return {
      'overall_mood': moodAnalysis['forecast'] ?? 'UNREADABLE',
      'current_mood': moodAnalysis['current'] ?? 'UNREADABLE',
      'morning_mood': moodAnalysis['morning'] ?? 'UNREADABLE',
      'weekly_forecast': weeklyForecast,
      'total_tracks_analyzed': recentTracks.length,
    };
  } catch (e) {
    print('Error getting detailed forecast: $e');
    return {
      'overall_mood': 'UNREADABLE',
      'current_mood': 'UNREADABLE',
      'morning_mood': 'UNREADABLE',
      'weekly_forecast': [
        {'day': 'MON', 'mood': 'UNREADABLE'},
        {'day': 'TUE', 'mood': 'UNREADABLE'},
        {'day': 'WED', 'mood': 'UNREADABLE'},
        {'day': 'THU', 'mood': 'UNREADABLE'},
      ],
      'total_tracks_analyzed': 0,
    };
  }
}

Future<List<dynamic>> getRecommendations({
  required List<String> seedGenres,
  double? targetValence,
  double? targetEnergy,
  double? targetTempo,
}) async {
  final token = await getAccessToken();
  if (token == null) {
    throw Exception('Not authenticated with Spotify. Please login first.');
  }

  try {
    // Spotify API requires at least one seed parameter
    // Validate and filter genres to only valid Spotify genres
    final validGenres = _getValidSpotifyGenres(seedGenres);

    if (validGenres.isEmpty) {
      print('No valid genres provided, using default genres');
      validGenres.addAll(['pop', 'indie', 'alternative']);
    }

    // Spotify requires at least 1 and at most 5 seed values total
    // We can use seed_genres (1-5), seed_artists (1-5), or seed_tracks (1-5)
    // Total of all seeds must be between 1 and 5
    final seedGenresParam = validGenres.take(5).join(',');

    if (seedGenresParam.isEmpty) {
      throw Exception('No valid seed genres available for recommendations');
    }

    // Build query parameters - use proper URL encoding
    final queryParams = <String, String>{
      "seed_genres": seedGenresParam,
      "limit": "20",
    };

    if (targetValence != null) {
      queryParams["target_valence"] = targetValence.toStringAsFixed(2);
    }
    if (targetEnergy != null) {
      queryParams["target_energy"] = targetEnergy.toStringAsFixed(2);
    }
    if (targetTempo != null) {
      queryParams["target_tempo"] = targetTempo.toStringAsFixed(0);
    }

    print('Getting recommendations with genres: $seedGenresParam');

    // Use Uri.https which properly encodes the parameters
    final uri = Uri.https('api.spotify.com', '/v1/recommendations', queryParams);

    print('Recommendations API URL: $uri');

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    print('Recommendations API response: ${response.statusCode}');
    if (response.statusCode != 200) {
      print('Response body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final tracks = data['tracks'] ?? [];
      print('Successfully retrieved ${tracks.length} recommendations');
      return tracks;
    } else if (response.statusCode == 401) {
      throw Exception('Authentication expired. Please login again.');
    } else if (response.statusCode == 404) {
      // Try with just the first genre if multiple genres fail
      if (validGenres.length > 1) {
        print('Trying with single genre: ${validGenres.first}');
        final singleGenreParams = <String, String>{
          "seed_genres": validGenres.first,
          "limit": "20",
        };
        if (targetValence != null) {
          singleGenreParams["target_valence"] = targetValence.toStringAsFixed(2);
        }
        if (targetEnergy != null) {
          singleGenreParams["target_energy"] = targetEnergy.toStringAsFixed(2);
        }

        final singleGenreUri = Uri.https('api.spotify.com', '/v1/recommendations', singleGenreParams);
        final retryResponse = await http.get(
          singleGenreUri,
          headers: {"Authorization": "Bearer $token"},
        );

        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          return data['tracks'] ?? [];
        }
      }
      print('Recommendations API error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to get recommendations: ${response.statusCode}');
    } else {
      print('Recommendations API error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to get recommendations: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getRecommendations: $e');
    rethrow;
  }
}

  // Filter genres to only valid Spotify genre names
  List<String> _getValidSpotifyGenres(List<String> genres) {
    // Valid Spotify genres (common ones)
    final validSpotifyGenres = {
      'acoustic', 'afrobeat', 'alt-rock', 'alternative', 'ambient', 'anime',
      'black-metal', 'bluegrass', 'blues', 'bossanova', 'brazil', 'breakbeat',
      'british', 'cantopop', 'chicago-house', 'children', 'chill', 'classical',
      'club', 'comedy', 'country', 'dance', 'dancehall', 'death-metal',
      'deep-house', 'detroit-techno', 'disco', 'disney', 'drum-and-bass',
      'dub', 'dubstep', 'edm', 'electro', 'electronic', 'emo', 'folk',
      'forro', 'french', 'funk', 'garage', 'german', 'gospel', 'goth',
      'grindcore', 'groove', 'grunge', 'guitar', 'happy', 'hard-rock',
      'hardcore', 'hardstyle', 'heavy-metal', 'hip-hop', 'holidays', 'honky-tonk',
      'house', 'idm', 'indian', 'indie', 'indie-pop', 'industrial', 'iranian',
      'j-dance', 'j-idol', 'j-pop', 'j-rock', 'jazz', 'k-pop', 'kids',
      'latin', 'latino', 'malay', 'mandopop', 'metal', 'metal-misc', 'metalcore',
      'minimal-techno', 'movies', 'mpb', 'new-age', 'new-release', 'opera',
      'pagode', 'party', 'philippines-opm', 'piano', 'pop', 'pop-film',
      'post-dubstep', 'power-pop', 'progressive-house', 'psych-rock', 'punk',
      'punk-rock', 'r-n-b', 'rainy-day', 'reggae', 'reggaeton', 'road-trip',
      'rock', 'rock-n-roll', 'sad', 'salsa', 'samba', 'sertanejo', 'show-tunes',
      'singer-songwriter', 'ska', 'sleep', 'songwriter', 'soul', 'soundtracks',
      'spanish', 'study', 'summer', 'swedish', 'synth-pop', 'tango', 'techno',
      'trance', 'trip-hop', 'turkish', 'work-out', 'world-music'
    };

    return genres
        .map((g) => g.toLowerCase().trim())
        .where((g) => validSpotifyGenres.contains(g))
        .take(5) // Spotify allows max 5 seed genres
        .toList();
  }

Map<String, dynamic> formatTrack(Map<String, dynamic> track) {
  // Handle Spotify track object structure
  final artists = track['artists'] as List? ?? [];
  final artistName = artists.isNotEmpty
      ? (artists[0] is Map ? artists[0]['name'] : artists[0].toString())
      : 'Unknown';

  final album = track['album'] as Map<String, dynamic>?;
  final images = album?['images'] as List? ?? [];
  final imageUrl = images.isNotEmpty
      ? (images[0] is Map ? images[0]['url'] : null)
      : null;

  return {
    'name': track['name']?.toString() ?? 'Unknown',
    'artist': artistName.toString(),
    'image_url': imageUrl?.toString(),
  };
}
}