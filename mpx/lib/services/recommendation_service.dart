import 'spotify_service.dart';

class RecommendationService {
  final SpotifyService _spotifyService = SpotifyService();

  Future<List<Map<String, dynamic>>> getRecommendationsForMood(String mood) async {
    Map<String, dynamic> features = _moodToAudioFeatures(mood);

    final rawTracks = await _spotifyService.getRecommendations(
      seedGenres: ["pop", "chill", "indie"],
      targetValence: features["valence"],
      targetEnergy: features["energy"],
      targetTempo: features["tempo"],
    );

    // Convert all raw Spotify tracks → your UI map format
    return rawTracks.map<Map<String, dynamic>>((track) {
      return _spotifyService.formatTrack(track);
    }).toList();
  }

  Map<String, dynamic> _moodToAudioFeatures(String mood) {
    switch (mood.toLowerCase()) {
      case "mellow":
        return {"valence": 0.3, "energy": 0.2, "tempo": 90};
      case "happy":
        return {"valence": 0.8, "energy": 0.7, "tempo": 120};
      case "sad":
        return {"valence": 0.1, "energy": 0.2, "tempo": 70};
      case "energetic":
        return {"valence": 0.7, "energy": 0.9, "tempo": 140};
      default:
        return {"valence": 0.5, "energy": 0.5, "tempo": 110};
    }
  }
}
