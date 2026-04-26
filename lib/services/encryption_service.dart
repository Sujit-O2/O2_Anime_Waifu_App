import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Encryption Service - Encrypt sensitive data (API keys, user info, etc.)
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _magicKey = 'ZeroTwo_Encryption_Service_2026';

  /// Encrypt data using simple XOR + SHA256 hashing
  String encryptData(String plainText, {String? customKey}) {
    if (plainText.isEmpty) return '';
    try {
      final key = customKey ?? _magicKey;
      if (key.isEmpty) return plainText;
      final keyBytes = utf8.encode(key);
      final textBytes = utf8.encode(plainText);
      
      // Simple XOR encryption
      final encrypted = <int>[];
      for (int i = 0; i < textBytes.length; i++) {
        encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      // Add timestamp for uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final timestampBytes = utf8.encode(timestamp);
      
      // Combine encrypted data + timestamp
      final combined = [...encrypted, ...timestampBytes];
      
      // Convert to base64
      return base64Encode(combined);
    } catch (e) {
      if (kDebugMode) debugPrint('Encryption error: $e');
      return plainText;
    }
  }

  /// Decrypt data
  String decryptData(String encryptedText, {String? customKey}) {
    try {
      final key = customKey ?? _magicKey;
      final keyBytes = utf8.encode(key);
      
      // Decode from base64
      final combined = base64Decode(encryptedText);
      
      // Extract encrypted data (remove timestamp)
      // Epoch ms is currently 13 digits, will become 14 in ~2286.
      // Use a safe detection: timestamp is always at the end and is ASCII digits (0x30-0x39).
      int timestampLen = 0;
      for (int i = combined.length - 1; i >= 0 && i >= combined.length - 15; i--) {
        if (combined[i] >= 0x30 && combined[i] <= 0x39) {
          timestampLen++;
        } else {
          break;
        }
      }
      if (timestampLen == 0 || combined.length <= timestampLen) return '';
      final encryptedBytes = combined.sublist(0, combined.length - timestampLen);
      
      // XOR decryption
      final decrypted = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      if (kDebugMode) debugPrint('Decryption error: $e');
      return '';
    }
  }

  /// Hash sensitive data (one-way encryption)
  String hashData(String data) {
    try {
      final hash = sha256.convert(utf8.encode(data + _magicKey));
      return hash.toString();
    } catch (e) {
      if (kDebugMode) debugPrint('Hash error: $e');
      return '';
    }
  }

  /// Verify hashed data
  bool verifyHashedData(String plainText, String hash) {
    try {
      final computedHash = hashData(plainText);
      return computedHash == hash;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error verifying hash: $e');
      return false;
    }
  }

  /// Encrypt API key
  String encryptApiKey(String apiKey) {
    return encryptData(apiKey, customKey: 'api_key_$_magicKey');
  }

  /// Decrypt API key
  String decryptApiKey(String encryptedKey) {
    return decryptData(encryptedKey, customKey: 'api_key_$_magicKey');
  }

  /// Encrypt user email
  String encryptEmail(String email) {
    return encryptData(email, customKey: 'email_$_magicKey');
  }

  /// Decrypt user email
  String decryptEmail(String encryptedEmail) {
    return decryptData(encryptedEmail, customKey: 'email_$_magicKey');
  }

  /// Encrypt password
  String encryptPassword(String password) {
    return encryptData(password, customKey: 'pwd_$_magicKey');
  }

  /// Create password hash (for verification)
  String createPasswordHash(String password) {
    return hashData(password);
  }

  /// Verify password
  bool verifyPassword(String plainPassword, String hashedPassword) {
    return verifyHashedData(plainPassword, hashedPassword);
  }

  /// Generate secure token
  String generateSecureToken({int length = 32}) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final random = DateTime.now().microsecond.toString();
      final combined = timestamp + random + _magicKey;
      final hash = sha256.convert(utf8.encode(combined));
      return hash.toString().substring(0, length);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error generating token: $e');
      return '';
    }
  }
}

/// Global instance
final encryptionService = EncryptionService();
