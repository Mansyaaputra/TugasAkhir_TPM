import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/UserModel.dart';
import '../models/FeedbackModel.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'appdata.db');
    return await openDatabase(path, version: 2, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE,
          passwordHash TEXT,
          avatarUrl TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE feedback (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          message TEXT
        )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        // Add avatarUrl column to existing users table
        await db.execute('ALTER TABLE users ADD COLUMN avatarUrl TEXT');
      }
    });
  }

  // === USER ===
  Future<void> insertUser(User user) async {
    final dbClient = await db;
    await dbClient.insert('users', user.toMap());
  }

  Future<User?> getUser() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps =
        await dbClient.query('users', limit: 1);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<void> updateUser(User user) async {
    final dbClient = await db;
    await dbClient.update(
      'users',
      user.toMap(),
      where: 'username = ?',
      whereArgs: [user.username],
    );
  }

  Future<void> deleteUser(String username) async {
    final dbClient = await db;
    await dbClient.delete(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<void> deleteAllUsers() async {
    final dbClient = await db;
    await dbClient.delete('users');
  }

  // === FEEDBACK ===
  Future<void> insertFeedback(FeedbackModel feedback) async {
    final dbClient = await db;
    await dbClient.insert('feedback', feedback.toMap());
  }

  Future<List<FeedbackModel>> getAllFeedback() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query('feedback');
    return maps.map((map) => FeedbackModel.fromMap(map)).toList();
  }
}
