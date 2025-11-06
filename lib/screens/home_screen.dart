import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF121212),
              const Color(0xFF1E1E2E),
              const Color(0xFF2D2D44),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // Header Section
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      // Logo/Icon with glow effect
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.deepPurple[400]!,
                              Colors.purple[600]!,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🎯',
                          style: TextStyle(fontSize: 64),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Sudoku',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Challenge Your Mind',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Difficulty Selection Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Select Difficulty',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple[300],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Horizontal slider / PageView
                        SizedBox(
                          height: 110,
                          child: PageView.builder(
                            controller: PageController(
                              viewportFraction: 0.5,
                              initialPage: selectedIndex,
                            ),
                            onPageChanged: _onDifficultyChanged,
                            itemCount: difficulties.length,
                            itemBuilder: (context, index) {
                              bool isSelected = index == selectedIndex;
                              Color difficultyColor;
                              Color difficultyDarkColor;
                              switch (difficulties[index]) {
                                case 'Beginner':
                                  difficultyColor = Colors.green[400]!;
                                  difficultyDarkColor = Colors.green[700]!;
                                  break;
                                case 'Easy':
                                  difficultyColor = Colors.lightGreen[400]!;
                                  difficultyDarkColor = Colors.lightGreen[700]!;
                                  break;
                                case 'Medium':
                                  difficultyColor = Colors.orange[400]!;
                                  difficultyDarkColor = Colors.orange[700]!;
                                  break;
                                case 'Hard':
                                  difficultyColor = Colors.red[400]!;
                                  difficultyDarkColor = Colors.red[700]!;
                                  break;
                                case 'Extreme':
                                  difficultyColor = Colors.purple[400]!;
                                  difficultyDarkColor = Colors.purple[700]!;
                                  break;
                                default:
                                  difficultyColor = Colors.deepPurple[400]!;
                                  difficultyDarkColor = Colors.deepPurple[700]!;
                              }
                              return Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              difficultyColor,
                                              difficultyDarkColor,
                                            ],
                                          )
                                        : null,
                                    color: isSelected ? null : const Color(0xFF2A2A3E),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? difficultyColor.withOpacity(0.5)
                                          : Colors.grey[700]!.withOpacity(0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: difficultyColor.withOpacity(0.4),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    difficulties[index],
                                    style: TextStyle(
                                      fontSize: isSelected ? 26 : 20,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey[400],
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
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
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurple[400]!,
                                    Colors.purple[600]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pushNamed(
                                    context,
                                    '/game',
                                    arguments: {
                                      'difficulty': currentDifficulty,
                                      'newGame': true,
                                    },
                                  );
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                                label: const Text(
                                  'New Game',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: hasSavedGame
                                    ? const Color(0xFF2A4A2A)
                                    : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: hasSavedGame
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: hasSavedGame
                                    ? [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: hasSavedGame
                                    ? () {
                                        HapticFeedback.mediumImpact();
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
                                  hasSavedGame
                                      ? Icons.play_circle_outline_rounded
                                      : Icons.block_rounded,
                                  size: 28,
                                  color: hasSavedGame ? Colors.green[300] : Colors.grey[600],
                                ),
                                label: Text(
                                  hasSavedGame ? 'Resume Game' : 'No Saved Game',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: hasSavedGame
                                        ? Colors.green[300]
                                        : Colors.grey[600],
                                    letterSpacing: 1,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
