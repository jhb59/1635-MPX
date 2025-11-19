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
  bool _isLoading = false;
  bool _isLoadingData = true;
  Map<String, dynamic>? _userInfo;

  // Emotional forecast data
  Map<String, dynamic>? _emotionalForecast;

  // Song recommendations
  List<Map<String, dynamic>> _songRecommendations = [];

  // Playlists
  List<Map<String, dynamic>> _playlists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserInfo();
        _loadAllData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;
    final userInfo = await _authService.getUserInfo();
    if (mounted) {
      setState(() {
        _userInfo = userInfo;
      });
    }
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _spotifyService.getDetailedEmotionalForecast(),
        _spotifyService.getSongRecommendations(limit: 10),
        _spotifyService.getUserPlaylists(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _emotionalForecast = results[0] as Map<String, dynamic>;
          _songRecommendations = results[1] as List<Map<String, dynamic>>;
          _playlists = results[2] as List<Map<String, dynamic>>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Helper to convert mood string to MoodIcon
  MoodIcon _moodToIcon(String mood) {
    switch (mood.toUpperCase()) {
      case 'UPBEAT':
        return MoodIcon.sunny;
      case 'SAD':
        return MoodIcon.sad;
      case 'MELLOW':
      default:
        return MoodIcon.mellow;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              onLoginSuccess: () {},
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildUserAvatar() {
    final images = _userInfo!['images'] as List?;
    String? imageUrl;

    if (images != null && images.isNotEmpty) {
      try {
        final smallImage = images.firstWhere(
          (img) => img['width'] == 64 || img['height'] == 64,
          orElse: () => images[0],
        );
        imageUrl = smallImage['url'] as String?;
      } catch (e) {
        imageUrl = images[0]['url'] as String?;
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return RepaintBoundary(
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              final displayName = _userInfo!['display_name'] as String? ?? 'U';
              final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
              return CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      final displayName = _userInfo!['display_name'] as String? ?? 'U';
      final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.black,
        child: Text(
          initial,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildMoodIcon(MoodIcon icon, {double size = 60}) {
    String assetPath;
    switch (icon) {
      case MoodIcon.sunny:
        assetPath = 'assets/icons/sun.svg';
        break;
      case MoodIcon.cloudy:
        assetPath = 'assets/icons/cloud.svg';
        break;
      case MoodIcon.rainy:
        assetPath = 'assets/icons/cloud_rain.svg';
        break;
      case MoodIcon.sad:
        assetPath = 'assets/icons/sad.svg';
        break;
      case MoodIcon.mellow:
        assetPath = 'assets/icons/cloud_sun.svg';
        break;
    }

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
      placeholderBuilder: (context) => Container(
        width: size,
        height: size,
        color: Colors.grey[200],
      ),
      semanticsLabel: 'Mood icon',
    );
  }

  Widget _buildPanel({
    required String title,
    Widget? child,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmotionalForecastPanel() {
    if (_isLoadingData || _emotionalForecast == null) {
      return _buildPanel(
        title: 'EMOTIONAL FORECAST',
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        ),
      );
    }

    final overallMood = _emotionalForecast!['overall_mood'] as String? ?? 'MELLOW';
    final weeklyForecast = _emotionalForecast!['weekly_forecast'] as List? ?? [];
    final totalTracks = _emotionalForecast!['total_tracks_analyzed'] as int? ?? 0;

    return _buildPanel(
      title: 'EMOTIONAL FORECAST',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall mood
            Row(
              children: [
                _buildMoodIcon(_moodToIcon(overallMood), size: 80),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OVERALL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallMood,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Weekly forecast
            const Text(
              'WEEKLY FORECAST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ...weeklyForecast.map((dayData) {
              final day = dayData['day'] as String? ?? '';
              final mood = dayData['mood'] as String? ?? 'MELLOW';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildMoodIcon(_moodToIcon(mood), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        mood,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              'Based on $totalTracks tracks analyzed',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongRecommendationsPanel() {
    if (_isLoadingData) {
      return _buildPanel(
        title: 'SONG RECOMMENDATIONS',
        child: const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (_songRecommendations.isEmpty) {
      return _buildPanel(
        title: 'SONG RECOMMENDATIONS',
        child: const Center(
          child: Text('No recommendations available'),
        ),
      );
    }

    return _buildPanel(
      title: 'SONG RECOMMENDATIONS',
      child: ListView.builder(
        itemCount: _songRecommendations.length,
        itemBuilder: (context, index) {
          final song = _songRecommendations[index];
          final name = song['name'] as String? ?? 'Unknown';
          final artist = song['artist'] as String? ?? 'Unknown';
          final imageUrl = song['image_url'] as String?;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[300],
                          child: const Icon(Icons.music_note),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artist,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildMostRecommendedPlaylistPanel() {
    if (_isLoadingData) {
      return _buildPanel(
        title: 'MOST RECOMMENDED',
        child: const Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (_playlists.isEmpty) {
      return _buildPanel(
        title: 'MOST RECOMMENDED',
        child: const Center(
          child: Text('No playlists available'),
        ),
      );
    }

    // Get the first playlist as "most recommended"
    final playlist = _playlists[0];
    final name = playlist['name'] as String? ?? 'Unknown';
    final description = playlist['description'] as String? ?? '';
    final imageUrl = playlist['image_url'] as String?;
    final tracksCount = playlist['tracks_count'] as int? ?? 0;
    final externalUrl = playlist['external_url'] as String?;

    return _buildPanel(
      title: 'MOST RECOMMENDED',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.playlist_play, size: 40),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.playlist_play, size: 40),
              ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '$tracksCount tracks',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      buttonText: 'OPEN PLAYLIST',
      onButtonPressed: externalUrl != null
          ? () async {
              final uri = Uri.parse(externalUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          : null,
    );
  }

  Widget _buildOtherPlaylistPanel(int index) {
    if (_isLoadingData || index + 1 >= _playlists.length) {
      return _buildPanel(
        title: 'RECOMMENDED PLAYLIST',
        child: const Center(
          child: Text('No playlist available'),
        ),
      );
    }

    final playlist = _playlists[index + 1];
    final name = playlist['name'] as String? ?? 'Unknown';
    final imageUrl = playlist['image_url'] as String?;
    final tracksCount = playlist['tracks_count'] as int? ?? 0;
    final externalUrl = playlist['external_url'] as String?;

    return _buildPanel(
      title: 'RECOMMENDED PLAYLIST',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.playlist_play, size: 28),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(Icons.playlist_play, size: 28),
              ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$tracksCount tracks',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      buttonText: 'OPEN',
      onButtonPressed: externalUrl != null
          ? () async {
              final uri = Uri.parse(externalUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (_userInfo != null)
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      _buildUserAvatar(),
                      const SizedBox(width: 8),
                      Text(
                        _userInfo!['display_name'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.black),
                        onPressed: _handleLogout,
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Column 1: Full Emotional Forecast
                Expanded(
                  flex: 1,
                  child: _buildEmotionalForecastPanel(),
                ),
                const SizedBox(width: 16),
                // Column 2: Song Recommendations (2/3) + Most Recommended Playlist (1/3)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Song Recommendations - 2/3 height
                      Expanded(
                        flex: 2,
                        child: _buildSongRecommendationsPanel(),
                      ),
                      const SizedBox(height: 12),
                      // Most Recommended Playlist - 1/3 height
                      Expanded(
                        flex: 1,
                        child: _buildMostRecommendedPlaylistPanel(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Column 3: Three equal playlists
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildOtherPlaylistPanel(0),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildOtherPlaylistPanel(1),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildOtherPlaylistPanel(2),
                      ),
                    ],
                  ),
                ),
                    ], // Close Row children
                  ), // Close Row
                ); // Close SizedBox
              },
            ),
          ),
        ),
      ),
    );
  }
}
