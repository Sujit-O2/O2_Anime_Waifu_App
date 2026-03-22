import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_message.dart';

/// Exports the full chat history to a formatted text file and shares it.
class ChatExportService {
  static Future<void> exportToText(
    List<ChatMessage> messages, {
    String title = 'Zero Two Chat History',
  }) async {
    final buffer = StringBuffer();
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    buffer.writeln('═══════════════════════════════');
    buffer.writeln(' $title');
    buffer.writeln(' Exported: ${fmt.format(DateTime.now())}');
    buffer.writeln('═══════════════════════════════\n');

    for (final msg in messages) {
      final role = msg.role == 'assistant' ? '💕 Zero Two' : '👤 You';
      final time = fmt.format(msg.timestamp);
      buffer.writeln('[$time] $role');
      buffer.writeln(msg.content);
      buffer.writeln();
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'zerotwo_chat_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.txt';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: title,
      text: 'My chat history with Zero Two 💕',
    );
  }
}
