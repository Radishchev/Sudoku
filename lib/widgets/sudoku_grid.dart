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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
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
              double top = row % 3 == 0 ? 2.5 : 0.5;
              double left = col % 3 == 0 ? 2.5 : 0.5;
              double right = (col + 1) % 3 == 0 ? 2.5 : 0.5;
              double bottom = (row + 1) % 3 == 0 ? 2.5 : 0.5;

              Color cellColor = Colors.white;
              if (isSelected) {
                cellColor = Colors.lightBlueAccent.withOpacity(0.6);
              } else if (sameNumberHighlighted) {
                cellColor = Colors.amber.withOpacity(0.3);
              } else if (isFixed[row][col]) {
                cellColor = Colors.grey[100]!;
              }

              return GestureDetector(
                onTap: () => onCellTap(row, col),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: cellColor,
                    border: Border(
                      top: BorderSide(
                        width: top,
                        color: top > 2 ? Colors.deepPurple[700]! : Colors.grey[400]!,
                      ),
                      left: BorderSide(
                        width: left,
                        color: left > 2 ? Colors.deepPurple[700]! : Colors.grey[400]!,
                      ),
                      right: BorderSide(
                        width: right,
                        color: right > 2 ? Colors.deepPurple[700]! : Colors.grey[400]!,
                      ),
                      bottom: BorderSide(
                        width: bottom,
                        color: bottom > 2 ? Colors.deepPurple[700]! : Colors.grey[400]!,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      value == 0 ? '' : value.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: isFixed[row][col]
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isFixed[row][col]
                            ? Colors.deepPurple[900]
                            : Colors.deepPurple[700],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
