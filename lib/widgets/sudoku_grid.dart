import 'package:flutter/material.dart';

class SudokuGrid extends StatelessWidget {
  final List<List<int>> board;
  final int? selectedRow;
  final int? selectedCol;
  final Function(int, int) onCellTap;
  final List<List<bool>> isFixed;

  const SudokuGrid({
    super.key,
    required this.board,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
    required this.isFixed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 81,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemBuilder: (context, index) {
            int row = index ~/ 9;
            int col = index % 9;
            int value = board[row][col];

            // Determine highlight
            bool isSelected = selectedRow == row && selectedCol == col;
            bool sameNumberHighlighted =
                (selectedRow != null &&
                selectedCol != null &&
                value != 0 &&
                value == board[selectedRow!][selectedCol!]);

            // Determine borders (thicker for 3x3)
            double top = row % 3 == 0 ? 2 : 0.5;
            double left = col % 3 == 0 ? 2 : 0.5;
            double right = (col + 1) % 3 == 0 ? 2 : 0.5;
            double bottom = (row + 1) % 3 == 0 ? 2 : 0.5;

            return GestureDetector(
              onTap: () => onCellTap(row, col),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.lightBlueAccent.withOpacity(0.5)
                      : (sameNumberHighlighted
                            ? Colors.yellow.withOpacity(0.5)
                            : (isFixed[row][col]
                                  ? Colors.grey[300]
                                  : Colors.white)),
                  border: Border(
                    top: BorderSide(width: top, color: Colors.black),
                    left: BorderSide(width: left, color: Colors.black),
                    right: BorderSide(width: right, color: Colors.black),
                    bottom: BorderSide(width: bottom, color: Colors.black),
                  ),
                ),
                child: Center(
                  child: Text(
                    value == 0 ? '' : value.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isFixed[row][col]
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isFixed[row][col]
                          ? Colors.black
                          : Colors.blue[800],
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
