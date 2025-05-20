.data
.align 2
board:              .space 324           # 81 cells * 4 bytes each
.align 2
mini_status:        .space 36            # 9 mini boards * 4 bytes each
.align 2
current_target:     .word -1             # Next target mini board (-1 means free choice)

.align 2
mini_win_indices:
    .word 0,1,2
    .word 3,4,5
    .word 6,7,8
    .word 0,3,6
    .word 1,4,7
    .word 2,5,8
    .word 0,4,8
    .word 2,4,6

.align 2
ultimate_win_indices:
    .word 0,1,2
    .word 3,4,5
    .word 6,7,8
    .word 0,3,6
    .word 1,4,7
    .word 2,5,8
    .word 0,4,8
    .word 2,4,6

newline:            .asciiz "\n"
space:              .asciiz " "
msg_size:           .asciiz "Tas boyutu (1: kucuk, 2: orta, 3: buyuk): "
msg_place:          .asciiz "Hucre konumu (0-80): "
msg_invalid_board:  .asciiz "Bu mini tahta dolu veya kazanilmis. Baska secin.\n"
msg_invalid_move:   .asciiz "Gecersiz hamle! Tekrar deneyin.\n"
msg_valid_move:     .asciiz "Hamle yapildi.\n"
msg_turn1:          .asciiz "\nOyuncu 1'in sirasi\n"
msg_turn2:          .asciiz "\nOyuncu 2'in sirasi\n"
msg_win:            .asciiz "\nOyunu kazanan oyuncu: "
left_bracket:       .asciiz "["
right_bracket:      .asciiz "]"
dashline:           .asciiz "-----------------------------------------\n"

.text
.globl main

main:
    li $s7, 1
    j main_loop

main_loop:
    li $v0, 4
    beq $s7, 1, turn1_msg
    la $a0, msg_turn2
    syscall
    j show_target
turn1_msg:
    la $a0, msg_turn1
    syscall

show_target:
    jal print_ultimate_board

    li $v0, 4
    la $a0, msg_size
    syscall
    li $v0, 5
    syscall
    move $t0, $v0  # New stone size

    li $t2, 1
    blt $t0, $t2, invalid_move
    li $t2, 3
    bgt $t0, $t2, invalid_move

    li $v0, 4
    la $a0, msg_place
    syscall
    li $v0, 5
    syscall
    move $t3, $v0

    li $t2, 0
    blt $t3, $t2, invalid_move
    li $t2, 80
    bgt $t3, $t2, invalid_move

    li $t2, 9
    divu $t3, $t2
    mflo $s0
    mfhi $t1

    sll $t4, $t3, 2
    la $t5, board
    add $t5, $t5, $t4

    lw $t6, 0($t5)
    beqz $t6, store_stone

    li $t7, 10
    divu $t6, $t7
    mflo $t9
    mfhi $t8

    ble $t0, $t8, invalid_move
    beq $s7, $t9, invalid_move

store_stone:
    li $t7, 10
    mul $t8, $s7, $t7
    add $t8, $t8, $t0
    sw $t8, 0($t5)

    li $v0, 4
    la $a0, msg_valid_move
    syscall

    jal check_mini_win
    jal check_ultimate_win

    la $t9, mini_status
    mul $t2, $t1, 4
    add $t9, $t9, $t2
    lw $t0, 0($t9)
    li $t2, 0
    beq $t0, $t2, set_target
    li $t2, -1
set_target:
    la $t3, current_target
    sw $t2, 0($t3)

    li $t4, 1
    beq $s7, $t4, to_player2
    li $s7, 1
    j main_loop
to_player2:
    li $s7, 2
    j main_loop

invalid_move:
    li $v0, 4
    la $a0, msg_invalid_move
    syscall
    j main_loop

print_ultimate_board:
    li $t0, 0
print_outer_loop:
    li $t1, 0
print_inner_loop:
    li $t6, 9
    divu $t0, $t6
    mflo $t7
    remu $t8, $t0, $t6

    la $t9, mini_status
    mul $s0, $t7, 4
    add $t9, $t9, $s0
    lw $s1, 0($t9)

    li $t2, 4
    beqz $s1, normal_print
    bne $t8, $t2, skip_cell

    li $v0, 4
    la $a0, left_bracket
    syscall
    li $v0, 11
    li $a0, 'X'
    beq $s1, 1, pr_win
    li $a0, 'Y'
pr_win:
    syscall
    li $v0, 4
    la $a0, right_bracket
    syscall
    j finish_cell

normal_print:
    beqz $s1, continue_cell_print

    li $v0, 4
    la $a0, left_bracket
    syscall

    li $v0, 11
    li $a0, 'X'
    beq $s1, 1, pr_fullwin
    li $a0, 'Y'
pr_fullwin:
    syscall

    li $v0, 4
    la $a0, right_bracket
    syscall
    j finish_cell

continue_cell_print:
    la $t2, board
    sll $t3, $t0, 2
    add $t3, $t3, $t2
    lw $t4, 0($t3)

    li $v0, 4
    la $a0, left_bracket
    syscall

    beqz $t4, print_index
    li $t5, 10
    divu $t4, $t5
    mflo $t6
    mfhi $t7
    li $v0, 1
    move $a0, $t7
    syscall
    li $v0, 11
    li $a0, 'X'
    beq $t6, 1, pr_p
    li $a0, 'Y'
pr_p:
    syscall
    li $v0, 11
    li $a0, '.'
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    j finish_cell

print_index:
    li $v0, 4
    la $a0, space
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 4
    la $a0, space
    syscall

finish_cell:
    li $v0, 4
    la $a0, right_bracket
    syscall

skip_cell:
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1

    li $t5, 3
    remu $t6, $t1, $t5
    bnez $t6, skip_extra_colspace
    li $v0, 11
    li $a0, '|'
    syscall
    li $v0, 4
    la $a0, space
    syscall
skip_extra_colspace:
    li $t5, 9
    remu $t6, $t0, $t5
    bnez $t6, skip_newline
    li $v0, 4
    la $a0, newline
    syscall
    li $t5, 27
    remu $t6, $t0, $t5
    bnez $t6, skip_newline
    li $v0, 4
    la $a0, newline
    syscall
    li $v0, 4
    la $a0, dashline
    syscall
skip_newline:
    li $t5, 81
    blt $t0, $t5, print_inner_loop
    li $v0, 4
    la $a0, newline
    syscall
    jr $ra

# check_mini_win and check_ultimate_win remain unchanged
check_mini_win:
    move $s6, $s0      # Save mini-board index to $s6
    li $t0, 9
    mul $t1, $s0, $t0
    la $t2, mini_win_indices
    li $t3, 8
    li $t4, 0
mini_win_loop:
    lw $t5, 0($t2)
    lw $t6, 4($t2)
    lw $t7, 8($t2)

    la $t8, board

    add $t9, $t1, $t5
    sll $t9, $t9, 2
    add $a0, $t8, $t9
    lw $s0, 0($a0)

    add $t9, $t1, $t6
    sll $t9, $t9, 2
    add $a1, $t8, $t9
    lw $s1, 0($a1)

    add $t9, $t1, $t7
    sll $t9, $t9, 2
    add $a2, $t8, $t9
    lw $s2, 0($a2)

    li $t6, 10
    divu $s0, $t6
    mflo $s0
    divu $s1, $t6
    mflo $s1
    divu $s2, $t6
    mflo $s2

    beqz $s0, skip_mini_check
    bne $s0, $s1, skip_mini_check
    bne $s1, $s2, skip_mini_check

    la $t9, mini_status
    mul $t8, $s6, 4
    add $t9, $t9, $t8
    sw $s7, 0($t9)
    jr $ra

skip_mini_check:
    addiu $t2, $t2, 12
    addiu $t4, $t4, 1
    blt $t4, $t3, mini_win_loop
    jr $ra

check_ultimate_win:
    la $t0, mini_status  # Base address of mini_status

    # Load all 9 mini board statuses
    lw $t1, 0($t0)       # status[0]
    lw $t2, 4($t0)       # status[1]
    lw $t3, 8($t0)       # status[2]
    lw $t4, 12($t0)      # status[3]
    lw $t5, 16($t0)      # status[4]
    lw $t6, 20($t0)      # status[5]
    lw $t7, 24($t0)      # status[6]
    lw $t8, 28($t0)      # status[7]
    lw $t9, 32($t0)      # status[8]

    # Check rows
    bnez $t1, check_row1
    j check_row2
check_row1:
    beq $t1, $t2, next_row1
    j check_row2
next_row1:
    beq $t2, $t3, win_game
check_row2:
    bnez $t4, check_row2_val
    j check_row3
check_row2_val:
    beq $t4, $t5, next_row2
    j check_row3
next_row2:
    beq $t5, $t6, win_game
check_row3:
    bnez $t7, check_row3_val
    j check_col1
check_row3_val:
    beq $t7, $t8, next_row3
    j check_col1
next_row3:
    beq $t8, $t9, win_game

    # Check columns
check_col1:
    bnez $t1, check_col1_val
    j check_col2
check_col1_val:
    beq $t1, $t4, next_col1
    j check_col2
next_col1:
    beq $t4, $t7, win_game
check_col2:
    bnez $t2, check_col2_val
    j check_col3
check_col2_val:
    beq $t2, $t5, next_col2
    j check_col3
next_col2:
    beq $t5, $t8, win_game
check_col3:
    bnez $t3, check_col3_val
    j check_diag1
check_col3_val:
    beq $t3, $t6, next_col3
    j check_diag1
next_col3:
    beq $t6, $t9, win_game

    # Check diagonals
check_diag1:
    bnez $t1, check_diag1_val
    j check_diag2
check_diag1_val:
    beq $t1, $t5, next_diag1
    j check_diag2
next_diag1:
    beq $t5, $t9, win_game
check_diag2:
    bnez $t3, check_diag2_val
    j end_check
check_diag2_val:
    beq $t3, $t5, next_diag2
    j end_check
next_diag2:
    beq $t5, $t7, win_game

end_check:
    jr $ra

win_game:
    li $v0, 4
    la $a0, msg_win
    syscall

    li $v0, 1
    move $a0, $s7      # Print current player
    syscall

    li $v0, 10         # Exit
    syscall
