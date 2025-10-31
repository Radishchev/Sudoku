import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DBHelper {
  static Database? _db;

  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), 'sudoku.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE games(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          difficulty TEXT,
          board TEXT,
          solution TEXT,
          is_fixed TEXT,
          elapsed_time INTEGER,
          completed_at TEXT
        )
      ''');
      },
    );
    return _db!;
  }

  // Insert or update a saved game
  static Future<int> saveGame({
    required String difficulty,
    required List<List<int>> board,
    required List<List<int>> solution,
    required List<List<bool>> isFixed,
    int elapsedTime = 0,
    String? completedAt,
  }) async {
    final db = await getDatabase();
    // Check if a game already exists for this difficulty and not completed
    var existing = await db.query(
      'games',
      where: 'difficulty = ? AND completed_at IS NULL',
      whereArgs: [difficulty],
    );

    Map<String, dynamic> data = {
      'difficulty': difficulty,
      'board': jsonEncode(board),
      'solution': jsonEncode(solution),
      'is_fixed': jsonEncode(isFixed),
      'elapsed_time': elapsedTime,
      'completed_at': completedAt,
    };

    if (existing.isNotEmpty) {
      int id = existing.first['id'] as int;
      return await db.update('games', data, where: 'id = ?', whereArgs: [id]);
    } else {
      return await db.insert('games', data);
    }
  }

  // Load saved game for a difficulty
  static Future<Map<String, dynamic>?> loadGame(String difficulty) async {
    final db = await getDatabase();
    var result = await db.query(
      'games',
      where: 'difficulty = ? AND completed_at IS NULL',
      whereArgs: [difficulty],
      limit: 1,
    );
    if (result.isEmpty) return null;

    var row = result.first;
    return {
      'board': (jsonDecode(row['board'] as String) as List)
          .map((r) => (r as List).map((e) => e as int).toList())
          .toList(),
      'solution': (jsonDecode(row['solution'] as String) as List)
          .map((r) => (r as List).map((e) => e as int).toList())
          .toList(),
      'is_fixed': (jsonDecode(row['is_fixed'] as String) as List)
          .map((r) => (r as List).map((e) => e as bool).toList())
          .toList(),
      'elapsed_time': row['elapsed_time'] as int,
    };
  }

  // Mark game as completed
  static Future<int> completeGame(String difficulty, int elapsedTime) async {
    final db = await getDatabase();
    return await db.update(
      'games',
      {
        'completed_at': DateTime.now().toIso8601String(),
        'elapsed_time': elapsedTime,
      },
      where: 'difficulty = ? AND completed_at IS NULL',
      whereArgs: [difficulty],
    );
  }
}
