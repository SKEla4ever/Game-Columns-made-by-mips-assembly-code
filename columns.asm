################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       4
# - Unit height in pixels:      4
# - Display width in pixels:    64
# - Display height in pixels:   56
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##########################################################################
# Background music data: Columns theme (very simplified demo melody)
# Each note = (pitch, duration_ms)
# Pitch uses MIDI note numbers (Middle C = 60).
##########################################################################
    .eqv MUSIC_INSTR, 0        # 0 = Acoustic Grand Piano
    .eqv MUSIC_VOLUME, 80      # MIDI volume: 0..127
    .eqv NUM_NOTES, 16         # number of notes in the melody

columns_theme_notes:
    # pitch, duration (ms)
    .word 64, 250      # E4
    .word 67, 250      # G4
    .word 71, 250      # B4
    .word 72, 250      # C5

    .word 71, 250      # B4
    .word 67, 250      # G4
    .word 64, 250      # E4
    .word 60, 250      # C4

    .word 62, 250      # D4
    .word 64, 250      # E4
    .word 67, 250      # G4
    .word 71, 250      # B4

    .word 69, 250      # A4
    .word 67, 250      # G4
    .word 64, 250      # E4
    .word 60, 500      # C4 (longer to finish phrase)

  music_note_index:
    .word 0          # current note index in 0..NUM_NOTES-1
  music_last_time:
    .word 0          # last time (ms) when we advanced to next note

    .eqv MUSIC_NOTE_INTERVAL, 250   # at least 250 ms between notes


    
##############################################################################
# Immutable Data
##############################################################################
    .eqv GEM_WIDTH, 4 #width of a gem
    # Color constants (24-bit RGB: 0xRRGGBB)
    .eqv RED,    0x8f0000          
    .eqv ORANGE, 0xffa500          
    .eqv YELLOW, 0xcfcf00          
    .eqv GREEN,  0x00af00          
    .eqv BLUE,   0x0090ff          
    .eqv PURPLE, 0xa000a0
    .eqv WHITE,  0xffffff
    .eqv GREY,   0x909090
    .eqv Width, 256
    .eqv NUM_COLORS, 6

    # Preview panel position (right side of the screen, outside playfield)
    .eqv PREVIEW_X, 36          # x-coordinate of bottom gem of preview
    .eqv PREVIEW_BOTTOM_Y, 8   # y-coordinate of bottom gem of preview

    
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
keyboard_address:
    .word 0xffff0000
displayaddress:     
    .word 0x10008000
    
colors:
    .word RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE

current_column_colors:
    .word 0      # top gem color
    .word 0      # middle gem color
    .word 0      # bottom gem color

next_column_colors:
    .word 0      # top gem color of NEXT column
    .word 0      # middle gem color of NEXT column
    .word 0     # bottom gem color of NEXT column


current_column_address:
    .word 0
    
eliminate_marker:
    .word 0          # number of (x,y) pairs currently stored
    .space 624       # space for up to 78 gems: 78 * 2 coords * 4 bytes
                     # layout: [count][x0][y0][x1][y1]...[x_{count-1}][y_{count-1}]

chain_elim_flag:
    .word 0          # 0 = no elimination this pass, 1 = at least one elimination

menu_msg:
    .asciiz "Welcome to Columns!\nSelect difficulty:\n1 - Easy\n2 - Medium\n3 - Hard\n"
    .align 2
game_over_msg:
    .asciiz "GAME OVER! Press 'r' to retry or 'q' to quit.\n"
    .align 2
pause_msg:
    .asciiz "Game paused. Press 'p' again to resume.\n"
    .align 2


### Gravity ###
# Time (in ms) of the last automatic gravity drop
    .eqv INITIAL_DROP_INTERVAL, 1000   # start at 1 second
    .eqv MIN_DROP_INTERVAL,      200   # fastest allowed = 0.2s
    .eqv SPEEDUP_INTERVAL,     15000   # every 15s, increase gravity
    .eqv DROP_INTERVAL_DECREMENT, 50   # 50 ms faster each step

last_drop_time:
    .word 0

# Time (in ms) of the last *speedup* of gravity
last_speedup_time:
    .word 0

# Current drop interval (in ms) – will shrink over time
drop_interval:
    .word INITIAL_DROP_INTERVAL
    
    # Optional: if you don't already have WHITE defined
    .eqv WHITE, 0xffffff

    .align 2
    
    
game_over_logo_coords:
    # G
    .word 6, 4
    .word 7, 4
    .word 8, 4
    .word 6, 5
    .word 6, 6
    .word 8, 6
    .word 6, 7
    .word 8, 7
    .word 6, 8
    .word 7, 8
    .word 8, 8

    # A
    .word 11, 4
    .word 10, 5
    .word 12, 5
    .word 10, 6
    .word 11, 6
    .word 12, 6
    .word 10, 7
    .word 12, 7
    .word 10, 8
    .word 12, 8

    # M
    .word 14, 4
    .word 16, 4
    .word 14, 5
    .word 15, 5
    .word 16, 5
    .word 14, 6
    .word 15, 6
    .word 16, 6
    .word 14, 7
    .word 16, 7
    .word 14, 8
    .word 16, 8

    # E (top)
    .word 18, 4
    .word 19, 4
    .word 20, 4
    .word 18, 5
    .word 18, 6
    .word 19, 6
    .word 20, 6
    .word 18, 7
    .word 18, 8
    .word 19, 8
    .word 20, 8

    # O
    .word 6, 13
    .word 7, 13
    .word 8, 13
    .word 6, 14
    .word 8, 14
    .word 6, 15
    .word 8, 15
    .word 6, 16
    .word 8, 16
    .word 6, 17
    .word 7, 17
    .word 8, 17

    # V
    .word 10, 13
    .word 12, 13
    .word 10, 14
    .word 12, 14
    .word 10, 15
    .word 12, 15
    .word 11, 16
    .word 11, 17

    # E 
    .word 14, 13
    .word 15, 13
    .word 16, 13

    .word 14, 14

    .word 14, 15
    .word 15, 15
    .word 16, 15

    .word 14, 16

    .word 14, 17
    .word 15, 17
    .word 16, 17


    # R
    .word 18, 13
    .word 19, 13
    .word 18, 14
    .word 20, 14
    .word 18, 15
    .word 19, 15
    .word 18, 16
    .word 20, 16
    .word 18, 17
    .word 20, 17

    # stop signal
    .word -1, -1



# The macro for pushing a value onto the stack.
.macro push1 (%reg1) 
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg1, 0($sp)         # push the register value onto the top of the stack
.end_macro

# The macro for popping a value off the stack.
.macro pop1 (%reg1) 
    lw %reg1, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
.end_macro


# The macro for pushing a value onto the stack.
.macro push2 (%reg1, %reg2) 
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg1, 0($sp)         # push the register value onto the top of the stack
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg2, 0($sp)         # push the register value onto the top of the stack
.end_macro

# The macro for popping a value off the stack.
.macro pop2 (%reg2, %reg1) 
    lw %reg2, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
    lw %reg1, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
.end_macro

.macro push3 (%reg1, %reg2, %reg3) 
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg1, 0($sp)         # push the register value onto the top of the stack
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg2, 0($sp)         # push the register value onto the top of the stack
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg3, 0($sp)         # push the register value onto the top of the stack
.end_macro

# The macro for popping a value off the stack.
.macro pop3 (%reg3, %reg2, %reg1)
    lw %reg3, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
    lw %reg2, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
    lw %reg1, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
.end_macro

.macro push4 (%reg1, %reg2, %reg3, %reg4) 
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg1, 0($sp)         # push the register value onto the top of the stack
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg2, 0($sp)         # push the register value onto the top of the stack
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg3, 0($sp)         # push the register value onto the top of the stack
    addi $sp, $sp, -4       # move the stack pointer to the next empty spot
    sw %reg4, 0($sp)         # push the register value onto the top of the stack
.end_macro

# The macro for popping a value off the stack.
.macro pop4 (%reg4, %reg3, %reg2, %reg1)
    lw %reg4, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
    lw %reg3, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
    lw %reg2, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
    lw %reg1, 0($sp)         # fetch the top element from the stack    
    addi $sp, $sp, 4        # move the stack pointer to the top element of the stack.
.end_macro
##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

#registers occupied: t0 -> address of (0,0), t9 -> Width, s0, t1 -> keyboard address, (t5, t6) -> coordinates of current three_gem
main:
    game_start:
        # base addresses
        lw   $t0, displayaddress   # $t0 = base address for display
        lw   $t1, keyboard_address # $t1 = keyboard base address
        addi $t9, $zero, Width     # $t9 = width of the bitmap (bytes per row)
    
        # Clear entire screen to black
        jal  clear_screen
    
        # Show difficulty selection and set drop_interval
        jal  home_screen
    
        # Draw playfield boundary
        jal  draw_boudary
    
        # Initialize timing: last_drop_time, last_speedup_time
        push2($t2, $t3)
        li   $v0, 30              # syscall 30: current time in ms
        syscall                   # result in $a0
    
        # last_drop_time = now
        la   $t2, last_drop_time
        sw   $a0, 0($t2)
    
        # last_speedup_time = now
        la   $t2, last_speedup_time
        sw   $a0, 0($t2)
    
        pop2($t3, $t2)

        # Initialize background music state
        la   $t2, music_note_index
        sw   $zero, 0($t2)

        la   $t2, music_last_time
        sw   $a0, 0($t2)      # start from current time

    
        # Reset elimination state
        la   $t2, chain_elim_flag
        sw   $zero, 0($t2)
    
        la   $t2, eliminate_marker
        sw   $zero, 0($t2)        # eliminate_marker[0] = 0 (no pending eliminations)
        
        # Initialize the NEXT column and draw its preview panel
        jal  init_next_column
    
test:
    # Spawn a new column (may trigger Game Over)
    jal  spawn_new_column

    # Run the main game loop (never returns until quit or Game Over/restart)
    jal  game_loop
    

##########################################################################
# play_columns_theme
# ------------------------------------------------------------------------
# Play the Columns theme music in the background (loop forever).
#
# This function:
#   - Sets the MIDI instrument and volume.
#   - Loops over the melody stored in columns_theme_notes.
#   - For each note, calls the MARS MIDI syscall to play the note.
#   - After finishing all notes, it repeats from the beginning.
#
# NOTE:
#   - This function never returns (infinite loop), so in your game
#     you should normally run it as a separate "background" thread
#     (i.e., start it in a separate MARS instance), or call it once
#     at the beginning and let it loop while the game is running.
##########################################################################
play_columns_theme:
    # We will use $s0: pointer to current note
    #             $s1: remaining note count
    #             $t0: temp for pitch
    #             $t1: temp for duration

    # Save callee-saved registers we use
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)

    #### 1. Set MIDI instrument (program change) ####
    # In MARS:
    #   $a0 = instrument number (0..127)
    #   $v0 = 33  -> MIDI set instrument
    li   $a0, MUSIC_INSTR
    li   $v0, 33
    syscall

    #### 2. Main infinite loop: repeatedly play all notes ####
music_main_loop:
        # Reset pointer and counter each time we start the melody
        la   $s0, columns_theme_notes   # s0 = &columns_theme_notes[0]
        li   $s1, NUM_NOTES             # s1 = notes remaining in this iteration
    
    music_note_loop:
            # If no more notes in this pass, restart melody
            beq  $s1, $zero, music_main_loop
    
            # Load (pitch, duration_ms)
            lw   $t0, 0($s0)            # pitch
            lw   $t1, 4($s0)            # duration in ms
    
            #### 2a. Play this note ####
            # In MARS:
            #   $a0 = pitch (0..127)
            #   $a1 = duration in ms
            #   $a2 = instrument (we reuse MUSIC_INSTR)
            #   $a3 = volume (0..127)
            #   $v0 = 31  -> MIDI out
            move $a0, $t0               # pitch
            move $a1, $t1               # duration
            li   $a2, MUSIC_INSTR
            li   $a3, MUSIC_VOLUME
            li   $v0, 31
            syscall                     # play note (non-blocking in MARS / SPIM)
    
            #### 2b. Wait for the note duration so tempo is correct ####
            # Use syscall 32 "sleep" (if your environment supports it), or
            # busy-wait with syscall 30 "current time".
            # Here we use syscall 32: $a0 = ms to sleep.
            move $a0, $t1
            li   $v0, 32                # sleep for duration_ms
            syscall
    
            #### 2c. Advance to next note ####
            addi $s0, $s0, 8            # move pointer by 2 words (pitch,duration)
            addi $s1, $s1, -1           # one less remaining
            j    music_note_loop

    # (We never reach here, but keep restore just in case.)
music_done:
    lw   $s1, 0($sp)
    lw   $s0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra

##########################################################################
# music_step
# ------------------------------------------------------------------------
# Non-blocking background music step.
# - Should be called frequently from game_loop.
# - At most once per MUSIC_NOTE_INTERVAL ms it plays the next note
#   of columns_theme_notes, and updates the index and timestamp.
# - Returns immediately (does not block the game).
##########################################################################
music_step:
    # Save caller-saved registers we use
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $t0, 8($sp)
    sw   $t1, 4($sp)
    sw   $t2, 0($sp)

    #### 1. Read current time ####
    li   $v0, 30          # syscall 30: current time in ms
    syscall               # time -> $a0
    move $t0, $a0         # t0 = now

    #### 2. Load last time and check if enough interval has passed ####
    la   $t1, music_last_time
    lw   $t2, 0($t1)      # t2 = last_time

    subu $t2, $t0, $t2    # t2 = now - last_time
    li   $t1, MUSIC_NOTE_INTERVAL
    blt  $t2, $t1, music_step_done   # if dt < interval, skip this step

    #### 3. Time to play next note ####
    # Update last_time = now
    la   $t1, music_last_time
    sw   $t0, 0($t1)

    # Load current note index
    la   $t1, music_note_index
    lw   $t2, 0($t1)      # t2 = index

    # Ensure index in range 0..NUM_NOTES-1
    li   $t0, NUM_NOTES
    bge  $t2, $t0, music_reset_index

    j    music_index_ok

music_reset_index:
    li   $t2, 0           # restart from first note

music_index_ok:
    # Save index back (in case we reset)
    sw   $t2, 0($t1)

    # Load (pitch, duration) for this note
    la   $t1, columns_theme_notes
    sll  $t0, $t2, 3       # each note = 8 bytes -> index * 8
    add  $t1, $t1, $t0     # t1 = &columns_theme_notes[index]
    lw   $t0, 0($t1)       # pitch
    lw   $t1, 4($t1)       # duration

    # Play the note using MIDI syscall 31
    move $a0, $t0          # pitch
    move $a1, $t1          # duration
    li   $a2, MUSIC_INSTR  # instrument
    li   $a3, MUSIC_VOLUME # volume
    li   $v0, 31
    syscall

    # Advance index = (index + 1) mod NUM_NOTES
    la   $t1, music_note_index
    lw   $t2, 0($t1)
    addi $t2, $t2, 1
    li   $t0, NUM_NOTES
    blt  $t2, $t0, music_store_index
    li   $t2, 0

music_store_index:
    sw   $t2, 0($t1)

music_step_done:
    # Restore registers and return
    lw   $t2, 0($sp)
    lw   $t1, 4($sp)
    lw   $t0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

    


  
# home_screen:
#   Show difficulty menu on console and set initial drop_interval
#   based on key '1', '2', or '3'.
#   Assumes: $t1 holds keyboard base address (0xffff0000).
home_screen:
    # Print menu to console
    la   $a0, menu_msg
    li   $v0, 4              # print_string
    syscall

    home_wait_key:
        # check key press
        lw   $t8, 0($t1)
        bne  $t8, 1, home_wait_key
    
        # Read ASCII code of pressed key
        lw   $t7, 4($t1)
    
        li   $t9, 0x31           # '1'
        beq  $t7, $t9, home_easy
    
        li   $t9, 0x32           # '2'
        beq  $t7, $t9, home_medium
    
        li   $t9, 0x33           # '3'
        beq  $t7, $t9, home_hard
    
        # keep waiting
        j    home_wait_key
    
    home_easy:
        # Easy: slow gravity
        la   $t2, drop_interval
        li   $t3, 1200           # 1.2 s between auto-drops
        sw   $t3, 0($t2)
        jr   $ra
    
    home_medium:
        # Medium: default-ish gravity
        la   $t2, drop_interval
        li   $t3, 800            # 0.8 s between auto-drops
        sw   $t3, 0($t2)
        jr   $ra
    
    home_hard:
        # Hard: fast gravity
        la   $t2, drop_interval
        li   $t3, 400            # 0.4 s between auto-drops
        sw   $t3, 0($t2)
        jr   $ra
        

# game_over_screen:
#   Display a simple Game Over screen on the bitmap display,
#   then wait for user input:
#       'r' (0x72) -> restart game (brand new)
#       'q' (0x71) -> quit program
#
# This function never returns to its caller: it either jumps to game_start
# or exits the program.
game_over_screen:

    jal draw_game_over_logo

    # Also print a console message
    la   $a0, game_over_msg
    li   $v0, 4         # print_string
    syscall
    
    game_over_wait_key:
        # Wait for a key press
        lw   $t8, 0($t1)    # keyboard status
        bne  $t8, 1, game_over_wait_key
    
        # Read ASCII of pressed key
        lw   $t7, 4($t1)
    
        li   $t9, 0x72      # 'r' for retry
        beq  $t7, $t9, game_over_retry
    
        li   $t9, 0x71      # 'q' for quit
        beq  $t7, $t9, game_over_quit
    
        # Ignore other keys
        j    game_over_wait_key
    
    game_over_retry:
        # Start a brand new game: re-run initialization
        j    game_start
    
    game_over_quit:
        li   $v0, 10        # exit syscall
        syscall


# Draws a pixel-based "GAME OVER" logo using game_over_logo_coords.
# Uses $s0 as the pointer into game_over_logo_coords so that
# other drawing routines (using $t2, $t3, etc.) can't clobber it.
draw_game_over_logo:
    # Save registers we will clobber
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $s0, 8($sp)
    sw   $t4, 4($sp)
    sw   $t2, 0($sp)

    # Set logo colour
    li   $t4, WHITE

    # Pointer to coordinate table
    la   $s0, game_over_logo_coords

    game_over_logo_loop:
        lw   $a0, 0($s0)        # x
        lw   $a1, 4($s0)        # y
    
        # Sentinel: if x < 0, stop
        bltz $a0, game_over_logo_done
    
        # Draw one pixel at (x,y) in colour $t4
        jal  draw_pixel
    
        # Advance to next (x,y) pair
        addi $s0, $s0, 8
        j    game_over_logo_loop

    game_over_logo_done:
        # Restore registers
        lw   $t2, 0($sp)
        lw   $t4, 4($sp)
        lw   $s0, 8($sp)
        lw   $ra, 12($sp)
        addi $sp, $sp, 16
        jr   $ra
    


game_loop:
    # 1a. Check if key has been pressed / handle input
    jal check_key          # handles a, d, w, s, q
    jal check_bottom       # may spawn a new column if the current one has landed

    # 1b. Background music step (non-blocking)
    jal music_step

    
    # 2. auto gravity drop
    push3($t7, $t8, $t9)
    push2($t2,$t3)
    # get current time 
    li   $v0, 30         # get current time (ms)
    syscall
    move $t7, $a0        # t7 = current_time_ms
    
    #### Update drop_interval every SPEEDUP_INTERVAL ms ####

    # elapsed_since_speedup = current_time - last_speedup_time
    la   $t8, last_speedup_time
    lw   $t9, 0($t8)             # t9 = last_speedup_time
    subu $t2, $t7, $t9           # t2 = elapsed_since_speedup

    li   $t3, SPEEDUP_INTERVAL
    blt  $t2, $t3, skip_speedup  # if elapsed < SPEEDUP_INTERVAL, no speed change

        # elapsed >= SPEEDUP_INTERVAL:
        # drop_interval = max(drop_interval - DROP_INTERVAL_DECREMENT, MIN_DROP_INTERVAL)

        la   $t8, drop_interval
        lw   $t3, 0($t8)                     # t3 = current drop_interval
        li   $t2, DROP_INTERVAL_DECREMENT
        subu $t3, $t3, $t2                   # t3 = new interval

        # clamp to MIN_DROP_INTERVAL
        li   $t2, MIN_DROP_INTERVAL
        bge  $t3, $t2, store_interval        # if new >= MIN, keep it
        move $t3, $t2                        # else clamp to MIN

    store_interval:
        sw   $t3, 0($t8)                     # drop_interval = t3

        # last_speedup_time = current_time
        la   $t8, last_speedup_time
        sw   $t7, 0($t8)

    skip_speedup:
    
    # Load last_drop_time
    la   $t8, last_drop_time
    lw   $t9, 0($t8)     # t9 = last_drop_time

    # delta = current_time - last_drop_time
    subu $t2, $t7, $t9   # t2 = elapsed ms since last auto-drop
    lw   $t3, drop_interval       

    # If less than 1 second has passed, skip gravity this frame
    blt  $t2, $t3, no_gravity

    # 1 second or more has passed -> drop column by one cell
    jal  move_down

    # Update last_drop_time = current_time
    sw   $t7, 0($t8)
    
    no_gravity:
        pop2($t3,$t2)
        pop3($t9, $t8, $t7)     
        # Loop again immediately (no sleep: input stays responsive)
        j    game_loop


#a0: X-coordinate; a1: Y-coordinate
draw_boudary:
    #prepare sp for function call
    addi $sp, $sp, -4
    sw $ra 0($sp)
    
    li $t4 GREY
    #draw 1st row
    addi $a0, $zero, 0 
    addi $a1, $zero, 0
    addi $a2, $zero, 28
    jal draw_line
    #draw 2ed row
    addi $a0, $zero, 0 
    addi $a1, $zero, 1
    addi $a2, $zero, 28
    jal draw_line
    #draw last 2ed row
    addi $a0, $zero, 0 
    addi $a1, $zero, 54
    addi $a2, $zero, 28
    jal draw_line
    #draw last 1st row
    addi $a0, $zero, 0 
    addi $a1, $zero, 55
    addi $a2, $zero, 28
    jal draw_line
    
    #draw 1st col
    addi $a0, $zero, 0 
    addi $a1, $zero, 0
    addi $a2, $zero, 55
    jal draw_vertical_line
    #draw 2ed col
    addi $a0, $zero, 1 
    addi $a1, $zero, 0
    addi $a2, $zero, 55
    jal draw_vertical_line
    #draw last 2ed col
    addi $a0, $zero, 26 
    addi $a1, $zero, 0
    addi $a2, $zero, 55
    jal draw_vertical_line
    #draw last 1st col
    addi $a0, $zero, 27 
    addi $a1, $zero, 0
    addi $a2, $zero, 55
    jal draw_vertical_line
    
    #rewind sp
    lw $ra 0($sp)
    addi $sp, $sp, 4

    jr $ra #go back to calling line

##  The draw_line function
##  - Draws a horizontal line from a given X and Y coordinate 
#
# $a0 = the x coordinate of the line (0..63)
# $a1 = the y coordinate of the line (0..55)
# $a2 = the length of the line in pixels
# $t4 = the colour for this line
# $t0 = the top left corner of the bitmap display
# $t2 = the current pixel address
# $t3 = stopping pixel address
draw_line:
    # horizontal offset = 4 * x
    sll  $a0, $a0, 2           # 4 * x
    add  $t2, $t0, $a0         # base + 4*x

    # vertical offset = Width * y  (Width = 256 bytes per row)
    li   $t3, Width            # t3 = 256
    multu $a1, $t3             # y * 256
    mflo $t3
    add  $t2, $t2, $t3         # t2 = base + 4*x + 256*y

    # end address for the line
    sll  $a2, $a2, 2           # a2 = 4 * length
    add  $t3, $t2, $a2         # t3 = end address (exclusive)

    line_loop_start:
        beq  $t2, $t3, line_loop_end   # stop when we reach end
        sw   $t4, 0($t2)               # paint current pixel
        addi $t2, $t2, 4               # move to next pixel (one word)
        j    line_loop_start

    line_loop_end:
        jr   $ra

    
##  The draw_vertical_line function
##  - Draws a vertical line from a given X and Y coordinate 
#
# $a0 = the x coordinate of the line (0..63)
# $a1 = the starting y coordinate (0..55)
# $a2 = the length of the vertical line in pixels
# $t4 = the colour for this line
# $t0 = base of display
# $t2 = current pixel address
# $t3 = stopping pixel address
draw_vertical_line:
    # horizontal offset = 4 * x
    sll  $a0, $a0, 2           # 4 * x
    add  $t2, $t0, $a0         # base + 4*x

    # vertical offset = Width * y  (Width = 256 bytes per row)
    li   $t3, Width            # t3 = 256
    multu $a1, $t3             # y * 256
    mflo $t3
    add  $t2, $t2, $t3         # t2 = base + 4*x + 256*y

    # total offset for length a2: a2 * Width bytes
    li   $t3, Width            # t3 = 256 again
    multu $a2, $t3             # a2 * 256
    mflo $a2
    add  $t3, $t2, $a2         # t3 = end address (exclusive)

    vertical_line_loop_start:
        beq  $t2, $t3, vertical_line_loop_end
        sw   $t4, 0($t2)           # paint current pixel
        addi $t2, $t2, Width       # go one row down: +256 bytes
        j    vertical_line_loop_start

    vertical_line_loop_end:
        jr   $ra



##  The draw_rect function
##  - Draws a rectangle at a given X and Y coordinate 
#
# $a0 = the x coordinate of the line
# $a1 = the y coordinate of the line
# $a2 = the width of the rectangle
# $a3 = the height of the rectangle
# $t4 = the color of the rectangle
draw_rect:
    # no registers to initialize (use $a3 as the loop variable)
    rect_loop_start:
    beq $a3, $zero, rect_loop_end   # test if the stopping condition has been satisfied
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $ra, 0($sp)                  # push $ra onto the stack
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $a0, 0($sp)                  # push $a0 onto the stack
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $a1, 0($sp)                  # push $a1 onto the stack
    addi $sp, $sp, -4               # move the stack pointer to an empty location
    sw $a2, 0($sp)                  # push $a2 onto the stack
    
    jal draw_line                   # call the draw_line function.
    
    lw $a2, 0($sp)                  # pop $a2 from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    lw $a1, 0($sp)                  # pop $a1 from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    lw $a0, 0($sp)                  # pop $a0 from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    lw $ra, 0($sp)                  # pop $ra from the stack
    addi $sp, $sp, 4                # move the stack pointer to the top stack element
    addi $a1, $a1, 1                # move the Y coordinate down one row in the bitmap
    addi $a3, $a3, -1               # decrement loop variable $a3 by 1
    j rect_loop_start               # jump to the top of the loop.
    rect_loop_end:
    jr $ra                          # return to the calling program.
     
# clear_screen:
#   Fill the entire 64x56 bitmap with black (0).
#   Uses draw_rect with colour 0.
clear_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t4, 0      # black
    li   $a0, 0      # x = 0
    li   $a1, 0      # y = 0
    li   $a2, 64     # width in "pixels"
    li   $a3, 56     # height in "pixels"
    jal  draw_rect

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# draw_pixel:
#   Draw a single pixel at (x, y) with colour $t4.
#   $a0 = x (0..63)
#   $a1 = y (0..55)
#   $t4 = colour
#   $t0 = base display address
draw_pixel:
    push4($t2, $t3, $t4, $ra)
    # horizontal offset = 4 * x
    sll  $t2, $a0, 2           # t2 = 4 * x

    # vertical offset = Width * y
    li   $t3, Width            # Width = 256 bytes per row
    multu $a1, $t3
    mflo $t3

    # total address = base + 4*x + Width*y
    addu $t2, $t2, $t3
    addu $t2, $t0, $t2

    sw   $t4, 0($t2)           # write pixel
    
    pop4($ra, $t4, $t3, $t2)
    jr   $ra
   
     
########## Drawing Gems ##########
##  The draw_gem function
##  - Draws a gem at a given X and Y coordinate 
# Set before calling:
    # $a0 = the x coordinate of the line
    # $a1 = the y coordinate of the line
    # $t4 = the color of the rectangle
# Settings in function:
    # $a2 = the width of the rectangle, which is 4
    # $a3 = the height of the rectangle, which is 4 
draw_gem:
    li $a2, GEM_WIDTH
    li $a3, GEM_WIDTH
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal draw_rect
    lw $ra, 0($sp) 
    addi $sp, $sp, 4
    jr $ra

# get_random_color function: 
# return $t8 = a random colour word from Colors label
# setting in the funtion:
# $v0 = 42; 
# $a0 = 0(random id; later stores random number); 
# $a1 = 6(# of colors); 
# $t2: base address of Colors;
get_random_color:
    addi $sp, $sp, -4
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    addi $sp, $sp, -4
    sw $t2, 0($sp)
    
    li   $v0, 42          # syscall 42: create random int within upper bound exclusively
    li   $a0, 0           # random id
    li   $a1, NUM_COLORS  # upper bound = 6
    syscall               

    la   $t2, colors      # base address of Colors
    sll  $a0, $a0, 2      # calculate the bits that are going to shift from base address
    add  $t2, $t2, $a0    # address of a color in colors
    lw   $t8, 0($t2)      # t8 = colors[index]
    
    lw $t2, 0($sp)
    addi $sp, $sp, 4
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

##  The draw_initial_three_gem function
##  - Draws three vertical gem bar as the given three gems
#   Return $t5, $t6, as the initial x,y coordinates(top left pixel in bottom gem) and keep with this three_gem until next intial gem.
# Settings in function:
    # $t5 = 14
    # $t6 = 10
    # $a0 = $t5 = 14 (x-coordinate of top gem(top left pixel in bottom gem))
    # $a1 = $t6 = 10  (y-coordinate of top gem(top left pixel in bottom gem))
    # $a2 = the width of the rectangle, which is 4
    # $a3 = the height of the rectangle, which is 4 
    # $t8 = random color 
    # $t4 = $t8: color for draw_gem call
    # $t2 = help register to uodate current_column_address
    # $t3 = help register to uodate current_column_address
draw_initial_three_gem:    
    li $t5, 14
    li $t6, 10
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $sp, $sp, -4   #back up $t2 so no effect on other code
    sw $t2, 0($sp)
    addi $sp, $sp, -4   #back up $t3 so no effect on other code
    sw $t3, 0($sp)
    
    #update current_column_address to be the address of top left pixel in bottom gem.
    #li $t3, Width      #use $t3 as a helper to calculate vertical shift + horizontal shift from t0
    #multu $t6, $t3
    #mflo $t3           #now $t3 holds vertical shift
    #sll $t2, $t5, 2     #shift 4X bits
    #add $t3, $t3, $t2  #also add horizontal shift

    # add $t2, $t0, $t3   #$t0 + $t3 is the address of the calculated current_column_address
    # la $t3, current_column_address # now use $t3 to store the address of the label
    # sw $t2, 0($t3)      #store the new calculated current_column_address into the label current_column_address.
    
    # temporaryly use $t7 as the pointer for current_column_colors
    addi $sp, $sp, -4 
    sw $t7, 0($sp)
    la $t7, current_column_colors
    
    ###first gem
    addi $a0, $t5, 0 #set x,y coordinates
    addi $a1, $t6, 0
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal get_random_color #t8 will store the color
    sw $t8, 8($t7) # store the random color in t8 into the third color in current_column_colors, #current_column_color[2] = bottom gem color; 
    lw $a1, 0($sp)                                                                               #current_column_color[1] = middle gem color;                                                                      
    addi $sp, $sp, 4                                                                             #current_column_color[0] = top gem color;        
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    addi $t4, $t8, 0 #set t4 for draw_gem call
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    ###second gem
    add $a1, $a1, -4      #set x,y coordinates, here a0 unchanged as x-coordinates unchanged
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal get_random_color
    sw $t8, 4($t7) # store the random color in t8 into current_column_colors[1]
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    addi $t4, $t8, 0  #copy color for draw_gem call
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    
    ###third gem
    add $a1, $a1, -4      #set x,y coordinates, here a0 unchanged as x-coordinates unchanged
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal get_random_color
    sw $t8, 0($t7) # store the random color in t8 into current_column_colors[1]
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    addi $t4, $t8, 0  #copy color for draw_gem call
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    lw $t7, 0($sp)    #rewind t7
    addi $sp, $sp, 4
    lw $t3, 0($sp)    #rewind t3
    addi $sp, $sp, 4
    lw $t2, 0($sp)    #rewind t2
    addi $sp, $sp, 4
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra          #jump back



# init_next_column:
#   - Generate random colours for the next column and store them into
#     next_column_colors (top, middle, bottom).
#   - Then redraw the preview panel on the right side.
#
# Uses (and restores): $ra, $t2, $t3, $t4, $t8
init_next_column:
    # # Save caller registers we care about
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $t2, 8($sp)
    sw   $t3, 4($sp)
    sw   $t4, 0($sp)

    addi $sp, $sp, -4
    sw   $t8, 0($sp)

    # Pointer to next_column_colors
    la   $t2, next_column_colors

    # --- Top gem colour ---
    jal  get_random_color       # random colour in $t8
    sw   $t8, 0($t2)

    # --- Middle gem colour ---
    jal  get_random_color
    sw   $t8, 4($t2)

    # --- Bottom gem colour ---
    jal  get_random_color
    sw   $t8, 8($t2)

    # # Draw the preview column using these colours
    jal  draw_preview_column

    # Restore $t8
    lw   $t8, 0($sp)
    addi $sp, $sp, 4

    # Restore $ra, $t2, $t3, $t4
    lw   $t4, 0($sp)
    lw   $t3, 4($sp)
    lw   $t2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16

    jr   $ra



# PREVIEW_X: x-position of the preview column
# PREVIEW_BOTTOM_Y: y-position of the BOTTOM preview gem (top-left of that gem)
# next_column_colors layout:
#   offset 0: top color
#   offset 4: middle color
#   offset 8: bottom color

draw_preview_column:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    #### 1. Clear the preview area (3 gems tall, 1 gem wide) ####
    li   $t4, 0                    # colour = black
    li   $a0, PREVIEW_X            # x
    li   $a1, PREVIEW_BOTTOM_Y     # bottom y
    addi $a1, $a1, -8              # start 2 gems above bottom (top gem)
    li   $a2, GEM_WIDTH            # width = 4
    li   $a3, 12                   # height = 3 * GEM_WIDTH = 12
    jal  draw_rect                 # uses $t4 as colour

    #### 2. Draw the three preview gems using next_column_colors ####

    # --- Bottom gem (offset 8) ---
    la   $t2, next_column_colors   # reload pointer BEFORE each use
    lw   $t4, 8($t2)               # bottom colour
    li   $a0, PREVIEW_X
    li   $a1, PREVIEW_BOTTOM_Y     # bottom y
    jal  draw_gem

    # --- Middle gem (offset 4), y = PREVIEW_BOTTOM_Y - 4 ---
    la   $t2, next_column_colors   # reload pointer (draw_gem clobbers $t2)
    lw   $t4, 4($t2)               # middle colour
    li   $a0, PREVIEW_X
    li   $a1, PREVIEW_BOTTOM_Y
    addi $a1, $a1, -4              # one gem above bottom
    jal  draw_gem

    # --- Top gem (offset 0), y = PREVIEW_BOTTOM_Y - 8 ---
    la   $t2, next_column_colors   # reload pointer again
    lw   $t4, 0($t2)               # top colour
    li   $a0, PREVIEW_X
    li   $a1, PREVIEW_BOTTOM_Y
    addi $a1, $a1, -8              # two gems above bottom
    jal  draw_gem

    #### 3. Restore $ra and return ####
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra





##  draw_three_gem function
##  - Draws three vertical gem bar by given location and with current_column_colors
#   Depending on $t5, $t6(possibly changed in shifter function), as the new x,y coordinates(top left pixel in bottom gem).
# Precondition:     # $t5 = as given and unchanged to be the (x,y) of current column coordinate(top left pixel in bottom gem)
                    # $t6 = as given and unchanged
# Settings in function:
    # $a0 = $t5  (x-coordinate of top gem(bottom left pixel))
    # $a1 = $t6  (y-coordinate of top gem(bottom left pixel))
    # $a2 = the width of the rectangle, which is 4
    # $a3 = the height of the rectangle, which is 4 
    # $t4 = color variable for draw_gem call 
draw_three_gem:

    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # temporaryly use t7 as the pointer for current_column_colors
    addi $sp, $sp, -4 
    sw $t7, 0($sp)
    la $t7, current_column_colors
    
    ###first gem
    lw $t4, 8($t7)      #fetch color
    addi $a0, $t5, 0 #set x,y coordinates
    addi $a1, $t6, 0
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    ###second gem
    lw $t4, 4($t7)        #fetch color
    add $a1, $a1, -4      #set x,y coordinates, here a0 unchanged as x-coordinates unchanged
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    
    ###third gem
    lw $t4, 0($t7)        #fetch color
    add $a1, $a1, -4      #set x,y coordinates, here a0 unchanged as x-coordinates unchanged
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    lw $t7, 0($sp)    #rewind t7
    addi $sp, $sp, 4
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra          #jump back

# draw_three_black function:
# draw a three_black column to delete three_gem
# preconditions: $t5, $t6 should be the coordinates of the three_gen that is READY TO BE DELETED(i.e. before moving)
# setting variables:
# $a0 = $t5  (x-coordinate of top gem(bottom left pixel))
# $a1 = $t6  (y-coordinate of top gem(bottom left pixel))
# $a2 = the width of the rectangle, which is 4
# $a3 = the height of the rectangle, which is 4 
# $t4 = color variable for draw_gem call, set to 0 in this function
draw_three_black:

    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    add $a0, $zero, $t5     #set draw location for draw_gem call
    add $a1, $zero, $t6
    
    ###first gem
    addi $t4, $zero, 0 #black
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4 
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    ###second gem
    addi $t4, $zero, 0    #black
    add $a1, $a1, -4      #set x,y coordinates, here a0 unchanged as x-coordinates unchanged
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    
    ###third gem
    addi $t4, $zero, 0    #black
    add $a1, $a1, -4      #set x,y coordinates, here a0 unchanged as x-coordinates unchanged
    
    addi $sp, $sp, -4  #stack pointer shift here to protect $a0 and $a1
    sw $a0, 0($sp)
    addi $sp, $sp, -4
    sw $a1, 0($sp)
    jal draw_gem
    lw $a1, 0($sp)
    addi $sp, $sp, 4
    lw $a0, 0($sp)
    addi $sp, $sp, 4  #rewind $a0, $a1
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra          #jump back

## gem_color_fetcher function  -> return $t4 color of the gem
# return the color of the given gem (save in $t4, keep $t2, $t3 unchanged)
# precondition: $t0 is origin; $t2,$t3 are the (X,Y) coordinates of the input gem (top left pixel)
# setting in the function:
#   $t4: returned colour
#   uses $t7, $t8, $t9 as helpers, but restores them.
gem_color_fetcher:
    addi $sp, $sp, -4
    sw   $t2, 0($sp)
    addi $sp, $sp, -4
    sw   $t3, 0($sp)
    addi $sp, $sp, -4
    sw   $t7, 0($sp)
    addi $sp, $sp, -4
    sw   $t8, 0($sp)
    addi $sp, $sp, -4
    sw   $t9, 0($sp)

    # Make copy
    add  $t7, $zero, $t2      # t7 = x
    add  $t8, $zero, $t3      # t8 = y

    # Bound check on x: 0 <= x < 64 ----
    bltz $t7, gcf_out_of_bounds     # x < 0
    li   $t9, 64
    bge  $t7, $t9, gcf_out_of_bounds  # x >= 64

    # Bounds check on y: 0 <= y < 56 ----
    bltz $t8, gcf_out_of_bounds     # y < 0
    li   $t9, 56
    bge  $t8, $t9, gcf_out_of_bounds  # y >= 56

    # ---- In bounds: compute address = t0 + 4*x + Width*y ----
    # Use original x,y in $t2,$t3 (unchanged from caller’s view)
    sll  $t2, $t2, 2          # t2 = 4 * x
    li   $t9, Width           # Width = 256
    mult $t3, $t9             # y * Width
    mflo $t3                  # t3 = y * Width
    addu $t2, $t2, $t3        # t2 = 4*x + Width*y
    addu $t8, $t0, $t2        # t8 = base + offset (guaranteed 4-aligned)
    lw   $t4, 0($t8)          # load colour
    j    gcf_done

    gcf_out_of_bounds:
        # Treat out-of-bounds as black
        li   $t4, 0
    
    gcf_done:
        # Rewind
        lw   $t9, 0($sp)
        addi $sp, $sp, 4
        lw   $t8, 0($sp)
        addi $sp, $sp, 4
        lw   $t7, 0($sp)
        addi $sp, $sp, 4
        lw   $t3, 0($sp)
        addi $sp, $sp, 4
        lw   $t2, 0($sp)
        addi $sp, $sp, 4
    
        jr   $ra



## move left function
# move the current three_gem column left by a length of 4 pixels, or if left side is blocked then stay. Using (X', Y') tp denote the test coordinate.
# Setting variables:
# $t5 -> $t5 - 4 or stay unchanged 
# $t6: Y-coordinate unchanged
# $t2: test register, used to fetch the color of the pixel($t5 - 2, $t6 + 3) on the left of the pixel in the gem(t5,t6 - 3), 
#       and check if it is not black, then can't move, otherwise can move
# $t3: help register with $t2
move_left:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $sp, $sp, -4
    sw $t2, 0($sp)
    addi $sp, $sp, -4
    sw $t3, 0($sp)
     
    #algrithm to get the color value of the test pixel (X', Y') and store into $t2
    addi $t2, $t6, 3  #calculate Y' and store in $t2 first
    li $t3, Width      #use $t3 as a helper to calculate vertical shift + horizontal shift from t0
    multu $t2, $t3
    mflo $t3           #now $t3 is the shift bits from $t0 to (0,Y')
    sll $t2, $t5, 2    # horizonral shift bits from $t0 to (X,0)
    add $t3, $t2, $t3  #total shift btis from $t0 to (X', Y')
    addi $t3, $t3, -8  # add horizontal difference(-8) to get total shift bits from $t0 to (X',Y')
    
    add $t2, $t0, $t3  #calculate the address of the pixel (X', Y')
    lw $t2, 0($t2)      #now $t2 is the color value of the pixel (X',Y')
    
    #check if (X',Y') is balck 
    bne $t2, 0, not_black # if color of (X', Y') is not black(i.e. next to a colored pixel)
        #first delete the former column by overwriting using a black three_gem
        jal draw_three_black
        # updating ($t5, $t6) to be (X - 4, Y)
        addi $t5, $t5, -4
        #then draw a new three_gem at (X - 4, Y)
        jal draw_three_gem
        #then update current_column_address by subtracting 16
        #la $t2, current_column_address    #get address of current_column_address
        #lw $t3, 0($t2)   #get the former address of (X,Y)
        #addi $t3, $t3, -16                #new address of (X - 4, Y) 
        #sw $t3, 0($t2)                   # store new address
        
    not_black:   #no operation
    
    lw $t3, 0($sp)
    addi $sp, $sp, 4
    lw $t2, 0($sp)
    addi $sp, $sp, 4
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
    
    ## move left function
# move the current three_gem column right by a length of 4 pixels, or if right side is blocked then stay. Using (X', Y') tp denote the test coordinate.
# Setting variables:
# $t5 -> $t5 + 4 or stay unchanged 
# $t6: Y-coordinate unchanged
# $t2: test register, used to fetch the color of the pixel($t5 + 5, $t6 + 3) on the left of the pixel in the gem(t5,t6 - 3), 
#       and check if it is not black, then can't move, otherwise can move
# $t3: help register with $t2
move_right:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $sp, $sp, -4
    sw $t2, 0($sp)
    addi $sp, $sp, -4
    sw $t3, 0($sp)
     
    #algrithm to get the color value of the test pixel (X', Y') and store into $t2
    addi $t2, $t6, 3  #calculate Y' and store in $t2 first
    li $t3, Width      #use $t3 as a helper to calculate vertical shift + horizontal shift from t0
    multu $t2, $t3
    mflo $t3           #now $t3 is the shift bits from $t0 to (0,Y')
    sll $t2, $t5, 2    # horizonral shift bits from $t0 to (X,0)
    add $t3, $t2, $t3  #total shift btis from $t0 to (X', Y')
    addi $t3, $t3, 20   # add horizontal difference(20) to get total shift bits from $t0 to (X',Y')
    
    add $t2, $t0, $t3  #calculate the address of the pixel (X', Y')
    lw $t2, 0($t2)      #now $t2 is the color value of the pixel (X',Y')
    
    #check if (X',Y') is black 
    bne $t2, 0, not_black_1 # if color of (X', Y') is not black(i.e. next to a colored pixel)
        #first delete the former column by overwriting using a black three_gem
        jal draw_three_black
        # updating ($t5, $t6) to be (X + 5, Y)
        addi $t5, $t5, 4
        #then draw a new three_gem at (X + 5, Y)
        jal draw_three_gem
        #then update current_column_address by subtracting 16
        #la $t2, current_column_address    #get address of current_column_address
        #lw $t3, 0($t2)                   #get the former address of (X,Y)
        #addi $t3, $t3, 16                #new address of (X + 5, Y) 
        #sw $t3, 0($t2)                   # store new address
        
        not_black_1:   #no operation
    
        lw $t3, 0($sp)
        addi $sp, $sp, 4
        lw $t2, 0($sp)
        addi $sp, $sp, 4
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
 
## move_down function:
# Move the current 3-gem column one cell down if there is empty space.
# Preconditions: $t5, $t6 are curent (X,Y) for current three_gem column
# $t5, $t6 = bottom gem top-left (they remain the base coordinates)
# Setting in the function:
# $t5, $t6 = (X, Y) may update as down move
# $t2, $t3 as helpers to detect if able to move 
move_down:
    
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    addi $sp, $sp, -4
    sw   $t2, 0($sp)

    addi $sp, $sp, -4
    sw   $t3, 0($sp)

    # --- Compute test pixel (X', Y') just below the bottom gem ---
    # Y' = $t6 + 4 (one pixel row below the bottom gem)
    addi $t2, $t6, 4

    # vertical offset = Y' * Width
    li   $t3, Width
    multu $t2, $t3
    mflo $t3                      # t3 = vertical bits offset

    # X' = $t5 + 2 (roughly the center of the gem)
    addi $t2, $t5, 2
    sll  $t2, $t2, 2              # horizontal byte offset = X' * 4

    add  $t3, $t3, $t2            # total offset from base
    add  $t2, $t0, $t3            # t2 = address of test pixel (X', Y')

    lw   $t2, 0($t2)              # t2 = colour of test pixel

    # If the pixel below is not black (!= 0), we cannot move down
    bne  $t2, $zero, s_not_black

        # 1. Erase current column at (t5, t6)
        jal  draw_three_black

        # 2. Update coordinates: move bottom gem down by 4 pixels
        addi $t6, $t6, 4

        # 3. Update current_column_address by adding Width bytes (one row down)
        #la   $t2, current_column_address
        #lw   $t3, 0($t2)
        #li   $t4, Width 
        #sll  $t4, $t4, 2
        #add  $t3, $t3, $t4
        #sw   $t3, 0($t2)

        # 4. Draw the column at the new position
        jal  draw_three_gem
        
    s_not_black:
        # Restore registers and return
        lw   $t3, 0($sp)
        addi $sp, $sp, 4
    
        lw   $t2, 0($sp)
        addi $sp, $sp, 4
    
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
        
# swap_color function:
# Reroder the current three_gem column: curr_color[2] -> curr_color[0]; curr_color[1] -> curr_color[2]; curr_color[0] -> curr_color[1]
# preconditions: $t5, $t6 are curent (X,Y) for current three_gem column
# Setting in function:
# $t5, $t6 = (X,Y)
# $t7 = address of current_column_colors
# $t3, as helper, used to fetch color from current_column_colors
# $t4, as helper, used to fetch color from current_column_colors
swap_color:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    addi $sp, $sp, -4
    sw $t4, 0($sp)
    addi $sp, $sp, -4
    sw $t7, 0($sp)
    
    #fetch color of current bottom gem and store in current_column_colors
    la $t7, current_column_colors
    lw $t3, 8($t7)  #t3 = bottom gem color
    lw $t4, 0($t7)  #t4 = top gem color
    sw $t3, 0($t7)  # bottom color -> top color
    lw $t3, 4($t7)  #t3 = middle gem color
    sw $t4, 4($t7)  #top color -> middle color
    sw $t3, 8($t7)  #middle color -> bottom color  
    
    lw $t7, 0($sp)      #rewind $t7
    addi $sp, $sp, 4
    
    # draw new color three_gem
    jal draw_three_gem
    
    lw $t4, 0($sp)
    addi $sp, $sp, 4
    lw $t3, 0($sp)
    addi $sp, $sp, 4
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    

##check_bottom function:
# This function checks if the current three_gem columns's bottom touches the bottom boundary or touches some other gems, if so, 
#  the life of this three gem will be finished, and will swtich to a new born three_gem column
# Precondition: $t5, $t6 are (X,Y) coordinates of the top left pixel in the bottom gem in current three_gem_column, which is waitign for check
# Setting in funtion
# $t5, $t6 intially be (X,Y), and may changed to new (X,Y) if bottom touches something
# $t2, $t3 as helpers to detect if able to move
check_bottom:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    addi $sp, $sp, -4
    sw   $t2, 0($sp)

    addi $sp, $sp, -4
    sw   $t3, 0($sp)

    # --- Compute test pixel (X', Y') just below the bottom gem ---
    # Y' = $t6 + 4 (one pixel row below the bottom gem)
    addi $t2, $t6, 4

    # vertical offset = Y' * Width
    li   $t3, Width
    multu $t2, $t3
    mflo $t3                      # t3 = vertical bits offset

    # X' = $t5 + 2 (roughly the center of the gem)
    addi $t2, $t5, 2
    sll  $t2, $t2, 2              # horizontal byte offset = X' * 4

    add  $t3, $t3, $t2            # total offset from base
    add  $t2, $t0, $t3            # t2 = address of test pixel (X', Y')

    lw   $t2, 0($t2)              # t2 = colour of test pixel

    # If the pixel below is not black (!= 0), cannot move down
    bne  $t2, $zero, bottom_not_black
        # Restore registers and return
        lw   $t3, 0($sp)
        addi $sp, $sp, 4
    
        lw   $t2, 0($sp)
        addi $sp, $sp, 4
    
        lw   $ra, 0($sp)
        addi $sp, $sp, 4
        jr   $ra
    
    bottom_not_black:
        
        # check eliminate around the just-landed 3-gem column
        # bottom gem (x = $t5, y = $t6)
        addi $t2, $t5, 0
        addi $t3, $t6, 0
        jal  eliminate
    
        # middle gem (x = $t5, y = $t6 - 4)
        addi $t2, $t5, 0
        addi $t3, $t6, -4
        jal  eliminate
    
        # top gem (x = $t5, y = $t6 - 8)
        addi $t2, $t5, 0
        addi $t3, $t6, -8
        jal  eliminate

        # perform chain elimination: repeatedly scan the board
        jal  chain_elimination
        
        # Restore saved registers for check_bottom
        lw   $t3, 0($sp)
        addi $sp, $sp, 4
    
        lw   $t2, 0($sp)
        addi $sp, $sp, 4
    
        lw   $ra, 0($sp)
        addi $sp, $sp, 4

        # Spawn a new 3-gem column (may trigger Game Over)
        j    spawn_new_column


# spawn_new_column:
#   Check if the three spawn positions for the new column are empty.
#   If any of them is occupied (colour != 0), go to Game Over.
#   Otherwise:
#     - copy NEXT colours into current_column_colors
#     - set (t5,t6) as the bottom gem position
#     - draw the new falling column
#     - generate a new NEXT column + preview
#
# Spawn positions (top-left pixel of each gem):
#   bottom gem: (14, 10)
#   middle gem: (14,  6)
#   top   gem: (14,  2)
spawn_new_column:
    # Save caller registers we use (t5,t6 are intentionally NOT saved,
    # because we WANT them to become the new column position)
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $t2, 4($sp)
    sw   $t3, 0($sp)

    ########## check bottom gem at (14, 10) ##########
    li   $t2, 14
    li   $t3, 10
    jal  gem_color_fetcher      # colour -> $t4
    bne  $t4, $zero, spawn_game_over

    ########## check middle gem at (14, 6) ##########
    li   $t2, 14
    li   $t3, 6
    jal  gem_color_fetcher
    bne  $t4, $zero, spawn_game_over

    ########## check top gem at (14, 2) ##########
    li   $t2, 14
    li   $t3, 2
    jal  gem_color_fetcher
    bne  $t4, $zero, spawn_game_over

    ########## All three spawn cells are empty ##########
    # 1. Copy next_column_colors -> current_column_colors
    la   $t2, next_column_colors
    la   $t3, current_column_colors

    lw   $t4, 0($t2)        # top
    sw   $t4, 0($t3)

    lw   $t4, 4($t2)        # middle
    sw   $t4, 4($t3)

    lw   $t4, 8($t2)        # bottom
    sw   $t4, 8($t3)

    # 2. Set starting position for the new falling column
    #    (bottom gem top-left pixel)
    li   $t5, 14            # x
    li   $t6, 10            # y

    # 3. Draw the new current column on the playfield
    jal  draw_three_gem

    # 4. Generate a NEW "next" column and redraw preview
    jal  init_next_column

    # 5. Restore and return
    lw   $t3, 0($sp)
    lw   $t2, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra

spawn_game_over:
    # Restore stack frame, then go to Game Over screen (no return)
    lw   $t3, 0($sp)
    lw   $t2, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12

    j    game_over_screen

    
######### Code for eliminating gems ############

## check_row function -> return # of gems with same color on the row (including center)-> $t7
# Checks how many consecutive same color gems are there in row of the input gem(if boundary then stop counting), returning the number
# preconditions: $t2, $t3 store the coordinates of the top left corner pixel of the gem.
# Setting in the function:
# $t2, $t3 are coordinates 
# $t4 used to fetch the color of the input gem
# $t7: same-color pixel counter
# $t8, $t9: helper
check_row: 
    push3($ra, $t8, $t9)
    push2($t2, $t3)
    
    addi $t7, $zero, 1      #initializa $t7
    
    jal gem_color_fetcher # color -> $t4
    addi $t8, $t4, 0      # store in $t8
    
    
    check_left_loop:
        addi $t2, $t2, -4
        
        jal gem_color_fetcher # color -> $t4
        addi $t9, $zero, 2
        ble $t2, $t9, end_check_left   # if x <= 0, stop scanning
        bne $t8, $t4, end_check_left #left pixel color isn't the same as current gem
            addi $t7, $t7, 1
        
        j check_left_loop
    
    end_check_left: 
    
    #reposition $t2 to the current gem
    lw   $t3, 0($sp)                # top of stack = saved $t3
    lw   $t2, 4($sp)                # sp + 4 -> saved $t2 
    
    check_right_loop:
        addi $t2, $t2, 4
        
        jal gem_color_fetcher # color -> $t4
        addi $t9, $zero, 61
        bge $t2, $t9, end_check_right   # if x <= 0, stop scanning
        bne $t8, $t4, end_check_right #left pixel color isn't the same as current gem
            addi $t7, $t7, 1
        
        j check_right_loop
    
    end_check_right: 
    
    pop2($t3, $t2)
    pop3($t9, $t8, $ra)
    
    jr $ra
    
## mark_eliminates_row function
# Given the current(the gem that needs to be eliminated according to check_row) coordinate of the gem,
# make the same colors in a row and push their coordinates one by one into eliminate_marker.
# preconditions: $t2, $t3 are coordinates of the current gem (top left pixel of the gem), 
#
# Settings in the function:
#   Uses $t7, $t8, $t9 as helpers.
#   eliminate_marker layout:
#       eliminate_marker[0] = count (word)
#       eliminate_marker[1] = x0
#       eliminate_marker[2] = y0
#       eliminate_marker[3] = x1
#       eliminate_marker[4] = y1
mark_eliminates_row:
    # Save caller registers we will modify
    push4($ra, $t7, $t8, $t9)
    push2($t2, $t3)             # save original (x,y) on stack

    # Get colour of the center gem and keep it in $t8
    jal  gem_color_fetcher      # uses $t2,$t3, returns colour in $t4
    addi $t8, $t4, 0            # $t8 = centre colour (constant in this function)

    # Load eliminate_marker base and current count into $t9 and $t7
    la   $t9, eliminate_marker  # $t9 = &eliminate_marker
    lw   $t7, 0($t9)            # $t7 = current count of stored coords

    # Store center gem (x = $t2, y = $t3)
    sll  $t4, $t7, 3            # offset = 8 * count (two words per coord pair)
    addi $t4, $t4, 4            # skip the count word
    add  $t4, $t4, $t9          # $t4 = address to store this (x,y)
    sw   $t2, 0($t4)            # store x
    sw   $t3, 4($t4)            # store y
    addi $t7, $t7, 1            # count++

    # Scan LEFT from the center: x -> x - 4 each step
    addi $t2, $t2, -4           # first left neighbour: x - 4

    mark_row_left_loop:
        addi $t4, $zero, 2          # left boundary: x >= 2
        blt  $t2, $t4, mark_row_left_done
    
        jal  gem_color_fetcher      # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_row_left_done
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3            # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)            # store x
        sw   $t3, 4($t4)            # store y
        addi $t7, $t7, 1            # count++
    
        addi $t2, $t2, -4           # move further left
        j    mark_row_left_loop
    
    mark_row_left_done:
        # Restore original (x,y) from stack for RIGHT scan
        lw   $t3, 0($sp)            # saved original y
        lw   $t2, 4($sp)            # saved original x
    

    # Scan RIGHT from the center: x -> x + 4 each step
    addi $t2, $t2, 4            # first right neighbour: x + 4
    
    mark_row_right_loop:
        addi $t4, $zero, 61         # right boundary: x <= 61
        bgt  $t2, $t4, mark_row_right_done
    
        jal  gem_color_fetcher      # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_row_right_done
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3            # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)            # store x
        sw   $t3, 4($t4)            # store y
        addi $t7, $t7, 1            # count++
    
        addi $t2, $t2, 4            # move further right
        j    mark_row_right_loop
    
    mark_row_right_done:
        # Write back updated count into eliminate_marker[0]
        sw   $t7, 0($t9)
    
        # Restore caller registers and return
        pop2($t3, $t2)
        pop4($t9, $t8, $t7, $ra)
    
        jr   $ra


## check_col function -> return # of gems with same color in the column -> $t7
# Checks how many consecutive same color gems are there in column of the input gem
# (if boundary then stop counting), returning the number.
# preconditions: $t2, $t3 store the coordinates of the top left corner pixel of the gem.
# Settings in the function:
#   $t2, $t3 are coordinates 
#   $t4 used to fetch the color of the input gem
#   $t7: same-color pixel counter
#   $t8, $t9: helper
check_col:
    push3($ra, $t8, $t9)
    push2($t2, $t3)
    
    addi $t7, $zero, 0      # initialize $t7
    
    jal  gem_color_fetcher  # color -> $t4
    addi $t8, $t4, 0        # store centre color in $t8
    
    ########## scan UP ##########
    check_up_loop:
            addi $t3, $t3, -4        # one gem up (y - 4)
            
            jal  gem_color_fetcher   # color -> $t4
            addi $t9, $zero, 2       # top boundary
            ble  $t3, $t9, end_check_up   # if y <= 2, stop scanning
            bne  $t8, $t4, end_check_up   # colour differs -> stop
                addi $t7, $t7, 1          # same colour, count++
            
            j    check_up_loop
    
    end_check_up:
        
        # reposition (x,y) back to the original gem
        lw   $t3, 0($sp)               # top of stack = saved $t3
        lw   $t2, 4($sp)               # sp + 4 -> saved $t2 
    
    ########## scan DOWN ##########
    check_down_loop:
            addi $t3, $t3, 4           # one gem down (y + 4)
            
            jal  gem_color_fetcher     # color -> $t4
            addi $t9, $zero, 53        # bottom boundary
            bge  $t3, $t9, end_check_down  # if y >= 53, stop scanning
            bne  $t8, $t4, end_check_down  # colour differs -> stop
                addi $t7, $t7, 1            # same colour, count++
            
            j    check_down_loop
        
    end_check_down:
        
        pop2($t3, $t2)
        pop3($t9, $t8, $ra)
        
        jr $ra

## mark_eliminates_col function
# Given the current (the gem that needs to be eliminated according to check_col)
# coordinate of the gem, make the same colors in a column and push their coordinates 
# one by one into eliminate_marker, and later will be eliminated together.
#
# preconditions: $t2, $t3 are coordinates of the current gem (top left pixel of the gem), 
# 
# Settings in the function:
#   Uses $t7, $t8, $t9 as helpers.
#   eliminate_marker layout:
#       eliminate_marker[0] = count (word)
#       eliminate_marker[1] = x0
#       eliminate_marker[2] = y0
#       eliminate_marker[3] = x1
#       eliminate_marker[4] = y1
#       ...
mark_eliminates_col:
    # Save caller registers we will modify
    push4($ra, $t7, $t8, $t9)
    push2($t2, $t3)             # save original (x,y) on stack

    # Get colour of the center gem and keep it in $t8
    jal  gem_color_fetcher      # uses $t2,$t3, returns colour in $t4
    addi $t8, $t4, 0            # $t8 = centre colour (constant in this function)

    # Load eliminate_marker base and current count into $t9 and $t7
    la   $t9, eliminate_marker  # $t9 = &eliminate_marker
    lw   $t7, 0($t9)            # $t7 = current count of stored coords

    # ---- Store center gem (x = $t2, y = $t3) ----
    sll  $t4, $t7, 3            # offset = 8 * count (two words per coord pair)
    addi $t4, $t4, 4            # skip the count word
    add  $t4, $t4, $t9          # $t4 = address to store this (x,y)
    sw   $t2, 0($t4)            # store x
    sw   $t3, 4($t4)            # store y
    addi $t7, $t7, 1            # count++

    # Scan UP from the center: y -> y - 4 each step
    addi $t3, $t3, -4           # first upper neighbour: y - 4

    mark_col_up_loop:
        addi $t4, $zero, 2          # top boundary: y >= 2
        blt  $t3, $t4, mark_col_up_done
    
        jal  gem_color_fetcher      # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_col_up_done
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3            # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)            # store x (unchanged)
        sw   $t3, 4($t4)            # store y
        addi $t7, $t7, 1            # count++
    
        addi $t3, $t3, -4           # move further up
        j    mark_col_up_loop

    mark_col_up_done:
        # Restore original (x,y) from stack for DOWN scan
        lw   $t3, 0($sp)            # saved original y
        lw   $t2, 4($sp)            # saved original x
    
        # Scan DOWN from the center: y -> y + 4 each step
        addi $t3, $t3, 4            # first lower neighbour: y + 4

    mark_col_down_loop:
        addi $t4, $zero, 53         # bottom boundary: y <= 53
        bgt  $t3, $t4, mark_col_down_done
    
        jal  gem_color_fetcher      # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_col_down_done
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3            # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)            # store x
        sw   $t3, 4($t4)            # store y
        addi $t7, $t7, 1            # count++
    
        addi $t3, $t3, 4            # move further down
        j    mark_col_down_loop
    
    mark_col_down_done:
        # Write back updated count into eliminate_marker[0]
        sw   $t7, 0($t9)
    
        # Restore caller registers and return
        pop2($t3, $t2)
        pop4($t9, $t8, $t7, $ra)
    
        jr   $ra


## check_diag_left function -> return # of gems with same color on the left diagonal -> $t7
# Checks how many consecutive same color gems are there on the left diagonal of the input gem
# (if boundary then stop counting), returning the number.
# preconditions: $t2, $t3 store the coordinates of the top left corner pixel of the gem.
# Settings in the function:
#   $t2, $t3 are coordinates 
#   $t4 used to fetch the color of the input gem
#   $t7: same-color pixel counter
#   $t8, $t9: helper
check_diag_left:
    push3($ra, $t8, $t9)
    push2($t2, $t3)
    
    addi $t7, $zero, 0         # initialize $t7
    
    jal  gem_color_fetcher     # colour of centre gem -> $t4
    addi $t8, $t4, 0           # store centre colour in $t8
    
    ########## scan up-left (x - 4, y - 4) ##########
    check_up_left_loop:
            addi $t2, $t2, -4      # x -= 4
            addi $t3, $t3, -4      # y -= 4
            
            jal  gem_color_fetcher # colour -> $t4
            
            addi $t9, $zero, 2
            ble  $t2, $t9, end_check_up_left     # if x <= 2, stop
            ble  $t3, $t9, end_check_up_left     # if y <= 2, stop
            bne  $t8, $t4, end_check_up_left     # colour differs -> stop
                addi $t7, $t7, 1                 # same colour, count++
            
            j    check_up_left_loop
        
    end_check_up_left:
    
        # reposition (x,y) back to original from stack (without popping yet)
        lw   $t3, 0($sp)           # top of stack = saved $t3
        lw   $t2, 4($sp)           # sp + 4 -> saved $t2

    ########## scan down-right (x + 4, y + 4) ##########
    check_down_right_loop:
            addi $t2, $t2, 4       # x += 4
            addi $t3, $t3, 4       # y += 4
            
            jal  gem_color_fetcher # colour -> $t4
            
            addi $t9, $zero, 61
            bge  $t2, $t9, end_check_down_right  # if x >= 61, stop
            addi $t9, $zero, 53
            bge  $t3, $t9, end_check_down_right  # if y >= 53, stop
            bne  $t8, $t4, end_check_down_right  # colour differs -> stop
                addi $t7, $t7, 1                 # same colour, count++
            
            j    check_down_right_loop
    
    end_check_down_right:
        
        pop2($t3, $t2)
        pop3($t9, $t8, $ra)
        
        jr $ra
        
## mark_eliminates_diag_left function
# Given the current (the gem that needs to be eliminated according to check_diag_left)
# coordinate of the gem, make the same colors on the left diagonal and push their coordinates 
# one by one into eliminate_marker, and later will be eliminated together.
#
# preconditions: $t2, $t3 are coordinates of the current gem (top left pixel of the gem), 
# 
# Settings in the function:
#   Uses $t7, $t8, $t9 as helpers.
#   eliminate_marker layout:
#       eliminate_marker[0] = count (word)
#       eliminate_marker[1] = x0
#       eliminate_marker[2] = y0
#       eliminate_marker[3] = x1
#       eliminate_marker[4] = y1
#       ...
mark_eliminates_diag_left:
    # Save registers we will modify
    push4($ra, $t7, $t8, $t9)
    push2($t2, $t3)                # save original (x,y)

    # Get colour of the centre gem and keep it in $t8
    jal  gem_color_fetcher         # uses $t2,$t3, returns colour in $t4
    addi $t8, $t4, 0               # $t8 = centre colour

    # Load eliminate_marker base and current count into $t9 and $t7
    la   $t9, eliminate_marker     # $t9 = &eliminate_marker
    lw   $t7, 0($t9)               # $t7 = current count of stored coords

    # ---- Store center gem (x = $t2, y = $t3) ----
    sll  $t4, $t7, 3               # offset = 8 * count (two words per coord pair)
    addi $t4, $t4, 4               # skip the count word
    add  $t4, $t4, $t9             # $t4 = address to store this (x,y)
    sw   $t2, 0($t4)               # store x
    sw   $t3, 4($t4)               # store y
    addi $t7, $t7, 1               # count++

    # Scan up-left from the center: (x - 4, y - 4)

    addi $t2, $t2, -4              # first up-left neighbour
    addi $t3, $t3, -4

    mark_diag_left_up_loop:
        addi $t4, $zero, 2             # top/left boundary value
    
        blt  $t2, $t4, mark_diag_left_up_done   # if x < 2, stop
        blt  $t3, $t4, mark_diag_left_up_done   # if y < 2, stop
    
        jal  gem_color_fetcher         # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_diag_left_up_done   # if colour != centre, stop
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3               # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)               # store x
        sw   $t3, 4($t4)               # store y
        addi $t7, $t7, 1               # count++
    
        addi $t2, $t2, -4              # move further up-left
        addi $t3, $t3, -4
        j    mark_diag_left_up_loop
    
    mark_diag_left_up_done:
        # Restore original (x,y) from stack for DOWN-RIGHT scan
        lw   $t3, 0($sp)               # saved original y
        lw   $t2, 4($sp)               # saved original x
    
        # Scan down-right from the center: (x + 4, y + 4)
        addi $t2, $t2, 4              # first down-right neighbour
        addi $t3, $t3, 4
    
    mark_diag_left_down_loop:
        addi $t4, $zero, 61           # right boundary for x
        bgt  $t2, $t4, mark_diag_left_down_done   # if x > 61, stop
    
        addi $t4, $zero, 53           # bottom boundary for y
        bgt  $t3, $t4, mark_diag_left_down_done   # if y > 53, stop
    
        jal  gem_color_fetcher        # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_diag_left_down_done   # if colour != centre, stop
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3              # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)              # store x
        sw   $t3, 4($t4)              # store y
        addi $t7, $t7, 1              # count++
    
        addi $t2, $t2, 4              # move further down-right
        addi $t3, $t3, 4
        j    mark_diag_left_down_loop
    
    mark_diag_left_down_done:
        # Write back updated count into eliminate_marker[0]
        sw   $t7, 0($t9)
    
        # Restore caller registers and return
        pop2($t3, $t2)
        pop4($t9, $t8, $t7, $ra)
    
        jr   $ra


## check_diag_right function -> return # of gems with same color on the right diagonal -> $t7
# Checks how many consecutive same color gems are there on the right diagonal of the input gem
# (if boundary then stop counting), returning the number.
# preconditions: $t2, $t3 store the coordinates of the top left corner pixel of the gem.
# Settings in the function:
#   $t2, $t3 are coordinates 
#   $t4 used to fetch the color of the input gem
#   $t7: same-color pixel counter
#   $t8, $t9: helper
check_diag_right:
    push3($ra, $t8, $t9)
    push2($t2, $t3)
    
    addi $t7, $zero, 0         # initialize $t7
    
    jal  gem_color_fetcher     # colour of centre gem -> $t4
    addi $t8, $t4, 0           # store centre colour in $t8
    
    ########## scan up-right (x + 4, y - 4) ##########
    check_up_right_loop:
            addi $t2, $t2, 4       # x += 4
            addi $t3, $t3, -4      # y -= 4
            
            jal  gem_color_fetcher # colour -> $t4
            
            addi $t9, $zero, 61
            bge  $t2, $t9, end_check_up_right    # if x >= 61, stop
            addi $t9, $zero, 2
            ble  $t3, $t9, end_check_up_right    # if y <= 2, stop
            bne  $t8, $t4, end_check_up_right    # colour differs -> stop
                addi $t7, $t7, 1                 # same colour, count++
            
            j    check_up_right_loop
        
    end_check_up_right:
    
        # reposition (x,y) back to original from stack (without popping yet)
        lw   $t3, 0($sp)           # top of stack = saved $t3
        lw   $t2, 4($sp)           # sp + 4 -> saved $t2
    
    ########## scan down-left (x - 4, y + 4) ##########
    check_down_left_loop:
            addi $t2, $t2, -4      # x -= 4
            addi $t3, $t3, 4       # y += 4
            
            jal  gem_color_fetcher # colour -> $t4
            
            addi $t9, $zero, 2
            ble  $t2, $t9, end_check_down_left   # if x <= 2, stop
            addi $t9, $zero, 53
            bge  $t3, $t9, end_check_down_left   # if y >= 53, stop
            bne  $t8, $t4, end_check_down_left   # colour differs -> stop
                addi $t7, $t7, 1                 # same colour, count++
            
            j    check_down_left_loop
        
    end_check_down_left:
        
        pop2($t3, $t2)
        pop3($t9, $t8, $ra)
        
        jr $ra
        
    
## mark_eliminates_diag_right function
# Given the current (the gem that needs to be eliminated according to check_diag_right)
# coordinate of the gem, make the same colors on the right diagonal and push their coordinates 
# one by one into eliminate_marker, and later will be eliminated together.
#
# preconditions: $t2, $t3 are coordinates of the current gem (top left pixel of the gem), 
# 
# Settings in the function:
#   Uses $t7, $t8, $t9 as helpers.
#   eliminate_marker layout as in mark_eliminates_diag_left.
mark_eliminates_diag_right:
    # Save registers we will modify
    push4($ra, $t7, $t8, $t9)
    push2($t2, $t3)                # save original (x,y)

    # Get colour of the centre gem and keep it in $t8
    jal  gem_color_fetcher         # uses $t2,$t3, returns colour in $t4
    addi $t8, $t4, 0               # $t8 = centre colour

    # Load eliminate_marker base and current count into $t9 and $t7
    la   $t9, eliminate_marker     # $t9 = &eliminate_marker
    lw   $t7, 0($t9)               # $t7 = current count of stored coords

    # ---- Store center gem (x = $t2, y = $t3) ----
    sll  $t4, $t7, 3               # offset = 8 * count (two words per coord pair)
    addi $t4, $t4, 4               # skip the count word
    add  $t4, $t4, $t9             # $t4 = address to store this (x,y)
    sw   $t2, 0($t4)               # store x
    sw   $t3, 4($t4)               # store y
    addi $t7, $t7, 1               # count++

    # Scan up-right from the center: (x + 4, y - 4)
    addi $t2, $t2, 4              # first up-right neighbour
    addi $t3, $t3, -4

    mark_diag_right_up_loop:
        addi $t4, $zero, 61
        bge  $t2, $t4, mark_diag_right_up_done   # if x >= 61, stop
    
        addi $t4, $zero, 2
        ble  $t3, $t4, mark_diag_right_up_done   # if y <= 2, stop
    
        jal  gem_color_fetcher        # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_diag_right_up_done   # if colour != centre, stop
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3              # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)              # store x
        sw   $t3, 4($t4)              # store y
        addi $t7, $t7, 1              # count++
    
        addi $t2, $t2, 4              # move further up-right
        addi $t3, $t3, -4
        j    mark_diag_right_up_loop
    
    mark_diag_right_up_done:
        # Restore original (x,y) from stack for DOWN-LEFT scan
        lw   $t3, 0($sp)               # saved original y
        lw   $t2, 4($sp)               # saved original x
    
        # Scan down-left from the center: (x - 4, y + 4)
        addi $t2, $t2, -4             # first down-left neighbour
        addi $t3, $t3, 4
    
    mark_diag_right_down_loop:
        addi $t4, $zero, 2
        ble  $t2, $t4, mark_diag_right_down_done   # if x <= 2, stop
    
        addi $t4, $zero, 53
        bge  $t3, $t4, mark_diag_right_down_done   # if y >= 53, stop
    
        jal  gem_color_fetcher        # colour at (t2,t3) -> $t4
        bne  $t4, $t8, mark_diag_right_down_done   # if colour != centre, stop
    
        # Same colour: store this coordinate
        sll  $t4, $t7, 3              # offset = 8 * count
        addi $t4, $t4, 4
        add  $t4, $t4, $t9
        sw   $t2, 0($t4)              # store x
        sw   $t3, 4($t4)              # store y
        addi $t7, $t7, 1              # count++
    
        addi $t2, $t2, -4             # move further down-left
        addi $t3, $t3, 4
        j    mark_diag_right_down_loop
    
    mark_diag_right_down_done:
        # Write back updated count into eliminate_marker[0]
        sw   $t7, 0($t9)
    
        # Restore caller registers and return
        pop2($t3, $t2)
        pop4($t9, $t8, $t7, $ra)
    
        jr   $ra

   
## eliminate_marked_gems function
# Actually eliminate all gems recorded in eliminate_marker by drawing black gems,
# and then clear all used entries in eliminate_marker.
#
# Precondition:
#   eliminate_marker[0] = N  (number of gems to eliminate)
#   eliminate_marker[1..] = (x0, y0, x1, y1, ..., x_{N-1}, y_{N-1})
#
# Effect:
#   For each stored (x, y), draw a black gem at that coordinate.
#   Then clear the used (x, y) entries and reset eliminate_marker[0] to 0.
#
# Registers used (and preserved):
#   Uses $t2, $t3 as temporary x,y for each gem.
#   Uses $t7 as pointer into eliminate_marker.
#   Uses $t8 as remaining-count loop variable.
#   Uses $t4 for colour (set to 0 = black).
#   Saves/restores $ra, $t2, $t3, $t7, $t8.

eliminate_marked_gems:
    # Save caller-saved registers we will overwrite
    push3($ra, $t7, $t8)
    push2($t2, $t3)

    # $t7 = base address of eliminate_marker
    la   $t7, eliminate_marker

    # $t8 = count of (x,y) pairs to eliminate
    lw   $t8, 0($t7)

    # If count == 0, nothing to do (no gravity, no chain flag)
    beq  $t8, $zero, elim_done

    # Mark that an elimination actually happened (for chain reactions)
    la   $t9, chain_elim_flag
    li   $t4, 1
    sw   $t4, 0($t9)

    # Set colour to black for all eliminations
    li   $t4, 0              # black

    # Move pointer to first (x,y) pair: eliminate_marker + 4
    addi $t7, $t7, 4         # $t7 now points at x0

elim_loop:
        # If no more pairs, exit loop
        beq  $t8, $zero, elim_loop_end
    
        # Load x,y from eliminate_marker
        lw   $t2, 0($t7)         # x
        lw   $t3, 4($t7)         # y
    
        # Prepare arguments for draw_gem
        addi $a0, $t2, 0         # a0 = x
        addi $a1, $t3, 0         # a1 = y
        # t4 already = 0 (black)
    
        # Draw a single black gem at (x,y)
        jal  draw_gem
    
        # Clear the marker entries we just consumed
        sw   $zero, 0($t7)       # clear x
        sw   $zero, 4($t7)       # clear y
    
        # Move to next (x,y) pair
        addi $t7, $t7, 8         # advance pointer by 8 bytes (2 words)
        addi $t8, $t8, -1        # decrement remaining count
        j    elim_loop
    
elim_loop_end:
        # After finishing elimination, reset count to 0
        la   $t7, eliminate_marker
        sw   $zero, 0($t7)

elim_done:
        # Apply gravity AFTER all deletions in this call
        jal  apply_gravity

        # Restore caller registers
        pop2($t3, $t2)
        pop3($t8, $t7, $ra)
    
        jr   $ra



## eliminate function
# For the gem at coordinates ($t2, $t3), check all 4 directions (row, column,
# left diagonal, right diagonal). For each direction that has at least 3
# same-colour gems including the centre, record all their coordinates into
# eliminate_marker via the appropriate mark_* function.
# Finally calls eliminate_marked_gems to erase them and clear the marker.
#
# Preconditions:
#   - $t2, $t3 are the coordinates (X, Y) of the gem (top-left pixel).
#
# Uses (and preserves):
#   - $t2, $t3 (anchor coordinates)
#   - $t7, $t8, $t9 as temporaries / counters
#   - $ra for returns
eliminate:
    # Save registers we will use
    push4($ra, $t7, $t8, $t9)
    push2($t2, $t3)              # save original (x,y) on stack

    # if this gem is black (empty), skip all checks
    jal  gem_color_fetcher       # colour -> $t4 (gem_color_fetcher preserves t2,t3)
    beq  $t4, $zero, elim_calls_done

    # 1. Check / mark ROW
    # Restore anchor (x,y)
    lw   $t3, 0($sp)             # saved original y
    lw   $t2, 4($sp)             # saved original x

    jal  check_row               # check_row: t7 = total in row INCLUDING centre
    li   $t9, 3
    blt  $t7, $t9, skip_mark_row  # if < 3, no row elimination

        # Restore anchor again for marking
        lw   $t3, 0($sp)
        lw   $t2, 4($sp)
        jal  mark_eliminates_row

    skip_mark_row:
    
    # 2. Check / mark COLUMN  #
    # Restore anchor (x,y)
    lw   $t3, 0($sp)
    lw   $t2, 4($sp)

    jal  check_col               # check_col: t7 = neighbours above + below (NO centre)
    addi $t8, $t7, 1             # total_in_col = neighbours + centre
    li   $t9, 3
    blt  $t8, $t9, skip_mark_col # if < 3 INCLUDING centre, skip

        lw   $t3, 0($sp)
        lw   $t2, 4($sp)
        jal  mark_eliminates_col

    skip_mark_col:

    # 3. Check / mark LEFT DIAGONAL        

    lw   $t3, 0($sp)
    lw   $t2, 4($sp)

    jal  check_diag_left          # check_diag_left: t7 = neighbours up-left + down-right
    addi $t8, $t7, 1              # total_in_diag = neighbours + centre
    li   $t9, 3
    blt  $t8, $t9, skip_mark_diag_left

        lw   $t3, 0($sp)
        lw   $t2, 4($sp)
        jal  mark_eliminates_diag_left

    skip_mark_diag_left:


    # 4. Check / mark RIGHT DIAGONAL
    
    # Restore anchor (x,y)
    lw   $t3, 0($sp)
    lw   $t2, 4($sp)

    jal  check_diag_right         # check_diag_right: t7 = neighbours up-right + down-left
    addi $t8, $t7, 1              # total_in_diag = neighbours + centre
    li   $t9, 3
    blt  $t8, $t9, skip_mark_diag_right

        lw   $t3, 0($sp)
        lw   $t2, 4($sp)
        jal  mark_eliminates_diag_right

    skip_mark_diag_right:

    elim_calls_done:
    # After marking from ALL 4 directions (if any), actually eliminate them
    jal  eliminate_marked_gems

    # Restore registers and return
    pop2($t3, $t2)
    pop4($t9, $t8, $t7, $ra)

    jr   $ra

## chain_elimination function
# After an initial elimination + gravity, this function repeatedly scans the
# whole board for any possible 3+ matches and eliminates them (with gravity)
# until there are no more eliminations (i.e., no more chain reactions).
#
# Algorithm:
# outer_loop:
#   chain_elim_flag = 0
#   for each gem position (x = 2..58 step 4, y = 50..2 step -4):
#       set ($t2,$t3) = (x,y)
#       jal eliminate
#       (if eliminate finds a match, eliminate_marked_gems will set chain_elim_flag=1)
#   if chain_elim_flag == 1: repeat outer_loop
#   else: return
#
# Registers preserved: $ra, $t2, $t3
# Temporaries used (not preserved): $t4, $t5, $t6, $t9
chain_elimination:
    # Save registers
    push3($ra, $t2, $t3)

    chain_outer_loop:
        # Assume no elimination in this pass
        la   $t9, chain_elim_flag
        sw   $zero, 0($t9)
    
        # Scan all columns: x = 2, 6, 10, ..., 58
        li   $t5, 2            # $t5 = x
    
    chain_x_loop:
        li   $t9, 22
        bgt  $t5, $t9, chain_after_scan   # if x > 58, done with board scan
    
        # For this column, scan rows from bottom to top: y = 50, 46, ..., 2
        li   $t6, 50           # $t6 = y
    
    chain_y_loop:
        li   $t9, 2
        blt  $t6, $t9, chain_next_col     # if y < 2, done this column
    
        # Set anchor gem coordinates (top-left pixel of gem)
        add  $t2, $zero, $t5
        add  $t3, $zero, $t6
    
        # Try to eliminate matches involving this gem
        jal  eliminate
    
        # Next gem up in this column
        addi $t6, $t6, -4
        j    chain_y_loop
    
    chain_next_col:
        # Next column to the right
        addi $t5, $t5, 4
        j    chain_x_loop
    
    chain_after_scan:
        # Check if any elimination happened in this pass
        la   $t9, chain_elim_flag
        lw   $t4, 0($t9)
        bne  $t4, $zero, chain_outer_loop   # if flag==1, keep chaining
    
        # No more eliminations: restore registers and return
        pop3($t3, $t2, $ra)
        jr   $ra



## apply_gravity function
# After elimination has created empty (black) gems, make all remaining
# gems "fall" down in each column so that there are no floating gems.
#
# For each gem-column (fixed x):
#   - We scan from bottom to top (scan_y = 50, 46, ..., 2).
#   - We maintain a write pointer write_y (initially 50).
#   - When we see a non-black gem at (x, scan_y):
#       * If scan_y == write_y: gem is already as low as it can go.
#       * If scan_y != write_y: erase at (x, scan_y), draw gem at (x, write_y).
#       * Then write_y -= 4.
#
# Preconditions:
#   - Display base address in $t0 is correctly set.
#   - Board/boundary already drawn.
#   - Gems are axis-aligned 4x4 blocks with uniform colour, top-left at
#     (x, y) for x,y multiples of 2; game playfield uses x = 2..58, y = 2..50
#     stepping by 4.
#
# Settings in function:
#   - $s1 = current column x (2, 6, ..., 58)
#   - $s2 = write_y (destination row for next gem in this column)
#   - $s3 = scan_y (current row being scanned in this column)
#
#   Temporaries:
#   - $t2, $t3: used to hold x,y when computing addresses
#   - $t4: used as byte address temporarily and as scratch
#   - $t8: holds gem colour at (x, y)
#   - $t9: holds constants (Width, bounds)
#
#   Saved/restored:
#   - $ra, $t2, $t3, $t4, $t8, $t9, $s1, $s2, $s3
apply_gravity:
    # Save caller registers we will overwrite
    push4($ra, $t2, $t3, $t4)
    push4($t8, $t9, $s1, $s2)
    push1($s3)

    # Outer loop over columns: x = 2, 6, 10, ..., 58
    li   $s1, 2                # s1 = current column x

    gravity_col_loop:
        li   $t9, 22               # rightmost gem top-left x
        bgt  $s1, $t9, gravity_done_all   # if x > 58, all columns processed
    
        # For this column:
        #   write_y = 50  (bottom gem row)
        #   scan_y  = 50  (start scanning from bottom)
        li   $s2, 50               # s2 = write_y
        li   $s3, 50               # s3 = scan_y
    
    gravity_scan_loop:
        # If scan_y < 2, we are done with this column -> next column
        li   $t9, 2
        blt  $s3, $t9, gravity_next_col
    
        # Load colour at (x = s1, y = s3) into $t8
        # Compute address = t0 + 4*x + Width*y
        add  $t2, $zero, $s1       # t2 = x
        add  $t3, $zero, $s3       # t3 = y
    
        sll  $t4, $t2, 2           # t4 = 4 * x (horizontal offset in bytes)
        li   $t9, Width            # Width = 256 bytes per row
        multu $t3, $t9             # y * Width
        mflo $t9
        addu $t4, $t4, $t9         # t4 = 4*x + Width*y
        addu $t4, $t0, $t4         # t4 = base + offset
    
        lw   $t8, 0($t4)           # t8 = colour at (x, y)
    
        # If this cell is empty (black), just move scan_y up
        beq  $t8, $zero, gravity_scan_next
    
        # If scan_y == write_y, gem is already as low as possible
        beq  $s3, $s2, gravity_gem_placed
    
            # Move gem from (x = s1, y = s3) down to (x = s1, y = s2)
    
            # 1. Erase old gem by drawing a black gem at (s1, s3)
            li   $t4, 0            # t4 = black
            add  $a0, $zero, $s1   # a0 = x
            add  $a1, $zero, $s3   # a1 = scan_y
            add  $t4, $zero, $t4   # t4 already 0; keep style that t4 is colour
            jal  draw_gem
    
            # 2. Draw gem with original colour t8 at (s1, s2)
            add  $t4, $zero, $t8   # t4 = saved colour
            add  $a0, $zero, $s1   # a0 = x
            add  $a1, $zero, $s2   # a1 = write_y
            jal  draw_gem
    
    gravity_gem_placed:
        # A gem is now "fixed" at (x = s1, y = s2) in this column.
        addi $s2, $s2, -4          # write_y -= 4 (next free slot above)
    
    gravity_scan_next:
        # Move scan_y up one gem and continue scanning this column
        addi $s3, $s3, -4          # scan_y -= 4
        j    gravity_scan_loop
    
    gravity_next_col:
        # Finished this column; proceed to next column x += 4
        addi $s1, $s1, 4
        j    gravity_col_loop
    
    gravity_done_all:
        # Restore caller registers
        pop1($s3)
        pop4($s2, $s1, $t9, $t8)
        pop4($t4, $t3, $t2, $ra)
    
        jr   $ra





###################################################################
# Code for Key Detection
# $t1 stores keyboard address, keep unchanged

# ASCII code reference table:
# w - 0x77
# a - 0x61
# s - 0x73
# d - 0x64
# q - 0x71
# p - 0x70

# check_key funtion:
# By calling to check whether the key is clicked, if clicked, go to correspending key branches
# setting variable:
# $t8: hold value at keyboard_address, may be 0(unclicked) or 1(clicked)
check_key: 
    lw $t8, 0($t1)
    beq $t8, 1, keyboard_input
    jr $ra

# keyboard_input function:
# If a pressed key is detected, this function will be called to further check which key is clicked and then allocate to difference key branches
# setting variables:
# $t7: hold the value of the second word from keyboard_address($t0), which is the ASCII value of the key 
keyboard_input:
    lw $t7, 4($t1)
    beq $t7, 0x61, responed_to_a
    beq $t7, 0x64, responed_to_d
    beq $t7, 0x77, responed_to_w
    beq $t7, 0x73, responed_to_s
    beq $t7, 0x71, responed_to_q
    beq $t7, 0x70, responed_to_p
    jr $ra
    
responed_to_a:
    addi $sp, $sp, -4   #store ra
    sw $ra, 0($sp)
    
    jal move_left
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

responed_to_d:
    addi $sp, $sp, -4   #store ra
    sw $ra, 0($sp)
    
    jal move_right
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
responed_to_w:
    addi $sp, $sp, -4   #store ra
    sw $ra, 0($sp)
    
    jal swap_color
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

responed_to_s:
    addi $sp, $sp, -4   #store ra
    sw $ra, 0($sp)
    
    jal move_down
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra

responed_to_q:
    # Exit the program when 'q' is pressed
    li  $v0, 10           # syscall code 10 = exit
    syscall               # terminate the program
    
responed_to_p:
    addi $sp, $sp, -4     # store $ra
    sw   $ra, 0($sp)

    jal  pause_game       # enter pause mode

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
        

# pause_game function
# Called when the user presses 'p' during normal gameplay.
#
# Behaviour:
#   - Record the time when pause starts.
#   - Print a "paused" message on the console.
#   - Wait until the user presses 'p' again.
#   - Compute how long the game was paused (dt).
#   - Add dt to last_drop_time and last_speedup_time
#     so that gravity and speedup do NOT jump after unpause.
pause_game:
    # Save registers we will use
    push4($ra, $t2, $t3, $t4)
    push1($t9)

    # 1. Record pause start time
    li   $v0, 30          # syscall 30: current time (ms)
    syscall
    addi $t2, $a0, 0         # t2 = pause_start_time

    # 2. Print paused message to console
    la   $a0, pause_msg
    li   $v0, 4           # print_string
    syscall

    # 3. Flush the key that triggered the pause ('p' that we already handled)
    #    Wait until no key is currently pressed (status == 0).
    pause_flush:
        lw   $t3, 0($t1)      # keyboard status
        bne  $t3, $zero, pause_flush
    
    # 4. Wait for a NEW 'p' press to resume
    pause_wait:
        lw   $t3, 0($t1)      # keyboard status
        beq  $t3, $zero, pause_wait   # no key pressed yet

    lw   $t4, 4($t1)      # ASCII of pressed key
    li   $t9, 0x70        # 'p'
    bne  $t4, $t9, pause_wait     # ignore non-'p' keys

    # 5. Got 'p' again -> resume. Record pause end time.
    li   $v0, 30
    syscall
    addi $t3, $a0, 0         # t3 = pause_end_time

    # dt = pause_end_time - pause_start_time
    subu $t4, $t3, $t2    # t4 = dt

    # 6. Adjust last_drop_time so gravity ignores the paused duration
    la   $t2, last_drop_time
    lw   $t3, 0($t2)
    addu $t3, $t3, $t4    # last_drop_time += dt
    sw   $t3, 0($t2)

    # 7. Adjust last_speedup_time similarly
    la   $t2, last_speedup_time
    lw   $t3, 0($t2)
    addu $t3, $t3, $t4    # last_speedup_time += dt
    sw   $t3, 0($t2)

    # 8. Restore registers and return
    pop1($t9)
    pop4($t4, $t3, $t2, $ra)
    jr   $ra


#######Test Cases########

#    addi $sp, $sp, -4 #store $ra
#        sw $ra, 0($sp) 
#        jal draw_initial_three_gem
#        lw $ra, 0($sp)    #rewind $ra
#       addi $sp, $sp, 4
#        jr $ra            #jump back

######NOTES######
# 1. If to extend size (especially witdth) of the bitmap, go change width constant and it will be fine, width was used in draw_line, everthing based on draw_ling
# 2. Intial position of new coming initial three_gem is fixed at (x=14, y=2), also in draw_initial_three_gem this is assigned to $t5,$t6, if want to change, which
#    which may happen later to adjust the three_gem higher at initial position, note that we need to draw_intial_three_gem function. Can by immediately draw 
#    boundary to make sure boundary always overwrites color s
# 3. If want to set gravity as droping 2 words / unit time, which is saying in Y direction the column may move with half-gem unit speed, and if doing so please 
#    update boundary check in move_down function, so that it not only detects 1 row down but also 3 or 4 rows down, to avoid (s)-controlled moving down move too far.