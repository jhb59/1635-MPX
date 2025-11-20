import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/spotify_service.dart';

class LoginPage extends StatefulWidget {
  final Function() onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showManualEntry = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSpotifyLogin() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Open Spotify authentication
      await _authService.spotifyService.authenticate();
      
      // Show message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('After authorizing, you\'ll see a "connection refused" error - this is normal! Copy the code from the URL and use "Enter Authorization Code Manually" below.'),
            duration: Duration(seconds: 10),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
      // Show detailed error message
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      
      // Also show as dialog for credential errors
      if (errorMsg.contains('credentials not configured') || errorMsg.contains('INVALID_CLIENT')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Spotify Setup Required'),
              content: SingleChildScrollView(
                child: Text(
                  '$errorMsg\n\n'
                  'Quick Fix:\n'
                  '1. Open lib/services/spotify_service.dart\n'
                  '2. Replace YOUR_SPOTIFY_CLIENT_ID with your actual Client ID\n'
                  '3. Replace YOUR_SPOTIFY_CLIENT_SECRET with your actual Client Secret\n'
                  '4. Make sure the Redirect URI in Spotify Dashboard matches:\n'
                  '   http://127.0.0.1:8080/callback\n'
                  '5. Restart the app',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _handleManualCodeEntry() async {
    if (!mounted) return;
    
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please enter an authorization code';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final success = await _authService.spotifyService.exchangeCodeForToken(code);
      if (success && mounted) {
        widget.onLoginSuccess();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to exchange code. Please check:\n1. The code is correct\n2. Redirect URI matches Spotify Dashboard\n3. Code hasn\'t expired (get a new one)';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _errorMessage = 'Error: $errorMsg\n\nCommon issues:\n- Redirect URI mismatch\n- Code expired (get a fresh one)\n- Invalid code';
          _isLoading = false;
        });
        
        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Authentication Error'),
            content: SingleChildScrollView(
              child: Text(
                errorMsg + '\n\nTroubleshooting:\n'
                '1. Make sure redirect URI in code matches Spotify Dashboard exactly\n'
                '2. Get a fresh authorization code (they expire quickly)\n'
                '3. Check that Client ID and Secret are correct\n'
                '4. Try the authentication flow again',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isAuthenticated = await _authService.isAuthenticated();
      
      if (isAuthenticated && mounted) {
        widget.onLoginSuccess();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Not authenticated yet. Please complete the login process in your browser first.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking status: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Title
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'MP-X',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MOOD TRACKER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Description
                Text(
                  'Connect with Spotify to create personalized mood-balancing playlists based on your emotional state.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!, width: 1),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Login button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSpotifyLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Spotify green circle icon
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1DB954),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'CONTINUE WITH SPOTIFY',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Manual code entry option
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showManualEntry = !_showManualEntry;
                    });
                  },
                  child: Text(
                    _showManualEntry ? 'Hide Manual Entry' : 'Enter Authorization Code Manually',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                
                if (_showManualEntry) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Authorization Code',
                      hintText: 'Paste code from URL here',
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleManualCodeEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: const Text(
                        'SUBMIT CODE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'After authorizing, Spotify will redirect you to an error page.\n'
                    'Even though the page shows "connection refused", you can still:\n'
                    '1. Look at the browser address bar\n'
                    '2. Find the URL that looks like: http://127.0.0.1:8080/callback?code=AQBx...\n'
                    '3. Copy everything after "code=" (the long string)\n'
                    '4. Paste it in the field above',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Check Status button
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _checkAuthStatus,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: const Text(
                      'CHECK STATUS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Info text
                Text(
                  'After authorizing in your browser, you can either:\n'
                  '1. Enter the code manually (if redirected to error page)\n'
                  '2. Click "Check Status" if already authenticated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Redirect URI info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Redirect URI:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        SpotifyService.redirectUri,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '⚠️ This MUST match exactly in your Spotify Dashboard!\n'
                        'If your Flutter app runs on a different port, update both:\n'
                        '1. lib/services/spotify_service.dart (line 24)\n'
                        '2. Spotify Dashboard → Settings → Redirect URIs',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
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

