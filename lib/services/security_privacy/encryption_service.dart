import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

/// Encryption Service - Encrypt sensitive data (API keys, user info, etc.)
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const String _magicKey = 'ZeroTwo_Encryption_Service_2026';

  /// Encrypt data using simple XOR + SHA256 hashing
  String encryptData(String plainText, {String? customKey}) {
    try {
      final key = customKey ?? _magicKey;
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
      final encoded = base64Encode(combined);
      if (kDebugMode) debugPrint('✅ Data encrypted');
      return encoded;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error encrypting data: $e');
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
      final encryptedBytes = combined.sublist(0, combined.length - 13);
      
      // XOR decryption
      final decrypted = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      final plainText = utf8.decode(decrypted);
      if (kDebugMode) debugPrint('✅ Data decrypted');
      return plainText;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error decrypting data: $e');
      return '';
    }
  }

  /// Hash sensitive data (one-way encryption)
  String hashData(String data) {
    try {
      final hash = sha256.convert(utf8.encode(data + _magicKey));
      if (kDebugMode) debugPrint('✅ Data hashed');
      return hash.toString();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error hashing data: $e');
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


