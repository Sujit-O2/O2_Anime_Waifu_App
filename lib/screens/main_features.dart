part of '../main.dart';

extension _MainFeaturesExtension on _ChatHomePageState {
  // ── Chat Export ──────────────────────────────────────────────────────────────
  Future<String> _exportChatToFile() async {
    try {
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fname =
          's002_chat_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.txt';
      final file = File('${dir.path}/$fname');

      final buffer = StringBuffer();
      buffer.writeln('S-002 AI Assistant — Chat Export');
      buffer.writeln('Exported: ${now.toString().substring(0, 16)}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final msg in _messages) {
        final role = msg.role == 'user' ? 'You' : 'S-002';
        final ts =
            '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';
        buffer.writeln('[$ts] $role:');
        buffer.writeln(msg.content);
        if (msg.imagePath != null) buffer.writeln('[Image: ${msg.imagePath}]');
        buffer.writeln();
      }

      await file.writeAsString(buffer.toString());
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'S-002 Chat Export',
      );
      return 'Chat exported! 📄 ${_messages.length} messages saved, Darling~';
    } catch (e) {
      return 'Export failed: $e';
    }
  }

  // ── Conversation Summary ─────────────────────────────────────────────────────
  Future<String> _summarizeConversation() async {
    try {
      final msgs = _messages.where((m) => m.content.isNotEmpty).toList();
      final recent = msgs.length > 30 ? msgs.sublist(msgs.length - 30) : msgs;
      if (recent.length < 3) {
        return 'Not enough conversation to summarize yet, Darling!';
      }
      final transcript = recent.map((m) {
        final roleLabel = m.role == 'user' ? 'User' : 'Zero Two';
        return '$roleLabel: ${m.content}';
      }).join('\n');
      final summaryPayload = [
        {
          'role': 'system',
          'content':
              'You are Zero Two. Summarize the following conversation in 2–3 compact sentences, speaking in first person as Zero Two.',
        },
        {
          'role': 'user',
          'content': transcript,
        }
      ];
      final summary = await _apiService.sendConversation(summaryPayload);
      return summary.isNotEmpty
          ? '📋 **Summary:**\n$summary'
          : 'I couldn\'t summarize that, Darling. Try again?';
    } catch (e) {
      return 'Summary failed, Darling: $e';
    }
  }
}
