import 'dart:convert';
import 'package:http/http.dart' as http;
import 'spotify_service.dart';

class RecommendationService {
  final SpotifyService _spotifyService = SpotifyService();

  Future<List<Map<String, dynamic>>> getRecommendationsForMood(
    String mood,
  ) async {
    try {
      final moodLower = mood.toLowerCase();
      Map<String, dynamic> features = _moodToAudioFeatures(moodLower);
      List<String> genres = _moodToGenres(moodLower);

      print(
        'Getting recommendations for mood: $moodLower with genres: ${genres.join(", ")}',
      );

      try {
        final rawTracks = await _spotifyService.getRecommendations(
          seedGenres: genres,
          targetValence: features["valence"],
          targetEnergy: features["energy"],
          targetTempo: features["tempo"],
        );

        if (rawTracks.isNotEmpty) {
          print('Received ${rawTracks.length} raw tracks from Spotify');

          // Convert all raw Spotify tracks 
          final formattedTracks = rawTracks.map<Map<String, dynamic>>((track) {
            try {
              final formatted = _spotifyService.formatTrack(track);
              return formatted;
            } catch (e) {
              print('Error formatting track: $e');
              return {
                'name': track['name']?.toString() ?? 'Unknown',
                'artist':
                    (track['artists'] as List?)?[0]?['name']?.toString() ??
                    'Unknown',
                'image_url': (track['album'] as Map?)?['images']?[0]?['url']
                    ?.toString(),
              };
            }
          }).toList();

          print('Returning ${formattedTracks.length} formatted tracks');
          return formattedTracks;
        }
      } catch (recommendationsError) {
        print('Recommendations API failed: $recommendationsError');
        print('Falling back to search-based recommendations...');
      }

      // Fallback: Use search API if recommendations fail
      return await _getSearchBasedRecommendations(moodLower, genres);
    } catch (e) {
      print('Error in getRecommendationsForMood: $e');
      // Return empty list instead of rethrowing to prevent UI crash
      return [];
    }
  }

  // Fallback method using search API
  Future<List<Map<String, dynamic>>> _getSearchBasedRecommendations(
    String mood,
    List<String> genres,
  ) async {
    try {
      // Use the first genre for search
      final searchGenre = genres.isNotEmpty ? genres.first : 'pop';
      final searchQuery = '$searchGenre $mood';

      print('Searching for tracks: $searchQuery');

      final token = await _spotifyService.getAccessToken();
      if (token == null) {
        print('No access token for search fallback');
        return [];
      }

      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeComponent(searchQuery)}&type=track&limit=20',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = (data['tracks']?['items'] as List? ?? []);
        print('Found ${tracks.length} tracks via search');

        return tracks.map<Map<String, dynamic>>((track) {
          return _spotifyService.formatTrack(track);
        }).toList();
      } else {
        print('Search API failed: ${response.statusCode} - ${response.body}');
      }

      return [];
    } catch (e) {
      print('Error in search-based recommendations: $e');
      return [];
    }
  }

  List<String> _moodToGenres(String mood) {
    switch (mood.toLowerCase()) {
      case "upbeat":
      case "happy":
      case "energetic":
        return ["pop", "dance", "electronic", "house", "funk"];
      case "sad":
        return ["blues", "indie", "acoustic", "folk", "sad"];
      case "mellow":
        return ["ambient", "acoustic", "indie", "jazz", "singer-songwriter"];
      case "unreadable":
      default:
        // Use valid Spotify genres for unreadable/default mood
        return ["ambient", "acoustic", "indie", "jazz", "singer-songwriter"];
    }
  }

  Map<String, dynamic> _moodToAudioFeatures(String mood) {
    switch (mood.toLowerCase()) {
      case "mellow":
        return {"valence": 0.5, "energy": 0.3, "tempo": 90};
      case "unreadable":
        return {"valence": 0.5, "energy": 0.4, "tempo": 100};
      case "upbeat":
      case "happy":
        return {"valence": 0.8, "energy": 0.7, "tempo": 120};
      case "sad":
        return {"valence": 0.2, "energy": 0.3, "tempo": 70};
      case "energetic":
        return {"valence": 0.7, "energy": 0.9, "tempo": 140};
      default:
        return {"valence": 0.5, "energy": 0.5, "tempo": 110};
    }
  }
}
