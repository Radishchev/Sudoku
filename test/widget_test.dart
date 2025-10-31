import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void printDbPath() async {
  String path = join(await getDatabasesPath(), 'sudoku.db');
  print(path);
}
