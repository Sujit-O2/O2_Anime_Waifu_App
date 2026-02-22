import 'package:anime_waifu/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Zero Two App Widget Tests', () {
    testWidgets('App launches without crashing',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const VoiceAiApp());

      // Verify the app title renders
      expect(find.text('ZERO TWO'), findsWidgets);

      // Verify scaffold exists
      expect(find.byType(Scaffold), findsWidgets);

      // Basic smoke test - no crashes
      await tester.pumpAndSettle();
    });

    testWidgets('MaterialApp is properly configured',
        (WidgetTester tester) async {
      await tester.pumpWidget(const VoiceAiApp());

      expect(find.byType(MaterialApp), findsOneWidget);
      
      final MaterialApp app =
          find.byType(MaterialApp).evaluate().single.widget as MaterialApp;
      expect(app.theme, isNotNull);

      await tester.pumpAndSettle();
    });

    testWidgets('App bar is present',
        (WidgetTester tester) async {
      await tester.pumpWidget(const VoiceAiApp());
      await tester.pumpAndSettle();

      // Verify app bar exists with Zero Two title
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('ZERO TWO'), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('Text input field renders',
        (WidgetTester tester) async {
      await tester.pumpWidget(const VoiceAiApp());
      await tester.pumpAndSettle();

      // Verify text field exists
      expect(find.byType(TextField), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Action buttons exist in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(const VoiceAiApp());
      await tester.pumpAndSettle();

      // Verify multiple action buttons exist
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('Chat list view is present',
        (WidgetTester tester) async {
      await tester.pumpWidget(const VoiceAiApp());
      await tester.pumpAndSettle();

      // Verify ListView exists for chat messages
      expect(find.byType(ListView), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Send button icon is present',
        (WidgetTester tester) async {
      await tester.pumpWidget(const VoiceAiApp());
      await tester.pumpAndSettle();

      // Verify send button with icon exists
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}

