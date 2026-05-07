import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class TokenStorage {
  static const _kKey = 'brainthink_session_token';
  final _store = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> readToken() => _store.read(key: _kKey);
  Future<void> writeToken(String token) => _store.write(key: _kKey, value: token);
  Future<void> clear() => _store.delete(key: _kKey);
}
