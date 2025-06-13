import 'dart:convert';

class User {
  final int? id;
  final String username;
  final String? avatarUrl;
  String? passwordHash;

  User({this.id, required this.username, this.avatarUrl, this.passwordHash});

  // Method untuk set password dengan hashing sederhana
  void setPassword(String password) {
    // Simple hash (dalam implementasi nyata, gunakan bcrypt atau algoritma yang lebih aman)
    passwordHash = _simpleHash(password);
  }

  // Simple hash function untuk demo
  String _simpleHash(String input) {
    var bytes = utf8.encode(input);
    var digest = bytes.fold(0, (prev, element) => prev + element);
    return digest.toString();
  }

  // Method untuk verifikasi password
  bool verifyPassword(String password) {
    return passwordHash == _simpleHash(password);
  }

  // Method untuk membuat salinan user dengan data yang diperbarui
  User copyWith({
    int? id,
    String? username,
    String? avatarUrl,
    String? passwordHash,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'avatarUrl': avatarUrl,
        'passwordHash': passwordHash,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        username: map['username'],
        avatarUrl: map['avatarUrl'],
        passwordHash: map['passwordHash'],
      );

  factory User.fromDb(Map<String, dynamic> map) => User(
        id: map['id'],
        username: map['username'],
        avatarUrl: map['avatarUrl'], // tambahkan ini!
        passwordHash: map['passwordHash'],
      );
}
