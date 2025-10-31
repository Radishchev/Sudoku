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
      appBar: AppBar(title: const Text('Sudoku'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Difficulty',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Horizontal slider / PageView
            SizedBox(
              height: 80,
              child: PageView.builder(
                controller: PageController(
                  viewportFraction: 0.4,
                  initialPage: selectedIndex,
                ),
                onPageChanged: _onDifficultyChanged,
                itemCount: difficulties.length,
                itemBuilder: (context, index) {
                  bool isSelected = index == selectedIndex;
                  return Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        difficulties[index],
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 18,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'New Game',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: hasSavedGame
                          ? Colors.green
                          : Colors.grey,
                    ),
                    child: const Text('Resume', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
