import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/UserModel.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_interface.dart';

class LocalDb implements DatabaseInterface {
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
      print('Initializing database: $file');
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, file);
      print('Database path: $dbPath');

      // Ensure the directory exists
      final directory = Directory(databasesPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Created database directory: $databasesPath');
      }

      return await openDatabase(dbPath, version: 2, onCreate: (db, v) {
        print('Creating users table with avatarUrl');
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

  @override
  Future<bool> saveUser(String u, String ph, {String? avatarUrl}) async {
    try {
      print('Attempting to save user on mobile: $u');
      final dbClient = await db;
      print('Database connection established');
      final id = await dbClient.insert(
          'users', {'username': u, 'passwordHash': ph, 'avatarUrl': avatarUrl});
      print('User saved with ID: $id');
      return id > 0;
    } catch (e) {
      print('Error saving user on mobile: $e');
      return false;
    }
  }

  @override
  Future<User?> getUser(String u) async {
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

  // Session management using SharedPreferences
  @override
  Future<bool> setCurrentUser(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString('currentUser', username);
      print(
          'Mobile: Current user set to: $username, result: $result'); // Debug log
      return result;
    } catch (e) {
      print('Error setting current user: $e');
      return false;
    }
  }

  @override
  Future<String?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('currentUser');
      print('Mobile: Current user retrieved: $user'); // Debug log
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<bool> clearCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove('currentUser');
      print('Mobile: Current user cleared, result: $result'); // Debug log
      return result;
    } catch (e) {
      print('Error clearing current user: $e');
      return false;
    }
  }

  @override
  Future<bool> updateUser(
      String oldUsername, String newUsername, String newPasswordHash,
      {String? avatarUrl}) async {
    try {
      final dbClient = await db;

      // Check if old user exists
      final oldUser = await getUser(oldUsername);
      if (oldUser == null) {
        return false;
      }

      // Update user data
      final result = await dbClient.update(
        'users',
        {
          'username': newUsername,
          'passwordHash': newPasswordHash,
          'avatarUrl': avatarUrl ?? oldUser.avatarUrl
        },
        where: 'username = ?',
        whereArgs: [oldUsername],
      );

      // Update session if it was the updated user
      final currentUser = await getCurrentUser();
      if (currentUser == oldUsername) {
        await setCurrentUser(newUsername);
      }

      return result > 0;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteUser(String username) async {
    try {
      final dbClient = await db;

      // Delete user
      final result = await dbClient.delete(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      // Clear session if it was the deleted user
      final currentUser = await getCurrentUser();
      if (currentUser == username) {
        await clearCurrentUser();
      }

      return result > 0;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
