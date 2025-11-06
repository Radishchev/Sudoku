import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _hintCount = 3; // Allow 3 hints per game

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
    HapticFeedback.selectionClick();
    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  Future<void> _showHint() async {
    if (_hintCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hints remaining!'),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (selectedRow == null || selectedCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a cell first!'),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isFixed[selectedRow!][selectedCol!]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This cell is already filled!'),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_puzzle[selectedRow!][selectedCol!] != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This cell already has a value!'),
          backgroundColor: Colors.orange[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _puzzle[selectedRow!][selectedCol!] = _solution[selectedRow!][selectedCol!];
      _isFixed[selectedRow!][selectedCol!] = true; // Mark as fixed after hint
      _hintCount--;
    });

    await _saveGame();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hint used! $_hintCount remaining'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );

    // Check if game is complete
    bool isComplete = _puzzle.every((row) => row.every((cell) => cell != 0));
    if (isComplete) {
      await DBHelper.completeGame(_difficulty, _elapsedSeconds);
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
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
  }

  Future<void> _onNumberInput(int number) async {
    if (selectedRow == null || selectedCol == null) return;
    if (_isFixed[selectedRow!][selectedCol!]) return;

    HapticFeedback.lightImpact();

    if (_solution[selectedRow!][selectedCol!] == number) {
      setState(() {
        _puzzle[selectedRow!][selectedCol!] = number;
      });

      HapticFeedback.mediumImpact();

      // Always save after a valid move
      await _saveGame();
      
      // Check if all cells are filled
      bool isComplete = _puzzle.every((row) => row.every((cell) => cell != 0));
      if (isComplete) {
        // Mark game as completed
        await DBHelper.completeGame(_difficulty, _elapsedSeconds);
        HapticFeedback.heavyImpact();
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
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
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Invalid move!'),
            ],
          ),
          backgroundColor: Colors.red[500],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _clearCell() async {
    if (selectedRow == null || selectedCol == null) return;
    if (_isFixed[selectedRow!][selectedCol!]) return;

    HapticFeedback.lightImpact();
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
        backgroundColor: const Color(0xFF121212),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
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
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF1E1E2E),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _difficulty,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Text(
                'Sudoku',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 18),
                  const SizedBox(width: 6),
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
              icon: Stack(
                children: [
                  const Icon(Icons.lightbulb_outline),
                  if (_hintCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_hintCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Hint ($_hintCount remaining)',
              onPressed: _showHint,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Game',
              onPressed: () async {
                await _saveGame();
                if (mounted) {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Game saved!'),
                        ],
                      ),
                      backgroundColor: Colors.green[600],
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        border: Border(
          top: BorderSide(
            color: Colors.deepPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Number pad grid (3x3 + clear button)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 1; i <= 3; i++)
                _buildNumberButton(i, isFirst: i == 1, isLast: i == 3),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 4; i <= 6; i++)
                _buildNumberButton(i, isFirst: i == 4, isLast: i == 6),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 7; i <= 9; i++)
                _buildNumberButton(i, isFirst: i == 7, isLast: i == 9),
            ],
          ),
          const SizedBox(height: 12),
          // Clear button
          SizedBox(
            width: 280,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _clearCell,
              icon: const Icon(Icons.backspace_outlined, size: 22),
              label: const Text(
                'Clear',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: Colors.red.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number, {bool isFirst = false, bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(
        left: isFirst ? 0 : 8,
        right: isLast ? 0 : 8,
      ),
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: () => _onNumberInput(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A3E),
          foregroundColor: Colors.deepPurple[300],
          elevation: 4,
          shadowColor: Colors.deepPurple.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.deepPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.deepPurple[200],
          ),
        ),
      ),
    );
  }
}
