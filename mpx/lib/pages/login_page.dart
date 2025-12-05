import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../services/spotify_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _showManualEntry = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tryAutoCompleteLogin();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// AUTO Login if a redirect code was stored in browser localStorage
  Future<void> _tryAutoCompleteLogin() async {
    final code = html.window.localStorage['spotify_auth_code'];
    if (code == null || code.isEmpty) return;

    html.window.localStorage.remove('spotify_auth_code');

    final authVM = context.read<AuthViewModel>();

    setState(() => _isLoading = true);

    try {
      await authVM.handleCallback(code);
      // CallbackPage will handle navigation automatically
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Start the Spotify OAuth flow (opens Spotify authorization page)
  Future<void> _startLogin() async {
    final authVM = context.read<AuthViewModel>();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await authVM.login(); // MVVM call
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Manual entry fallback ONLY (does not interfere with normal flow)
  Future<void> _submitManualCode() async {
    final authVM = context.read<AuthViewModel>();
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = "Enter a valid authorization code.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authVM.handleCallback(code);
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Check if the user is already authenticated (using stored refresh token)
  Future<void> _checkStatus() async {
    final authVM = context.read<AuthViewModel>();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final ok = await authVM.checkStatus();
      if (!ok) setState(() => _errorMessage = "Not authenticated yet.");
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // --------------------------------------------------
  //                       UI
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    children: const [
                      Text(
                        'MP-X',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'MOOD TRACKER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                const Text(
                  "Connect with Spotify to create personalized mood-balancing playlists based on your emotional state.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),

                const SizedBox(height: 36),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                // Spotify Login Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.music_note, size: 18),
                              SizedBox(width: 12),
                              Text(
                                "CONTINUE WITH SPOTIFY",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle Manual Entry
                TextButton(
                  onPressed: () =>
                      setState(() => _showManualEntry = !_showManualEntry),
                  child: Text(
                    _showManualEntry
                        ? "Hide Manual Entry"
                        : "Enter Authorization Code Manually",
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                if (_showManualEntry) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: "Authorization Code",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitManualCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("SUBMIT CODE"),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // CHECK STATUS
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _checkStatus,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    child: const Text(
                      "CHECK STATUS",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Current Redirect URI:\n${SpotifyService.redirectUri}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
