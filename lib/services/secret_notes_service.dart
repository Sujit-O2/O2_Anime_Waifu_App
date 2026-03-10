import '../services/firestore_service.dart';

/// Secret notes service — delegates to Firestore for cloud-synced,
/// per-user, PIN-locked storage. Public API is unchanged so existing UI works.
class SecretNotesService {
  // ── PIN ────────────────────────────────────────────────────────────────────

  static Future<bool> hasPin() => FirestoreService().hasPin();

  static Future<void> setPin(String pin) => FirestoreService().setPin(pin);

  static Future<bool> verifyPin(String pin) =>
      FirestoreService().verifyPin(pin);

  static Future<void> clearPin() async {
    // Reset pin in Firestore vault by setting to null
    await FirestoreService().setPin('');
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, String>>> getAllNotes() =>
      FirestoreService().getSecretNotes();

  static Future<void> saveNote(String title, String content) =>
      FirestoreService().saveSecretNote(title, content);

  static Future<void> deleteNote(String id) =>
      FirestoreService().deleteSecretNote(id);

  static Future<void> clearAll() => FirestoreService().clearSecretNotes();
}
