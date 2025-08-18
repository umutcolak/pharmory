// Flutter widget tests for Pharmory iOS app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pharmory/main.dart';
import 'package:pharmory/providers/app_provider.dart';

void main() {
  group('Pharmory iOS App Tests', () {
    testWidgets('App should start with HomeScreen', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const PharmoryApp(),
        ),
      );

      // Verify that app starts with title
      expect(find.text('Pharmory'), findsOneWidget);
      
      // Verify main UI elements are present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ARA'), findsOneWidget);
      expect(find.text('Prospektüs Fotoğrafı Çek'), findsOneWidget);
      
      // Verify accessibility controls
      expect(find.text('Yazı Boyutu:'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('Search text field should accept input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const PharmoryApp(),
        ),
      );

      // Find the search text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter text
      await tester.enterText(textField, 'Parol');
      expect(find.text('Parol'), findsOneWidget);
    });

    testWidgets('Font size slider should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const PharmoryApp(),
        ),
      );

      // Find and interact with slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Move slider (this is a basic interaction test)
      await tester.tap(slider);
      await tester.pump();
      
      // The slider should still be present
      expect(slider, findsOneWidget);
    });

    testWidgets('Language dropdown should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const PharmoryApp(),
        ),
      );

      // Find language dropdown
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      // Verify Turkish is selected by default
      expect(find.text('Türkçe'), findsOneWidget);
    });

    testWidgets('Camera button should be present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const PharmoryApp(),
        ),
      );

      // Find camera button
      final cameraButton = find.text('Prospektüs Fotoğrafı Çek');
      expect(cameraButton, findsOneWidget);
      
      // Verify it's a button that can be tapped
      final button = find.ancestor(
        of: cameraButton,
        matching: find.byType(OutlinedButton),
      );
      expect(button, findsOneWidget);
    });
  });

  group('AppProvider Tests', () {
    test('AppProvider should initialize with default values', () {
      final provider = AppProvider();
      
      expect(provider.fontSize, 16.0);
      expect(provider.language, 'tr');
      expect(provider.isLoading, false);
      expect(provider.searchHistory, isEmpty);
    });

    test('AppProvider should update font size', () async {
      final provider = AppProvider();
      
      await provider.updateFontSize(20.0);
      expect(provider.fontSize, 20.0);
    });

    test('AppProvider should update language', () async {
      final provider = AppProvider();
      
      await provider.updateLanguage('en');
      expect(provider.language, 'en');
    });

    test('AppProvider should manage loading state', () {
      final provider = AppProvider();
      
      provider.setLoading(true);
      expect(provider.isLoading, true);
      
      provider.setLoading(false);
      expect(provider.isLoading, false);
    });
  });
}