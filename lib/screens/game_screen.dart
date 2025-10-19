import 'package:flutter/material.dart';
import '../services/sudoku_generator.dart';
import '../widgets/sudoku_grid.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> _puzzle;
  late List<List<int>> _solution;
  late List<List<bool>> _isFixed;
  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    _generateNewPuzzle();
  }

  void _generateNewPuzzle() {
    final generator = SudokuGenerator();
    _solution = generator.generateFullSolution();
    _puzzle = generator.generatePuzzle(_solution, 36);

    _isFixed = List.generate(
      9,
      (r) => List.generate(9, (c) => _puzzle[r][c] != 0),
    );

    selectedRow = null;
    selectedCol = null;
  }

  void _onCellTap(int row, int col) {
    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  void _onNumberInput(int number) {
    if (selectedRow == null || selectedCol == null) return;
    if (_isFixed[selectedRow!][selectedCol!]) return;

    if (_solution[selectedRow!][selectedCol!] == number) {
      setState(() {
        _puzzle[selectedRow!][selectedCol!] = number;

        // Check if all cells are filled
        if (_puzzle.every((row) => row.every((cell) => cell != 0))) {
          Future.delayed(const Duration(milliseconds: 200), () {
            Navigator.pushReplacementNamed(context, '/win');
          });
        }
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid move!')));
    }
  }

  void _clearCell() {
    if (selectedRow == null || selectedCol == null) return;
    if (_isFixed[selectedRow!][selectedCol!]) return;

    setState(() {
      _puzzle[selectedRow!][selectedCol!] = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_generateNewPuzzle),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SudokuGrid(
              board: _puzzle,
              selectedRow: selectedRow,
              selectedCol: selectedCol,
              onCellTap: _onCellTap,
              isFixed: _isFixed,
            ),
          ),
          _buildNumberPad(),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 1; i <= 9; i++)
                ElevatedButton(
                  onPressed: () => _onNumberInput(i),
                  child: Text(
                    i.toString(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ElevatedButton(
                onPressed: _clearCell,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Icon(Icons.clear),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
