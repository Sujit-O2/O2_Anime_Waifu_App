import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:anime_waifu/utils/api_call.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUpAll(() async {
      // Initialize dotenv with test values
      await dotenv.load(fileName: '.env');
    });

    setUp(() {
      apiService = ApiService();
    });

    tearDown(() {
      apiService.configure(
        apiKeyOverride: '',
        modelOverride: '',
        urlOverride: '',
        brevoApiKeyOverride: '',
      );
    });

    test('hasApiKey returns true when env key is set', () {
      expect(apiService.hasApiKey, true);
    });

    test('hasApiKey returns true when override is set', () {
      apiService.configure(apiKeyOverride: 'override-key');
      expect(apiService.hasApiKey, true);
    });

    test('configure sets apiKeyOverride', () {
      apiService.configure(apiKeyOverride: 'test-key-123');
      expect(apiService.hasApiKey, true);
    });

    test('sendConversation throws when no messages provided', () async {
      expect(
        () => apiService.sendConversation([]),
        throwsA(isA<Exception>()),
      );
    });

    test('sendConversation throws when messages is null or empty', () async {
      expect(
        () => apiService.sendConversation([]),
        throwsA(isA<Exception>()),
      );
    });
  });
}
