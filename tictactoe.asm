.data
newline:        .asciiz "\n"
space:          .asciiz " "
msg_size:       .asciiz "Stone size (1: small, 2: medium, 3: large): "
msg_index:      .asciiz "Board index (0-8): "
msg_invalid:    .asciiz "Invalid move! Please try again.\n"
msg_no_stock:   .asciiz "You have no stones of this size left! Please choose another.\n"
msg_valid:      .asciiz "Move successfully made.\n"
msg_board:      .asciiz "\nCurrent Board:\n"
msg_turn1:      .asciiz "Player 1's turn\n"
msg_turn2:      .asciiz "Player 2's turn\n"
msg_win:        .asciiz "\nPlayer "
msg_win_end:    .asciiz " wins!\n" 
cell_empty:     .asciiz "[ ]"

.text
.globl main

main:
    # Reset the board
    li $s7, 1
    la $s0, board
init_board_loop:
    li $t1, 0
    sw $t1, 0($s0)
    addiu $s0, $s0, 4
    addiu $t0, $t0, 1
    li $t2, 9
    blt $t0, $t2, init_board_loop

    # Oyuncu 1 stock: s1-s3
    li $s1, 3  # small
    li $s2, 3  # medium
    li $s3, 3  # large

    # Oyuncu 2 stock: s4-s6
    li $s4, 3
    li $s5, 3
    li $s6, 3

    li $t1, 1  # First Player 1

game_loop:
    # Player message
    li $v0, 4
    beq $s7, 1, show_turn1
    la $a0, msg_turn2
    syscall
    j ask_size
show_turn1:
    la $a0, msg_turn1
    syscall

ask_size:
    # Get stone size
    li $v0, 4
    la $a0, msg_size
    syscall
    li $v0, 5
    syscall
    move $t2, $v0  # taþ boyutu

    # Stoðu kontrol et
    beq $s7, 1, check_stock1
    beq $s7, 2, check_stock2

check_stock1:
    beq $t2, 1, ck_s1
    beq $t2, 2, ck_s2
    beq $t2, 3, ck_s3
ck_s1: blez $s1, no_stock
       addi $s1, $s1, -1
       j stock_checked
ck_s2: blez $s2, no_stock
       addi $s2, $s2, -1
       j stock_checked
ck_s3: blez $s3, no_stock
       addi $s3, $s3, -1
       j stock_checked

check_stock2:
    beq $t2, 1, ck_s4
    beq $t2, 2, ck_s5
    beq $t2, 3, ck_s6
ck_s4: blez $s4, no_stock
       addi $s4, $s4, -1
       j stock_checked
ck_s5: blez $s5, no_stock
       addi $s5, $s5, -1
       j stock_checked
ck_s6: blez $s6, no_stock
       addi $s6, $s6, -1
       j stock_checked

no_stock:
    li $v0, 4
    la $a0, msg_no_stock
    syscall
    j game_loop

stock_checked:
    li $v0, 4
    la $a0, msg_index
    syscall
    li $v0, 5
    syscall
    move $t3, $v0  # indeks

    # Hücre adresi
    la $t4, board
    li $t5, 4
    mul $t6, $t3, $t5
    add $t4, $t4, $t6

    lw $t7, 0($t4)
    bnez $t7, compare_size
    j place

compare_size:
    ble $t2, $t7, invalid_move  # Küçük taþ konulamaz

place:
    sw $t2, 0($t4)
    li $v0, 4
    la $a0, msg_valid
    syscall

    jal print_board
    jal check_win
    

    # Oyuncu deðiþtir
    li $t8, 1
    beq $s7, $t8, switch_to_2
    li $s7, 1
    j game_loop
switch_to_2:
    li $s7, 2
    j game_loop

invalid_move:
    li $v0, 4
    la $a0, msg_invalid
    syscall

    # Stok iade
    beq $s7, 1, refund1
    beq $s7, 2, refund2

refund1:
    beq $t2, 1, r1s1
    beq $t2, 2, r1s2
    beq $t2, 3, r1s3
r1s1: addi $s1, $s1, 1
      j game_loop
r1s2: addi $s2, $s2, 1
      j game_loop
r1s3: addi $s3, $s3, 1
      j game_loop

refund2:
    beq $t2, 1, r2s4
    beq $t2, 2, r2s5
    beq $t2, 3, r2s6
r2s4: addi $s4, $s4, 1
      j game_loop
r2s5: addi $s5, $s5, 1
      j game_loop
r2s6: addi $s6, $s6, 1
      j game_loop



    
print_board:
    li $t0, 0
    la $s0, board
    li $v0, 4
    la $a0, msg_board
    syscall
print_loop:
    lw $t1, 0($s0)
    beqz $t1, print_empty
    li $v0, 1
    move $a0, $t1
    syscall
    li $v0, 4
    la $a0, space
    syscall
    j print_next
print_empty:
    li $v0, 4
    la $a0, cell_empty
    syscall
print_next:
    addiu $s0, $s0, 4
    addiu $t0, $t0, 1
    li $t2, 3
    remu $t3, $t0, $t2
    bnez $t3, continue
    li $v0, 4
    la $a0, newline
    syscall
continue:
    li $t2, 9
    blt $t0, $t2, print_loop
    jr $ra

check_win:
    la $t0, board
    la $t9, win_indices
    li $t8, 8
    li $t1, 0
win_loop:
    lw $t4, 0($t9)
    lw $t5, 4($t9)
    lw $t6, 8($t9)

    la $t7, board
    mul $t4, $t4, 4
    mul $t5, $t5, 4
    mul $t6, $t6, 4

    add $a1, $t7, $t4
    add $a2, $t7, $t5
    add $a3, $t7, $t6

    lw $t4, 0($a1)
    lw $t5, 0($a2)
    lw $t6, 0($a3)

    li $t0, 3
    bne $t4, $t0, skip
    bne $t5, $t0, skip
    bne $t6, $t0, skip

    li $v0, 4
    la $a0, msg_win
    syscall
    li $v0, 1
    move $a0, $s7
    syscall
    li $v0, 4
    la $a0, msg_win_end
    syscall
    li $v0, 10
    syscall

skip:
    addiu $t9, $t9, 12
    addiu $t1, $t1, 1
    blt $t1, $t8, win_loop
    jr $ra

.data
.align 2
board: .space 36
.align 2
win_indices:
    .word 0,1,2
    .word 3,4,5
    .word 6,7,8
    .word 0,3,6
    .word 1,4,7
    .word 2,5,8
    .word 0,4,8
    .word 2,4,6
