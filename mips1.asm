.data
.align 2
board:              .space 324
.align 2
mini_status:        .space 36
.align 2
current_target:     .word -1

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
msg_index:          .asciiz "Tahta hucre indeksi (0-8): "
msg_choose_board:   .asciiz "Mini tahtayi secin (0-8): "
msg_invalid_board:  .asciiz "Bu mini tahta dolu veya kazanilmis. Baska secin.\n"
msg_invalid_move:   .asciiz "Gecersiz hamle! Tekrar deneyin.\n"
msg_valid_move:     .asciiz "Hamle yapildi.\n"
msg_turn1:          .asciiz "\nOyuncu 1'in sirasi\n"
msg_turn2:          .asciiz "\nOyuncu 2'in sirasi\n"
msg_win:            .asciiz "\nOyunu kazanan oyuncu: "
cell_empty:         .asciiz "[ ]"
left_bracket:       .asciiz "["
right_bracket:      .asciiz "]"

.text
.globl main

main:
    li $s7, 1
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
    jal get_target_board
    jal print_ultimate_board

    li $v0, 4
    la $a0, msg_size
    syscall
    li $v0, 5
    syscall
    move $t0, $v0  # New stone size

    # Validate stone size (must be 1, 2, or 3)
    li $t2, 1
    blt $t0, $t2, invalid_move
    li $t2, 3
    bgt $t0, $t2, invalid_move

    li $v0, 4
    la $a0, msg_index
    syscall
    li $v0, 5
    syscall
    move $t1, $v0  # Cell index

    li $t2, 9
    mul $t3, $s0, $t2
    add $t3, $t3, $t1
    sll $t3, $t3, 2
    la $t5, board
    add $t5, $t5, $t3

    lw $t6, 0($t5)
    beqz $t6, store_stone

    li $t7, 10
    divu $t6, $t7
    mflo $t9     # Existing player
    mfhi $t8     # Existing size

    ble $t0, $t8, invalid_move  # Must be larger
    beq $s7, $t9, invalid_move  # Can't overwrite own stone

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

get_target_board:
    lw $t0, current_target
    bltz $t0, ask_board
    la $t1, mini_status
    li $t2, 4
    mul $t3, $t0, $t2
    add $t1, $t1, $t3
    lw $t4, 0($t1)
    bnez $t4, ask_board
    move $s0, $t0
    jr $ra

ask_board:
    li $v0, 4
    la $a0, msg_choose_board
    syscall
    li $v0, 5
    syscall
    move $s0, $v0
    la $t1, mini_status
    li $t2, 4
    mul $t3, $s0, $t2
    add $t1, $t1, $t3
    lw $t4, 0($t1)
    bnez $t4, ask_board_invalid
    jr $ra

ask_board_invalid:
    li $v0, 4
    la $a0, msg_invalid_board
    syscall
    j ask_board

check_ultimate_win:
    la $t0, ultimate_win_indices
    li $t1, 8
    li $t2, 0
loop_check:
    lw $t3, 0($t0)
    lw $t4, 4($t0)
    lw $t5, 8($t0)

    la $t6, mini_status
    li $t7, 4

    mul $t8, $t3, $t7
    add $t9, $t6, $t8
    lw $s0, 0($t9)

    mul $t8, $t4, $t7
    add $t9, $t6, $t8
    lw $s1, 0($t9)

    mul $t8, $t5, $t7
    add $t9, $t6, $t8
    lw $s2, 0($t9)

    beqz $s0, skip
    bne $s0, $s1, skip
    bne $s1, $s2, skip

    li $v0, 4
    la $a0, msg_win
    syscall
    li $v0, 1
    move $a0, $s7
    syscall
    li $v0, 10
    syscall

skip:
    addiu $t0, $t0, 12
    addiu $t2, $t2, 1
    blt $t2, $t1, loop_check
    jr $ra

check_mini_win:
    move $t5, $s0      # Save mini-board index
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
    mul $t8, $t5, 4          # Use saved mini-board index
    add $t9, $t9, $t8
    sw $s7, 0($t9)
    jr $ra
    jr $ra

skip_mini_check:
    addiu $t2, $t2, 12
    addiu $t4, $t4, 1
    blt $t4, $t3, mini_win_loop
    jr $ra

print_ultimate_board:
    li $t0, 0          # cell index
print_outer_loop:
    li $t1, 0          # column in row
print_inner_loop:
    la $t2, board
    sll $t3, $t0, 2
    add $t3, $t3, $t2
    lw $t4, 0($t3)

    li $v0, 4
    la $a0, left_bracket
    syscall

    beqz $t4, print_space
    li $t5, 10
    divu $t4, $t5
    mflo $t6     # player
    mfhi $t7     # size
    li $v0, 1
    move $a0, $t7
    syscall
    li $v0, 11
    li $a0, 'x'
    beq $t6, 1, pr_p
    li $a0, 'y'
pr_p:
    syscall
    j print_close

print_space:
    li $v0, 4
    la $a0, space
    syscall
    li $v0, 4
    la $a0, space
    syscall

print_close:
    li $v0, 4
    la $a0, right_bracket
    syscall

    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    li $t5, 9
    remu $t6, $t0, $t5
    bnez $t6, skip_newline
    li $v0, 4
    la $a0, newline
    syscall

skip_newline:
    li $t5, 81
    blt $t0, $t5, print_inner_loop
    li $v0, 4
    la $a0, newline
    syscall
    jr $ra
