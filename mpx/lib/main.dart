import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class MyApp extends StatelessWidget {
  final bool isCallback;
  final Uri uri;

  const MyApp({required this.isCallback, required this.uri, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "MPX",
        home: isCallback
            ? CallbackPage(uri: uri)
            : const LoginPage(),
      ),
    );
  }
}
