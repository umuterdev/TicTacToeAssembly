.data
board:      .space 9            # 9 bytes for board positions
msgX:       .asciiz "Player X's turn:\n"
msgO:       .asciiz "Player O's turn:\n"
msgPrompt:  .asciiz "Enter position (0-8): "
msgInvalid: .asciiz "Invalid move. Try again.\n"
msgWinner:  .asciiz "Winner is: "
msgDraw:    .asciiz "It's a draw!\n"
msgBoard:   .asciiz "\nBoard:\n"

.text
.globl main

main:
    # Initialize board with -1
    li $t0, 0              # i = 0
init_loop:
    li $t1, 9
    bge $t0, $t1, start_game
    li $t2, -1
    sb $t2, board($t0)
    addi $t0, $t0, 1
    j init_loop

start_game:
    li $s0, 0              # currentPlayer (0 for X, 1 for O)

game_loop:
    # Show board
    li $v0, 4
    la $a0, msgBoard
    syscall
    jal print_board

    # Show prompt
    beqz $s0, prompt_X
    la $a0, msgO
    j show_prompt
prompt_X:
    la $a0, msgX
show_prompt:
    li $v0, 4
    syscall

get_input:
    li $v0, 4
    la $a0, msgPrompt
    syscall

    li $v0, 5          # read_int syscall
    syscall
    move $t1, $v0      # input position

    # Check bounds (0-8)
    bltz $t1, invalid_input
    li $t2, 8
    bgt $t1, $t2, invalid_input

    # Check if spot taken
    lb $t3, board($t1)
    li $t4, -1
    bne $t3, $t4, invalid_input

    # Valid move
    move $t5, $s0      # currentPlayer
    sb $t5, board($t1)

    # Save player before switching for correct win print
    move $t6, $s0

    # Check win
    jal check_win
    bne $v0, $zero, print_winner

    # Check draw
    jal is_draw
    bne $v0, $zero, print_draw

    # Switch player
    xori $s0, $s0, 1
    j game_loop

invalid_input:
    li $v0, 4
    la $a0, msgInvalid
    syscall
    j get_input

print_winner:
    li $v0, 4
    la $a0, msgBoard
    syscall
    jal print_board

    li $v0, 4
    la $a0, msgWinner
    syscall

    beqz $t6, print_X_win
    li $v0, 11
    li $a0, 79      # 'O'
    syscall
    j end_game
print_X_win:
    li $v0, 11
    li $a0, 88      # 'X'
    syscall
    j end_game

print_draw:
    li $v0, 4
    la $a0, msgDraw
    syscall

end_game:
    li $v0, 10
    syscall

# -----------------------
# PRINT BOARD
# -----------------------
print_board:
    li $t0, 0
print_loop:
    li $t1, 9
    bge $t0, $t1, print_done

    lb $t2, board($t0)
    li $v0, 11
    li $t3, -1
    beq $t2, $t3, print_dot

    li $t3, 0
    beq $t2, $t3, print_X

    li $t3, 1
    beq $t2, $t3, print_O

print_dot:
    li $a0, 46      # '.'
    syscall
    j print_space

print_X:
    li $a0, 88      # 'X'
    syscall
    j print_space

print_O:
    li $a0, 79      # 'O'
    syscall

print_space:
    li $t4, 3
    remu $t5, $t0, $t4
    addi $t0, $t0, 1
    beqz $t5, print_newline
    j print_loop
print_newline:
    li $v0, 11
    li $a0, 10      # newline
    syscall
    j print_loop

print_done:
    jr $ra

# -----------------------
# CHECK WIN
# returns 1 in $v0 if win
# -----------------------
check_win:
    li $v0, 0

    # Rows
    li $t0, 0
check_rows:
    li $t1, 3
    bge $t0, $t1, check_cols
    mul $t2, $t0, 3        # row start index

    lb $t3, board($t2)
    addi $t7, $t2, 1
    lb $t4, board($t7)
    addi $t7, $t2, 2
    lb $t5, board($t7)

    li $t6, -1
    beq $t3, $t6, next_row
    beq $t3, $t4, rows_eq1
    j next_row
rows_eq1:
    beq $t4, $t5, win_found
next_row:
    addi $t0, $t0, 1
    j check_rows

# Columns
check_cols:
    li $t0, 0
check_cols_loop:
    li $t1, 3
    bge $t0, $t1, check_diags
    lb $t3, board($t0)

    addi $t7, $t0, 3
    lb $t4, board($t7)
    addi $t7, $t0, 6
    lb $t5, board($t7)

    li $t6, -1
    beq $t3, $t6, next_col
    beq $t3, $t4, cols_eq1
    j next_col
cols_eq1:
    beq $t4, $t5, win_found
next_col:
    addi $t0, $t0, 1
    j check_cols_loop

# Diagonals
check_diags:
    lb $t3, board
    lb $t4, board+4
    lb $t5, board+8
    li $t6, -1
    beq $t3, $t6, diag2
    beq $t3, $t4, diag1_eq
    j diag2
diag1_eq:
    beq $t4, $t5, win_found

diag2:
    lb $t3, board+2
    lb $t4, board+4
    lb $t5, board+6
    li $t6, -1
    beq $t3, $t6, done_check_win
    beq $t3, $t4, diag2_eq
    j done_check_win
diag2_eq:
    beq $t4, $t5, win_found

done_check_win:
    jr $ra

win_found:
    li $v0, 1
    jr $ra

# -----------------------
# CHECK DRAW
# returns 1 in $v0 if draw
# -----------------------
is_draw:
    li $t0, 0
    li $v0, 1
check_draw_loop:
    li $t1, 9
    bge $t0, $t1, draw_done
    lb $t2, board($t0)
    li $t3, -1
    beq $t2, $t3, not_draw
    addi $t0, $t0, 1
    j check_draw_loop

not_draw:
    li $v0, 0
draw_done:
    jr $ra
