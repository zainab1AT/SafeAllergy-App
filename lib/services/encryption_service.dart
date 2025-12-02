import 'package:encrypt/encrypt.dart';

class EncryptionService {
  EncryptionService._();

  static final EncryptionService _instance = EncryptionService._();
  static EncryptionService get instance => _instance;
  Future<String> encrypt(String data) async {
    try {
      final key = await _getOrCreateKey();
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key));
      final encrypted = encrypter.encrypt(data, iv: iv);

      final combined = '${iv.base64}:${encrypted.base64}';
      return combined;
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  Future<String> decrypt(String encryptedData) async {
    try {
      final key = await _getOrCreateKey();
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw EncryptionException('Invalid encrypted data format');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(key));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  Future<Key> _getOrCreateKey() async {
    const sharedKeyString = '32charslongsecretkey1234567890!!';
    return Key.fromUtf8(sharedKeyString);
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
