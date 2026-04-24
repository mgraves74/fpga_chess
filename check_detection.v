/* 

Check Detection

Marshall Graves & Sheel Shah --- FPGA Chess
Created: 4/24/26

Original File

*/

/*

Key information:

Check detection happens twice. First in IDLE, second in the CHECK_2 State

Check 1 (IDLE State)
- This checks whether the current player is currently in check. It produces the output check_1 which is used solely to control SSD 
display. This does not have any effect on move enforcement

Check 2 (CHECK_2 State)
- This checks whether the current player is still in check after attempting a move. It produces the output check_2 which is used to
validate whether the move can be made (progressing to MOVING state). CHECK_2 happens for all moves regardless of whether the player
is originally in check or not. This is because the player can't move into check regardless.

*/

`timescale 1ns / 1ps

module check_detection (
    input [3:0] board [0:63],
    input [5:0] src,
    input [5:0] dst,
    output reg check
);


endmodule