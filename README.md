# 🧠 Ultimate-Matrushka Tic Tac Toe (MIPS Assembly)

This is a custom hybrid implementation of **Ultimate Tic Tac Toe** and **Matrushka Tic Tac Toe**, written entirely in **MIPS Assembly** for the [MARS simulator](http://courses.missouristate.edu/kenvollmar/mars/).

## 🎮 Game Description

This game reimagines Ultimate Tic Tac Toe with a twist:

- The board has **81 linear cells** (indexed 0–80), not grouped in visual 3x3 grids.
- Mini boards are defined as **specific lines across the board**, such as `0-3-6` or `0-4-8`.
- Players can place **stones of different sizes** (small, medium, large) and **stack over smaller stones**, inspired by Matrushka-style logic.
- Players aim to win individual mini boards (lines), and then win the ultimate board by forming a line of 3 won mini boards.

---

## 🧱 Memory Structure


.data
board:          .space 324     # 81 cells × 4 bytes each
mini_status:    .space 36      # 9 mini boards (lines) × 4 bytes each
current_target: .word -1       # Target mini board (-1 = free choice)



board: Stores the state of each cell using encoding: player * 10 + stone_size
mini_status: Tracks the winner of each line-based mini board
current_target: Forces the player to play in a specific mini board unless it’s set to -1 (free choice)
🧩 How Mini Boards Work

Unlike classic Ultimate Tic Tac Toe, the 81-cell board is treated as a flat linear space.

Each mini board is defined by a fixed group of 3 indices (called “win patterns”).

✅ Example Mini Board Lines
Mini Board	Cell Indices
0	0, 1, 2
1	3, 4, 5
2	6, 7, 8
3	0, 3, 6
4	1, 4, 7
5	2, 5, 8
6	0, 4, 8
7	2, 4, 6
These patterns are applied across the full 81-cell board, treating it like a stream of values, not a visual grid.
🪙 Gameplay Rules

Each player takes turns.
On each turn:
Choose a stone size:
1 = small, 2 = medium, 3 = large
Choose a cell number (0–80) to place your stone
You can:
Place on an empty cell
Stack over an opponent’s stone only if your stone is larger
You cannot place:
On your own stone
Over a larger or equal opponent stone
🏆 Winning the Game

There are two levels of victory:

🥇 Mini Board Victory
If you control all 3 cells in any mini board (line), you win that board
The mini board becomes locked and marked as yours (X or Y)

🏆 Ultimate Board Victory
If you win 3 mini boards in a row (e.g. boards 0, 1, 2 or 0, 4, 8), you win the entire game
