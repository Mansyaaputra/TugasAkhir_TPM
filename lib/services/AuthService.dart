import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'Local_db_new.dart'; // Using the new platform-aware version

class AuthService {
  Future<bool> register(String username, String password,
      {String? avatarUrl}) async {
    try {
      print('AuthService: Starting registration for username: $username');
      final hash = sha256.convert(utf8.encode(password)).toString();
      print('AuthService: Password hashed successfully');
      final result =
          await LocalDb.instance.saveUser(username, hash, avatarUrl: avatarUrl);
      print('AuthService: Registration result: $result');
      return result;
    } catch (e) {
      print('Error in register: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final hash = sha256.convert(utf8.encode(password)).toString();
      final user = await LocalDb.instance.getUser(username);

      if (user != null && user.passwordHash == hash) {
        // Set current user session
        await LocalDb.instance.setCurrentUser(username);
        return true;
      }
      return false;
    } catch (e) {
      print('Error in login: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      return await LocalDb.instance.clearCurrentUser();
    } catch (e) {
      print('Error in logout: $e');
      return false;
    }
  }

  Future<String?> getCurrentUser() async {
    try {
      return await LocalDb.instance.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<bool> updateUser(
      String oldUsername, String newUsername, String newPassword,
      {String? avatarUrl}) async {
    try {
      final hash = sha256.convert(utf8.encode(newPassword)).toString();
      return await LocalDb.instance
          .updateUser(oldUsername, newUsername, hash, avatarUrl: avatarUrl);
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> updateUserWithoutPassword(String oldUsername, String newUsername,
      {String? avatarUrl}) async {
    try {
      // Get current user to keep existing password
      final currentUser = await LocalDb.instance.getUser(oldUsername);
      if (currentUser == null || currentUser.passwordHash == null) return false;

      return await LocalDb.instance.updateUser(
          oldUsername, newUsername, currentUser.passwordHash!,
          avatarUrl: avatarUrl);
    } catch (e) {
      print('Error updating user without password: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String username) async {
    try {
      return await LocalDb.instance.deleteUser(username);
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
