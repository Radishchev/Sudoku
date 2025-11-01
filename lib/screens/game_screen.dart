import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sudoku_generator.dart';
import '../services/db_helper.dart';
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
  String _difficulty = 'Medium';
  bool _isNewGame = true;
  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _startTime;
  bool _isLoading = true;
  bool _isInitialized = false;
  int _lastSavedSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with empty defaults to avoid late initialization errors
    _puzzle = List.generate(9, (_) => List.filled(9, 0));
    _solution = List.generate(9, (_) => List.filled(9, 0));
    _isFixed = List.generate(9, (_) => List.filled(9, false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initializeGame();
    }
  }

  Future<void> _initializeGame() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _difficulty = args['difficulty'] ?? 'Medium';
      _isNewGame = args['newGame'] ?? true;
    }

    if (_isNewGame) {
      await _generateNewPuzzle();
    } else {
      await _loadSavedGame();
    }
    
    if (mounted) {
      _startTimer();
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _getCluesForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return 45;
      case 'Easy':
        return 40;
      case 'Medium':
        return 36;
      case 'Hard':
        return 32;
      case 'Extreme':
        return 28;
      default:
        return 36;
    }
  }

  Future<void> _generateNewPuzzle() async {
    final generator = SudokuGenerator();
    _solution = generator.generateFullSolution();
    int clues = _getCluesForDifficulty(_difficulty);
    _puzzle = generator.generatePuzzle(_solution, clues);

    _isFixed = List.generate(
      9,
      (r) => List.generate(9, (c) => _puzzle[r][c] != 0),
    );

    selectedRow = null;
    selectedCol = null;
    _elapsedSeconds = 0;
    _startTime = DateTime.now();
    
    // Save new game to database
    await _saveGame();
  }

  Future<void> _loadSavedGame() async {
    try {
      final savedGame = await DBHelper.loadGame(_difficulty);
      if (savedGame != null) {
        setState(() {
          _puzzle = savedGame['board'] as List<List<int>>;
          _solution = savedGame['solution'] as List<List<int>>;
          _isFixed = savedGame['is_fixed'] as List<List<bool>>;
          _elapsedSeconds = savedGame['elapsed_time'] as int;
          _lastSavedSeconds = _elapsedSeconds;
          _startTime = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
        });
        debugPrint('Loaded saved game: difficulty=$_difficulty, time=$_elapsedSeconds');
      } else {
        // If no saved game found, generate new one
        debugPrint('No saved game found, generating new puzzle');
        await _generateNewPuzzle();
      }
    } catch (e) {
      debugPrint('Error loading saved game: $e');
      // If error loading saved game, generate new one
      await _generateNewPuzzle();
    }
  }

  void _startTimer() {
    _startTime ??= DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isLoading) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
        });
        // Auto-save every 30 seconds
        if (_isInitialized && _elapsedSeconds - _lastSavedSeconds >= 30) {
          _lastSavedSeconds = _elapsedSeconds;
          _saveGame();
        }
      }
    });
  }

  Future<void> _saveGame() async {
    if (!_isInitialized || _isLoading) {
      debugPrint('Save skipped: initialized=$_isInitialized, loading=$_isLoading');
      return;
    }
    try {
      debugPrint('Saving game: difficulty=$_difficulty, time=$_elapsedSeconds');
      int result = await DBHelper.saveGame(
        difficulty: _difficulty,
        board: _puzzle,
        solution: _solution,
        isFixed: _isFixed,
        elapsedTime: _elapsedSeconds,
      );
      _lastSavedSeconds = _elapsedSeconds;
      debugPrint('Game saved successfully: result=$result');
    } catch (e, stackTrace) {
      debugPrint('Error saving game: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveOnExit() async {
    if (!_isLoading && _isInitialized && mounted) {
      await _saveGame();
    }
  }

  void _onCellTap(int row, int col) {
    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  Future<void> _onNumberInput(int number) async {
    if (selectedRow == null || selectedCol == null) return;
    if (_isFixed[selectedRow!][selectedCol!]) return;

    if (_solution[selectedRow!][selectedCol!] == number) {
      setState(() {
        _puzzle[selectedRow!][selectedCol!] = number;
      });

      // Always save after a valid move
      await _saveGame();
      
      // Check if all cells are filled
      bool isComplete = _puzzle.every((row) => row.every((cell) => cell != 0));
      if (isComplete) {
        // Mark game as completed
        await DBHelper.completeGame(_difficulty, _elapsedSeconds);
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context, 
                '/win',
                arguments: {
                  'time': _formatTime(_elapsedSeconds),
                  'difficulty': _difficulty,
                },
              );
            }
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid move!'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _clearCell() async {
    if (selectedRow == null || selectedCol == null) return;
    if (_isFixed[selectedRow!][selectedCol!]) return;

    setState(() {
      _puzzle[selectedRow!][selectedCol!] = 0;
    });
    await _saveGame();
  }

  Future<void> _onNewGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Game'),
        content: const Text('Start a new game? Your current progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New Game'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _generateNewPuzzle();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.deepPurple[50],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          await _saveOnExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.deepPurple[50],
        appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _difficulty,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const Text(
              'Sudoku',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await _saveOnExit();
            if (mounted) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Game',
            onPressed: () async {
              await _saveGame();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Game saved!'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: _onNewGame,
          ),
        ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SudokuGrid(
                    board: _puzzle,
                    selectedRow: selectedRow,
                    selectedCol: selectedCol,
                    onCellTap: _onCellTap,
                    isFixed: _isFixed,
                  ),
                ),
              ),
              _buildNumberPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 1; i <= 9; i++)
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _onNumberInput(i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[100],
                      foregroundColor: Colors.deepPurple[900],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      i.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: 50,
                height: 50,
                child: ElevatedButton(
                  onPressed: _clearCell,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.clear, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
      );
  }
}
