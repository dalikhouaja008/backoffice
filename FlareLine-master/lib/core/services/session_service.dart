import 'dart:convert';
import 'package:flareline/domain/entities/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service responsible for managing user sessions
class SessionService {
  static const String _userKey = 'current_user';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Save the user session data
  Future<void> saveSession({
    required User user,
    required String accessToken,
    required String refreshToken,
  }) async {
    print('[${DateTime.now()}] 💾 SessionService: Saving user session'
          '\n└─ User: ${user.username}'
          '\n└─ Email: ${user.email}');
    
    // Convert user object to JSON string
    final userJson = jsonEncode({
      '_id': user.id,
      'username': user.username,
      'email': user.email,
      'role': user.role,
      'twoFactorSecret': user.twoFactorSecret,
      'isTwoFactorEnabled': user.isTwoFactorEnabled,
      'createdAt': user.createdAt.toIso8601String(),
      'updatedAt': user.updatedAt.toIso8601String(),
    });
    
    // Save everything to secure storage
    await Future.wait([
      _storage.write(key: _userKey, value: userJson),
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
    
    print('[${DateTime.now()}] ✅ SessionService: Session saved successfully');
  }

  /// Get the stored user session
  Future<SessionData?> getSession() async {
    try {
      print('[${DateTime.now()}] 🔍 SessionService: Retrieving session');
      
      // Get all session data
      final userJson = await _storage.read(key: _userKey);
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      
      // Check if we have all required session data
      if (userJson == null || accessToken == null || refreshToken == null) {
        print('[${DateTime.now()}] ℹ️ SessionService: No session found');
        return null;
      }
      
      // Parse user object
      final userData = jsonDecode(userJson);
      final user = User(
        id: userData['_id'],
        username: userData['username'],
        email: userData['email'],
        role: userData['role'],
        twoFactorSecret: userData['twoFactorSecret'],
        isTwoFactorEnabled: userData['isTwoFactorEnabled'] ?? false,
        createdAt: DateTime.parse(userData['createdAt']),
        updatedAt: DateTime.parse(userData['updatedAt']),
      );
      
      print('[${DateTime.now()}] ✅ SessionService: Session retrieved successfully'
            '\n└─ User: ${user.username}'
            '\n└─ Email: ${user.email}');
      
      return SessionData(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (e) {
      print('[${DateTime.now()}] ❌ SessionService: Error retrieving session'
            '\n└─ Error: $e');
      return null;
    }
  }

  /// Clear the user session (logout)
  Future<void> clearSession() async {
    print('[${DateTime.now()}] 🧹 SessionService: Clearing user session');
    
    await Future.wait([
      _storage.delete(key: _userKey),
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
    
    print('[${DateTime.now()}] ✅ SessionService: Session cleared successfully');
  }
}

/// Data class to hold session information
class SessionData {
  final User user;
  final String accessToken;
  final String refreshToken;
  
  SessionData({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}