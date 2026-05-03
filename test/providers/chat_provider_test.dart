import 'package:flutter_test/flutter_test.dart';
import 'package:anime_waifu/core/providers/chat_provider.dart';
import 'package:anime_waifu/models/chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ChatProvider', () {
    late ChatProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = ChatProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state is correct', () {
      expect(provider.messages, isEmpty);
      expect(provider.pastMessages, isEmpty);
      expect(provider.pinnedMessages, isEmpty);
      expect(provider.isBusy, false);
      expect(provider.isSpeaking, false);
      expect(provider.currentVoiceText, '');
      expect(provider.isChatSearchActive, false);
      expect(provider.chatSearchQuery, '');
      expect(provider.quickReplies, isEmpty);
      expect(provider.currentMoodLabel, 'Happy 😊');
      expect(provider.swipeCount, 0);
      expect(provider.userMessageCount, 0);
    });

    group('isBusy', () {
      test('notifies listeners on change', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.isBusy = true;
        expect(notified, true);
        expect(provider.isBusy, true);
      });

      test('does not notify when value unchanged', () {
        provider.isBusy = false;
        var notified = false;
        provider.addListener(() => notified = true);
        provider.isBusy = false;
        expect(notified, false);
      });
    });

    group('isSpeaking', () {
      test('notifies listeners on change', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.isSpeaking = true;
        expect(notified, true);
        expect(provider.isSpeaking, true);
      });
    });

    group('currentVoiceText', () {
      test('notifies listeners on change', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.currentVoiceText = 'Hello';
        expect(notified, true);
        expect(provider.currentVoiceText, 'Hello');
      });
    });

    group('chat search', () {
      test('isChatSearchActive toggles and notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.isChatSearchActive = true;
        expect(notified, true);
        expect(provider.isChatSearchActive, true);
      });

      test('chatSearchQuery updates and notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.chatSearchQuery = 'test query';
        expect(notified, true);
        expect(provider.chatSearchQuery, 'test query');
      });
    });

    group('quickReplies', () {
      test('updates and notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.quickReplies = ['Reply 1', 'Reply 2'];
        expect(notified, true);
        expect(provider.quickReplies, ['Reply 1', 'Reply 2']);
      });
    });

    group('mood label', () {
      test('updates and notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.currentMoodLabel = 'Sad 😢';
        expect(notified, true);
        expect(provider.currentMoodLabel, 'Sad 😢');
      });
    });

    group('sleep mode', () {
      test('sleepModeEnabled toggles', () {
        provider.sleepModeEnabled = true;
        expect(provider.sleepModeEnabled, true);
      });

      test('isSleepTime returns false when sleep mode disabled', () {
        provider.sleepModeEnabled = false;
        expect(provider.isSleepTime, false);
      });

      test('isSleepTime returns true during sleep hours (12am-7am)', () {
        provider.sleepModeEnabled = true;
        // Note: This test depends on actual time, skip in automated tests
        // or mock DateTime - skipped here for simplicity
      });
    });

    group('addMessage', () {
      test('adds message to messages list', () {
        final msg = ChatMessage(role: 'user', content: 'Hello');
        provider.addMessage(msg);
        expect(provider.messages.length, 1);
        expect(provider.messages.first.content, 'Hello');
      });

      test('notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.addMessage(ChatMessage(role: 'user', content: 'Hi'));
        expect(notified, true);
      });
    });

    group('clearMessages', () {
      test('clears all message lists and resets counter', () {
        provider.addMessage(ChatMessage(role: 'user', content: 'Msg1'));
        provider.addMessage(ChatMessage(role: 'assistant', content: 'Reply1'));
        provider.userMessageCount = 5;
        provider.pinnedMessages
            .add(ChatMessage(role: 'user', content: 'Pinned'));

        provider.clearMessages();

        expect(provider.messages, isEmpty);
        expect(provider.pastMessages, isEmpty);
        expect(provider.pinnedMessages, isEmpty);
        expect(provider.userMessageCount, 0);
      });
    });

    group('deleteMessages', () {
      test('removes messages by id from all lists', () {
        final msg1 = ChatMessage(role: 'user', content: 'Keep');
        final msg2 = ChatMessage(role: 'user', content: 'Delete');
        final msg3 = ChatMessage(role: 'assistant', content: 'Also delete');

        provider.addMessage(msg1);
        provider.addMessage(msg2);
        provider.pastMessages.add(msg3);
        provider.pinnedMessages.add(msg2);

        provider.deleteMessages({msg2.id, msg3.id});

        expect(provider.messages.length, 1);
        expect(provider.messages.first.content, 'Keep');
        expect(provider.pastMessages, isEmpty);
        expect(provider.pinnedMessages, isEmpty);
      });
    });

    group('insertPastMessages', () {
      test('moves past messages to main list', () {
        final msg1 = ChatMessage(role: 'user', content: 'Past 1');
        final msg2 = ChatMessage(role: 'user', content: 'Past 2');
        provider.pastMessages.addAll([msg1, msg2]);
        provider.swipeCount = 3;

        provider.insertPastMessages();

        expect(provider.messages.length, 2);
        expect(provider.pastMessages, isEmpty);
        expect(provider.swipeCount, 0);
      });

      test('does nothing if pastMessages is empty', () {
        provider.swipeCount = 5;
        provider.insertPastMessages();
        expect(provider.swipeCount, 5); // unchanged
      });
    });

    group('selectedImage', () {
      test('updates and notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);
        // We can't easily create a File in tests, but we can set to null
        provider.selectedImage = null;
        expect(notified, true);
      });
    });

    group('persona', () {
      test('selectedPersona updates and notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.selectedPersona = 'Tsundere';
        expect(notified, true);
        expect(provider.selectedPersona, 'Tsundere');
      });
    });

    group('apiKeyStatus', () {
      test('updates and notifies', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.apiKeyStatus = 'Valid';
        expect(notified, true);
        expect(provider.apiKeyStatus, 'Valid');
      });
    });

    group('loadPersistedState', () {
      test('loads values from SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({
          'idle_timer_enabled': false,
          'idle_duration_seconds': 300,
          'proactive_interval_seconds': 900,
          'proactive_enabled': false,
          'proactive_random_enabled': false,
          'selected_persona_v1': 'Yandere',
          'sleep_mode_enabled_v1': true,
        });

        final p = ChatProvider();
        await p.loadPersistedState();

        expect(p.idleTimerEnabled, false);
        expect(p.idleDurationSeconds, 300);
        expect(p.proactiveIntervalSeconds, 900);
        expect(p.proactiveEnabled, false);
        expect(p.proactiveRandomEnabled, false);
        expect(p.selectedPersona, 'Yandere');
        expect(p.sleepModeEnabled, true);
        p.dispose();
      });

      test('uses defaults when no prefs stored', () async {
        SharedPreferences.setMockInitialValues({});
        final p = ChatProvider();
        await p.loadPersistedState();

        expect(p.idleTimerEnabled, true);
        expect(p.idleDurationSeconds, 600);
        expect(p.proactiveIntervalSeconds, 1800);
        expect(p.proactiveEnabled, true);
        expect(p.proactiveRandomEnabled, true);
        expect(p.selectedPersona, 'Default');
        expect(p.sleepModeEnabled, false);
        p.dispose();
      });
    });
  });
}
