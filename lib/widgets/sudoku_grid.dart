import 'package:flutter/material.dart';

class SudokuGrid extends StatelessWidget {
  final List<List<int>> board;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onCellTap;

  const SudokuGrid({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          itemCount: 81,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            int row = index ~/ 9;
            int col = index % 9;
            int value = board[row][col];
            bool isSelected = selectedRow == row && selectedCol == col;

            return GestureDetector(
              onTap: () => onCellTap(row, col),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.lightBlueAccent.withOpacity(0.5)
                      : (value == 0 ? Colors.white : Colors.grey[200]),
                  border: Border.all(color: Colors.black26),
                ),
                child: Center(
                  child: Text(
                    value == 0 ? '' : value.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: value == 0
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
