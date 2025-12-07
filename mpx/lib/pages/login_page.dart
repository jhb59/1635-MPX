import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../services/spotify_service.dart';
import '../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  // final VoidCallback onToggleLanguage;
  const LoginPage({super.key, this.onToggleLanguage});

  final VoidCallback? onToggleLanguage;

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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onToggleLanguage,
                    child: const Text("ES / EN"),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.title,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // STEP 1: Sign in with Spotify
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sign in with Spotify',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Click the button below to authorize MPX with your Spotify account. You will be redirected to Spotify to grant permissions.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red, width: 1),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
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
                                  children: [
                                    Icon(Icons.music_note, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!.continueWithSpotify,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // STEP 2: Get the authorization code from URL
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Get the authorization code',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'After authorizing, Spotify will redirect you to a URL. Look for the "code" parameter in the URL.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Example URL:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              '${SpotifyService.redirectUri}?code=YOUR_AUTHORIZATION_CODE_HERE',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Copy everything after "code=" in the URL',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showManualEntry = !_showManualEntry),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showManualEntry ? Icons.expand_less : Icons.expand_more,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showManualEntry
                                  ? 'Hide code entry'
                                  : 'Paste your authorization code here',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showManualEntry) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.authorizationCode,
                            hintText: 'Paste the code from the URL here',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.vpn_key),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitManualCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.submitCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Optional: Check Status
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _checkStatus,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.checkStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
