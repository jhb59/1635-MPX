// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get title => 'RASTREADOR DE ESTADO DE ÁNIMO';

  @override
  String get subtitle => 'MP-X';

  @override
  String get loginDescription => 'Conéctate con Spotify para crear listas de reproducción personalizadas según tu estado emocional.';

  @override
  String get continueWithSpotify => 'CONTINUAR CON SPOTIFY';

  @override
  String get enterCodeManually => 'Ingresar código manualmente';

  @override
  String get hideManualEntry => 'Ocultar ingreso manual';

  @override
  String get authorizationCode => 'Código de autorización';

  @override
  String get submitCode => 'ENVIAR CÓDIGO';

  @override
  String get checkStatus => 'VERIFICAR ESTADO';

  @override
  String get notAuthenticated => 'Aún no autenticado.';

  @override
  String get emotionalForecast => 'PRONÓSTICO EMOCIONAL';

  @override
  String get weeklyForecast => 'PRONÓSTICO SEMANAL';

  @override
  String get recentlyPlayed => 'REPRODUCIDO RECIENTEMENTE';

  @override
  String get recommended => 'RECOMENDADO';

  @override
  String get mostRecommended => 'MÁS RECOMENDADO';

  @override
  String get noRecentTracks => 'No se encontraron canciones recientes';

  @override
  String get unknown => 'Desconocido';

  @override
  String get user => 'Usuario';

  @override
  String trackCount(int count) {
    return '$count canciones';
  }

  @override
  String tracksAnalyzed(int count) {
    return 'Basado en $count canciones analizadas';
  }
}
