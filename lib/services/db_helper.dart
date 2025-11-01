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
    try {
      final db = await getDatabase();
      // Check if a game already exists for this difficulty and not completed
      var existing = await db.query(
        'games',
        where: 'difficulty = ? AND completed_at IS NULL',
        whereArgs: [difficulty],
      );

      // Convert boolean array to int array for JSON encoding
      List<List<int>> isFixedInt = isFixed
          .map((row) => row.map((b) => b ? 1 : 0).toList())
          .toList();

      Map<String, dynamic> data = {
        'difficulty': difficulty,
        'board': jsonEncode(board),
        'solution': jsonEncode(solution),
        'is_fixed': jsonEncode(isFixedInt),
        'elapsed_time': elapsedTime,
        'completed_at': completedAt,
      };

      if (existing.isNotEmpty) {
        int id = existing.first['id'] as int;
        int result = await db.update('games', data, where: 'id = ?', whereArgs: [id]);
        return result;
      } else {
        int result = await db.insert('games', data);
        return result;
      }
    } catch (e) {
      print('Error in saveGame: $e');
      rethrow;
    }
  }

  // Load saved game for a difficulty
  static Future<Map<String, dynamic>?> loadGame(String difficulty) async {
    try {
      final db = await getDatabase();
      var result = await db.query(
        'games',
        where: 'difficulty = ? AND completed_at IS NULL',
        whereArgs: [difficulty],
        limit: 1,
      );
      if (result.isEmpty) return null;

      var row = result.first;
      
      // Decode board
      List<List<int>> board = (jsonDecode(row['board'] as String) as List)
          .map((r) => (r as List).map((e) => e as int).toList())
          .toList()
          .cast<List<int>>();
      
      // Decode solution
      List<List<int>> solution = (jsonDecode(row['solution'] as String) as List)
          .map((r) => (r as List).map((e) => e as int).toList())
          .toList()
          .cast<List<int>>();
      
      // Decode is_fixed (convert from int array back to bool array)
      List<List<bool>> isFixed = (jsonDecode(row['is_fixed'] as String) as List)
          .map((r) => (r as List).map((e) => (e as int) == 1).toList())
          .toList()
          .cast<List<bool>>();
      
      return {
        'board': board,
        'solution': solution,
        'is_fixed': isFixed,
        'elapsed_time': row['elapsed_time'] as int,
      };
    } catch (e) {
      print('Error in loadGame: $e');
      return null;
    }
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
