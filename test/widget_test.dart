import 'package:anime_waifu/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const VoiceAiApp());
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_KEY=gsk_test_key');
  });

  group('Zero Two App Widget Tests', () {
    testWidgets('App launches without crashing', (WidgetTester tester) async {
      await _pumpApp(tester);

      // Verify the app title renders
      expect(find.text('ZERO TWO'), findsWidgets);

      // Verify scaffold exists
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('MaterialApp is properly configured',
        (WidgetTester tester) async {
      await _pumpApp(tester);

      expect(find.byType(MaterialApp), findsOneWidget);

      final MaterialApp app =
          find.byType(MaterialApp).evaluate().single.widget as MaterialApp;
      expect(app.theme, isNotNull);
    });

    testWidgets('App bar is present', (WidgetTester tester) async {
      await _pumpApp(tester);

      // Verify app bar exists with Zero Two title
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('ZERO TWO'), findsWidgets);
    });

    testWidgets('Text input field renders', (WidgetTester tester) async {
      await _pumpApp(tester);

      // Verify text field exists
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Action buttons exist in app bar', (WidgetTester tester) async {
      await _pumpApp(tester);

      // Verify multiple action buttons exist
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);
    });

    testWidgets('Chat list view is present', (WidgetTester tester) async {
      await _pumpApp(tester);

      // Verify AnimatedList exists for chat messages
      expect(find.byType(AnimatedList), findsOneWidget);
    });

    testWidgets('Send button icon is present', (WidgetTester tester) async {
      await _pumpApp(tester);

      // Verify send button with icon exists
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });
  });
}
