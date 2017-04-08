# File:		connect4.asm
#
# Decription:
#		Go for the glory, go for the score;
#		Go for it! Connect Four!
#

#
# Constants for system calls.
#

#4 = 4		# code for syscall to print a string
#5 = 5		# code for syscall to read an integer

#
# Name:	Data areas
#
# Description:	Most of the data for the program is declared here.
#

#
# The ASCII strings.
#
	.data
	.align 0

title1: .ascii  "   ************************\n"
		.ascii	"   **    Connect Four    **\n"
		.asciiz	"   ************************\n\n"
		
board1: .asciiz "   0   1   2   3   4   5   6\n"

board2: .asciiz "+-----------------------------+\n"
		
board3: .asciiz "|+---+---+---+---+---+---+---+|\n"

line0:  .asciiz "\n"

line1:  .asciiz "|| "

line2:  .asciiz " | "

line3:  .asciiz " ||"

coin0:  .asciiz " "

coin1:  .asciiz "X"

coin2:  .asciiz "O"

play1:	.asciiz "Player 1"

play2:	.asciiz "Player 2"

pick:	.asciiz ": select a row to place your coin (0-6 or -1 to quit):"

badcol: .asciiz "Illegal column number.\n"

noroom: .asciiz "Illegal move, no more room in that column.\n"

isfull: .asciiz "The game ends in a tie.\n"

winner: .asciiz " wins!\n"

loser:  .asciiz " quit.\n"

#
# The board array initialized to blank spaces.
#
	.align 2

coinarray:	.word coin0, coin0, coin0, coin0, coin0, coin0, coin0
			.word coin0, coin0, coin0, coin0, coin0, coin0, coin0
			.word coin0, coin0, coin0, coin0, coin0, coin0, coin0
			.word coin0, coin0, coin0, coin0, coin0, coin0, coin0
			.word coin0, coin0, coin0, coin0, coin0, coin0, coin0
			.word coin0, coin0, coin0, coin0, coin0, coin0, coin0

#
# Name:	Main program
#
# Description:	Handles start up print statements then starts the game.
#
				# this is program code
	.align 2		# instructions must be on word boundaries
	.globl main		# main is a global label
.text
main:
	#M_FRAMESIZE = 8
	addi $sp, $sp, -8		# allocate space for the return address
	sw	 $ra, 4($sp)	# store the ra on the stack
	
	jal	startgame
	jal printboard
	jal playgame

#
# All done -- exit the program!
#
	lw	 $ra, 4($sp)	# restore the ra
	addi $sp, $sp, 8		# deallocate stack space 
	jr	 $ra						# return from main and exit spim
	
#
# Name:		startgame
#
# Description:	Prints out the game title.
#

	.text		# begin subroutine code
	
startgame:
	#START_FRAMESIZE = 16
	addi $sp, $sp, -16 
	sw	 $ra, 12($sp)	# store the ra on the stack
	sw	 $s0, 8($sp)	# store the s0 on the stack
	
#
# Prints the ASCII label containing the game title.
#
	li 	$v0, 4
	la 	$a0, title1
	syscall

#
# Return to the calling program.
#
	lw	 $s0, 8($sp)	# restore the s0
	lw	 $ra, 12($sp)	# restore the ra
	addi $sp, $sp, 16		# deallocate stack space 
	jr	 $ra
	
#
# Name:		printboard
#
# Description:	Prints the board with the values from the 
#				board array in their respective places.
#
	.text 		# begin subroutine code
	
printboard:

	#PRINT_FRAMESIZE = 16
	addi $sp, $sp, -16 
	sw	 $ra, 12($sp)	# store the ra on the stack
	sw	 $s0, 8($sp)	# store the s0 on the stack
	
	la	 $s0, coinarray
	add  $t0, $zero, $s0
	add  $t1, $zero, $zero
	addi $t2, $zero, 168		# t2 = max offset in the array
	addi $t3, $zero, 7			# t3 = numColumns
	addi $t4, $zero, 4			# t4 = index multiplier for array offset
	addi $t6, $zero, 6			# t6 = numRows
	
#
# Prints start of the board.
#
	li	$v0, 4
	la	$a0, board1
	syscall
	la	$a0, board2
	syscall
	la	$a0, board3
	syscall
	la	$a0, line1
	syscall

#
# Prints board array values in their respective places as well as
# the row separators.
#
printloop:
	lw	$a0, 0($t0)
	syscall
	div	 $t1, $t4
	mflo $t5
	div	 $t5, $t3
	mfhi $t5
	add  $t0, $t0, $t4
	addi $t1, $t1, 4
	beq  $t5, $t6, printloop2
	la   $a0, line2
	syscall
	j printloop

#
# Handles new lines in the board.
#
printloop2:
	li 	$v0, 4
	la  $a0, line3
	syscall
	beq $t1, $t2, printloopend
	la  $a0, line0
	syscall
	la  $a0, board3
	syscall
	la  $a0, line1
	syscall
	j printloop
	
printloopend:
	la 	$a0, line0
	syscall
	la 	$a0, board3
	syscall
	la 	$a0, board2
	syscall
	la 	$a0, board1
	syscall
	
#
# Return to the calling program.
#
	lw	 $s0, 8($sp)	# restore the s0
	lw	 $ra, 12($sp)	# restore the ra
	addi $sp, $sp, 16   	# deallocate stack space 
	jr	 $ra
	
#
# Name: playgame
#
# Description:	Handles all of the input and output after 
#				starting the game.
#
playgame:
	#PLAY_FRAMESIZE = 40

#
# Save registers ra and s0 - s7 on the stack.
#
	addi 	$sp, $sp, -40
	sw 	$ra, 36($sp)
	sw 	$s7, 28($sp)	
	sw 	$s6, 24($sp)	
	sw 	$s5, 20($sp)	# Direction checked boolean
	sw 	$s4, 16($sp)	# Top-right constant (6)
	sw 	$s3, 12($sp)	# Coin array address
	sw 	$s2, 8($sp)		# Index of dropped coin
	sw 	$s1, 4($sp)		# Player turn
	sw 	$s0, 0($sp)		# Player input
	
#
# Prepares for the prompt.
#
	li	$v0, 4
	la	$a0, line0
	syscall
	la	 $s3, coinarray
	addi $s4, $zero, 6
	add  $s5, $zero, $zero
	
#
# Prompt for Player 1.
#
playprompt1:
	bne $s1, $zero, playprompt2
	li	$v0, 4
	la	$a0, play1
	syscall
	j playprompt0

#
# Prompt for Player 2.
#
playprompt2:
	li	$v0, 4
	la	$a0, play2
	syscall

#
# Reads in player input and checks to see if it is valid.
#
playprompt0:
	la	$a0, pick
	syscall
	li	$v0, 5
	syscall
	move $s0, $v0
	addi $t0, $zero, -1
	beq  $s0, $t0, playquit
	bltz $s0, playillegal
	addi $t0, $s0, -6
	bgtz $t0, playillegal
	addi $t0, $s0, 35

#
# Checks to see where to place the coin.
#
playcoin:
	addi $t1, $zero, 4
	mult $t0, $t1
	mflo $t2
	move $t3, $s3
	add	 $t3, $t3, $t2
	lw	 $t4, 0($t3)
	la	 $t5, coin0
	bltz $t0, playillegal2
	move $s2, $t0
	addi $t0, $t0, -7
	bne $t4, $t5, playcoin
	bne $s1, $zero, playdrop2

#
# Drops Player 1's coin.
#
playdrop1:
	la	$t0, coin1
	sw	$t0, 0($t3)
	li	$v0, 4
	la	$a0, line0
	syscall
	jal printboard
	addi $s1, $zero, 1
	la	 $a0, line0
	syscall
	move $t0, $s3
	add  $t3, $zero, $zero
	j playcheckfull

#
# Drops Player 2's coin.
#
playdrop2:
	la	$t0, coin2
	sw	$t0, 0($t3)
	li	$v0, 4
	la	$a0, line0
	syscall
	jal printboard
	add $s1, $zero, $zero
	la	$a0, line0
	syscall
	move $t0, $s3
	add  $t3, $zero, $zero
	j playcheckfull

#
# Handles illegal column input.
#
playillegal:
	li	$v0, 4
	la	$a0, badcol
	syscall
	bne $s1, $zero, playprompt2
	j playprompt1

#
# Handles full column input.
#
playillegal2:
	li	$v0, 4
	la	$a0, noroom
	syscall
	bne $s1, $zero, playprompt2
	j playprompt1
	
#
# Prepares win checking with Player 1's coin.
#
playcheckwin1:
	bne $s1, $zero, playcheckwin2
	la	$t0, coin2
	j playcheckhori

#
# Prepares win checking with Player 2's coin.
#
playcheckwin2:
	la $t0, coin1
	
#
# Beginning of the win direction checking.
# Starts with horizontal win checking.
#
# $t0 is appropriate player's coin.
# $t3 is index of dropped coin.
#
playcheckhori:
	move $t3, $s2
	addi $t1, $zero, 7    # t1 = 7
	addi $t4, $zero, 4	  # t4 = 4
	bne	 $s5, $zero, playcheckhoriright
	addi $t5, $zero, 1	  # t5 = coin count
	div	 $t3, $t1
	mfhi $t2
	addi $s5, $zero, 1
	beq	 $t2, $zero, playcheckhoriright
	
#
# Checks for consecutive coin matches to the left of the dropped coin.
#
playcheckhorileft:
	addi $t3, $t3, -1
	div	 $t3, $t1
	mfhi $t2						# t2 = new index mod 7
	beq  $t2, $s4, playcheckhori	# if modded index = 6, checked all left, go right
	mult $t3, $t4
	mflo $t6						# t6 = offset of coin to be checked
	move $t7, $s3					# t7 = array address
	add  $t7, $t7, $t6
	lw	 $t6, 0($t7)
	bne  $t0, $t6, playcheckhori 	# if left coin not player's coin, try right
	addi $t5, $t5, 1
	beq	 $t5, $t4, playboardwin 	# if count = 4, win
	j playcheckhorileft

#
# Checks for consecutive coin matches to the right of the dropped coin.
#
playcheckhoriright:
	addi $t3, $t3, 1
	div	 $t3, $t1
	mfhi $t2						# t2 = new index mod 7
	beq	 $t2, $zero, playcheckverti # if modded index = 0, checked all right, go verti
	mult $t3, $t4
	mflo $t6						# t6 = offset of coin to be checked
	move $t7, $s3					# t7 = array address
	add	 $t7, $t7, $t6
	lw	 $t6, 0($t7)
	bne	 $t0, $t6, playcheckverti 	# if right coin not player's coin, try verti
	addi $t5, $t5, 1
	beq	 $t5, $t4, playboardwin 	# if count = 4, win
	j playcheckhoriright

#
# Sets up vertical win checking.
#
playcheckverti:
	move $t3, $s2
	addi $t1, $zero, 20
	addi $t4, $zero, 4	  			# t4 = 4
	addi $t5, $zero, 1	  			# t5 = coin count
	add	 $s5, $zero, $zero
	bgt	 $t3, $t1, playcheckdiagup	# if coin lower than 4th from bottom, try diagup
	addi $t1, $zero, 7    			# t1 = 7

#
# Checks for consecutive coin matches below the dropped coin.
#
playcheckvertidown:
	addi $t3, $t3, 7
	mult $t3, $t4
	mflo $t6						# t6 = offset of coin to be checked
	move $t7, $s3					# t7 = array address
	add	 $t7, $t7, $t6
	lw	 $t6, 0($t7)
	bne	 $t0, $t6, playcheckdiagup	# if lower coin not player's coin, try diagup
	addi $t5, $t5, 1
	beq	 $t5, $t4, playboardwin		# if count = 4, win
	j playcheckvertidown

#	
# Sets up diagonal-up ( / ) win checking.
#
playcheckdiagup:
	move $t3, $s2
	addi $t1, $zero, 34
	bgt	 $s2, $t1, playcheckdiagup2		# if coin on bottom row, skip to up-right
	addi $t1, $zero, 7    				# t1 = 7
	addi $t4, $zero, 4	  				# t4 = 4
	bne  $s5, $zero, playcheckdiagup2	# checks the directionChecked boolean
	addi $t5, $zero, 1	  				# t5 = coin count
	div  $t3, $t1
	mfhi $t2
	addi $s5, $zero, 1
	beq	 $t2, $zero, playcheckdiagup2	# if coin on far left, skip to up-right

#
# Checks for consecutive coin matches below and left of the dropped coin.
#
playcheckdiagup1:
	addi $t3, $t3, 6
	div	 $t3, $t1
	mfhi $t2						# t2 = new index mod 7
	beq  $t2, $s4, playcheckdiagup	# if modded index = 6, checked all left, go diagup
	addi $t2, $zero, 41
	bgt  $t3, $t2, playcheckdiagup	# if coin on bottom row, skip to diagup
	mult $t3, $t4
	mflo $t6						# t6 = offset of coin to be checked
	move $t7, $s3					# t7 = array address
	add  $t7, $t7, $t6
	lw	 $t6, 0($t7)
	bne  $t0, $t6, playcheckdiagup 	# if left coin not player's coin, try diagup
	addi $t5, $t5, 1
	beq	 $t5, $t4, playboardwin 	# if count = 4, win
	j playcheckdiagup1

#
# Checks for consecutive coin matches above and right of the dropped coin.
#
playcheckdiagup2:
	addi $t3, $t3, -6
	div	 $t3, $t1
	mfhi $t2								# t2 = new index mod 7
	beq  $t2, $zero, playcheckdiagdownfix	# if modded index = 0, checked all right, go diagdown
	blt  $t3, $zero, playcheckdiagdownfix	# if index less than the top-left, go diagdown
	mult $t3, $t4
	mflo $t6								# t6 = offset of coin to be checked
	move $t7, $s3							# t7 = array address
	add  $t7, $t7, $t6
	lw	 $t6, 0($t7)
	bne  $t0, $t6, playcheckdiagdownfix		# if left coin not player's coin, try diagdown
	addi $t5, $t5, 1
	beq  $t5, $t4, playboardwin				# if count = 4, win
	j playcheckdiagup2

#
# Fix to reset the directionChecked boolean.
#
playcheckdiagdownfix:
	add $s5, $zero, $zero

#	
# Sets up diagonal-down ( \ ) win checking.
#
playcheckdiagdown:
	move $t3, $s2
	addi $t1, $zero, 7    				# t1 = 7
	addi $t4, $zero, 4	 				# t4 = 4
	blt  $s2, $t1, playcheckdiagdown2	# if index at the top, go diagdown2
	bne  $s5, $zero, playcheckdiagdown2	# checks the directionChecked boolean
	addi $t5, $zero, 1	  				# t5 = coin count
	div  $t3, $t1
	mfhi $t2
	addi $s5, $zero, 1
	beq  $t2, $zero, playcheckdiagdown2	# if index at the far left, go diagdown2

#
# Checks for consecutive coin matches above and left of the dropped coin.
#
playcheckdiagdown1:
	addi $t3, $t3, -8
	div  $t3, $t1
	mfhi $t2							# t2 = new index mod 7
	beq  $t2, $s4, playcheckdiagdown	# if modded index = 6, checked all left, go diagdown
	blt  $t3, $zero, playcheckdiagdown	# if index at top of board, go diagdown
	mult $t3, $t4
	mflo $t6							# t6 = offset of coin to be checked
	move $t7, $s3						# t7 = array address
	add  $t7, $t7, $t6
	lw	 $t6, 0($t7)
	bne  $t0, $t6, playcheckdiagdown 	# if left coin not player's coin, try diagdown
	addi $t5, $t5, 1
	beq  $t5, $t4, playboardwin 		# if count = 4, win
	j playcheckdiagdown1

#
# Checks for consecutive coin matches below and right of the dropped coin.
#
playcheckdiagdown2:
	addi $t3, $t3, 8
	div  $t3, $t1
	mfhi $t2						# t2 = new index mod 7
	beq  $t2, $zero, playcheckdone 	# if modded index = 0, checked all right, go to the end
	addi $t2, $zero, 41
	bgt  $t3, $t2, playcheckdone	# if index at the bottom, go to the end
	mult $t3, $t4
	mflo $t6						# t6 = offset of coin to be checked
	move $t7, $s3					# t7 = array address
	add  $t7, $t7, $t6
	lw   $t6, 0($t7)
	bne  $t0, $t6, playcheckdone 	# if left coin not player's coin, go to the end
	addi $t5, $t5, 1
	beq  $t5, $t4, playboardwin 	# if count = 4, win
	j playcheckdiagdown2

#
# Finishes the win checking and returns to the prompt.
#
playcheckdone:
	add $s5, $zero, $zero
	bne $s1, $zero, playprompt2	
	j playprompt1 

#
# Checks for a full board.
#
playcheckfull:
	lw	 $t1, 0($t0)
	la	 $t2, coin0
	beq  $t1, $t2, playcheckwin1
	addi $t0, $t0, 4
	beq  $t3, $s4, playboardfull
	addi $t3, $t3, 1
	j playcheckfull

#
# Checks which player is the winner.
#
playboardwin:
	beq $s1, $zero, playboardwin2

#
# Declares Player 1 the winner.
#
playboardwin1:
	li	$v0, 4
	la	$a0, play1
	syscall
	la	$a0, winner
	syscall
	j playend

#
# Declares Player 2 the winner.
#
playboardwin2:
	li	$v0, 4
	la	$a0, play2
	syscall
	la	$a0, winner
	syscall
	j playend

#
# Announces that the game is a tie.
#
playboardfull:
	li	$v0, 4
	la	$a0, isfull
	syscall
	j playend
	
#
# Announces that Player 1 quit the game.
#
playquit:
	bne $s1, $zero, playquit2
	li	$v0, 4
	la	$a0, play1
	syscall
	la	$a0, loser
	syscall
	j playend

#
# Announces that Player 2 quit the game.
#
playquit2:
	li	$v0, 4
	la	$a0, play2
	syscall
	la	$a0, loser
	syscall
	
playend:

#
# Restore registers ra and s0 - s7 from the stack.
#
	lw 	$ra, 36($sp)
	lw 	$s7, 28($sp)
	lw 	$s6, 24($sp)
	lw 	$s5, 20($sp)
	lw 	$s4, 16($sp)
	lw 	$s3, 12($sp)
	lw 	$s2, 8($sp)
	lw 	$s1, 4($sp)
	lw 	$s0, 0($sp)
	addi 	$sp, $sp, 40
	jr	$ra
	
