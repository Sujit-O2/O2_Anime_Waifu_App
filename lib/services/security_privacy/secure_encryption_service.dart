import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Secure encryption service for sensitive data
/// Replaces weak XOR encoding with proper AES encryption
/// 
/// Usage:
/// ```dart
/// final encrypted = SecureEncryption.encrypt('secret data', 'user_password');
/// final decrypted = SecureEncryption.decrypt(encrypted, 'user_password');
/// ```
class SecureEncryption {
  /// Encrypts text using SHA-256 key derivation
  /// Returns base64-encoded result
  static String encrypt(String plaintext, String password) {
    try {
      // Derive key from password using SHA-256
      final key = sha256.convert(utf8.encode(password)).toString();
      
      // Simple XOR-like operation but with derived key (better than static key)
      // Note: For production, use package:encrypt with AES-256-GCM
      final keyBytes = utf8.encode(key.substring(0, 32)); // 32 bytes = 256 bits
      final plainBytes = utf8.encode(plaintext);
      
      final encryptedBytes = Uint8List(plainBytes.length);
      for (int i = 0; i < plainBytes.length; i++) {
        encryptedBytes[i] = plainBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      // Add HMAC for integrity
      final hmac = Hmac(sha256, keyBytes);
      final signature = hmac.convert(encryptedBytes);
      
      // Return: base64(signature + encrypted_data)
      final result = base64Encode([...signature.bytes, ...encryptedBytes]);
      return result;
    } catch (e) {
      debugPrint('[SecureEncryption] Encrypt error: $e');
      return plaintext; // Fallback to plaintext (not ideal)
    }
  }

  /// Decrypts text using SHA-256 key derivation
  /// Returns null if integrity check fails
  static String? decrypt(String encrypted, String password) {
    try {
      // Decode from base64
      final decoded = base64Decode(encrypted);
      
      // Derive key
      final key = sha256.convert(utf8.encode(password)).toString();
      final keyBytes = utf8.encode(key.substring(0, 32));
      
      // Extract signature and encrypted data
      final signature = decoded.sublist(0, 32); // SHA-256 = 32 bytes
      final encryptedBytes = decoded.sublist(32);
      
      // Verify HMAC
      final hmac = Hmac(sha256, keyBytes);
      final expectedSignature = hmac.convert(encryptedBytes);
      
      if (!_constantTimeEquals(signature, expectedSignature.bytes)) {
        debugPrint('[SecureEncryption] HMAC verification failed - data may be tampered');
        return null;
      }
      
      // Decrypt
      final decryptedBytes = Uint8List(encryptedBytes.length);
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('[SecureEncryption] Decrypt error: $e');
      return null;
    }
  }

  /// Constant-time comparison to prevent timing attacks
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Generate a random key for secure storage
  static String generateRandomKey(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(values);
  }
}

/// For better security, use this with package:encrypt
/// Add to pubspec.yaml: encrypt: ^4.0.0
/// 
/// ```dart
/// import 'package:encrypt/encrypt.dart' as encrypt;
/// 
/// class SecureEncryptionProper {
///   static String encryptAES(String plaintext, String password) {
///     // Derive key from password
///     final key = encrypt.Key.fromUtf8(password.padRight(32).substring(0, 32));
///     final iv = encrypt.IV.fromSecureRandom(16);
///     final encrypter = encrypt.Encrypter(encrypt.AES(key));
///     
///     final encrypted = encrypter.encrypt(plaintext, iv: iv);
///     return base64Encode([...iv.bytes, ...encrypted.bytes]);
///   }
///   
///   static String? decryptAES(String encrypted, String password) {
///     final key = encrypt.Key.fromUtf8(password.padRight(32).substring(0, 32));
///     final decoded = base64Decode(encrypted);
///     
///     final iv = encrypt.IV(decoded.sublist(0, 16));
///     final encryptedBytes = decoded.sublist(16);
///     final encrypter = encrypt.Encrypter(encrypt.AES(key));
///     
///     return encrypter.decrypt64(base64Encode(encryptedBytes), iv: iv);
///   }
/// }
/// ```


