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
    input [255:0] board_flat,
    input current_turn,
    output reg check
);

// unflattening board
wire [3:0] board [0:63];
genvar g;
generate
    for (g = 0; g < 64; g = g + 1) begin
        assign board[g] = board_flat[g*4 +: 4];
    end
endgenerate

//// King position ////

reg [5:0] king_pos;
wire [2:0] king_row, king_col;
assign king_row = king_pos[5:3];
assign king_col = king_pos[2:0];

integer i;

always @(*) begin
    king_pos = 0;
    for (i = 0; i < 64; i = i + 1) begin
        // Find position of the white king
        if (!current_turn) begin
            if (board[i] == 4'b0110) king_pos = i;

        // Find position of the black king
        end else begin
            if (board[i] == 4'b1110) king_pos = i;
        end
    end
end

// Defining enemy pieces -- if white, enemy is black and vice versa
wire [3:0] enemy_bishop, enemy_rook, enemy_queen, enemy_pawn, enemy_king, enemy_knight;
assign enemy_bishop = current_turn ? 4'b0100 : 4'b1100;
assign enemy_rook = current_turn ? 4'b0011 : 4'b1011;
assign enemy_queen = current_turn ? 4'b0101 : 4'b1101;
assign enemy_pawn = current_turn ? 4'b0001 : 4'b1001;
assign enemy_king = current_turn ? 4'b0110 : 4'b1110;
assign enemy_knight = current_turn ? 4'b0010 : 4'b1010;

// defining the two types of check - simple check from knight (no path checking) and check which depends on the incrementation algorithm
reg knight_check, ray_check;

// initializations
reg [2:0] r, c; // current ray step's row and colum
reg [3:0] target; // the piece at the current ray step
reg blocked; // flag for stopping at the first piece

// Knight Check -- TBD
always @(*)
begin



end

// Ray Check -- TBD
always @(*)
begin



end

always @(*) begin
    check = knight_check | ray_check;
end

endmodule