import '../models/UserModel.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'database_interface.dart';

class LocalDb implements DatabaseInterface {
  static final instance = LocalDb._init();
  LocalDb._init();

  @override
  Future<bool> saveUser(String u, String ph, {String? avatarUrl}) async {
    try {
      print('Attempting to save user on web: $u');
      final usersJson = html.window.localStorage['users'] ?? '{}';
      final users = jsonDecode(usersJson) as Map<String, dynamic>;

      if (users.containsKey(u)) {
        print('User already exists: $u');
        return false;
      }

      users[u] = {
        'passwordHash': ph,
        'avatarUrl': avatarUrl,
      };
      html.window.localStorage['users'] = jsonEncode(users);
      print('User saved on web with username: $u');
      return true;
    } catch (e) {
      print('Error saving user on web: $e');
      return false;
    }
  }

  @override
  Future<User?> getUser(String username) async {
    try {
      final usersJson = html.window.localStorage['users'] ?? '{}';
      final users = jsonDecode(usersJson) as Map<String, dynamic>;

      if (users.containsKey(username)) {
        final userData = users[username] as Map<String, dynamic>;
        return User(
          username: username,
          passwordHash: userData['passwordHash'] as String,
          avatarUrl: userData['avatarUrl'] as String?,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user on web: $e');
      return null;
    }
  }

  @override
  Future<bool> setCurrentUser(String username) async {
    try {
      html.window.localStorage['currentUser'] = username;
      print('Web: Current user set to: $username'); // Debug log
      return true;
    } catch (e) {
      print('Error setting current user on web: $e');
      return false;
    }
  }

  @override
  Future<String?> getCurrentUser() async {
    try {
      final user = html.window.localStorage['currentUser'];
      print('Web: Current user retrieved: $user'); // Debug log
      return user;
    } catch (e) {
      print('Error getting current user on web: $e');
      return null;
    }
  }

  @override
  Future<bool> clearCurrentUser() async {
    try {
      html.window.localStorage.remove('currentUser');
      print('Web: Current user cleared'); // Debug log
      return true;
    } catch (e) {
      print('Error clearing current user on web: $e');
      return false;
    }
  }

  @override
  Future<bool> updateUser(
      String oldUsername, String newUsername, String newPasswordHash,
      {String? avatarUrl}) async {
    try {
      final usersJson = html.window.localStorage['users'] ?? '{}';
      final users = jsonDecode(usersJson) as Map<String, dynamic>;

      if (!users.containsKey(oldUsername)) {
        return false;
      }

      // Get current user data
      final oldUserData = users[oldUsername] as Map<String, dynamic>;

      // Remove old user entry
      users.remove(oldUsername);

      // Add new user entry
      users[newUsername] = {
        'passwordHash': newPasswordHash,
        'avatarUrl': avatarUrl ?? oldUserData['avatarUrl'],
      };

      html.window.localStorage['users'] = jsonEncode(users);

      // Update current user if it was the updated user
      final currentUser = await getCurrentUser();
      if (currentUser == oldUsername) {
        await setCurrentUser(newUsername);
      }

      return true;
    } catch (e) {
      print('Error updating user on web: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteUser(String username) async {
    try {
      final usersJson = html.window.localStorage['users'] ?? '{}';
      final users = jsonDecode(usersJson) as Map<String, dynamic>;

      if (!users.containsKey(username)) {
        return false;
      }

      // Remove user
      users.remove(username);
      html.window.localStorage['users'] = jsonEncode(users);

      // Clear current user if it was the deleted user
      final currentUser = await getCurrentUser();
      if (currentUser == username) {
        await clearCurrentUser();
      }

      return true;
    } catch (e) {
      print('Error deleting user on web: $e');
      return false;
    }
  }
}
