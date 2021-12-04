#  -------------------------------------
#
#  Sudoku Solver
#
#  -------------------------------------
#
#  MIPS assembly language program to 
#  brute-force solve a Sudoku puzzle.
#
#  To solve a puzzle, enter its values 
#  in the PGrid array below, leaving 0's
#  in indices where no value is present.
#  If a puzzle cannot be solved, the 
#  program should return a suitable 
#  message.
#
#  I, Nathan Douglas, the creator of 
#  this program, hereby renounce all 
#  copyrights on this material and release 
#  this application and its source code 
#  into the Public Domain.
#
#  -------------------------------------
#
#  Data Segment
#
#  -------------------------------------

.data

hdr:      .asciiz   "\nMIPS Assembly Sudoku Solver \n"

TRUE          =   1
FALSE         =   0
GRID_SIZE     =   9
SUB_GRID_SIZE =   3

new_ln:   .asciiz   "\n"

PGrid:    .word   4,0,7,0,0,0,0,0,0
          .word   0,3,9,0,0,5,6,1,4
          .word   0,6,5,0,3,0,0,0,0
          .word   0,9,0,0,1,2,0,7,3
          .word   0,4,0,5,0,7,0,9,0
          .word   6,7,0,9,4,0,0,2,0
          .word   0,0,0,0,2,0,7,4,0
          .word   9,2,4,7,0,0,5,3,0
          .word   0,0,0,0,0,0,2,0,8

SGrid:    .space    324

found:    .byte   FALSE,FALSE,FALSE,FALSE,FALSE
          .byte   FALSE,FALSE,FALSE,FALSE,FALSE
 
top_ln:   .asciiz   "  +-------+-------+-------+ \n"
bar:      .asciiz   "| "
space:    .asciiz   " "
space2:   .asciiz   "  "
wtf_msg:  .asciiz   "\nUnknown failure encountered :(\n"
fail_msg: .asciiz   "\nFailed to solve puzzle :(\n"

#  -------------------------------------
#
#  Text/Code Segment
#
#  -------------------------------------

.text
.globl main
.ent main

main:

  print_header:
    # Print a nice header to explain what we're trying to do.
    la $a0, hdr                   # Set $a0 (&hdr).
    li $v0, 4                     # Set $v0 (print string).
    syscall                       # Print header.
    la $a0, new_ln                # Set $a0 (new_ln).
    li $v0, 4                     # Set $v0 (print string).
    syscall                       # Print new line.

  copy_puzzle_init:
    # Prepare to copy the supplied puzzle to the working copy.
    la $s0, PGrid                 # Set $s0 (&PGrid[]).
    la $s1, SGrid                 # Set $s1 (&SGrid[]).  
    li $s2, GRID_SIZE             # Set $s2 (GRID_SIZE).
    mul $s2, $s2, $s2             # Set $s2 (GRID_SIZE^2).

  copy_puzzle_loop:
    # Copy the supplied puzzle to the working copy.
    lw $s3, ($s0)                 # Set $s3 (PGrid[n]).
    sw $s3, ($s1)                 # Set SGrid[n].
    addu $s0, $s0, 4              # Increment $s0 (&PGrid[]).
    addu $s1, $s1, 4              # Increment $s1 (&SGrid[]).
    subu $s2, $s2, 1              # Decrement $s2 (counter).
    bge $s2, 0, copy_puzzle_loop  # Loop throughout PGrid[]/SGrid[].

  solve_puzzle:
    # Solve the puzzle, if possible.
    la $a0, PGrid                 # Set $a0 (&PGrid[]).
    la $a1, SGrid                 # Set $a1 (&SGrid[]).
    jal solvePuzzle               # Solve the puzzle.

  check_solve:
    # Check the return value from the solver and act accordingly.
    move $s0, $v0                 # Set $v0 (return value).
    beq $s0, FALSE, solve_failure # Failed to solve this puzzle.
    beq $s0, TRUE, solve_success  # Successfully solved this puzzle.

  solve_wtf:
    # Something weird happened!  Complain.
    la $a0, wtf_msg               # Set $a0 (&wtf_msg).
    li $v0, 4                     # Set $v0 (print string).
    syscall                       # Print error message.
    b main_end                    # Jump to termination.

  solve_failure:
    # We failed!  Complain.
    la $a0, fail_msg              # Set $a0 (&fail_msg).
    li $v0, 4                     # Set $v0 (print string).
    syscall                       # Print failure message.
    la $a0, SGrid                 # Set $a0 (&SGrid[]).
    li $a1, TRUE                  # Set $a1 (TRUE).
    jal DisplaySudoku             # Print the solved puzzle.    
    b main_end                    # Jump to termination.

  solve_success:
    # We did it!  Beg for extra credit.
    la $a0, SGrid                 # Set $a0 (&SGrid[]).
    li $a1, TRUE                  # Set $a1 (TRUE).
    jal DisplaySudoku             # Print the solved puzzle.    
    b main_end                    # Jump to termination.

  main_end:
    # Terminate the application.
    li $v0, 10                    # Set $v0 (terminate application).
    syscall                       # Terminate application.

.end main

#  -------------------------------------
#  Procedure to solve a Sudoku puzzle.
#
#  The method is follows:
#    I.  Check to see if the current space is occupied in the problem grid.
#       A.  If so, skip to the next space.
#       B.  If not, insert a number and validate.
#           1.  If valid, proceed to the next space.
#           2.  If not valid, attempt to insert the next number and repeat.
#               a.  If we run through 1 through GRID_SIZE, backtrack.
#               b.  Otherwise, just insert the next number.
#
#  Arguments:
#    $a0 [address] - Problem grid.
#    $a1 [address] - Solution grid.
#
#  Return value:
#    $v0 [boolean] - If we found a valid solution.

.globl solvePuzzle
.ent solvePuzzle

solvePuzzle:
  solve_push:
    # Perform some pushes to keep from screwing anything up.
    subu $sp, $sp, 48             # Increase stack pointer address.
    sw $fp, ($sp)                 # Push $fp.
    sw $ra, 4($sp)                # Push $ra.
    sw $a0, 8($sp)                # Push $a0.
    sw $a1, 12($sp)               # Push $a1.
    sw $a2, 16($sp)               # Push $a2.
    sw $s0, 20($sp)               # Push $s0.
    sw $s1, 24($sp)               # Push $s1.
    sw $s2, 28($sp)               # Push $s2.
    sw $s3, 32($sp)               # Push $s3.
    sw $s4, 36($sp)               # Push $s4.
    sw $s5, 40($sp)               # Push $s5.
    sw $s6, 44($sp)               # Push $s6.
    addu $fp, $sp, 48             # Set $fp (frame pointer).

  solve_init:
    # Initialize procedure.
    move $s0, $a0                 # Set $s0 (&PGrid[]).
    move $s1, $a1                 # Set $s1 (&SGrid[]).
    move $s2, $zero               # Set $s2 (x).
    move $s3, $zero               # Set $s3 (y).
    li $s4, TRUE                  # Set $s4 (direction).

  solve_loop:
    # Loop managing solution process.

  solve_isset:
    mul $t0, $s3, GRID_SIZE       # Set $t0 (y*y_dim).
    addu $t0, $t0, $s2            # Set $t0 (y*y_dim+x).
    mul $t0, $t0, 4               # Set $t0 ([y*y_dim+x]).
    addu $t0, $t0, $s0            # Set $t0 (&PGrid[x,y]).
    lw $t1, ($t0)                 # Set $t1 (PGrid[x,y]).
    bne $t1, $zero, solve_step    # If filled, skip this square.

  solve_set:
    # Manipulate this square.
    move $a0, $s1                 # Set $a0 (&SGrid[]).
    move $a1, $s2                 # Set $a1 (x).
    move $a2, $s3                 # Set $a2 (y).
    jal setSquare                 # Manipulate this square directly.
    move $s4, $v0                 # Set $s4 (direction).
    b solve_step                  # Continue.

  solve_step:
    # Proceed to the previous or next square.
    beq $s4, FALSE, solve_prev    # Go backwards.
    beq $s4, TRUE, solve_next     # Go forwards.

  solve_prev:
    # Step backward.
    subu $s2, $s2, 1                # Decrement x.
    bge $s2, $zero, solve_loop_end  # Continue, in most cases.
    addu $s2, $s2, GRID_SIZE        # Reset x.
    subu $s3, $s3, 1                # Decrement y.
    blt $s3, $zero, solve_fail      # We failed!
    b solve_loop_end                # Continue loop.

  solve_next:
    # Step forward.
    addu $s2, $s2, 1                    # Increment x.
    blt $s2, GRID_SIZE, solve_loop_end  # Continue, in most cases.
    subu $s2, $s2, GRID_SIZE            # Reset x.
    addu $s3, $s3, 1                    # Increment y.
    bge $s3, GRID_SIZE, solve_win       # We succeeded!
    b solve_loop_end                    # Continue loop.

  solve_loop_end:
    # Exit or continue loop.
    b solve_loop                  # Continue loop.

  solve_win:
    # We successfully solved this puzzle.
    li $v0, TRUE                  # Set return value to true.
    b solve_end                   # Skip to the end.

  solve_fail:
    # We failed to solve this puzzle.
    li $v0, FALSE                 # Set return value to false.
    b solve_end                   # Skip to the end.

  solve_end:
    # Finish up.

  solve_pop:
    # Restore affected registers.
    lw $fp, ($sp)                 # Pop $fp.
    lw $ra, 4($sp)                # Pop $ra.
    lw $a0, 8($sp)                # Pop $a0.
    lw $a1, 12($sp)               # Pop $a1.
    lw $a2, 16($sp)               # Pop $a2.
    lw $s0, 20($sp)               # Pop $s0.
    lw $s1, 24($sp)               # Pop $s1.
    lw $s2, 28($sp)               # Pop $s2.
    lw $s3, 32($sp)               # Pop $s3.
    lw $s4, 36($sp)               # Pop $s4.
    lw $s5, 40($sp)               # Pop $s5.
    lw $s6, 44($sp)               # Pop $s6.
    addu $sp, $sp, 48             # Reset stack pointer address.
    jr $ra                        # Return to caller.

.end solvePuzzle

#  -------------------------------------
#  Procedure to set and validate a specific square of a Sudoku puzzle.
#
#  Arguments:
#    $a0 [address] - Solution grid.
#    $a1 [value] - X coordinate of square.
#    $a2 [value] - Y coordinate of square.
#
#  Return value:
#    $v0 [boolean] - If we found a valid solution.

.globl setSquare
.ent setSquare

setSquare:
  square_push:
    # Perform some pushes to keep from screwing anything up.
    subu $sp, $sp, 48     # Increase stack pointer address.
    sw $fp, ($sp)         # Push $fp.
    sw $ra, 4($sp)        # Push $ra.
    sw $a0, 8($sp)        # Push $a0.
    sw $a1, 12($sp)       # Push $a1.
    sw $a2, 16($sp)       # Push $a2.
    sw $s0, 20($sp)       # Push $s0.
    sw $s1, 24($sp)       # Push $s1.
    sw $s2, 28($sp)       # Push $s2.
    sw $s3, 32($sp)       # Push $s3.
    sw $s4, 36($sp)       # Push $s4.
    sw $s5, 40($sp)       # Push $s5.
    sw $s6, 44($sp)       # Push $s6.
    addu $fp, $sp, 48     # Set $fp (frame pointer).

  square_init:
    # Initialize values for procedure.
    move $s0, $a0             # Set $s0 (&SGrid[]).
    move $s1, $a1             # Set $s1 (x).
    move $s2, $a2             # Set $s2 (y).
    mul $s3, $s2, GRID_SIZE   # Set $s3 (y*y_dim).
    addu $s3, $s3, $s1        # Set $s3 (y*y_dim+x).
    mul $s3, $s3, 4           # Set $s3 ([y*y_dim+x]).
    addu $s3, $s0, $s3        # Set $s3 (&SGrid[x,y]).

  square_check:
    # Check to see if current square value needs to be reset.
    lw $s4, ($s3)                         # Set $s4 (insertion candidate).
    blt $s4, GRID_SIZE, square_start      # If maxxed out, reset.
    sw $zero, ($s3)                       # Reset value to 0.
    b square_loop_end                     # Otherwise, jump to the end.

  square_start:
    # Initialize for the loop.
    addu $s4, $s4, 1            # Increment $s4 (candidate).

  square_loop:
    # Insert value.
    sw $s4, ($s3)               # Insert candidate.

  square_vrow:
    # Verify row.
    move $a0, $s0                         # Set $a0 (&SGrid[]).
    move $a1, $s2                         # Set $a1 (y).
    jal checkRow                          # Check the row.
    beq $v0, FALSE, square_loop_end       # Jump to end of loop if invalid.

  square_vcol:
    # Verify column.
    move $a0, $s0                         # Set $a0 (&SGrid[]).
    move $a1, $s1                         # Set $a1 (x).
    jal checkCol                          # Check the column.
    beq $v0, FALSE, square_loop_end       # Jump to end of loop if invalid.

  square_vsub:
    # Verify the subgrid of the current square.
    move $a0, $s0                         # Set $a0 (&SGrid[]).
    move $a1, $s1                         # Set $a1 (x).
    move $a2, $s2                         # Set $a2 (y).
    jal checkSub                          # Check the subgrid.
    beq $v0, FALSE, square_loop_end       # Jump to end of loop if invalid.

  square_vpass:
    # Value not eliminated.
    li $v0, TRUE                # This value was valid!
    b square_end                # Branch to the end.

  square_loop_end:
    # Complete and continue the loop.
    addu $s4, $s4, 1                    # Increment $s4 (candidate).
    ble $s4, GRID_SIZE, square_loop     # Loop throughout possibilities.
    li $v0, FALSE                       # Oops, couldn't find a valid value.
    sw $zero, ($s3)                     # Set this square's value to 0.
    b square_end                        # Branch to the end.

  square_end:
    # Wrap up this procedure.
 
  square_pop:
    # Pop affected registers.
    lw $fp, ($sp)                       # Pop $fp.
    lw $ra, 4($sp)                      # Pop $ra.
    lw $a0, 8($sp)                      # Pop $a0.
    lw $a1, 12($sp)                     # Pop $a1.
    lw $a2, 16($sp)                     # Pop $a2.
    lw $s0, 20($sp)                     # Pop $s0.
    lw $s1, 24($sp)                     # Pop $s1.
    lw $s2, 28($sp)                     # Pop $s2.
    lw $s3, 32($sp)                     # Pop $s3.
    lw $s4, 36($sp)                     # Pop $s4.
    lw $s5, 40($sp)                     # Pop $s5.
    lw $s6, 44($sp)                     # Pop $s6.
    addu $sp, $sp, 48                   # Reset stack pointer address.
    jr $ra                              # Return to caller.

.end setSquare

#  -------------------------------------
#  Function to check a row.
#
#  Arguments:
#    $a0 [address] - Address of the solution grid.
#    $a1 [value] - Y coordinate of row.
#
#  Returns
#    $v0 [boolean] - If row passed verification.
#

.globl checkRow
.ent checkRow

checkRow:
  row_push:
    # Push affected registers.
    subu $sp, $sp, 48       # Increase stack pointer address.
    sw $fp, ($sp)           # Push $fp.
    sw $ra, 4($sp)          # Push $ra.
    sw $a0, 8($sp)          # Push $a0.
    sw $a1, 12($sp)         # Push $a1.
    sw $a2, 16($sp)         # Push $a2.
    sw $s0, 20($sp)         # Push $s0.
    sw $s1, 24($sp)         # Push $s1.
    sw $s2, 28($sp)         # Push $s2.
    sw $s3, 32($sp)         # Push $s3.
    sw $s4, 36($sp)         # Push $s4.
    sw $s5, 40($sp)         # Push $s5.
    sw $s6, 44($sp)         # Push $s6.
    addu $fp, $sp, 48       # Set $fp (frame pointer).

  row_init:    
    # Set up the row validation loop.
    jal zeroFoundArray      # Zero the found array.
    move $s0, $a0           # Set $s0 (&SGrid[]).
    li $s1, GRID_SIZE       # Set $s1 (GRID_SIZE).
    mul $s2, $s1, $a1       # Set $s2 (y*y_dim).
    mul $s2, $s2, 4         # Set $s2 ([y*y_dim]).
    addu $s2, $s0, $s2      # Set $s2 (&SGrid[0,y]).

  row_loop:
    # Loop through the squares of this row.
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, row_loop_end      # If unset, skip.
    jal checkFoundNumber              # Check this number.
    bne $v0, TRUE, row_pop            # If not new, bail.

  row_loop_end:
    # Loop maintenance and continuance.
    addu $s2, $s2, 4                  # Increment $s2 (&SGrid[x,y]).
    subu $s1, $s1, 1                  # Decrement $s1 (counter).
    bgt $s1, $zero, row_loop          # Continue through row.
    li $v0, TRUE                      # We've made it through!

  row_pop:
    # Pop affected registers.
    lw $fp, ($sp)               # Pop $fp.
    lw $ra, 4($sp)              # Pop $ra.
    lw $a0, 8($sp)              # Pop $a0.
    lw $a1, 12($sp)             # Pop $a1.
    lw $a2, 16($sp)             # Pop $a2.
    lw $s0, 20($sp)             # Pop $s0.
    lw $s1, 24($sp)             # Pop $s1.
    lw $s2, 28($sp)             # Pop $s2.
    lw $s3, 32($sp)             # Pop $s3.
    lw $s4, 36($sp)             # Pop $s4.
    lw $s5, 40($sp)             # Pop $s5.
    lw $s6, 44($sp)             # Pop $s6.
    addu $sp, $sp, 48           # Reset stack pointer address.
    jr $ra                      # Return to caller.

.end checkRow
 
#  -------------------------------------
#  Function to check a column.
#
#  Arguments:
#    $a0 [address] - Address of the solution grid.
#    $a1 [value] - X coordinate of column.
#
#  Returns
#    $v0 [boolean] - If column passed verification.
#

.globl checkCol
.ent checkCol

checkCol:
  col_push:
    # Push affected registers.
    subu $sp, $sp, 48         # Increase stack pointer address.
    sw $fp, ($sp)             # Push $fp.
    sw $ra, 4($sp)            # Push $ra.
    sw $a0, 8($sp)            # Push $a0.
    sw $a1, 12($sp)           # Push $a1.
    sw $a2, 16($sp)           # Push $a2.
    sw $s0, 20($sp)           # Push $s0.
    sw $s1, 24($sp)           # Push $s1.
    sw $s2, 28($sp)           # Push $s2.
    sw $s3, 32($sp)           # Push $s3.
    sw $s4, 36($sp)           # Push $s4.
    sw $s5, 40($sp)           # Push $s5.
    sw $s6, 44($sp)           # Push $s6.
    addu $fp, $sp, 48         # Set $fp (frame pointer).

  col_init:    
    # Set up the column validation loop.
    jal zeroFoundArray      # Zero the found[] array.
    move $s0, $a0           # Set $s0 (&SGrid[]).
    move $s1, $a1           # SEt $s1 (x).
    li $s2, GRID_SIZE       # Set $s2 (GRID_SIZE).
    mul $s2, $s2, 4         # Set $s2 (GRID_SIZE*4).
    mul $s3, $s1, 4         # Set $s3 ([x]).
    addu $s3, $s0, $s3      # Set $s3 (&SGrid[x]).
    li $s4, GRID_SIZE       # Set $s4 (GRID_SIZE).

  col_loop:
    # Loop through the squares of this column.
    lw $a0, ($s3)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, col_loop_end      # If unset, skip check.
    jal checkFoundNumber              # Check to see if this is a new number.
    bne $v0, TRUE, col_fail           # If not, bail.

  col_loop_end:
    # Loop maintenance and continuation.
    addu $s3, $s3, $s2                # Increment $s3 (&SGrid[x,y]).
    subu $s4, $s4, 1                  # Decrement $s4 (counter).
    bne $s4, $zero, col_loop          # Continue through column.
    b col_succeed                     # We've made it through!

  col_succeed:
    # This column is valid.
    li $v0, TRUE                      # This column is valid.
    b col_end                         # Skip to the end.

  col_fail:
    # This column is invalid.
    li $v0, FALSE                     # This column is invalid.
    b col_end                         # Skip to the end.
 
  col_end:
  col_pop:
    # Pop affected registers.
    lw $fp, ($sp)               # Pop $fp.
    lw $ra, 4($sp)              # Pop $ra.
    lw $a0, 8($sp)              # Pop $a0.
    lw $a1, 12($sp)             # Pop $a1.
    lw $a2, 16($sp)             # Pop $a2.
    lw $s0, 20($sp)             # Pop $s0.
    lw $s1, 24($sp)             # Pop $s1.
    lw $s2, 28($sp)             # Pop $s2.
    lw $s3, 32($sp)             # Pop $s3.
    lw $s4, 36($sp)             # Pop $s4.
    lw $s5, 40($sp)             # Pop $s5.
    lw $s6, 44($sp)             # Pop $s6.
    addu $sp, $sp, 48           # Reset stack pointer address.
    jr $ra                      # Return to caller.

.end checkCol

#  -------------------------------------
#  Function to check a subgrid.
#
#  Arguments:
#    $a0 [address] - Address of the solution grid.
#    $a1 [value] - X coordinate of square.
#    $a2 [value] - Y coordinate of square.
#
#  Returns
#    $v0 [boolean] - If subgrid passed verification.
#
 
.globl checkSub
.ent checkSub

checkSub: 
  sub_push:
    # Push affected registers.
    subu $sp, $sp, 48             # Increase stack pointer address.
    sw $fp, ($sp)                 # Push $fp.
    sw $ra, 4($sp)                # Push $ra.
    sw $a0, 8($sp)                # Push $a0.
    sw $a1, 12($sp)               # Push $a1.
    sw $a2, 16($sp)               # Push $a2.
    sw $s0, 20($sp)               # Push $s0.
    sw $s1, 24($sp)               # Push $s1.
    sw $s2, 28($sp)               # Push $s2.
    sw $s3, 32($sp)               # Push $s3.
    sw $s4, 36($sp)               # Push $s4.
    sw $s5, 40($sp)               # Push $s5.
    sw $s6, 44($sp)               # Push $s6.
    addu $fp, $sp, 48             # Set $fp (frame pointer).

  sub_init:    
    # Set up the subgrid validation loop.
    jal zeroFoundArray                # Zero the found array.
    move $t0, $a0                     # Set $t0 (&SGrid[]).
    move $t1, $a1                     # Set $t1 (x).
    div $t1, $t1, SUB_GRID_SIZE       # Set $t1 (subgrid_x).
    move $t2, $a2                     # Set $t2 (y).
    div $t2, $t2, SUB_GRID_SIZE       # Set $t2 (subgrid_y).
    move $s0, $t0                     # Set $s0 (&SGrid[]).
    mul $s1, $t1, SUB_GRID_SIZE       # Set $s1 (subgrid upper-left x).
    mul $s2, $t2, SUB_GRID_SIZE       # Set $s2 (subgrid upper_left y).
    mul $s2, $s2, GRID_SIZE           # Set $s2 (y1).
    addu $s2, $s2, $s1                # Set $s2 (x1,y1).
    mul $s2, $s2, 4                   # Set $s2 ([x1,y1]).
    addu $s2, $s0, $s2                # Set $s2 (&SGrid[x1,y1]).
    li $s6, GRID_SIZE                 # Set $s6 (GRID_SIZE).
    mul $s6, $s6, 4                   # Set $s6 (GRID_SIZE*4).

  sub_check00:
    # Check 0, 0 of subgrid.
    lw $a0, ($s2)                     # Set $a0 (SGrid[x1,y1]).
    beq $a0, $zero, sub_check01       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x1,y1].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check01:
    # Check 0, 1 of subgrid.
    addu $s2, $s2, 4                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_check02       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check02:
    # Check 0, 2 of subgrid.
    addu $s2, $s2, 4                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_check10       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check10:
    # Check 1, 0 of subgrid.
    addu $s2, $s2, $s6                # Set $s2 (&SGrid[x,y]).
    subu $s2, $s2, 8                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_check11       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check11:
    # Check 1, 1 of subgrid.
    addu $s2, $s2, 4                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_check12       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check12:
    # Check 1, 2 of subgrid.
    addu $s2, $s2, 4                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_check20       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check20:
    # Check 2, 0 of subgrid.
    addu $s2, $s2, $s6                # Set $s2 (&SGrid[x,y]).
    subu $s2, $s2, 8                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_check21       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check21:
    # Check 2, 1 of subgrid.
    addu $s2, $s2, 4                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_check22       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_check22:
    # Check 2, 2 of subgrid.
    addu $s2, $s2, 4                  # Set $s2 (&SGrid[x,y]).
    lw $a0, ($s2)                     # Set $a0 (SGrid[x,y]).
    beq $a0, $zero, sub_succeed       # Skip if zero.
    jal checkFoundNumber              # Check SGrid[x,y].
    bne $v0, TRUE, sub_fail           # Fail if this number is a duplicate.

  sub_succeed:
    # This subgrid is valid.
    li $v0, TRUE                      # This subgrid is valid.
    b sub_end                         # Skip to the end.

  sub_fail:
    # This subgrid is invalid.
    li $v0, FALSE                     # This subgrid is invalid.
    b sub_end                         # Skip to the end.

  sub_end:
  sub_pop:
    # Pop affected registers.
    lw $fp, ($sp)                     # Pop $fp.
    lw $ra, 4($sp)                    # Pop $ra.
    lw $a0, 8($sp)                    # Pop $a0.
    lw $a1, 12($sp)                   # Pop $a1.
    lw $a2, 16($sp)                   # Pop $a2.
    lw $s0, 20($sp)                   # Pop $s0.
    lw $s1, 24($sp)                   # Pop $s1.
    lw $s2, 28($sp)                   # Pop $s2.
    lw $s3, 32($sp)                   # Pop $s3.
    lw $s4, 36($sp)                   # Pop $s4.
    lw $s5, 40($sp)                   # Pop $s5.
    lw $s6, 44($sp)                   # Pop $s6.
    addu $sp, $sp, 48                 # Reset stack pointer address.
    jr $ra                            # Return to caller.

.end checkSub

#  -------------------------------------
#  Function to zero 'found' array (9)
#
#  Arguments:
#    N/A.
#
#  Returns
#    N/A.
#

.globl zeroFoundArray
.ent zeroFoundArray

zeroFoundArray:
    la $t0, found         # Set $t0 (&found[]).
    sb $zero, 0($t0)      # Zero found[0].
    sb $zero, 1($t0)      # Zero found[1].
    sb $zero, 2($t0)      # Zero found[2].
    sb $zero, 3($t0)      # Zero found[3].
    sb $zero, 4($t0)      # Zero found[4].
    sb $zero, 5($t0)      # Zero found[5].
    sb $zero, 6($t0)      # Zero found[6].
    sb $zero, 7($t0)      # Zero found[7].
    sb $zero, 8($t0)      # Zero found[8].
    sb $zero, 9($t0)      # Zero found[9].
    jr $ra                # Return to caller.

.end zeroFoundArray

#  -------------------------------------
#  Function to check that a supplied number has not already been found in a
#  row, column, or subgrid.
#
#  Arguments:
#    $a0 [value] - The number found.
#
#  Returns
#    $v0 [boolean] - If number has not already been found.
#

.globl checkFoundNumber
.ent checkFoundNumber

checkFoundNumber:

  checkNum_init:
    # Begin.
    li $v0, FALSE                       # Set $v0 (FALSE).
    la $t0, found                       # Set $t0 (&found[]).
    addu $t0, $t0, $a0                  # Set $t0 (&found[number]).
    lb $t1, ($t0)                       # Set $t1 (found[number]).
    beq $t1, TRUE, checkNum_end         # Skip to end if number not new.
    li $t1, TRUE                        # Set $t1 (TRUE).
    sb $t1, ($t0)                       # Set found[number].
    li $v0, TRUE                        # Set $v0 (TRUE).

  checkNum_end:
    # End.
    jr $ra                              # Return to caller.

.end checkFoundNumber

#  -------------------------------------
#  Procedure to display formatted Sudoku grid to output, 
#  formatting as per assignment directions
#
#  Arguments:
#    $a0 - starting address of matrix to print
#    $a1 - flag valid (true) or not valid (false)
#

.globl DisplaySudoku
.ent DisplaySudoku

DisplaySudoku:
  display_push:
    # Push affected registers.
    subu $sp, $sp, 44       # Increase stack address by 44 bytes.
    sw $fp, ($sp)           # Push $fp.
    sw $ra, 4($sp)          # Push $ra.
    sw $a0, 8($sp)          # Push $a0.
    sw $a1, 12($sp)         # Push $a1.
    sw $s0, 16($sp)         # Push $s0.
    sw $s1, 20($sp)         # Push $s1.
    sw $s2, 24($sp)         # Push $s2.
    sw $s3, 28($sp)         # Push $s3.
    sw $s4, 32($sp)         # Push $s4.
    sw $s5, 36($sp)         # Push $s5.
    sw $s6, 40($sp)         # Push $s6.
    addu $fp, $sp, 44       # Set $fp (frame pointer).

  display_init:
    # Initialize for display.
    move $s0, $a0       # Set $s0 (starting address).
    move $s1, $a1       # Set $s1 (validity flag).
    li $s2, 0           # Set $s2 (row).
    li $s4, 0           # Set $s4 (counter_x).
    la $a0, new_ln      # Set $a0 (new_ln).
    li $v0, 4           # Set $v0 (print string).
    syscall             # Print newline.
    la $a0, new_ln      # Set $a0 (new_ln).
    li $v0, 4           # Set $v0 (print string).
    syscall             # Print newline.
    la $a0, top_ln      # Set $a0 (top_ln).
    li $v0, 4           # Set $v0 (print string).
    syscall             # Print top line.

  display_row:
    # Display each row.
    li $s3, 0         # Set $s3 (col).
    li $s5, 0         # Set $s5 (counter_y).
    la $a0, space2    # Set $a0 (space2).
    li $v0, 4         # Set $v0 (print string).
    syscall           # Print two leading spaces.
    la $a0, bar       # Set $a0 (bar).
    li $v0, 4         # Set $v0 (print string).
    syscall           # Print first bar.

  display_col:
    # Display each character.
    mul $t0, $s2, GRID_SIZE                         # Set $t0 (y*y_dimension).
    addu $t0, $t0, $s3                              # Set $t0 (y*y_dimension+x).
    mul $t0, $t0, 4                                 # Set $t0 ([y*y_dimension+x]).
    addu $t0, $t0, $s0                              # Set $t0 (array[y*y_dimension+x]).
    lw $a0, ($t0)                                   # Set $a0 (array[y*y_dimension+x]).
    li $v0, 1                                       # Set $v0 (print integer).
    syscall                                         # Print number.
    la $a0, space                                   # Set $a0 (space).
    li $v0, 4                                       # Set $v0 (print string).
    syscall                                         # Print number.
    addu $s3, $s3, 1                                # Increment column.
    addu $s5, $s5, 1                                # Increment counter_y.
    blt $s5, SUB_GRID_SIZE, display_col_end         # Skip the formatting.
    subu $s5, $s5, SUB_GRID_SIZE                    # Reset counter_y.
    la $a0, bar                                     # Set $a0 (bar).
    li $v0, 4                                       # Set $v0 (print string).
    syscall                                         # Print bar.

  display_col_end:
    # End this column.
    blt $s3, GRID_SIZE, display_col                 # Continue through the columns.
    la $a0, new_ln                                  # Set $a0 (new_ln).
    li $v0, 4                                       # Set $v0 (print string).
    syscall                                         # Print new line.
    addu $s2, $s2, 1                                # Increment row.
    addu $s4, $s4, 1                                # Increment counter_x.
    blt $s4, SUB_GRID_SIZE, display_row_end         # Skip the formatting.
    subu $s4, $s4, SUB_GRID_SIZE                    # Reset counter_x.
    la $a0, top_ln                                  # Set $a0 (top_ln).
    li $v0, 4                                       # Set $v0 (print string).
    syscall                                         # Print top line.

  display_row_end:
    # End this row.
    blt $s2, GRID_SIZE, display_row                 # Continue through the rows.

  display_pop:
    # Pop affected registers.
    lw $fp, ($sp)                 # Pop $fp.
    lw $ra, 4($sp)                # Pop $ra.
    lw $a0, 8($sp)                # Pop $a0.
    lw $a1, 12($sp)               # Pop $a1.
    lw $s0, 16($sp)               # Pop $s0.
    lw $s1, 20($sp)               # Pop $s1.
    lw $s2, 24($sp)               # Pop $s2.
    lw $s3, 28($sp)               # Pop $s3.
    lw $s4, 32($sp)               # Pop $s4.
    lw $s5, 36($sp)               # Pop $s5.
    lw $s6, 40($sp)               # Pop $s6.
    addu $sp, $sp, 44             # Reset stack address.
    jr $ra                        # Return to caller.

.end DisplaySudoku
