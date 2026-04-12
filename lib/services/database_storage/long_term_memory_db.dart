import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LongTermMemoryDb {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'zerotwo_memory.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create an FTS5 virtual table for extremely fast, efficient sentence-level keyword matching
        await db.execute('''
          CREATE VIRTUAL TABLE memories USING fts5(
            fact,
            timestamp UNINDEXED
          )
        ''');
      },
    );
  }

  /// Silent background processor that analyzes the conversation for permanent facts
  static Future<void> extractAndSave(String userMessage, String aiResponse) async {
    try {
      await dotenv.load();
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) return;

      final prompt = """
Analyze the following conversation turn between a User and their AI companion.
Did the User explicitly state any NEW, distinct, permanent personal facts about themselves, their life, their preferences, their history, or their relationships?
For example: "My dog is named Rufus", "I live in Texas", "I hate broccoli", "I have an interview next Tuesday".

If YES: Output EXACTLY ONE concise sentence summarizing the fact from a third-person perspective (e.g. "The user's dog is named Rufus.").
If NO: Output EXACTLY the word "NONE" with no punctuation.

User: $userMessage
AI: $aiResponse
""";

      final resp = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3-8b-8192', // Use a smaller, faster model for background extraction
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
          'max_tokens': 50,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final result = data['choices'][0]['message']['content'].toString().trim();
        
        if (result != 'NONE' && result.isNotEmpty && !result.toLowerCase().startsWith('none')) {
          final db = await database;
          await db.insert('memories', {
            'fact': result,
            'timestamp': DateTime.now().toIso8601String(),
          });
          debugPrint('[MemoryVault] Saved permanent fact: $result');
        }
      }
    } catch (e) {
      debugPrint('[MemoryVault] Failed to extract facts: $e');
    }
  }

  /// Queries the database for stored facts matching the current discussion
  static Future<List<String>> getRelevantContext(String userMessage) async {
    try {
      final db = await database;
      
      // Clean query string for FTS matching (remove punctuation, keep > 3 chars)
      final words = userMessage.replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .where((w) => w.length > 3)
          .toList();
      
      if (words.isEmpty) return [];

      // Create an OR search query: "word1 OR word2 OR word3*"
      final ftsQuery = words.map((w) => '$w*').join(' OR ');

      final results = await db.query(
        'memories',
        where: 'memories MATCH ?',
        whereArgs: [ftsQuery],
        limit: 5,
      );

      return results.map((e) => e['fact'] as String).toList();
    } catch (e) {
      debugPrint('[MemoryVault] Query error: $e');
      return [];
    }
  }

  /// Retrieve all memories (Useful for a UI dump)
  static Future<List<Map<String, dynamic>>> getAllMemories() async {
    final db = await database;
    return await db.query('memories', orderBy: 'timestamp DESC');
  }

  /// Clear a specific memory
  static Future<void> deleteMemory(String fact) async {
    final db = await database;
    await db.delete('memories', where: 'fact = ?', whereArgs: [fact]);
  }

  static Future<void> insertMemory(String fact, String timestamp) async {
    final db = await database;
    await db.insert('memories', {'fact': fact, 'timestamp': timestamp});
  }
}


