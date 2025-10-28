import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Encrypted storage service for wallet data
/// 
/// Features:
/// - AES-256 encryption
/// - PBKDF2 password-based key derivation
/// - Password verification without keychain
/// - Single encrypted file storage
/// - Cross-platform support
class EncryptedStorage {
  static const String _fileName = 'gold_and_silver_wallet.bin';
  static const int _saltLength = 32;
  static const int _iterations = 100000;
  static const int _keyLength = 32;

  /// Check if password/data file exists
  Future<bool> hasPassword() async {
    try {
      final file = await _getStorageFile();
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Set initial password (creates new encrypted file)
  Future<void> setPassword(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }

    // Create initial empty data with password verification
    final data = {
      'version': 1,
      'wallets': [],
      'accounts': {},
      'createdAt': DateTime.now().toIso8601String(),
    };

    await saveData(data, password);
  }

  /// Verify password by attempting to decrypt
  Future<bool> verifyPassword(String password) async {
    try {
      await loadData(password);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Change password (decrypt with old, re-encrypt with new)
  Future<void> changePassword(String oldPassword, String newPassword) async {
    // Verify old password and load data
    final data = await loadData(oldPassword);
    if (data == null) {
      throw Exception('Current password is incorrect');
    }

    // Re-encrypt with new password
    await saveData(data, newPassword);
  }

  /// Save encrypted data
  Future<void> saveData(Map<String, dynamic> data, String password) async {
    try {
      // Convert data to JSON
      final jsonString = jsonEncode(data);
      
      // Generate random salt
      final salt = _generateRandomBytes(_saltLength);
      
      // Derive key from password using PBKDF2
      final key = _deriveKey(password, salt);
      final iv = encrypt_lib.IV.fromSecureRandom(16);
      
      // Encrypt data
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      
      // File format: [salt(32)][iv(16)][encrypted_data]
      final combined = Uint8List.fromList([
        ...salt,
        ...iv.bytes,
        ...encrypted.bytes,
      ]);
      
      // Write to file
      final file = await _getStorageFile();
      await file.writeAsBytes(combined);
    } catch (e) {
      throw Exception('Failed to save data: $e');
    }
  }

  /// Load and decrypt data
  Future<Map<String, dynamic>?> loadData(String password) async {
    try {
      final file = await _getStorageFile();
      
      // Check if file exists
      if (!await file.exists()) {
        return null;
      }
      
      // Read encrypted data
      final bytes = await file.readAsBytes();
      
      // Extract salt, IV, and encrypted data
      if (bytes.length < _saltLength + 16) {
        throw Exception('Invalid encrypted data');
      }
      
      final salt = bytes.sublist(0, _saltLength);
      final iv = encrypt_lib.IV(Uint8List.fromList(bytes.sublist(_saltLength, _saltLength + 16)));
      final encryptedBytes = bytes.sublist(_saltLength + 16);
      
      // Derive key from password using PBKDF2
      final key = _deriveKey(password, salt);
      
      // Decrypt data
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.cbc));
      final encrypted = encrypt_lib.Encrypted(Uint8List.fromList(encryptedBytes));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      // Parse JSON
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load data. Wrong password or corrupted file: $e');
    }
  }

  /// Delete all data
  Future<void> deleteAll() async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  /// Get storage file path
  Future<File> _getStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Derive encryption key from password using PBKDF2
  encrypt_lib.Key _deriveKey(String password, List<int> salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(Uint8List.fromList(salt), _iterations, _keyLength));
    
    final key = derivator.process(Uint8List.fromList(utf8.encode(password)));
    return encrypt_lib.Key(key);
  }

  /// Generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = FortunaRandom();
    final seed = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch + i);
    random.seed(KeyParameter(Uint8List.fromList(seed)));
    return random.nextBytes(length);
  }

  /// Export encrypted backup (returns file content as bytes)
  Future<Uint8List?> exportBackup(String password) async {
    try {
      // Verify password first
      if (!await verifyPassword(password)) {
        throw Exception('Invalid password');
      }

      final file = await _getStorageFile();
      if (!await file.exists()) {
        return null;
      }

      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to export backup: $e');
    }
  }

  /// Import encrypted backup
  Future<void> importBackup(Uint8List backupData, String password) async {
    try {
      final file = await _getStorageFile();
      await file.writeAsBytes(backupData);

      // Try to decrypt with provided password to verify
      await loadData(password);
    } catch (e) {
      // If import fails, delete the bad file
      final file = await _getStorageFile();
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception('Failed to import backup: $e');
    }
  }
}
