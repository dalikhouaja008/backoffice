import 'dart:convert';

class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? twoFactorSecret;
  final bool isTwoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.twoFactorSecret,
    this.isTwoFactorEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Ajout de la méthode fromJson
factory User.fromJson(Map<String, dynamic> json) {
  print('[2025-02-13 20:50:39] 🔄 Parsing User from JSON:'
        '\n${const JsonEncoder.withIndent('  ').convert(json)}');
        
  try {

    return User(
      // Utiliser '_id' au lieu de 'id' car c'est le format renvoyé par le backend
      id: json['_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      twoFactorSecret: json['twoFactorSecret'] as String?,
      isTwoFactorEnabled: json['isTwoFactorEnabled'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  } catch (e) {
    print('[2025-02-13 20:50:39] ❌ Error parsing User from JSON:'
          '\n└─ Error: $e'
          '\n└─ JSON: ${json.toString()}');
    rethrow;
  }
}

  // Ajout de la méthode toJson
// Mettre à jour toJson pour correspondre
Map<String, dynamic> toJson() {
  final Map<String, dynamic> data = {
    '_id': id,  // Utiliser '_id' pour être cohérent
    'username': username,
    'email': email,
    'role': role,
    'twoFactorSecret': twoFactorSecret,
    'isTwoFactorEnabled': isTwoFactorEnabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  
  return data;
}

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? twoFactorSecret,
    bool? isTwoFactorEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      twoFactorSecret: twoFactorSecret ?? this.twoFactorSecret,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
   
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          email == other.email &&
          role == other.role &&
          twoFactorSecret == other.twoFactorSecret &&
          isTwoFactorEnabled == other.isTwoFactorEnabled &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      email.hashCode ^
      role.hashCode ^
      twoFactorSecret.hashCode ^
      isTwoFactorEnabled.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, role: $role, '
        'isTwoFactorEnabled: $isTwoFactorEnabled, createdAt: $createdAt, '
        'updatedAt: $updatedAt}';
  }
}