import 'package:flutter_test/flutter_test.dart';
import 'package:anime_waifu/models/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('creates message with required fields', () {
      final msg = ChatMessage(role: 'user', content: 'Hello');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.id, isNotEmpty);
      expect(msg.timestamp, isA<DateTime>());
    });

    test('uses provided id when given', () {
      const testId = 'test-uuid-123';
      final msg = ChatMessage(id: testId, role: 'assistant', content: 'Hi');
      expect(msg.id, testId);
    });

    test('defaults isPinned and isGhost to false', () {
      final msg = ChatMessage(role: 'user', content: 'test');
      expect(msg.isPinned, false);
      expect(msg.isGhost, false);
    });

    test('sets optional fields correctly', () {
      final msg = ChatMessage(
        role: 'assistant',
        content: 'Hello',
        isPinned: true,
        isGhost: true,
        reaction: '❤️',
        imagePath: '/path/to/image.png',
        imageUrl: 'https://example.com/img.png',
        internalThought: 'thinking...',
      );
      expect(msg.isPinned, true);
      expect(msg.isGhost, true);
      expect(msg.reaction, '❤️');
      expect(msg.imagePath, '/path/to/image.png');
      expect(msg.imageUrl, 'https://example.com/img.png');
      expect(msg.internalThought, 'thinking...');
    });

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': 'msg-1',
          'role': 'user',
          'content': 'Hello World',
          'timestamp': '2024-01-15T10:30:00.000',
          'isPinned': true,
          'isGhost': true,
          'reaction': '🔥',
          'imagePath': '/img.png',
          'imageUrl': 'https://example.com/x.png',
          'internalThought': 'internal',
        };
        final msg = ChatMessage.fromJson(json);
        expect(msg.id, 'msg-1');
        expect(msg.role, 'user');
        expect(msg.content, 'Hello World');
        expect(msg.isPinned, true);
        expect(msg.isGhost, true);
        expect(msg.reaction, '🔥');
        expect(msg.imagePath, '/img.png');
        expect(msg.imageUrl, 'https://example.com/x.png');
        expect(msg.internalThought, 'internal');
      });

      test('handles missing fields with defaults', () {
        final msg = ChatMessage.fromJson({});
        expect(msg.role, 'user');
        expect(msg.content, '');
        expect(msg.isPinned, false);
        expect(msg.isGhost, false);
      });

      test('parses ISO timestamp string', () {
        final json = {
          'timestamp': '2024-06-15T12:00:00.000Z',
        };
        final msg = ChatMessage.fromJson(json);
        expect(msg.timestamp.year, 2024);
        expect(msg.timestamp.month, 6);
      });

      test('parses epoch int timestamp', () {
        final json = {
          'timestamp': 1700000000000,
        };
        final msg = ChatMessage.fromJson(json);
        expect(msg.timestamp,
            DateTime.fromMillisecondsSinceEpoch(1700000000000));
      });

      test('handles null timestamp as now', () {
        final msg = ChatMessage.fromJson({'timestamp': null});
        expect(msg.timestamp, isA<DateTime>());
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final msg = ChatMessage(
          id: 'msg-1',
          role: 'assistant',
          content: 'Hello',
          isPinned: true,
          isGhost: false,
          reaction: '❤️',
          imagePath: '/path.png',
          imageUrl: 'https://example.com',
          internalThought: 'thought',
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );
        final json = msg.toJson();
        expect(json['id'], 'msg-1');
        expect(json['role'], 'assistant');
        expect(json['content'], 'Hello');
        expect(json['isPinned'], true);
        expect(json['isGhost'], false);
        expect(json['reaction'], '❤️');
        expect(json['imagePath'], '/path.png');
        expect(json['imageUrl'], 'https://example.com');
        expect(json['internalThought'], 'thought');
        expect(json['timestamp'], '2024-01-15T10:30:00.000');
      });

      test('omits null optional fields', () {
        final msg = ChatMessage(role: 'user', content: 'test');
        final json = msg.toJson();
        expect(json.containsKey('reaction'), false);
        expect(json.containsKey('imagePath'), false);
        expect(json.containsKey('imageUrl'), false);
        expect(json.containsKey('internalThought'), false);
      });
    });

    group('toApiJson', () {
      test('includes only role and content', () {
        final msg = ChatMessage(
          role: 'user',
          content: 'Hello',
          internalThought: 'secret',
          reaction: '🔥',
        );
        final json = msg.toApiJson();
        expect(json.length, 2);
        expect(json['role'], 'user');
        expect(json['content'], 'Hello');
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        final original = ChatMessage(
          id: 'id-1',
          role: 'user',
          content: 'original',
        );
        final copy = original.copyWith(content: 'modified', isPinned: true);
        expect(copy.id, 'id-1');
        expect(copy.role, 'user');
        expect(copy.content, 'modified');
        expect(copy.isPinned, true);
      });

      test('keeps original values when not specified', () {
        final original = ChatMessage(
          role: 'assistant',
          content: 'Hello',
          isGhost: true,
        );
        final copy = original.copyWith();
        expect(copy.role, 'assistant');
        expect(copy.content, 'Hello');
        expect(copy.isGhost, true);
      });
    });

    group('sanitize', () {
      test('removes control characters', () {
        const input = 'Hello\x00\x01World\x1F';
        expect(ChatMessage.sanitize(input), 'HelloWorld');
      });

      test('preserves newlines and tabs', () {
        const input = 'Line1\nLine2\tTab';
        expect(ChatMessage.sanitize(input), input);
      });

      test('trims whitespace', () {
        expect(ChatMessage.sanitize('  hello  '), 'hello');
      });

      test('limits length', () {
        final long = 'a' * 20000;
        final result = ChatMessage.sanitize(long, maxLength: 100);
        expect(result.length, 100);
      });
    });
  });
}
