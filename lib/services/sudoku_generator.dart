import 'dart:math';

class SudokuGenerator {
  final Random _rand = Random();

  /// Generates a complete valid Sudoku board
  List<List<int>> generateFullSolution() {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(board);
    return board;
  }

  /// Generates a Sudoku puzzle from a complete board
  List<List<int>> generatePuzzle(List<List<int>> fullBoard, int clues) {
    List<List<int>> puzzle = fullBoard
        .map((row) => List<int>.from(row))
        .toList();
    int cellsToRemove = 81 - clues;

    while (cellsToRemove > 0) {
      int r = _rand.nextInt(9);
      int c = _rand.nextInt(9);
      if (puzzle[r][c] != 0) {
        puzzle[r][c] = 0;
        cellsToRemove--;
      }
    }

    return puzzle;
  }

  // ------------------- PRIVATE HELPERS -------------------

  bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_rand);
          for (int num in numbers) {
            if (_isSafe(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) return true;
              board[row][col] = 0;
            }
          }
          return false; // backtrack
        }
      }
    }
    return true;
  }

  bool _isSafe(List<List<int>> board, int row, int col, int num) {
    for (int x = 0; x < 9; x++) {
      if (board[row][x] == num ||
          board[x][col] == num ||
          board[(row ~/ 3) * 3 + x ~/ 3][(col ~/ 3) * 3 + x % 3] == num) {
        return false;
      }
    }
    return true;
  }

  /// Checks if a Sudoku board is completely and correctly solved
  bool isSolved(List<List<int>> board) {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] == 0 || !_isSafe(board, i, j, board[i][j])) {
          return false;
        }
      }
    }
    return true;
  }
}
