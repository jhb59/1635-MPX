import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'landing_page.dart';

class CallbackPage extends StatefulWidget {
  final Uri uri;
  final VoidCallback onToggleLanguage;

  const CallbackPage({
    required this.uri,
    required this.onToggleLanguage,
    super.key,
  });

  @override
  State<CallbackPage> createState() => _CallbackPageState();
}

class _CallbackPageState extends State<CallbackPage> {
  @override
  void initState() {
    super.initState();

    final code = widget.uri.queryParameters['code'];

    if (code != null) {
      final authVM = context.read<AuthViewModel>();
      authVM.handleCallback(code).then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LandingPage(
              onToggleLanguage: widget.onToggleLanguage,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
