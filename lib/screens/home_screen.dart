import 'package:flutter/material.dart';
import '../services/db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> difficulties = [
    'Beginner',
    'Easy',
    'Medium',
    'Hard',
    'Extreme',
  ];
  int selectedIndex = 0;
  bool hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh saved game status when screen becomes visible again
    _checkSavedGame();
  }

  Future<void> _checkSavedGame() async {
    var game = await DBHelper.loadGame(difficulties[selectedIndex]);
    setState(() {
      hasSavedGame = game != null;
    });
  }

  void _onDifficultyChanged(int index) async {
    setState(() {
      selectedIndex = index;
    });
    await _checkSavedGame();
  }

  @override
  Widget build(BuildContext context) {
    String currentDifficulty = difficulties[selectedIndex];

    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          'Sudoku',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎯',
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select Difficulty',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Horizontal slider / PageView
                    SizedBox(
                      height: 100,
                      child: PageView.builder(
                        controller: PageController(
                          viewportFraction: 0.45,
                          initialPage: selectedIndex,
                        ),
                        onPageChanged: _onDifficultyChanged,
                        itemCount: difficulties.length,
                        itemBuilder: (context, index) {
                          bool isSelected = index == selectedIndex;
                          Color difficultyColor;
                          switch (difficulties[index]) {
                            case 'Beginner':
                              difficultyColor = Colors.green;
                              break;
                            case 'Easy':
                              difficultyColor = Colors.lightGreen;
                              break;
                            case 'Medium':
                              difficultyColor = Colors.orange;
                              break;
                            case 'Hard':
                              difficultyColor = Colors.red;
                              break;
                            case 'Extreme':
                              difficultyColor = Colors.purple;
                              break;
                            default:
                              difficultyColor = Colors.deepPurple;
                          }
                          return Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? difficultyColor
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: difficultyColor.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                difficulties[index],
                                style: TextStyle(
                                  fontSize: isSelected ? 24 : 20,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/game',
                                arguments: {
                                  'difficulty': currentDifficulty,
                                  'newGame': true,
                                },
                              );
                            },
                            icon: const Icon(Icons.play_arrow, size: 24),
                            label: const Text(
                              'New Game',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: hasSavedGame
                                ? () {
                                    Navigator.pushNamed(
                                      context,
                                      '/game',
                                      arguments: {
                                        'difficulty': currentDifficulty,
                                        'newGame': false,
                                      },
                                    );
                                  }
                                : null,
                            icon: Icon(
                              Icons.refresh,
                              size: 24,
                              color: hasSavedGame ? Colors.white : Colors.grey[400],
                            ),
                            label: Text(
                              hasSavedGame ? 'Resume Game' : 'No Saved Game',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: hasSavedGame ? Colors.white : Colors.grey[400],
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasSavedGame
                                  ? Colors.green[600]
                                  : Colors.grey[300],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: hasSavedGame ? 4 : 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
