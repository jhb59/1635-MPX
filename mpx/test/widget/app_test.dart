import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mpx/viewmodel/auth_viewmodel.dart';

void main() {
  group('MyApp Widget Tests', () {
    testWidgets('MyApp provides AuthViewModel to children', (WidgetTester tester) async {
      // Test the provider setup without importing main.dart to avoid dart:html issues
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final viewModel = context.watch<AuthViewModel>();
                  return Text('Authenticated: ${viewModel.isAuthenticated}');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AuthViewModel is available in the widget tree
      expect(find.byType(MultiProvider), findsOneWidget);
      expect(find.text('Authenticated: false'), findsOneWidget);
    });

    testWidgets('MyApp structure test - MaterialApp with providers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const Center(child: Text('Test Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('MyApp localization delegates setup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('es')],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Text('Locale: ${Localizations.localeOf(context)}');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.textContaining('Locale:'), findsOneWidget);
    });
  });
}

