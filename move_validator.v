/* 

Move Validator

Marshall Graves & Sheel Shah --- FPGA Chess
Created: 4/20/26

Original File

*/

/*

Key information:

Fully combinational module containing move validation logic

- Very important to remember that going up on the board is actually a decrease in rows
- Also note that state machine handles correct piece selected (and not empty square) validation

How it works:

Final validation = geometric validation && path validation && capture validation
- Geometric validation - define the set of allowed moves if the board were empty
- Path validation - check that pieces between but not including the destination square are empty
- Capture validation - check that the destination square is either empty or an opposing piece

*/

`timescale 1ns / 1ps

module move_validator (
    input [255:0] board_flat,
    input [5:0] src,
    input [5:0] dst,
    output reg valid
);

// unflattening board
wire [3:0] board [0:63];
genvar g;
generate
    for (g = 0; g < 64; g = g + 1)
        assign board[g] = board_flat[g*4 +: 4];
endgenerate

// getting source and destination columns and rows separate from combined 6-bit port
wire [2:0] src_row = src[5:3];   wire [2:0] src_col = src[2:0];
wire [2:0] dst_row = dst[5:3];   wire [2:0] dst_col = dst[2:0];

// defining signed row and differences for move validation
wire signed [3:0] row_diff = $signed({1'b0, dst_row}) - $signed({1'b0, src_row});
wire signed [3:0] col_diff = $signed({1'b0, dst_col}) - $signed({1'b0, src_col});

// absolute value of row and column differences
wire [2:0] abs_row = row_diff[3] ? -row_diff : row_diff;
wire [2:0] abs_col = col_diff[3] ? -col_diff : col_diff;

// getting source and destination pieces from board mem
wire [3:0] src_piece = board[src];
wire [3:0] dst_piece = board[dst];

// getting source and destination color from the MSB of the encoding and type from the 3 LSB of the encoding
wire src_color = src_piece[3];
wire [2:0] src_type  = src_piece[2:0];
wire dst_color = dst_piece[3];
wire [2:0] dst_type  = dst_piece[2:0];

// flags for whether destination is empty or of the same color
wire dst_empty = (dst_type == 3'b000); // used in pawn validation
wire dst_friendly = !dst_empty && (dst_color == src_color); // used in final validation & pawn validation

//// Piece Geometry Validation ////

// Rook -- either up-down (same column) or left-right (same row)
wire rook_geo_valid = ((dst_row == src_row) ^ (dst_col == src_col)); // the xor of destination sq same row and destination sq same col
// row_diff == 0 || col_diff == 0 also works --- but it doesn't matter at all - I think xor is cooler

// Bishop -- diagonal
wire bishop_geo_valid = (abs_row == abs_col); // diagonal any time the row distance is equal to the column distance

// Queen -- up-down, left-right, diagonal
wire queen_geo_valid = (rook_geo_valid || bishop_geo_valid); // can move in either bishop or rook direction

// Knight -- L-shape- up-down or left-right by 2 and 1 move in the direction perpendicular
wire knight_valid = ((abs_row == 1 && abs_col == 2) || (abs_row == 2 && abs_col == 1)); // the OR of these 2 conditions (each with 4 possibilities) for a total of 8

// King -- 1 in any direction
wire king_valid = (abs_row <= 1 && abs_col <= 1); // when row difference or col difference is just 1

//// Piece Path Validation ////
// Not needed for King (can only move one square) or Knight (jumps)

// Rook init
integer i_rook;
reg not_empty_rook;

// Bishop init
integer i_bishop;
reg not_empty_bishop;

always @(*)
begin

// Rook
not_empty_rook = 0;
for (i_rook = 1; i_rook < abs_row + abs_col; i_rook = i_rook + 1) // increment - (abs_row + abs_col) since one of those is 0
begin
    if (dst_row == src_row) begin // if rows equal so traveling along row
        if (col_diff > 0) // if positive change
        begin
            if (board[src + i_rook] != 4'b0000) // check squares right
                not_empty_rook = 1;
        end else // if negative change
        begin
            if (board[src - i_rook] != 4'b0000) // check squares left
                not_empty_rook = 1;
        end
    end else // if columns equal so traveling along column 
    begin
        if (row_diff > 0) // if positive change
        begin
            if (board[src + 8 * i_rook] != 4'b0000) // check squares down
                not_empty_rook = 1;
        end else 
        begin
            if (board[src - 8 * i_rook] != 4'b0000) // check squares up
                not_empty_rook = 1;
        end 
    end
end

// Bishop
not_empty_bishop = 0;
for (i_bishop = 1; i_bishop < abs_row; i_bishop = i_bishop + 1) // increment- doesn't matter whether you use abs_row or abs_col here
begin
    if (row_diff > 0 && col_diff > 0) // if down and right
    begin
        if (board[src + 9 * i_bishop] != 4'b0000)
            not_empty_bishop = 1;
    end else 
    if (row_diff > 0 && col_diff < 0) // if down and left
    begin
        if (board[src + 7 * i_bishop] != 4'b0000)
            not_empty_bishop = 1;
    end else 
    if (row_diff < 0 && col_diff > 0) // if up and right
    begin
        if (board[src - 7 * i_bishop] != 4'b0000)
            not_empty_bishop = 1;
    end else // if up and left
    begin
        if (board[src - 9 * i_bishop] != 4'b0000)
            not_empty_bishop = 1;
    end
end

end

//// Final Validations ////

always @(*)
begin
    case (board[src])

        // Rook
        4'b0100, 4'b1100: valid = rook_geo_valid && !not_empty_rook && !dst_friendly;
        
        // Bishop
        4'b0011, 4'b1011: valid = bishop_geo_valid && !not_empty_bishop && !dst_friendly;

        // Knight
        4'b0010, 4'b1010: knight_valid && !dst_friendly;

        // Queen
        4'b0101, 4'b1101: valid = ((rook_geo_valid && !not_empty_rook) || (bishop_geo_valid && !not_empty_bishop)) && !dst_friendly;

        // King
        4'b0110, 4'b1110: valid = king_valid && !dst_friendly;

        // White Pawn
        4'b0001: begin
            if (src_row == 3'b110)
                valid = ((dst == (src - 16)) && (board[src - 16] == 4'b0000) && (board[src - 8] == 4'b0000)) // allowing pawn double move (if only on starting square)
                || ((dst == (src - 8)) && (board[src - 8] == 4'b0000)) // allowing pawn first move
                || ((dst == (src - 9)) && !dst_friendly && !dst_empty) // allowing pawn capture going up and to the left - only if opposite color and not empty
                || ((dst == (src - 7)) && !dst_friendly && !dst_empty); // allowing pawn capture going up and to the right - only if opposite color and not empty
            else
                valid = ((dst == (src - 8)) && (board[src - 8] == 4'b0000)) // repeated logic except for allowing the double move
                || ((dst == (src - 7)) && !dst_friendly && !dst_empty)
                || ((dst == (src - 9)) && !dst_friendly && !dst_empty);
            end

        // Black Pawn
        4'b1001: begin
            if (src_row == 3'b001)
                valid = ((dst == (src + 16)) && (board[src + 16] == 4'b0000) && (board[src + 8] == 4'b0000)) // checking pawn double move (if only on starting square)
                || ((dst == (src + 8)) && (board[src + 8] == 4'b0000)) // allowing pawn first move
                || ((dst == (src + 9)) && !dst_friendly && !dst_empty) // allowing pawn capture going down and to the right
                || ((dst == (src + 7)) && !dst_friendly && !dst_empty); // allowing pawn capture going down and to the left
            else
                valid = ((dst == (src + 8)) && (board[src + 8] == 4'b0000)) // repeated logic except for allowing the double move
                || ((dst == (src + 9)) && !dst_friendly && !dst_empty)
                || ((dst == (src + 7)) && !dst_friendly && !dst_empty);
            end

        default: valid = 0; // including cases 4'b0000 (empty) and unused cases 4'b1000, 4'b1111, and 4'b0111

    endcase
end

endmodule