/* 

Checkmate Detection

Marshall Graves & Sheel Shah --- FPGA Chess
Created: 4/26/26

Original File

*/

/*

Key Information:

Checkmate detection algorithm consists of a 3-state state machine reffered to as cm_phase with 3 phases:
0. King move - checks up to 8 (depending on valid) square candidates for possible escape
1. Capture - for all friendly pieces, checks if known attacker can be taken - this still requires a shadow move on the fsm side in the
case of discovery or double check
2. Blocking - for all friendly pieces, checks if a known attacker can be blocked - this still requires a shadow move on the fsm side
in the case of discovery or double check

*/

`timescale 1ns / 1ps

module checkmate_detection (
    input clk, reset,
    input [255:0] board_flat,
    input current_turn,
    input [5:0] attacker_pos_latched, // latched attacker pos
    input [5:0] king_pos_latched,
    input cm_advance,
    input cm_init,
    output reg [5:0] cm_src, // source square for checkmate detection shadow move
    output reg [5:0] cm_dst, // destination square for checkmate detection shadow move
    output reg candidates_exhausted,
    output reg cm_skip // flag to skip an invalid candidate
    );

    // unwrap board
    wire [3:0] board [0:63];
    genvar g;
    generate
        for (g = 0; g < 64; g = g + 1) begin
            assign board[g] = board_flat[g*4 +: 4];
        end
    endgenerate

    //-----------------//
    // INITIALIZATIONS //
    //-----------------//

    // General

    reg [1:0] cm_phase; // checkmate dection state machine phase - 0 - king escape, 1 - capture attacker, 2 - block attacker
    reg [2:0] cm_king_move_idx; // king escape move counter - increments 8 (0-7) times total for all king moves
    reg [5:0] cm_piece_idx; // friendly piece location counter - increments 64 times total for each square to check for friendly, valid, non-king candidates
    reg [2:0] cm_ray_idx; // king to attacker ray counter - increments once every time cm_piece_idx increments 64 times (if in phase 2)

    // king and attacker position
    wire [2:0] king_row = king_pos_latched[5:3];
    wire [2:0] king_col = king_pos_latched[2:0];
    wire [2:0] att_row  = attacker_pos_latched[5:3];
    wire [2:0] att_col  = attacker_pos_latched[2:0];

    // friendly king- if 0, white, if 1, black
    wire [3:0] friendly_king = current_turn ? 4'b1110 : 4'b0110;

    // if a knight is the attacker, skip phases 1 and 2
    wire is_knight_attacker = (board[attacker_pos_latched] == (current_turn ? 4'b0010 : 4'b1010));

    // flags stating ray direction
    wire ray_row_pos = (att_row > king_row);
    wire ray_row_neg = (att_row < king_row);
    wire ray_col_pos = (att_col > king_col);
    wire ray_col_neg = (att_col < king_col);

    // Phase 0

    // initializing 8 king move candidate rows and columns
    wire [2:0] king_move_rows [0:7];
    wire [2:0] king_move_cols [0:7];
    wire king_move_valid [0:7]; // 8 valid bit for king move based on boundary checking

    // direction 0: up-left
    assign king_move_rows[0] = king_row - 1;
    assign king_move_cols[0] = king_col - 1;
    assign king_move_valid[0] = (king_row >= 1) && (king_col >= 1);

    // direction 1: up
    assign king_move_rows[1] = king_row - 1;
    assign king_move_cols[1] = king_col;
    assign king_move_valid[1] = (king_row >= 1);

    // direction 2: up-right
    assign king_move_rows[2] = king_row - 1;
    assign king_move_cols[2] = king_col + 1;
    assign king_move_valid[2] = (king_row >= 1) && (king_col <= 6);

    // direction 3: left
    assign king_move_rows[3] = king_row;
    assign king_move_cols[3] = king_col - 1;
    assign king_move_valid[3] = (king_col >= 1);

    // direction 4: right
    assign king_move_rows[4] = king_row;
    assign king_move_cols[4] = king_col + 1;
    assign king_move_valid[4] = (king_col <= 6);

    // direction 5: down-left
    assign king_move_rows[5] = king_row + 1;
    assign king_move_cols[5] = king_col - 1;
    assign king_move_valid[5] = (king_row <= 6) && (king_col >= 1);

    // direction 6: down
    assign king_move_rows[6] = king_row + 1;
    assign king_move_cols[6] = king_col;
    assign king_move_valid[6] = (king_row <= 6);

    // direction 7: down-right
    assign king_move_rows[7] = king_row + 1;
    assign king_move_cols[7] = king_col + 1;
    assign king_move_valid[7] = (king_row <= 6) && (king_col <= 6);

    // Checking current king move candidate based on king move index 
    wire [5:0] king_cand_sq = king_move_rows[cm_king_move_idx] * 8 + king_move_cols[cm_king_move_idx]; // current square
    wire king_cand_in_bounds = king_move_valid[cm_king_move_idx]; // current bounds validation
    wire king_cand_friendly = (board[king_cand_sq][3] == current_turn) && (board[king_cand_sq][2:0] != 3'b000); // flag for if square is friendly (not valid)

    // Phase 1

    // Defining friendly candidates for capturing or blocking attacker -- need to make sure its not the king itself
    wire [3:0] piece_at_idx = board[cm_piece_idx];
    wire is_friendly_non_king = (piece_at_idx[3] == current_turn) && (piece_at_idx[2:0] != 3'b000) && (piece_at_idx != friendly_king);

    // Phase 2

    // ray incrementing for phase 2 attacker blocking
    reg [2:0] ray_row, ray_col;
    always @(*) begin
        
        // row component -- incrementing depending on direction of ray
        if (ray_row_pos)
            ray_row = king_row + (cm_ray_idx + 1); // add to king_row if attacker below king
        else if (ray_row_neg)
            ray_row = king_row - (cm_ray_idx + 1); // subtract to king_row if attacker above king
        else
            ray_row = king_row; // if ray is a row, stays constant

        // col component
        if (ray_col_pos)
            ray_col = king_col + (cm_ray_idx + 1); // add to king_col if attacker right of king
        else if (ray_col_neg)
            ray_col = king_col - (cm_ray_idx + 1); // add to king_col if attacker left of king
        else
            ray_col = king_col; // if ray is a column, stays constant
    end

    wire [5:0] ray_sq = ray_row * 8 + ray_col; // defining ray square
    wire ray_reached_attacker = (ray_sq == attacker_pos_latched); // flag for if attacker is reached

    // Insantiating Move Validator for checking if candidate move to capture or blocking square is valid
    wire mv_valid;
    reg [5:0] mv_dst_sq;
    wire dummy; // useless

    // defining the destination square for either capture or blocking
    always @(*) begin
        mv_dst_sq = (cm_phase == 2'd1) ? attacker_pos_latched : ray_sq; // if phase 1 - capture, otherwise blocking
    end

    move_validator mv_inst (
        .board_flat(board_flat),
        .src(cm_piece_idx),
        .dst(mv_dst_sq),
        .valid(mv_valid),
        .double_move(dummy)
    );

    // clocked always block to sequentially look at each candidate
    always @(posedge clk, posedge reset) begin
        
        // reset conditions
        if (reset) begin // asynchronous
            cm_phase <= 0;
            cm_king_move_idx <= 0;
            cm_piece_idx <= 0;
            cm_ray_idx <= 0;
            candidates_exhausted <= 0;
            cm_skip <= 0;
            cm_src <= 0;
            cm_dst <= 0;
        end else if (cm_init) begin // synchronous
            cm_phase <= 0;
            cm_king_move_idx <= 0;
            cm_piece_idx <= 0;
            cm_ray_idx <= 0;
            candidates_exhausted <= 0;
            cm_skip <= 0;
            cm_src <= 0;
            cm_dst <= 0;
        end else begin
            candidates_exhausted <= 0; // always 0 when coming into checkmate_detection module to then in the case of checkmate set as 1 thus ending the game
            cm_skip <= 0; // always 0 when coming into checkmate_detection module to be then temporarily set as otherwise

            case (cm_phase)
                2'd0: begin // phase 0
                    if (!king_cand_in_bounds || king_cand_friendly) begin
                        cm_skip <= 1; // skip if candidate not in bounds or square contains friendly piece
                        if (cm_king_move_idx == 7) begin // if looking at last king move candidate
                            cm_phase <= 2'd1; // go to next phase
                            cm_king_move_idx <= 0;
                            cm_piece_idx <= 0;
                        end else
                            cm_king_move_idx <= cm_king_move_idx + 1; // increment king move incrementer
                    end else begin
                        cm_src <= king_pos_latched; // set candidate move for fsm shadow move
                        cm_dst <= king_cand_sq; // set destination move for fsm shadow move
                        cm_skip <= 0; // don't skip
                        if (cm_advance) begin // if fsm says to advance
                            if (cm_king_move_idx == 7) begin // if looking at last king move candidate
                                cm_phase <= 2'd1; // go to next phase
                                cm_king_move_idx <= 0;
                                cm_piece_idx <= 0;
                            end else
                                cm_king_move_idx <= cm_king_move_idx + 1; // increment king move incrementer
                        end
                    end
                end

                2'd1: begin // phase 1
                    if (!is_friendly_non_king || !mv_valid) begin
                        cm_skip <= 1; // skip candidate if move to capture is not friendly, not valid, or is the king
                        if (cm_piece_idx == 63) begin // if last candidate
                            if (is_knight_attacker)
                                candidates_exhausted <= 1; // knights can't be blocked so game over here
                            else begin
                                cm_phase <= 2'd2; // go to next phase
                                cm_piece_idx <= 0;
                                cm_ray_idx <= 0;
                            end
                        end else
                            cm_piece_idx <= cm_piece_idx + 1; // increment friendly piece counter
                    end else begin
                        cm_src <= cm_piece_idx; // set candidate src for fsm
                        cm_dst <= attacker_pos_latched; // set candidate dst for fsm
                        cm_skip <= 0;
                        if (cm_advance) begin // if advance
                            if (cm_piece_idx == 63) begin // if last candidate
                                if (is_knight_attacker)
                                    candidates_exhausted <= 1; 
                                else begin
                                    cm_phase <= 2'd2;
                                    cm_piece_idx <= 0;
                                    cm_ray_idx <= 0;
                                end
                            end else
                                cm_piece_idx <= cm_piece_idx + 1;
                        end
                    end
                end

                2'd2: begin // phase 2
                    if (ray_reached_attacker) begin
                        candidates_exhausted <= 1; // if all inbetween squares checked
                    end else if (!is_friendly_non_king || !mv_valid) begin
                        cm_skip <= 1; // skip candidate if move to inbetween square is not friendly, not valid, or is the king
                        if (cm_piece_idx == 63) begin
                            cm_ray_idx <= cm_ray_idx + 1; // increment to next inbetween square after checking all 64 squares for friendly, valid, non-king candidates
                            cm_piece_idx <= 0; // reset piece candidate counter
                        end else
                            cm_piece_idx <= cm_piece_idx + 1; // increment piece candidate counter
                    end else begin
                        cm_src <= cm_piece_idx; // set src for fsm to perform shadow move
                        cm_dst <= ray_sq; // set dst for fsm to perform shadow move
                        cm_skip <= 0;
                        if (cm_advance) begin // if advance
                            if (cm_piece_idx == 63) begin
                                cm_ray_idx <= cm_ray_idx + 1;
                                cm_piece_idx <= 0;
                            end else
                                cm_piece_idx <= cm_piece_idx + 1;
                        end
                    end
                end

            endcase
        end
    end

endmodule