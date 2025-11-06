# Sudoku Game - Complete Project Documentation

## 1. PROJECT OVERVIEW

### 1.1 Introduction
This is a **Flutter-based Sudoku game** application that allows users to play Sudoku puzzles with multiple difficulty levels. The app features game persistence using SQLite database, allowing players to save and resume their progress.

### 1.2 Technology Stack
- **Framework**: Flutter (Dart SDK ^3.9.2)
- **Database**: SQLite using `sqflite` package (v2.4.2)
- **Platform**: Android (can be extended to iOS/Web)
- **UI Framework**: Material Design

### 1.3 Key Features
1. ✅ Multiple difficulty levels (Beginner, Easy, Medium, Hard, Extreme)
2. ✅ Save/Resume game functionality
3. ✅ Auto-save every 30 seconds
4. ✅ Real-time timer
5. ✅ Input validation
6. ✅ Win detection and celebration screen
7. ✅ Modern, responsive UI

---

## 2. PROJECT ARCHITECTURE

### 2.1 Folder Structure
```
lib/
├── main.dart                    # App entry point & routing
├── screens/
│   ├── home_screen.dart        # Difficulty selection screen
│   ├── game_screen.dart         # Main game screen
│   └── win_screen.dart          # Victory screen
├── services/
│   ├── sudoku_generator.dart   # Puzzle generation logic
│   └── db_helper.dart          # Database operations
└── widgets/
    └── sudoku_grid.dart        # Reusable grid widget
```

### 2.2 Architecture Pattern
- **MVC-like Pattern**: 
  - **Model**: Database (DBHelper) and game logic (SudokuGenerator)
  - **View**: Flutter Widgets (Screens, Widgets)
  - **Controller**: StatefulWidget state management

### 2.3 Design Principles
1. **Separation of Concerns**: Business logic separated from UI
2. **Reusability**: SudokuGrid as a reusable widget
3. **State Management**: Using Flutter's StatefulWidget for local state
4. **Data Persistence**: SQLite for permanent storage

---

## 3. DATA FLOW

### 3.1 Application Flow

```
[User Opens App]
    ↓
[HomeScreen] → User selects difficulty
    ↓
[Route Arguments] → Difficulty + newGame flag passed
    ↓
[GameScreen] → Reads route arguments in didChangeDependencies()
    ↓
    ├─→ If newGame: Generate new puzzle
    └─→ If resume: Load from database
    ↓
[Game Initialized] → Start timer, display grid
    ↓
[User Input] → Number pad → Validate → Update board
    ↓
    ├─→ If valid: Save to database
    └─→ If invalid: Show error
    ↓
[Auto-save] → Every 30 seconds
    ↓
[Win Check] → After each move
    ↓
    ├─→ If complete: Mark completed, navigate to WinScreen
    └─→ If not: Continue playing
    ↓
[User Navigates Back] → PopScope catches back button → Save game
    ↓
[HomeScreen] → Refresh saved game status
```

### 3.2 Database Flow

```
[Game State Changes]
    ↓
[Convert to JSON] → Board, Solution, isFixed arrays → JSON strings
    ↓
[SQLite Insert/Update] → Check if game exists for difficulty
    ↓
    ├─→ If exists: UPDATE existing record
    └─→ If new: INSERT new record
    ↓
[Load Game Request]
    ↓
[SQLite Query] → SELECT where difficulty AND completed_at IS NULL
    ↓
[Parse JSON] → JSON strings → List<List<int>> and List<List<bool>>
    ↓
[Return Game State] → Board, Solution, isFixed, elapsed_time
```

---

## 4. KEY COMPONENTS EXPLANATION

### 4.1 Main.dart (Entry Point)

**Purpose**: Application entry point and route configuration

**Key Code**:
```dart
void main() {
  runApp(const SudokuApp());
}
```

**Explanation**:
- `runApp()` initializes Flutter framework
- `SudokuApp` is the root widget
- `MaterialApp` configures:
  - Theme (deep purple color scheme)
  - Named routes for navigation
  - Initial route ('/')

**Why this approach?**
- Named routes provide type-safe navigation
- Centralized routing configuration
- Easy to add new screens

---

### 4.2 SudokuGenerator (Core Algorithm)

**Purpose**: Generate valid Sudoku puzzles using backtracking algorithm

#### 4.2.1 Backtracking Algorithm

**Method**: `_fillBoard()`
```dart
bool _fillBoard(List<List<int>> board) {
  for (int row = 0; row < 9; row++) {
    for (int col = 0; col < 9; col++) {
      if (board[row][col] == 0) {
        List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_rand);
        for (int num in numbers) {
          if (_isSafe(board, row, col, num)) {
            board[row][col] = num;
            if (_fillBoard(board)) return true;  // Recursion
            board[row][col] = 0;                 // Backtrack
          }
        }
        return false;
      }
    }
  }
  return true;
}
```

**Algorithm Explanation**:
1. **Iterate** through each cell (row by row, column by column)
2. **Find empty cell** (value = 0)
3. **Try numbers 1-9** in random order
4. **Check safety**: Verify number doesn't violate Sudoku rules
5. **Place number** if safe
6. **Recursively solve** remaining board
7. **Backtrack**: If no valid number, remove placement and try next
8. **Base case**: All cells filled → return true

**Time Complexity**: O(9^N) where N = number of empty cells (worst case)
**Space Complexity**: O(1) if we don't count recursion stack

#### 4.2.2 Safety Check (_isSafe)

**Purpose**: Validate Sudoku rules

```dart
bool _isSafe(List<List<int>> board, int row, int col, int num) {
  for (int x = 0; x < 9; x++) {
    // Check row
    if (board[row][x] == num) return false;
    // Check column
    if (board[x][col] == num) return false;
    // Check 3x3 box
    if (board[(row ~/ 3) * 3 + x ~/ 3][(col ~/ 3) * 3 + x % 3] == num)
      return false;
  }
  return true;
}
```

**Sudoku Rules Checked**:
1. **Row constraint**: Number not in same row
2. **Column constraint**: Number not in same column
3. **Box constraint**: Number not in same 3x3 box
   - `(row ~/ 3) * 3` calculates box's starting row
   - `(col ~/ 3) * 3` calculates box's starting column

#### 4.2.3 Puzzle Generation

**Method**: `generatePuzzle()`
```dart
List<List<int>> generatePuzzle(List<List<int>> fullBoard, int clues) {
  List<List<int>> puzzle = fullBoard.map(...).toList(); // Clone
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
```

**Difficulty Levels**:
- Beginner: 45 clues (36 cells removed)
- Easy: 40 clues (41 cells removed)
- Medium: 36 clues (45 cells removed)
- Hard: 32 clues (49 cells removed)
- Extreme: 28 clues (53 cells removed)

**More clues = Easier puzzle**

---

### 4.3 DBHelper (Database Layer)

**Purpose**: Handle all SQLite database operations

#### 4.3.1 Database Schema

```sql
CREATE TABLE games(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  difficulty TEXT,              -- Difficulty level
  board TEXT,                   -- JSON encoded current board state
  solution TEXT,               -- JSON encoded solution
  is_fixed TEXT,               -- JSON encoded fixed cells (clues)
  elapsed_time INTEGER,        -- Time spent in seconds
  completed_at TEXT             -- ISO timestamp when completed (NULL if in progress)
)
```

**Design Decisions**:
- **Single table design**: Simple, sufficient for requirements
- **JSON storage**: Arrays stored as JSON strings (SQLite doesn't support arrays natively)
- **Soft delete**: `completed_at IS NULL` indicates active game
- **One game per difficulty**: Simple query logic

#### 4.3.2 Singleton Pattern

```dart
static Database? _db;

static Future<Database> getDatabase() async {
  if (_db != null) return _db!;  // Return existing connection
  // Create new connection
  String path = join(await getDatabasesPath(), 'sudoku.db');
  _db = await openDatabase(path, version: 1, onCreate: ...);
  return _db!;
}
```

**Why Singleton?**
- Single database connection = better performance
- Avoids connection pool management
- Reduces resource usage

#### 4.3.3 Save Game Logic

**Key Features**:
1. **Upsert pattern**: Insert if new, update if exists
2. **Boolean encoding**: Convert `List<List<bool>>` to `List<List<int>>` for JSON
3. **Error handling**: Try-catch with logging

```dart
// Check if game exists
var existing = await db.query(
  'games',
  where: 'difficulty = ? AND completed_at IS NULL',
  whereArgs: [difficulty],
);

if (existing.isNotEmpty) {
  // UPDATE existing game
  await db.update('games', data, where: 'id = ?', whereArgs: [id]);
} else {
  // INSERT new game
  await db.insert('games', data);
}
```

#### 4.3.4 Load Game Logic

**Process**:
1. Query database for incomplete game of selected difficulty
2. Parse JSON strings back to arrays
3. Convert boolean arrays back from integers
4. Return game state map

**Why this structure?**
- Single query for efficiency
- Clear return type (Map with typed values)
- Nullable return (null if no saved game)

---

### 4.4 GameScreen (Main Game Logic)

**Purpose**: Main gameplay screen with state management and user interaction

#### 4.4.1 State Variables

```dart
late List<List<int>> _puzzle;      // Current board state
late List<List<int>> _solution;   // Complete solution (for validation)
late List<List<bool>> _isFixed;   // Which cells are clues (immutable)
int? selectedRow, selectedCol;    // Currently selected cell
String _difficulty;               // Current difficulty level
Timer? _timer;                     // Timer for elapsed time
int _elapsedSeconds;              // Total elapsed seconds
bool _isLoading;                   // Loading state indicator
bool _isInitialized;               // Prevent multiple initializations
```

#### 4.4.2 Initialization Flow

**Why `didChangeDependencies()` instead of `initState()`?**

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_isInitialized) {
    _isInitialized = true;
    _initializeGame();
  }
}
```

**Reason**: `ModalRoute.of(context)` requires BuildContext to be fully initialized. In `initState()`, context isn't ready yet, causing errors.

**Initialization Steps**:
1. Read route arguments (difficulty, newGame flag)
2. Generate new puzzle OR load saved game
3. Initialize timer
4. Set loading = false

#### 4.4.3 Save Triggers

**Multiple save points ensure data persistence**:

1. **After each valid move**: Immediate save
   ```dart
   await _saveGame(); // Called in _onNumberInput()
   ```

2. **Auto-save timer**: Every 30 seconds
   ```dart
   if (_elapsedSeconds - _lastSavedSeconds >= 30) {
     _saveGame();
   }
   ```

3. **Manual save button**: User-initiated
   ```dart
   IconButton(
     icon: Icon(Icons.save),
     onPressed: () async {
       await _saveGame();
       // Show confirmation
     },
   )
   ```

4. **Navigation back**: PopScope catches back button
   ```dart
   PopScope(
     onPopInvokedWithResult: (bool didPop, result) async {
       if (didPop) await _saveOnExit();
     },
   )
   ```

5. **Widget disposal**: Before widget destroyed
   ```dart
   @override
   void dispose() {
     _timer?.cancel();
     // Note: Save happens in PopScope before dispose
   }
   ```

#### 4.4.4 Timer Implementation

```dart
void _startTimer() {
  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (mounted && !_isLoading) {
      setState(() {
        _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      });
      // Auto-save logic
    }
  });
}
```

**Key Points**:
- `Timer.periodic`: Fires every second
- `mounted` check: Prevents errors if widget disposed
- `setState()`: Updates UI with new time
- Timer saved with game state for resume

#### 4.4.5 Input Validation

```dart
Future<void> _onNumberInput(int number) async {
  // Check if cell is selected
  if (selectedRow == null || selectedCol == null) return;
  
  // Check if cell is a clue (fixed)
  if (_isFixed[selectedRow!][selectedCol!]) return;

  // Validate against solution
  if (_solution[selectedRow!][selectedCol!] == number) {
    // Valid move - update board
    setState(() {
      _puzzle[selectedRow!][selectedCol!] = number;
    });
    await _saveGame();
    
    // Check win condition
    if (_puzzle.every((row) => row.every((cell) => cell != 0))) {
      await DBHelper.completeGame(_difficulty, _elapsedSeconds);
      // Navigate to win screen
    }
  } else {
    // Invalid move - show error
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

**Validation Rules**:
1. Cell must be selected
2. Cell must not be a clue (fixed)
3. Input must match solution
4. If valid: Update board, save, check win
5. If invalid: Show error message

---

### 4.5 SudokuGrid Widget

**Purpose**: Reusable widget to display 9x9 Sudoku grid

#### 4.5.1 Grid Rendering

```dart
GridView.builder(
  itemCount: 81,  // 9x9 = 81 cells
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 9,  // 9 columns
  ),
  itemBuilder: (context, index) {
    int row = index ~/ 9;  // Integer division
    int col = index % 9;   // Modulo
    // Build cell widget
  },
)
```

**Index to Row/Col Conversion**:
- `row = index ~/ 9`: Integer division gives row (0-8)
- `col = index % 9`: Modulo gives column (0-8)

**Example**: Index 25
- Row: 25 ~/ 9 = 2
- Col: 25 % 9 = 7
- Cell at [2, 7]

#### 4.5.2 Visual Features

1. **Border Styling**:
   ```dart
   double top = row % 3 == 0 ? 2.5 : 0.5;
   ```
   - Thicker borders (2.5px) for 3x3 box boundaries
   - Thinner borders (0.5px) for individual cells

2. **Color Coding**:
   - **Selected cell**: Light blue highlight
   - **Same number**: Yellow highlight (all instances of selected number)
   - **Fixed cells**: Gray background (clues)
   - **User input**: White background

3. **Typography**:
   - Fixed cells: Bold, dark purple
   - User input: Medium weight, lighter purple

---

### 4.6 HomeScreen

**Purpose**: Difficulty selection and game entry point

#### 4.6.1 Difficulty Selection

**Implementation**: `PageView` for swipeable difficulty selector

```dart
PageView.builder(
  viewportFraction: 0.45,  // Show 2.2 items at once
  onPageChanged: _onDifficultyChanged,
  itemBuilder: (context, index) {
    // Animated difficulty buttons
  },
)
```

**Features**:
- Horizontal scrolling
- Color-coded difficulties
- Smooth animations
- Visual feedback on selection

#### 4.6.2 Save Game Detection

```dart
Future<void> _checkSavedGame() async {
  var game = await DBHelper.loadGame(difficulties[selectedIndex]);
  setState(() {
    hasSavedGame = game != null;
  });
}
```

**When checked**:
- On screen load
- When difficulty changes
- When returning from game screen (didChangeDependencies)

**UI Response**:
- Resume button enabled/disabled based on `hasSavedGame`
- Visual indication (green vs gray button)

---

## 5. DATA STRUCTURES

### 5.1 Board Representation

**2D List Structure**:
```dart
List<List<int>> board = [
  [5, 3, 0, 0, 7, 0, 0, 0, 0],
  [6, 0, 0, 1, 9, 5, 0, 0, 0],
  // ... 9 rows total
];
```

**Meaning**:
- `0` = Empty cell
- `1-9` = Number placed
- Fixed dimensions: 9x9 (81 cells)

### 5.2 Fixed Cells Tracking

**Boolean Matrix**:
```dart
List<List<bool>> isFixed = [
  [true, true, false, false, true, ...],
  // true = clue (cannot be modified)
  // false = user can input
];
```

**Purpose**: 
- Prevent modification of puzzle clues
- Visual distinction (gray background)
- Input validation

---

## 6. UI/UX DESIGN DECISIONS

### 6.1 Color Scheme
- **Primary**: Deep Purple (modern, professional)
- **Accent**: Light Blue (selection), Yellow (number highlight)
- **Background**: Light Gray (soft, easy on eyes)
- **Text**: Dark Purple (readable, consistent)

### 6.2 User Experience Features

1. **Visual Feedback**:
   - Cell selection highlighted
   - Same numbers highlighted
   - Error messages (SnackBar)
   - Success confirmations

2. **Accessibility**:
   - Large tap targets (50x50 number pad buttons)
   - Clear visual hierarchy
   - Consistent spacing

3. **Performance**:
   - AnimatedContainer for smooth transitions
   - Efficient GridView.builder (lazy loading)
   - Timer cancellation on dispose

---

## 7. CODE QUALITY & BEST PRACTICES

### 7.1 Error Handling

**Database Operations**:
```dart
try {
  // Database operation
} catch (e) {
  print('Error: $e');
  // Graceful degradation (return null, use defaults)
}
```

**Widget Lifecycle**:
```dart
if (mounted) {
  setState(() { ... });
  Navigator.push(...);
}
```

**Why?**: Prevents errors when widget disposed during async operations

### 7.2 Memory Management

1. **Timer Cleanup**:
   ```dart
   @override
   void dispose() {
     _timer?.cancel();  // Prevent memory leaks
     super.dispose();
   }
   ```

2. **Database Singleton**: Single connection, properly managed

3. **Async Operations**: Proper await usage, no blocking

### 7.3 Code Organization

- **Separation of Concerns**: Logic separate from UI
- **Single Responsibility**: Each class has one purpose
- **DRY Principle**: Reusable widgets and functions
- **Naming Conventions**: Clear, descriptive names

---

## 8. TESTING CONSIDERATIONS

### 8.1 Unit Tests (To Add)

1. **SudokuGenerator**:
   - Test backtracking algorithm
   - Verify solution validity
   - Test difficulty levels

2. **DBHelper**:
   - Test save/load operations
   - Test JSON encoding/decoding
   - Test boolean array conversion

3. **Game Logic**:
   - Test input validation
   - Test win condition detection

### 8.2 Widget Tests

1. **SudokuGrid**: Render test, tap handling
2. **GameScreen**: State management, navigation
3. **HomeScreen**: Difficulty selection

---

## 9. FUTURE ENHANCEMENTS

1. **Features**:
   - Undo/Redo functionality
   - Hint system
   - Multiple puzzles per difficulty
   - Statistics tracking
   - Leaderboard

2. **Technical**:
   - Provider/Riverpod for state management
   - Cloud sync
   - Puzzle difficulty solver validation
   - Performance optimizations

3. **UI/UX**:
   - Dark mode
   - Animations
   - Sound effects
   - Haptic feedback

---

## 10. IMPORTANT QUESTIONS FOR VIVA

### Q: Why use SQLite?
**A**: 
- Lightweight, embedded database
- No server required (offline-first)
- Perfect for local game state
- Fast read/write operations
- Standard for mobile apps

### Q: Why backtracking for puzzle generation?
**A**:
- Guaranteed valid solution
- Works for all difficulty levels
- Well-understood algorithm
- Reliable and deterministic

### Q: Why JSON encoding for arrays?
**A**:
- SQLite doesn't support array types natively
- JSON is human-readable for debugging
- Easy to serialize/deserialize
- Standard approach for complex data

### Q: Why multiple save triggers?
**A**:
- Data persistence reliability
- User experience (no lost progress)
- Edge case handling (app crash, navigation)
- Best practice for game state

### Q: Why separate SudokuGenerator class?
**A**:
- Separation of concerns
- Reusability (can be used elsewhere)
- Testability (easier to unit test)
- Maintainability (clear responsibilities)

### Q: Explain the timer implementation.
**A**:
- Uses `Timer.periodic` for 1-second intervals
- Calculates elapsed time from start time
- Saves timer state for resume functionality
- Auto-saves every 30 seconds
- Properly cleaned up on dispose

### Q: How does the resume feature work?
**A**:
1. Game state saved after each move
2. Database stores: board, solution, fixed cells, elapsed time
3. HomeScreen checks for saved games on load
4. When resume clicked, GameScreen loads saved state
5. Timer resumes from saved elapsed time
6. All game state restored

---

## 11. ALGORITHM COMPLEXITY

### Backtracking Algorithm
- **Time**: O(9^N) worst case (N = empty cells)
- **Space**: O(1) + recursion stack O(N)
- **Average**: Much better due to early validation

### Database Operations
- **Save**: O(1) - Single insert/update
- **Load**: O(1) - Single query with index
- **JSON Operations**: O(N) where N = 81 cells

---

## 12. CONCLUSION

This Sudoku game demonstrates:
- ✅ **Clean Architecture**: Well-organized code structure
- ✅ **State Management**: Proper Flutter state handling
- ✅ **Data Persistence**: Reliable SQLite integration
- ✅ **Algorithm Implementation**: Backtracking for puzzle generation
- ✅ **User Experience**: Intuitive, responsive UI
- ✅ **Error Handling**: Graceful degradation
- ✅ **Best Practices**: Memory management, lifecycle handling

The project showcases fundamental software engineering principles while creating a functional, enjoyable game application.

