// Google Drive service removed — all cloud storage now uses Firebase Firestore.
// This stub file is kept to avoid breaking other references.

class GoogleDriveService {
  bool get isSignedIn => false;

  Future<bool> signIn() async => false;

  Future<void> signOut() async {}

  Future<bool> backupData() async => false;

  Future<bool> restoreData() async => false;
}
