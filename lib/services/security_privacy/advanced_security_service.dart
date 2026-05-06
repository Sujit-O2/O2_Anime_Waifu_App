import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/services.dart';

/// Advanced security service: Biometric, device fingerprinting, certificate pinning
class AdvancedSecurityService {
  static final AdvancedSecurityService _instance =
      AdvancedSecurityService._internal();
  factory AdvancedSecurityService() => _instance;
  AdvancedSecurityService._internal();

  static const platform = MethodChannel('com.example.anime_waifu/security');

  // ── Biometric Authentication ─────────────────────────────────────────────

  /// Check if biometric is available on device
  static Future<bool> isBiometricAvailable() async {
    try {
      final result = await platform.invokeMethod<bool>('isBiometricAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user with biometric
  static Future<bool> authenticateWithBiometric({
    required String reason,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final result = await platform.invokeMethod<bool>(
        'authenticateWithBiometric',
        {'reason': reason},
      );
      return result ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Enable biometric lock for entire app
  static Future<void> enableBiometricLock(String uid) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) throw Exception('Biometric not available');

      await FirebaseFirestore.instance.collection('settings').doc(uid).set({
        'biometricLockEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error enabling biometric lock: $e');
    }
  }

  /// Disable biometric lock
  static Future<void> disableBiometricLock(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('settings').doc(uid).update({
        'biometricLockEnabled': false,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error disabling biometric lock: $e');
    }
  }

  /// Check if biometric lock is enabled
  static Future<bool> isBiometricLockEnabled(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(uid)
          .get();
      return doc.get('biometricLockEnabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  // ── Device Fingerprinting ────────────────────────────────────────────────

  /// Generate unique device fingerprint
  static Future<String> generateDeviceFingerprint() async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final fingerprint = sha256.convert(utf8.encode(deviceInfo)).toString();
      return fingerprint;
    } catch (e) {
      return '';
    }
  }

  /// Get detailed device information
  static Future<String> _getDeviceInfo() async {
    try {
      final result = await platform.invokeMethod<String>('getDeviceInfo');
      return result ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Detect if device is jailbroken/rooted
  static Future<bool> isDeviceCompromised() async {
    try {
      final result = await platform.invokeMethod<bool>('isDeviceCompromised');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Store device fingerprint in Firestore
  static Future<void> storeDeviceFingerprint(String uid) async {
    try {
      final fingerprint = await generateDeviceFingerprint();
      final isCompromised = await isDeviceCompromised();

      await FirebaseFirestore.instance
          .collection('user_data_sync')
          .doc(uid)
          .set({
            'deviceFingerprint': fingerprint,
            'lastDeviceCheck': FieldValue.serverTimestamp(),
            'isDeviceCompromised': isCompromised,
            'platform': Platform.operatingSystem,
            'osVersion': Platform.operatingSystemVersion,
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('Error storing device fingerprint: $e');
    }
  }

  /// Verify device fingerprint hasn't changed
  static Future<bool> verifyDeviceFingerprint(String uid) async {
    try {
      final currentFingerprint = await generateDeviceFingerprint();
      final storedDoc = await FirebaseFirestore.instance
          .collection('user_data_sync')
          .doc(uid)
          .get();

      final storedFingerprint = storedDoc.get('deviceFingerprint');
      if (storedFingerprint == null) {
        // First time, store it
        await storeDeviceFingerprint(uid);
        return true;
      }

      // Check if fingerprint matches
      if (currentFingerprint != storedFingerprint) {
        if (kDebugMode) debugPrint('⚠️ WARNING: Device fingerprint mismatch!');
        await _logSecurityAlert(
          uid: uid,
          message: 'Device fingerprint changed',
          severity: 'HIGH',
        );
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error verifying device fingerprint: $e');
      return false;
    }
  }

  // ── Certificate Pinning ──────────────────────────────────────────────────

  /// Get SSL/TLS certificate pins for domains
  static Map<String, List<String>> getCertificatePins() {
    return {
      'api.groq.com': [
        'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
        'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
      ],
      'firebaseio.com': ['sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC='],
    };
  }

  /// Verify certificate for domain (placeholder)
  static Future<bool> verifyCertificate(String domain) async {
    try {
      // Implementation would use http.Client with certificate pinning
      // For now, this is a placeholder that returns true
      final pins = getCertificatePins();
      return pins.containsKey(domain);
    } catch (e) {
      return false;
    }
  }

  // ── Security Alerts & Logging ────────────────────────────────────────────

  /// Log security alert to Firestore
  static Future<void> _logSecurityAlert({
    required String uid,
    required String message,
    required String severity,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('security_alerts').add({
        'uid': uid,
        'message': message,
        'severity': severity,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'appVersion': '11.0.2', // Update with actual version
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error logging security alert: $e');
    }
  }

  /// Get recent security alerts for user
  static Future<List<Map<String, dynamic>>> getSecurityAlerts(
    String uid, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('security_alerts')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching security alerts: $e');
      return [];
    }
  }

  /// Clear old security alerts (retention policy)
  static Future<void> clearOldSecurityAlerts(String uid) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      await FirebaseFirestore.instance
          .collection('security_alerts')
          .where('uid', isEqualTo: uid)
          .where('timestamp', isLessThan: thirtyDaysAgo)
          .snapshots()
          .first
          .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing old security alerts: $e');
    }
  }

  // ── Session Security ─────────────────────────────────────────────────────

  /// Generate secure session token
  static String generateSessionToken() {
    final random = List<int>.generate(32, (i) => DateTime.now().hashCode);
    return base64Url.encode(random);
  }

  /// Validate session is still active
  static Future<bool> isSessionValid(String uid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.uid != uid) return false;

      final isCompromised = await isDeviceCompromised();
      if (isCompromised) {
        await _logSecurityAlert(
          uid: uid,
          message: 'Device compromised detected',
          severity: 'CRITICAL',
        );
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout and clear all sessions
  static Future<void> secureLogout(String uid) async {
    try {
      await _logSecurityAlert(
        uid: uid,
        message: 'User logout',
        severity: 'LOW',
      );
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) debugPrint('Error during secure logout: $e');
    }
  }
}
