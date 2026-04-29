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
    output reg check,
    output reg [5:0] attacker_pos, // attacker position -- used for checkmate detection
    output reg [5:0] king_pos // king position -- used for checkmate detection
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

wire [2:0] king_row, king_col;
assign king_row = king_pos[5:3];
assign king_col = king_pos[2:0];

reg [6:0] i; // 7-bit incrementer for king pos search

always @(*) begin
    king_pos = 0;
    for (i = 0; i <= 63; i = i + 1) begin
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
assign enemy_bishop = current_turn ? 4'b0011 : 4'b1011; // the error in the demo lol - I had the rook and bishop encodings flipped
assign enemy_rook = current_turn ? 4'b0100 : 4'b1100;
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

// Knight Check
always @(*)
begin
    knight_check = 0;

    // checking all 8 possible squares from the king where an enemy knight could be attacking
    if (king_row >= 2 && king_col >= 1) begin // these comparisons provide boundary checking as to not look at a wrapped around square
        if (board[(king_row-2)*8 + (king_col-1)] == enemy_knight) begin
        knight_check = 1; // 2 up, 1 left
        attacker_pos = (king_row-2)*8 + (king_col-1);
        end
    end
    if (king_row >= 2 && king_col <= 6) begin
        if (board[(king_row-2)*8 + (king_col+1)] == enemy_knight) begin
        knight_check = 1; // 2 up, 1 right 
        attacker_pos = (king_row-2)*8 + (king_col+1);
        end
    end
    if (king_row >= 1 && king_col >= 2) begin
        if (board[(king_row-1)*8 + (king_col-2)] == enemy_knight) begin
            knight_check = 1; // 1 up, 2 left
            attacker_pos = (king_row-1)*8 + (king_col-2);
        end
    end
    if (king_row >= 1 && king_col <= 5) begin
        if (board[(king_row-1)*8 + (king_col+2)] == enemy_knight) begin
            knight_check = 1; // 1 up, 2 right
            attacker_pos = (king_row-1)*8 + (king_col+2);
        end
    end
    if (king_row <= 6 && king_col >= 2) begin
        if (board[(king_row+1)*8 + (king_col-2)] == enemy_knight) begin
            knight_check = 1; // 1 down, 2 left
            attacker_pos = (king_row+1)*8 + (king_col-2);
        end
    end
    if (king_row <= 6 && king_col <= 5) begin
        if (board[(king_row+1)*8 + (king_col+2)] == enemy_knight) begin
            knight_check = 1; // 1 down, 2 right
            attacker_pos = (king_row+1)*8 + (king_col+2);
        end
    end
    if (king_row <= 5 && king_col >= 1) begin
        if (board[(king_row+2)*8 + (king_col-1)] == enemy_knight) begin
            knight_check = 1; // 2 down, 1 left
            attacker_pos = (king_row+2)*8 + (king_col-1);
        end
    end
    if (king_row <= 5 && king_col <= 6) begin
        if (board[(king_row+2)*8 + (king_col+1)] == enemy_knight) begin
            knight_check = 1; // 2 down, 1 right
            attacker_pos = (king_row+2)*8 + (king_col+1);
        end
    end
end

// Ray Check
reg [3:0] j; // 4-bit incrementer for all ray checks
always @(*)
begin
    ray_check = 0;

    // straight rays -- rook, queen, king
    // up
    blocked = 0;
    for (j = 1; j < 8; j = j + 1) begin
        if (!blocked && king_row >= j) begin // boundary check- stops if increments king_row times up
            r = king_row - j; // increment row up
            c = king_col;
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 up, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j up, check if enemy rook or queen
                if (target == enemy_rook || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

    // down
    blocked = 0;
    for (j = 1; j < 8; j  = j + 1) begin
        if (!blocked && king_row + j <= 7) begin // boundary check- stop after increments from king_row to 7
            r = king_row + j; // increment row down
            c = king_col;
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 down, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j down, check if enemy rook or queen
                if (target == enemy_rook || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

    // left
    blocked = 0;
    for (j = 1; j < 8; j = j + 1) begin
        if (!blocked && king_col >= j) begin // boundary check- stops if increments king_col times left
            r = king_row;
            c = king_col - j; // increment column left
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 left, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j left, check if enemy rook or queen
                if (target == enemy_rook || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

    // right
    blocked = 0;
    for (j = 1; j < 8; j = j + 1) begin
        if (!blocked && king_col + j <= 7) begin // boundary check- stops after increments from king_col to 7
            r = king_row;
            c = king_col + j; // increment column right
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 right, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j right, check if enemy rook or queen
                if (target == enemy_rook || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

    // diagonal rays -- bishop, queen, pawn, king
    // diagonal up-left
    blocked = 0;
    for (j = 1; j < 8; j = j + 1) begin
        if (!blocked && king_row >= j && king_col >= j) begin // boundary check - stops if increments king_row and king_col times up-left
            r = king_row - j; // increment row up
            c = king_col - j; // increment column left
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 up-left, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for 1 up-left, if white, check if enemy pawn
                if (j == 1 && !current_turn && target == enemy_pawn) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j up-left, check if bishop or queen
                if (target == enemy_bishop || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

    // diagonal up-right
    blocked = 0;
    for (j = 1; j < 8; j = j + 1) begin
        if (!blocked && king_row >= j && king_col + j <= 7) begin // boundary check - stops if increments king_row up and after increments from king_col to 7
            r = king_row - j; // increment row up
            c = king_col + j; // increment column right
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 up-right, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for 1 up-right, if white, check if enemy pawn
                if (j == 1 && !current_turn && target == enemy_pawn) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j up-right, check if bishop or queen
                if (target == enemy_bishop || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

    // diagonal down-left
    blocked = 0;
    for (j = 1; j < 8; j = j + 1) begin
        if (!blocked && king_row + j <= 7 && king_col >= j) begin // boundary check - stops after increments from king_row to 7 and if king_col times left
            r = king_row + j; // increment row down
            c = king_col - j; // increment column left
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 down-left, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for 1 down-left, if black, check if enemy pawn
                if (j == 1 && current_turn && target == enemy_pawn) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j down-left, check if bishop or queen
                if (target == enemy_bishop || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

    // diagonal down-right
    blocked = 0;
    for (j = 1; j < 8; j = j + 1) begin
        if (!blocked && king_row + j <= 7 && king_col + j <= 7) begin // boundary check - stops after increments king_row and king_col to 7
            r = king_row + j; // increment row down
            c = king_col + j; // increment row right
            target = board[r*8 + c];
            if (target != 4'b0000) begin
                blocked = 1; // if not empty set blocked

                // for 1 down-right, check if enemy king
                if (j == 1 && target == enemy_king) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for 1 down-right, if black, check if enemy pawn
                if (j == 1 && current_turn && target == enemy_pawn) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end

                // for j down-right, check if bishop or queen
                if (target == enemy_bishop || target == enemy_queen) begin
                    ray_check = 1;
                    attacker_pos = r*8 + c;
                end
            end
        end
    end

end

always @(*) begin
    check = knight_check | ray_check;
end

endmodule