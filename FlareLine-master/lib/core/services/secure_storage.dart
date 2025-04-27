
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// un service pour gérer le stockage sécurisé des tokens
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

Future<void> saveTokens({
  required String accessToken,
  required String refreshToken,
}) async {
  const timestamp = '2025-02-13 22:35:23';
  print('[$timestamp] 💾 Starting token save operation'
        '\n└─ Access Token length: ${accessToken.length}'
        '\n└─ Refresh Token length: ${refreshToken.length}');

  try {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken).then((_) {
        print('[$timestamp] ✅ Access token saved successfully'
              '\n└─ Key: $_accessTokenKey'
              '\n└─ Token Preview: ${accessToken.substring(0, min(10, accessToken.length))}...');
      }),
      _storage.write(key: _refreshTokenKey, value: refreshToken).then((_) {
        print('[$timestamp] ✅ Refresh token saved successfully'
              '\n└─ Key: $_refreshTokenKey'
              '\n└─ Token Preview: ${refreshToken.substring(0, min(10, refreshToken.length))}...');
      }),
    ]);

    print('[$timestamp] 🎉 All tokens saved successfully'
          '\n└─ Saved tokens:'
          '\n   ├─ Access Token: ${_accessTokenKey}'
          '\n   └─ Refresh Token: ${_refreshTokenKey}');

  } catch (e) {
    print('[$timestamp] ❌ Failed to save tokens'
          '\n└─ Error: $e');
    throw Exception('Échec de la sauvegarde des tokens: $e');
  }
}


  Future<String?> getAccessToken() async {
    final timestamp = '2025-02-13 22:30:12';
    print('[$timestamp] 🔐 Attempting to retrieve access token');

    try {
      final token = await _storage.read(key: 'access_token');
      
      print('[$timestamp] 🔑 Access token retrieval result'
            '\n└─ Token exists: ${token != null}'
            '\n└─ Token length: ${token?.length ?? 0}');

      return token;
    } catch (e) {
      print('[$timestamp] ❌ Failed to retrieve access token'
            '\n└─ Error: $e');
      return null;
    }
  }


  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }


    Future<void> write({
    required String key,
    required String value,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] 💾 Writing to secure storage'
          '\n└─ Key: $key'
          '\n└─ Value length: ${value.length}');

    try {
      await _storage.write(key: key, value: value);
      print('[$timestamp] ✅ Data saved successfully'
            '\n└─ Key: $key');
    } catch (e) {
      print('[$timestamp] ❌ Failed to write data'
            '\n└─ Key: $key'
            '\n└─ Error: $e');
      throw Exception('Failed to write data: $e');
    }
  }

Future<String?> read({required String key}) async {
    final timestamp = '2025-03-09 10:35:22';
    print('[$timestamp] 🔐 Attempting to read data'
          '\n└─ Key: $key');

    try {
      final value = await _storage.read(key: key);
      
      print('[$timestamp] 🔑 Data retrieval result'
            '\n└─ Key: $key'
            '\n└─ Data exists: ${value != null}');

      return value;
    } catch (e) {
      print('[$timestamp] ❌ Failed to read data'
            '\n└─ Key: $key'
            '\n└─ Error: $e');
      return null;
    }
  }
  
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
  
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }
  
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
  
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

}