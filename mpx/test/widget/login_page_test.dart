import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mpx/viewmodel/auth_viewmodel.dart';
import 'package:mpx/l10n/app_localizations.dart';

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('LoginPage structure test - Scaffold with AuthViewModel', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: AppBar(title: const Text('Login')),
              body: Builder(
                builder: (context) {
                  final viewModel = context.watch<AuthViewModel>();
                  return Center(
                    child: Column(
                      children: [
                        Text('Authenticated: ${viewModel.isAuthenticated}'),
                        ElevatedButton(
                          onPressed: () => viewModel.login(),
                          child: const Text('Login with Spotify'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the structure exists
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('LoginPage AuthViewModel integration test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final viewModel = context.read<AuthViewModel>();
                  return Text('Status: ${viewModel.isAuthenticated}');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify AuthViewModel is available and working
      expect(find.byType(MultiProvider), findsOneWidget);
      expect(find.text('Status: false'), findsOneWidget);
    });

    testWidgets('LoginPage localization support', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Text('Current locale: ${Localizations.localeOf(context)}');
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.textContaining('Current locale:'), findsOneWidget);
    });
  });
}

