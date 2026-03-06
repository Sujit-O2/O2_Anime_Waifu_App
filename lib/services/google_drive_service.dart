import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  static const String _backupFileName = 'zero_two_backup.json';

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;

      final auth = await _currentUser!.authentication;
      final authHeaders = {
        'Authorization': 'Bearer ${auth.accessToken}',
        'X-Goog-AuthUser': '0',
      };

      final authClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authClient);

      return true;
    } catch (e) {
      debugPrint('Google Drive Sign-In Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  bool get isSignedIn => _currentUser != null;

  Future<String?> _getExistingBackupFileId() async {
    if (_driveApi == null) return null;
    try {
      final fileList = await _driveApi!.files.list(
        q: "name = '$_backupFileName' and trashed = false",
        spaces: 'drive',
      );
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
    } catch (e) {
      debugPrint('Error finding backup file: $e');
    }
    return null;
  }

  Future<bool> backupData() async {
    if (!isSignedIn) {
      final success = await signIn();
      if (!success) return false;
    }

    try {
      // 1. Gather all data to backup
      final prefs = await SharedPreferences.getInstance();

      // We will export SharedPreferences keys that start with "note_" for Secret Notes
      final Map<String, dynamic> backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'notes': {},
        'settings': {
          'wake_word_enabled': prefs.getBool('wake_word_enabled') ?? true,
          'selected_persona_v1':
              prefs.getString('selected_persona_v1') ?? 'Zero Two',
          'app_theme_index': prefs.getInt('app_theme_index') ?? 0,
        }
      };

      for (String key in prefs.getKeys()) {
        if (key.startsWith('note_')) {
          backupData['notes'][key] = prefs.getString(key);
        }
      }

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Write to temporary local file
      final dir = await getTemporaryDirectory();
      final localFile = File('${dir.path}/$_backupFileName');
      await localFile.writeAsString(jsonString);

      // 2. Upload to Drive
      final driveFile = drive.File()..name = _backupFileName;
      final existingFileId = await _getExistingBackupFileId();

      final media = drive.Media(localFile.openRead(), localFile.lengthSync());

      if (existingFileId != null) {
        // Update existing
        await _driveApi!.files
            .update(driveFile, existingFileId, uploadMedia: media);
      } else {
        // Create new
        await _driveApi!.files.create(driveFile, uploadMedia: media);
      }

      return true;
    } catch (e) {
      debugPrint('Backup Error: $e');
      return false;
    }
  }

  Future<bool> restoreData() async {
    if (!isSignedIn) {
      final success = await signIn();
      if (!success) return false;
    }

    try {
      final existingFileId = await _getExistingBackupFileId();
      if (existingFileId == null) {
        debugPrint('No backup file found to restore.');
        return false;
      }

      // Just to verify metadata exists
      await _driveApi!.files
          .get(existingFileId, downloadOptions: drive.DownloadOptions.metadata);

      final mediaResponse = await _driveApi!.files.get(existingFileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      // Read downloaded data
      final dir = await getTemporaryDirectory();
      final localFile = File('${dir.path}/downloaded_backup.json');

      final bytes = <int>[];
      await mediaResponse.stream.forEach((chunk) {
        bytes.addAll(chunk);
      });
      await localFile.writeAsBytes(bytes);

      final jsonString = await localFile.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Restore to SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      if (backupData.containsKey('notes')) {
        final notes = backupData['notes'] as Map<String, dynamic>;
        for (var entry in notes.entries) {
          await prefs.setString(entry.key, entry.value.toString());
        }
      }

      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        if (settings.containsKey('wake_word_enabled')) {
          await prefs.setBool(
              'wake_word_enabled', settings['wake_word_enabled'] as bool);
        }
        if (settings.containsKey('selected_persona_v1')) {
          await prefs.setString(
              'selected_persona_v1', settings['selected_persona_v1'] as String);
        }
        if (settings.containsKey('app_theme_index')) {
          await prefs.setInt(
              'app_theme_index', settings['app_theme_index'] as int);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Restore Error: $e');
      return false;
    }
  }
}
