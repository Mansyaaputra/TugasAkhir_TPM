import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'NotificationService.dart';

// Conditional imports
import 'Local_db_mobile.dart' if (dart.library.html) 'Local_db_web.dart' as db;

class AuthService {
  // Use platform-specific database implementation
  final _localDb = db.LocalDb.instance;

  Future<bool> register(String username, String password,
      {String? avatarUrl}) async {
    try {
      print('AuthService: Starting registration for username: $username');
      final hash = sha256.convert(utf8.encode(password)).toString();
      print('AuthService: Password hashed successfully');
      final result =
          await _localDb.saveUser(username, hash, avatarUrl: avatarUrl);
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
      final user = await _localDb.getUser(username);

      if (user != null && user.passwordHash == hash) {
        // Set current user session
        await _localDb.setCurrentUser(username);
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
      // Clear session saat logout
      bool success = await _localDb.clearCurrentUser();

      // Stop notifications saat logout
      NotificationService.stopPeriodicNotifications();

      print('Logout result: $success');
      return success;
    } catch (e) {
      print('Error in logout: $e');
      return false;
    }
  }

  Future<String?> getCurrentUser() async {
    try {
      return await _localDb.getCurrentUser();
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
      return await _localDb.updateUser(oldUsername, newUsername, hash,
          avatarUrl: avatarUrl);
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> updateUserWithoutPassword(String oldUsername, String newUsername,
      {String? avatarUrl}) async {
    try {
      // Get current user to keep existing password
      final currentUser = await _localDb.getUser(oldUsername);
      if (currentUser == null || currentUser.passwordHash == null) return false;

      return await _localDb.updateUser(
          oldUsername, newUsername, currentUser.passwordHash!,
          avatarUrl: avatarUrl);
    } catch (e) {
      print('Error updating user without password: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String username) async {
    try {
      return await _localDb.deleteUser(username);
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
