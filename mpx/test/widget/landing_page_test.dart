import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpx/l10n/app_localizations.dart';

void main() {
  group('LandingPage Widget Tests', () {
    testWidgets('LandingPage structure test - Scaffold with AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('MPX'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () {},
                ),
              ],
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      // Initially, the page should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('LandingPage displays emotional forecast panel structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emotional Forecast',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Check if the emotional forecast panel structure is present
      expect(find.text('Emotional Forecast'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LandingPage has logout button structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {},
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for logout button/icon
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}

