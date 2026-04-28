/* 

Castling

Marshall Graves & Sheel Shah --- FPGA Chess
Created: 4/24/26

Original File

*/

/*

Key Informaiton:
The module produces enables for kingside and/or queenside castling

In order to castle, the following must be true:
1. You haven't moved your king
2. You haven't moved the rook on the side you are trying to castle
3. In between squares is empty (all squares in between king and rook)
4. King is not currently in check
5. In between square (right of king on kingside, left of king on queenside) are not in check
6. Destination square is not in check

The following capabilities from the other modules are used to enable this
1. king_moved flag for each player
2. rook_moved flag for all 4 rooks
3. Checking if empty: board[sq] == 4'b0000
4. Check_1 during IDLE
5. Check_1 applied with in between square in place of king_pos
6. Check_1 applied with destination square in place of king_pos

*/

`timescale 1ns / 1ps

module castling (
    input [255:0] board_flat,
    input current_turn,
    input white_king_moved,
    input black_king_moved,
    input white_rook_ks_moved,
    input white_rook_qs_moved,
    input black_rook_ks_moved,
    input black_rook_qs_moved,
    input check,
    output castle_ks_en,
    output castle_qs_en
);

    // unflatten board
    wire [3:0] board [0:63];
    genvar g;
    generate
        for (g = 0; g < 64; g = g + 1) begin
            assign board[g] = board_flat[g*4 +: 4];
        end
    endgenerate

    // initialization based on current turn
    wire king_moved = current_turn ? black_king_moved : white_king_moved;
    wire rook_ks_moved = current_turn ? black_rook_ks_moved : white_rook_ks_moved;
    wire rook_qs_moved = current_turn ? black_rook_qs_moved : white_rook_qs_moved;

    // initialization of squares to check based on current turn
    wire [5:0] king_sq = current_turn ? 6'd4 : 6'd60;
    wire [5:0] ks_in_between = current_turn ? 6'd5 : 6'd61; // in between square
    wire [5:0] ks_dest = current_turn ? 6'd6 : 6'd62; // king destination square
    wire [5:0] qs_in_between = current_turn ? 6'd3 : 6'd59; // in between square
    wire [5:0] qs_dest = current_turn ? 6'd2 : 6'd58; // king destination square
    wire [5:0] qs_right_of_rook = current_turn ? 6'd1 : 6'd57; // only check for not empty; if in check, doesn't matter

    wire [3:0] king = current_turn ? 4'b1110 : 4'b0110; // the king based on current turn

    // if castling path empty
    wire ks_path_empty = (board[ks_in_between] == 4'b0000) && (board[ks_dest] == 4'b0000);
    wire qs_path_empty = (board[qs_in_between] == 4'b0000) && (board[qs_dest] == 4'b0000) && (board[qs_right_of_rook] == 4'b0000);

    // init board with if king simulated on in between square and destination for ks and qs
    reg [255:0] board_king_at_ks_in_between;
    reg [255:0] board_king_at_ks_dest;
    reg [255:0] board_king_at_qs_in_between;
    reg [255:0] board_king_at_qs_dest;

    // loop to produce simulated/shadow boards - if i is king square, clear it, if in between/dest, set to king, otherwise normal
    integer i;
    always @(*) begin
        for (i = 0; i < 64; i = i + 1) begin
            // ks in between
            board_king_at_ks_in_between[i*4 +: 4] = (i == king_sq) ? 4'b0000 : ((i == ks_in_between) ? king : board_flat[i*4 +: 4]);

            // ks destination
            board_king_at_ks_dest[i*4 +: 4] = (i == king_sq) ? 4'b0000 : ((i == ks_dest) ? king : board_flat[i*4 +: 4]);

            // qs in between
            board_king_at_qs_in_between[i*4 +: 4] = (i == king_sq) ? 4'b0000 : ((i == qs_in_between) ? king : board_flat[i*4 +: 4]);

            // qs destination
            board_king_at_qs_dest[i*4 +: 4] = (i == king_sq) ? 4'b0000 : ((i == qs_dest) ? king : board_flat[i*4 +: 4]);
        end
    end

    wire ks_in_between_check, ks_dest_check, qs_in_between_check, qs_dest_check; // init check flags
    wire [5:0] ap0, kp0, ap1, kp1, ap2, kp2, ap3, kp3; // dummy variables that do nothing

    // Check detection instantiations
    check_detection cd_ks_in_between (
        .board_flat(board_king_at_ks_in_between),
        .current_turn(current_turn),
        .check(ks_in_between_check),
        .attacker_pos(ap0),
        .king_pos(kp0)
    );

    check_detection cd_ks_dest (
        .board_flat(board_king_at_ks_dest),
        .current_turn(current_turn),
        .check(ks_dest_check),
        .attacker_pos(ap1),
        .king_pos(kp1)
    );

    check_detection cd_qs_in_between (
        .board_flat(board_king_at_qs_in_between),
        .current_turn(current_turn),
        .check(qs_in_between_check),
        .attacker_pos(ap2),
        .king_pos(kp2)
    );

    check_detection cd_qs_dest (
        .board_flat(board_king_at_qs_dest),
        .current_turn(current_turn),
        .check(qs_dest_check),
        .attacker_pos(ap3),
        .king_pos(kp3)
    );

    // final castle enable outputs
    assign castle_ks_en = !check && !king_moved && !rook_ks_moved && ks_path_empty && !ks_in_between_check && !ks_dest_check;
    assign castle_qs_en = !check && !king_moved && !rook_qs_moved && qs_path_empty && !qs_in_between_check && !qs_dest_check;

endmodule