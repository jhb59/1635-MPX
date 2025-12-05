import 'package:flutter/foundation.dart';
import '../services/spotify_service.dart';

class SpotifyViewModel extends ChangeNotifier {
  final SpotifyService _spotifyService = SpotifyService();

  bool _loading = false;
  List<Map<String, dynamic>> _tracks = [];   // ✔ FIXED
  String? _error;

  bool get loading => _loading;
  List<Map<String, dynamic>> get tracks => _tracks;
  String? get error => _error;

  Future<void> loadRecentTracks() async {
    _loading = true;
    notifyListeners();

    try {
      _tracks = await _spotifyService.getRecentlyPlayedTracks(limit: 10);  // ✔ FIXED TYPE
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }
}
