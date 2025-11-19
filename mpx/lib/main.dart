import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress Flutter web debug inspector errors (harmless JavaScript interop issues)
  // kIsWeb is available from foundation.dart in Flutter
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Suppress the known LegacyJavaScriptObject error from debug inspector
      final errorStr = details.exception.toString();
      if (errorStr.contains('LegacyJavaScriptObject') ||
          errorStr.contains('DiagnosticsNode') ||
          (errorStr.contains('TypeError') && errorStr.contains('LegacyJavaScriptObject'))) {
        // This is a known Flutter web debug inspector limitation - harmless
        // Only suppress in web debug mode
        return;
      }
      // Log other errors normally
      FlutterError.presentError(details);
    };
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MP-X Mood Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Use postFrameCallback to avoid issues during hot restart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAuthStatus();
      }
    });
  }

  @override
  void dispose() {
    // Clean up any pending operations
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;
    final isAuthenticated = await _authService.isAuthenticated();
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuthenticated;
        _isLoading = false;
      });
    }
  }

  void _handleLoginSuccess() {
    if (mounted) {
      setState(() {
        _isAuthenticated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const LandingPage();
    }

    return LoginPage(onLoginSuccess: _handleLoginSuccess);
  }
}
