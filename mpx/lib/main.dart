import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'pages/login_page.dart';
import 'pages/callback_page.dart';
import 'viewmodel/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final uri = Uri.base;
  final bool isSpotifyCallback =
      uri.path.contains('callback') && uri.queryParameters.containsKey('code');

  runApp(MyApp(isCallback: isSpotifyCallback, uri: uri));
}

class MyApp extends StatefulWidget {
  final bool isCallback;
  final Uri uri;

  const MyApp({required this.isCallback, required this.uri, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  void _toggleLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'en'
          ? const Locale('es')
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthViewModel())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "MPX",
        locale: _locale,

        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('es')],

        home: widget.isCallback
            ? CallbackPage(uri: widget.uri, onToggleLanguage: _toggleLanguage)
            : LoginPage(onToggleLanguage: _toggleLanguage),
      ),
    );
  }
}
