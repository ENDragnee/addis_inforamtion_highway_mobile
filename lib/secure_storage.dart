
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  Future<void> savePrivateKey(String privateKey) async {
    await _storage.write(key: 'fayda_private_key', value: privateKey);
  }

  Future<String?> getPrivateKey() async {
    return await _storage.read(key: 'fayda_private_key');
  }

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
