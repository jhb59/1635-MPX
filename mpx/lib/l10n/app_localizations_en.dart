// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'MUSIC VIBE';

  @override
  String get subtitle => 'MP-X';

  @override
  String get loginDescription => 'Connect with Spotify to create personalized mood-balancing playlists based on your emotional state.';

  @override
  String get continueWithSpotify => 'CONTINUE WITH SPOTIFY';

  @override
  String get enterCodeManually => 'Enter Authorization Code Manually';

  @override
  String get hideManualEntry => 'Hide Manual Entry';

  @override
  String get authorizationCode => 'Authorization Code';

  @override
  String get submitCode => 'SUBMIT CODE';

  @override
  String get checkStatus => 'CHECK STATUS';

  @override
  String get notAuthenticated => 'Not authenticated yet.';

  @override
  String get emotionalForecast => 'EMOTIONAL FORECAST';

  @override
  String get weeklyForecast => 'WEEKLY FORECAST';

  @override
  String get recentlyPlayed => 'RECENTLY PLAYED';

  @override
  String get recommended => 'RECOMMENDED';

  @override
  String get mostRecommended => 'MOST RECOMMENDED';

  @override
  String get noRecentTracks => 'No recent tracks found';

  @override
  String get unknown => 'Unknown';

  @override
  String get user => 'User';

  @override
  String trackCount(int count) {
    return '$count tracks';
  }

  @override
  String tracksAnalyzed(int count) {
    return 'Based on $count tracks analyzed';
  }
}
