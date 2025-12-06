import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/spotify_service.dart';
import '../services/auth_service.dart';
import '../models/mood_data.dart';
import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final SpotifyService _spotifyService = SpotifyService();
  final AuthService _authService = AuthService();

  bool _isLoadingData = true;
  Map<String, dynamic>? _userInfo;

  Map<String, dynamic>? _emotionalForecast;
  List<Map<String, dynamic>> _playlists = [];
  List<Map<String, dynamic>> _recentTracks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
      _loadAllData();
    });
  }

  Future<void> _loadUserInfo() async {
    final data = await _authService.getUserInfo();
    if (!mounted) return;
    setState(() => _userInfo = data);
  }

  Future<void> _loadAllData() async {
    final token = await _spotifyService.getAccessToken();
    if (token == null || !mounted) {
      setState(() => _isLoadingData = false);
      return;
    }

    try {
      final results = await Future.wait([
        _spotifyService.getDetailedEmotionalForecast(),
        _spotifyService.getUserPlaylists(limit: 10),
        _spotifyService.getRecentlyPlayedTracks(limit: 10),
      ]);

      setState(() {
        _emotionalForecast = results[0] as Map<String, dynamic>;
        _playlists = List<Map<String, dynamic>>.from(results[1] as List);
        _recentTracks = List<Map<String, dynamic>>.from(results[2] as List);
        _isLoadingData = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (_) => false,
    );
  }


  // Helpers ------------------------------------------------------------

  MoodIcon _moodToIcon(String mood) {
    switch (mood.toUpperCase()) {
      case 'UPBEAT':
        return MoodIcon.sunny;
      case 'SAD':
        return MoodIcon.sad;
      case 'UNREADABLE':
        return MoodIcon.sad; // placeholder for unreadable mood
      default:
        return MoodIcon.mellow;
    }
  }

  Widget _buildMoodIcon(MoodIcon icon, {double size = 60}) {
    const icons = {
      MoodIcon.sunny: 'assets/icons/sun.svg',
      MoodIcon.cloudy: 'assets/icons/cloud.svg',
      MoodIcon.rainy: 'assets/icons/cloud_rain.svg',
      MoodIcon.sad: 'assets/icons/sad.svg',
      MoodIcon.mellow: 'assets/icons/cloud_sun.svg',
    };

    return SvgPicture.asset(
      icons[icon]!,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  // Emotional Forecast --------------------------------------------------

  Widget _buildEmotionalForecast() {
    if (_isLoadingData || _emotionalForecast == null) {
      return _panel(
        title: "EMOTIONAL FORECAST",
        child: const Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final mood = _moodToIcon(_emotionalForecast!['overall_mood']);
    final week = _emotionalForecast!['weekly_forecast'] ?? [];
    final total = _emotionalForecast!['total_tracks_analyzed'] ?? 0;

    return _panel(
      title: "EMOTIONAL FORECAST",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _buildMoodIcon(mood, size: 80),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _emotionalForecast!['overall_mood'] ?? "",
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            const Text("WEEKLY FORECAST",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...week.map<Widget>((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  SizedBox(width: 60, child: Text(d['day'] ?? "")),
                  _buildMoodIcon(_moodToIcon(d['mood']), size: 30),
                  const SizedBox(width: 12),
                  Text(
                    d['mood'] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 12),
            Text("Based on $total tracks analyzed",
                style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // Recently Played -----------------------------------------------------

  Widget _buildRecentlyPlayed() {
    if (_isLoadingData) {
      return _panel(
        title: "RECENTLY PLAYED",
        child: const Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_recentTracks.isEmpty) {
      return _panel(
        title: "RECENTLY PLAYED",
        child: const Center(child: Text("No recent tracks found")),
      );
    }

    return _panel(
      title: "RECENTLY PLAYED",
      child: ListView.separated(
        itemCount: _recentTracks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final t = _recentTracks[i];
         return InkWell(
            onTap: () async {
              final url = t['external_url'];
              if (url != null) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    t['image_url'] ?? "",
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['name'] ?? "Unknown",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        t['artist'] ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Playlist cards ------------------------------------------------------

  Widget _playlistCard(int index, {bool small = false}) {
    if (index >= _playlists.length) {
      return _panel(title: "RECOMMENDED", child: Container());
    }

    final p = _playlists[index];

    return GestureDetector(
      onTap: () async {
        final url = p['external_url'];
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: _panel(
        title: small ? "RECOMMENDED" : "MOST RECOMMENDED",
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    p['image_url'],
                    height: small ? 80 : 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: small ? 80 : 100,
                  color: Colors.grey[300],
                ),
              const SizedBox(height: 8),
              Text(
                p['name'] ?? "Unknown",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "${p['tracks_count']} tracks",
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );

  }

  // Build UI ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_userInfo != null)
            Row(children: [
              Text(
                _userInfo!['display_name'] ?? "User",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.black),
              ),
            ])
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Left
          Expanded(flex: 1, child: _buildEmotionalForecast()),

          const SizedBox(width: 16),

          // Middle
          Expanded(
            flex: 1,
            child: Column(children: [
              Expanded(flex: 2, child: _buildRecentlyPlayed()),
              const SizedBox(height: 12),
              Expanded(flex: 1, child: _playlistCard(0)),
            ]),
          ),

          const SizedBox(width: 16),

          // Right
          Expanded(
            flex: 1,
            child: Column(children: [
              Expanded(child: _playlistCard(1, small: true)),
              const SizedBox(height: 12),
              Expanded(child: _playlistCard(2, small: true)),
              const SizedBox(height: 12),
              Expanded(child: _playlistCard(3, small: true)),
            ]),
          ),
        ]),
      ),
    );
  }
}
