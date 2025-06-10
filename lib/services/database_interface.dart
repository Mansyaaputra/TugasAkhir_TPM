// filepath: lib/services/database_interface.dart
import '../models/UserModel.dart';

abstract class DatabaseInterface {
  Future<bool> saveUser(String username, String passwordHash,
      {String? avatarUrl});
  Future<User?> getUser(String username);
  Future<bool> setCurrentUser(String username);
  Future<String?> getCurrentUser();
  Future<bool> clearCurrentUser();
  Future<bool> updateUser(
      String oldUsername, String newUsername, String newPasswordHash,
      {String? avatarUrl});
  Future<bool> deleteUser(String username);
}
