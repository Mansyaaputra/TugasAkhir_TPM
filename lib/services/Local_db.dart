import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/UserModel.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

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

      return await openDatabase(dbPath, version: 1, onCreate: (db, v) {
        print('Creating users table'); // Debug log
        return db.execute('''
            CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT UNIQUE, passwordHash TEXT)
          ''');
      }, onOpen: (db) {
        print('Database opened successfully');
      });
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<bool> saveUser(String u, String ph) async {
    try {
      print('Attempting to save user: $u'); // Debug log
      final dbClient = await db;
      print('Database connection established'); // Debug log
      final id =
          await dbClient.insert('users', {'username': u, 'passwordHash': ph});
      print('User saved with ID: $id'); // Debug log
      return id > 0;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  Future<User?> getUser(String u) async {
    try {
      final dbClient = await db;
      final maps =
          await dbClient.query('users', where: 'username=?', whereArgs: [u]);
      if (maps.isNotEmpty) return User.fromDb(maps.first);
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
}
