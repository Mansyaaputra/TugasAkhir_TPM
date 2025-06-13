import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/UserModel.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class LocalDb {
  static final instance = LocalDb._init();
  static Database? _db;
  LocalDb._init();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB('app.db');
    return _db!;
  }

  Future<Database> _initDB(String file) async {
    try {
      print('Initializing database: $file'); // Debug log
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, file);
      print('Database path: $dbPath'); // Debug log

      // Ensure the directory exists
      final directory = Directory(databasesPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Created database directory: $databasesPath');
      }
      return await openDatabase(dbPath, version: 2, onCreate: (db, v) {
        print('Creating users table with avatarUrl'); // Debug log
        return db.execute('''
            CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT UNIQUE, passwordHash TEXT, avatarUrl TEXT)
          ''');
      }, onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          print('Upgrading database to version 2');
          await db.execute('ALTER TABLE users ADD COLUMN avatarUrl TEXT');
        }
      }, onOpen: (db) {
        print('Database opened successfully');
      });
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<bool> saveUser(String u, String ph, {String? avatarUrl}) async {
    // Hanya implementasi mobile
    return await _saveUserMobile(u, ph, avatarUrl: avatarUrl);
  }

  Future<User?> getUser(String u) async {
    // Hanya implementasi mobile
    return await _getUserMobile(u);
  }

  // Session management hanya untuk mobile
  Future<bool> setCurrentUser(String username) async {
    return await _setCurrentUserMobile(username);
  }

  Future<String?> getCurrentUser() async {
    return await _getCurrentUserMobile();
  }

  Future<bool> clearCurrentUser() async {
    return await _clearCurrentUserMobile();
  }

  Future<bool> updateUser(
      String oldUsername, String newUsername, String passwordHash,
      {String? avatarUrl}) async {
    final dbClient = await db;
    final data = {
      'username': newUsername,
      'passwordHash': passwordHash,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
    final result = await dbClient.update(
      'users',
      data,
      where: 'username = ?',
      whereArgs: [oldUsername],
    );
    return result > 0;
  }

  Future<bool> deleteUser(String username) async {
    return await _deleteUserMobile(username);
  }

  // Mobile implementation using sqflite
  Future<bool> _saveUserMobile(String u, String ph, {String? avatarUrl}) async {
    try {
      print('Attempting to save user on mobile: $u'); // Debug log
      final dbClient = await db;
      print('Database connection established'); // Debug log
      final id = await dbClient.insert('users', {
        'username': u,
        'passwordHash': ph,
        'avatarUrl': avatarUrl,
      });
      print('User saved with ID: $id'); // Debug log
      return id > 0;
    } catch (e) {
      print('Error saving user on mobile: $e');
      return false;
    }
  }

  Future<User?> _getUserMobile(String u) async {
    try {
      final dbClient = await db;
      final maps =
          await dbClient.query('users', where: 'username=?', whereArgs: [u]);
      if (maps.isNotEmpty) {
        return User(
          id: maps.first['id'] as int?,
          username: maps.first['username'] as String,
          passwordHash: maps.first['passwordHash'] as String?,
          avatarUrl: maps.first['avatarUrl'] as String?,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user on mobile: $e');
      return null;
    }
  }

  // Session management for mobile
  Future<bool> _setCurrentUserMobile(String username) async {
    try {
      final dbClient = await db;
      // Create session table if not exists
      await dbClient.execute('''
        CREATE TABLE IF NOT EXISTS session(id INTEGER PRIMARY KEY, username TEXT)
      ''');

      // Clear existing session
      await dbClient.delete('session');

      // Set new session
      final id = await dbClient.insert('session', {'username': username});
      return id > 0;
    } catch (e) {
      print('Error setting current user on mobile: $e');
      return false;
    }
  }

  Future<String?> _getCurrentUserMobile() async {
    try {
      final dbClient = await db;

      // Create session table if not exists
      await dbClient.execute('''
        CREATE TABLE IF NOT EXISTS session(id INTEGER PRIMARY KEY, username TEXT)
      ''');

      final maps = await dbClient.query('session', limit: 1);
      if (maps.isNotEmpty) {
        return maps.first['username'] as String;
      }
      return null;
    } catch (e) {
      print('Error getting current user on mobile: $e');
      return null;
    }
  }

  Future<bool> _clearCurrentUserMobile() async {
    try {
      final dbClient = await db;
      await dbClient.delete('session');
      return true;
    } catch (e) {
      print('Error clearing current user on mobile: $e');
      return false;
    }
  }

  Future<bool> _updateUserMobile(
      String oldUsername, String newUsername, String newPasswordHash,
      {String? avatarUrl}) async {
    try {
      final dbClient = await db;

      // Check if old user exists
      final oldUser = await _getUserMobile(oldUsername);
      if (oldUser == null) {
        return false;
      }
      // Prepare update data
      final updateData = <String, dynamic>{
        'username': newUsername,
        'passwordHash': newPasswordHash,
      };

      // Include avatarUrl if provided, otherwise keep existing value
      if (avatarUrl != null) {
        updateData['avatarUrl'] = avatarUrl;
      } else if (oldUser.avatarUrl != null) {
        updateData['avatarUrl'] = oldUser.avatarUrl!;
      }

      // Update user data
      final result = await dbClient.update(
        'users',
        updateData,
        where: 'username = ?',
        whereArgs: [oldUsername],
      );

      // Update session if it was the updated user
      final currentUser = await _getCurrentUserMobile();
      if (currentUser == oldUsername) {
        await _setCurrentUserMobile(newUsername);
      }

      return result > 0;
    } catch (e) {
      print('Error updating user on mobile: $e');
      return false;
    }
  }

  Future<bool> _deleteUserMobile(String username) async {
    try {
      final dbClient = await db;

      // Delete user
      final result = await dbClient.delete(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      // Clear session if it was the deleted user
      final currentUser = await _getCurrentUserMobile();
      if (currentUser == username) {
        await _clearCurrentUserMobile();
      }

      return result > 0;
    } catch (e) {
      print('Error deleting user on mobile: $e');
      return false;
    }
  }
}
