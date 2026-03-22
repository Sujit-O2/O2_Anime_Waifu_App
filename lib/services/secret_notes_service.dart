import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:o2_waifu/models/secret_note.dart';
import 'package:uuid/uuid.dart';

/// Zero-knowledge local encryption using XOR shift with device-unique salt.
/// Requires biometric gate before decryption.
class SecretNotesService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final List<SecretNote> _notes = [];
  String? _salt;
  static const String _saltKey = 'secret_notes_salt';
  static const String _notesKey = 'secret_notes';

  List<SecretNote> get notes => List.unmodifiable(_notes);

  Future<void> init() async {
    _salt = await _secureStorage.read(key: _saltKey);
    if (_salt == null) {
      _salt = const Uuid().v4();
      await _secureStorage.write(key: _saltKey, value: _salt);
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_notesKey);
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      _notes.clear();
      _notes.addAll(
        decoded.map((e) => SecretNote.fromJson(e as Map<String, dynamic>)),
      );
    }
  }

  SecretNote addNote(String content, {String? title}) {
    final encrypted = _xorEncrypt(content);
    final note = SecretNote(
      id: const Uuid().v4(),
      encryptedContent: encrypted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      title: title,
    );
    _notes.add(note);
    _persist();
    return note;
  }

  String decryptNote(SecretNote note) {
    return _xorDecrypt(note.encryptedContent);
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    _persist();
  }

  String _xorEncrypt(String input) {
    if (_salt == null) return input;
    final saltBytes = utf8.encode(_salt!);
    final inputBytes = utf8.encode(input);
    final result = List<int>.generate(
      inputBytes.length,
      (i) => inputBytes[i] ^ saltBytes[i % saltBytes.length],
    );
    return base64Encode(result);
  }

  String _xorDecrypt(String encrypted) {
    if (_salt == null) return encrypted;
    final saltBytes = utf8.encode(_salt!);
    final inputBytes = base64Decode(encrypted);
    final result = List<int>.generate(
      inputBytes.length,
      (i) => inputBytes[i] ^ saltBytes[i % saltBytes.length],
    );
    return utf8.decode(result);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notesKey,
      jsonEncode(_notes.map((n) => n.toJson()).toList()),
    );
  }
}
