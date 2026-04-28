/* 

Game FSM

Marshall Graves & Sheel Shah --- FPGA Chess
Created: 4/14/26

Original File

*/

`timescale 1ns / 1ps

module game_fsm (
    input clk,
    input reset,
    input scen_c, // center button scen pulse
    input mcen_u, // up button mcen pulse
    input mcen_d, // down button mcen pulse
    input mcen_l, // left button mcen pulse
    input mcen_r, // right button mcen pulse
    input [3:0] rd_data_fsm, // read board memory
    input valid,
    input check_1, // only used for castling check detection
    input check_2,
    input [255:0] board_flat, // current board state
    input [5:0] attacker_pos, // position of the attacker for checkmate detection
    input [5:0] king_pos, // position of the king for checkmate detection
    output reg [5:0] wr_addr, // write board memory address (write to square on board)
    output reg [3:0] wr_data, // write board memory (piece encoding)
    output reg wr_en, // write enable
    output reg [2:0] cursor_row, // cursor current row (0-7)
    output reg [2:0] cursor_col, // cursor current column (0-7)
    output reg [2:0] sel_row, // selected row (0-7)
    output reg [2:0] sel_col, // selected column (0-7)
    output reg piece_selected, // piece selected flag
    output reg current_turn, // current turn flag - 0 for white's move, 1 for black's move
    output reg [2:0] state, // 2 bit state encoding for 3 states, exposed for showing state on LEDs
    output reg error_flag, // flag to indicate that an error has been produced from an invalidated move
    output reg [255:0] shadow_board_flat, // board latched at the begging of PIECE_SELECTED for check_2 detection
    output reg game_over, // game_over flag to enable ssd and vga game over displays
    output reg winner // winner for ssd and vga display
    );

    // states 
    localparam IDLE = 3'b000;
    localparam PIECE_SELECTED = 3'b001;
    localparam SHADOW_MOVING = 3'b010;
    localparam CHECK_2 = 3'b011;
    localparam CHECKMATE_DETECT = 3'b100;
    localparam MOVING = 3'b101;
    localparam CASTLE_MOVING = 3'b110;
    localparam GAME_OVER = 3'b111;
    
    reg move_phase; // move phase flag for MOVING state (see below)
    reg shadow_move_phase; // shadow move phase flag for SHADOW_MOVING state (see below)
    reg [3:0] moving_piece; // register to store encoding of the moving piece

    wire [5:0] sel_addr = sel_row * 8 + sel_col; // board memory address of the first/source selected piece
    wire [5:0] dst_addr = cursor_row * 8 + cursor_col; // board memory address of second/destination selected piece
    reg [5:0] dst_addr_latched; // lached dst_addr for shadow board

    // Ouputs from cm module
    wire [5:0] cm_src; // checkmate detection candidate source square
    wire [5:0] cm_dst; // checkmate detection candidate destination square
    wire candidates_exhausted; // flag set when all checkmate prevention candidates have been exhausted
    wire cm_skip; // flag to skip an invalid candidate
    
    // Inputs to cm module
    reg cm_advance; // flag for checkmate detection to increment to the next candidate
    reg [5:0] attacker_pos_latched; // latched attacker position 
    reg [5:0] king_pos_latched; // latched king position
    reg from_checkmate; // flag to control whether a shadow move is on a checkmate_detection or check_detection operation

    // Castling Initializations
    reg white_king_moved, black_king_moved; // king moved flags
    reg white_rook_ks_moved, white_rook_qs_moved; // white rook moved flags
    reg black_rook_ks_moved, black_rook_qs_moved; // black rook moved flags
    reg castle_side; // 0 = kingside, 1 = queenside // castling side flag
    reg [1:0] castle_move_phase; // 4-write sequence for CASTLE_MOVING similar to move_phase and shadow_move_phase

    // Checkmate Detection Module Instantiation
    checkmate_detection cm_inst (
        .clk(clk), .reset(reset),
        .board_flat(board_flat),
        .current_turn(current_turn),
        .attacker_pos_latched(attacker_pos_latched),
        .king_pos_latched(king_pos_latched),
        .cm_advance(cm_advance),
        .cm_src(cm_src),
        .cm_dst(cm_dst),
        .candidates_exhausted(candidates_exhausted),
        .cm_skip(cm_skip),
        .cm_init(cm_init)
    );

    wire castle_ks_en, castle_qs_en;

    castling castle_inst (
        .board_flat(board_flat),
        .current_turn(current_turn),
        .white_king_moved(white_king_moved),
        .black_king_moved(black_king_moved),
        .white_rook_ks_moved(white_rook_ks_moved),
        .white_rook_qs_moved(white_rook_qs_moved),
        .black_rook_ks_moved(black_rook_ks_moved),
        .black_rook_qs_moved(black_rook_qs_moved),
        .check(check_1),
        .castle_ks_en(castle_ks_en),
        .castle_qs_en(castle_qs_en)
    );

    always @(posedge clk, posedge reset) begin

        // reset conditions
        if (reset) begin
            state <= IDLE;
            cursor_row <= 3'd6; // init cursor to king's pawn
            cursor_col <= 3'd4;
            sel_row <= 3'd0; // init selected to 00 which is blacks rook, but it doesn't matter because no flag set anyway
            sel_col <= 3'd0;
            piece_selected <= 0;
            current_turn <= 0;
            move_phase <= 0;
            shadow_move_phase <= 0;
            moving_piece <= 4'b0000; // set moving piece to empty
            wr_en <= 0;
            wr_addr <= 0;
            wr_data <= 0;

            // Checkmate detection resets
            attacker_pos_latched <= 0;
            king_pos_latched <= 0;
            from_checkmate <= 0;
            cm_advance <= 0;
            game_over <= 0;
            cm_init = 0;
            white_king_moved <= 0;

            // Castling resets
            black_king_moved <= 0;
            white_rook_ks_moved <= 0;
            white_rook_qs_moved <= 0;
            black_rook_ks_moved <= 0;
            black_rook_qs_moved <= 0;
            castle_side <= 0;
            castle_move_phase <= 0;
        end

        else begin

            wr_en <= 0; // always disable write at start
            error_flag <= 0; // always clear error flag
            cm_advance <= 0; // always clear checkmate detection candidate advance flag
            cm_init <= 0; // always clear checkmate detection sychronous reset

            case (state)

                // IDLE state 
                IDLE: begin
                    // update cursor position due to buttons; boundary checks so no wrap arounds
                    if (mcen_u && cursor_row > 0) cursor_row <= cursor_row - 1; // up
                    if (mcen_d && cursor_row < 7) cursor_row <= cursor_row + 1; // down
                    if (mcen_l && cursor_col > 0) cursor_col <= cursor_col - 1; // left
                    if (mcen_r && cursor_col < 7) cursor_col <= cursor_col + 1; // right 

                    // IDLE --> Piece Selected: if select button and selected square not empty and correct color piece
                    if (scen_c && rd_data_fsm[2:0] != 3'b000 && rd_data_fsm[3] == current_turn) begin
                        sel_row <= cursor_row; // assign selected square
                        sel_col <= cursor_col;
                        moving_piece <= rd_data_fsm; // register the moving piece's encoding from read data
                        piece_selected <= 1; // set flag (the only reason this exists is to color square on the display; no function in the fsm)
                        state <= PIECE_SELECTED;
                    end
                    // Otherwise stay idle (selected empty square, wrong player's piece, or nothing)
                end

                // PIECE_SELECTED state
                PIECE_SELECTED: begin
                    if (mcen_u && cursor_row > 0) cursor_row <= cursor_row - 1; // up
                    if (mcen_d && cursor_row < 7) cursor_row <= cursor_row + 1; // down
                    if (mcen_l && cursor_col > 0) cursor_col <= cursor_col - 1; // left
                    if (mcen_r && cursor_col < 7) cursor_col <= cursor_col + 1; // right

                    if (scen_c) begin

                        // PIECE_SELECTED --> IDLE: if selected original square again
                        if (cursor_row == sel_row && cursor_col == sel_col) begin
                            piece_selected <= 0;
                            from_checkmate <= 0;
                            state <= IDLE;
                        end 
                        
                        // PIECE_SELECTED --> CASTLE_MOVING
                        // If castling attempt - a castling attempt (2 right of king for king-side, 2 left of king for queen-side) is not a valid move, instead it is an exception to the valid checks, which then causes castling
                        else if (moving_piece[2:0] == 3'b110 && cursor_row == sel_row && cursor_col == 6 && castle_ks_en) begin
                            castle_side <= 0;
                            piece_selected <= 0;
                            state <= CASTLE_MOVING;
                        end else if (moving_piece[2:0] == 3'b110 && cursor_row == sel_row && cursor_col == 2 && castle_qs_en) begin
                            castle_side <= 1;
                            piece_selected <= 0;
                            state <= CASTLE_MOVING;
                        end

                        // PIECE_SELECTED --> CHECK_2: if other square & if move valid
                        else if (valid) begin
                            shadow_board_flat <= board_flat; // latch board state when transitioning to shadow_moving to perform the move on the shadow board
                            dst_addr_latched <= dst_addr;
                            state <= SHADOW_MOVING;
                        end

                        // if not valid set error flash flag
                        else if (!valid)
                            error_flag <= 1;

                        // Otherwise stay in PIECE_SELECTED (no press || (press && different square && !valid))

                    end
                end

                // SHADOW_MOVING state
                SHADOW_MOVING: begin
                    if (!from_checkmate) begin
                        // shadow_move phase for 2-clock sequence in the same way as MOVING state
                        if (shadow_move_phase == 0) begin
                            shadow_board_flat[dst_addr_latched*4 +: 4] <= moving_piece; // write data to new square -- 4-bit part select on flat shadow board
                            shadow_move_phase <= 1; // set flag once destination is written
                        end else begin
                            shadow_board_flat[sel_addr*4 + : 4] <= 4'b0000; // write empty to old square
                            shadow_move_phase <= 0; // clear flag
                            state <= CHECK_2;
                        end
                    end else begin
                        // shadow_move phase for a checkmate_detection operation
                        if (shadow_move_phase == 0) begin
                            shadow_board_flat[cm_dst*4 +: 4] <= board_flat[cm_src*4 +: 4]; // write cm_src data
                            shadow_move_phase <= 1;
                        end else begin
                            shadow_board_flat[cm_src*4 + : 4] <= 4'b0000; // write empty
                            shadow_move_phase <= 0;
                            state <= CHECK_2;
                        end
                    end
                end
                
                // CHECK_2 state
                CHECK_2: begin
                    if (!from_checkmate) begin
                        if (check_2) begin
                            error_flag <= 1; // set error flag since still in check
                            state <= CHECKMATE_DETECT; // since in check, now check if actually checkmate
                            attacker_pos_latched <= attacker_pos; // latch attacker and king position here for checkmate detection
                            king_pos_latched <= king_pos;
                            from_checkmate <= 1; 
                            cm_init <= 1; // flag to reset (synchronously) checkmate detection counters only the first time
                        end else // !check_2
                            state <= MOVING;
                    end else begin
                        if (check_2 && !candidates_exhausted) begin
                            state <= CHECKMATE_DETECT;
                            cm_advance <= 1; // continue to test candidates if not exhausted
                        end else if (check_2 && candidates_exhausted) begin
                            state <= GAME_OVER; // game over if still in check when all checkmate prevention candidates are exhausted
                            from_checkmate <= 0;
                            game_over <= 1; // set game over flag
                            winner <= ~current_turn; // winner is the openent when checkmate detected
                        end else begin // !check_2
                            state <= PIECE_SELECTED;  // if a candidate works then go back to PIECE_SELECTED
                            from_checkmate <= 0;
                        end
                    end
                end

                // CHECKMATE_DETECT state
                CHECKMATE_DETECT: begin
                    if (cm_skip) begin
                        cm_advance <= 1;
                    end else begin
                        shadow_board_flat <= board_flat; // only latch a new shadow board, other states handle inputs and outputs to cm module
                        state <= SHADOW_MOVING;
                    end
                end

                // MOVING state
                MOVING: begin
                    // The purpose of the move_phase flag is to make MOVING run for exactly 2 clocks, first to write to new square, second to clear first square
                    if (move_phase == 0) begin
                        wr_en <= 1;
                        wr_addr <= dst_addr; // write to destination
                        wr_data <= moving_piece;
                        move_phase <= 1; // set flag once destination is written
                    end else begin
                        wr_en <= 1;
                        wr_addr <= sel_addr; // write to original selected address
                        wr_data <= 4'b0000; // clear to empty square - always 0000, never 1000
                        move_phase <= 0; // clear flags
                        piece_selected <= 0;
                        current_turn <= ~current_turn; // flip bit for opposite player's turn
                        cursor_row <= current_turn ? 3'd6 : 3'd1; // flip to init on the opposing player's king's pawn- white is 0 (false), if false, go to black's pawn
                        cursor_col <= 3'd4;
                        state <= IDLE;

                        // moved flags for castling enable
                        if (sel_addr == 60) white_king_moved <= 1; // white king
                        if (sel_addr == 63) white_rook_ks_moved <= 1; // white ks rook
                        if (sel_addr == 56) white_rook_qs_moved <= 1; // white qs rook
                        if (sel_addr == 4) black_king_moved <= 1; // black king
                        if (sel_addr == 7) black_rook_ks_moved <= 1; // black ks rook
                        if (sel_addr == 0) black_rook_qs_moved <= 1; // black qs rook
                    end
                end
                
                CASTLE_MOVING: begin
                    if (castle_move_phase == 0) begin // move phase 0 -- king write (0 = black; 0 = kingside)
                        wr_en <= 1;
                        wr_addr <= current_turn ? (castle_side ? 6'd2 : 6'd6) : (castle_side ? 6'd58 : 6'd62);
                        wr_data <= current_turn ? 4'b1110 : 4'b0110; // king
                        castle_move_phase <= 1;
                    end else if (castle_move_phase == 1) begin // move phase 1 -- original king clear
                        wr_en <= 1;
                        wr_addr <= current_turn ? 6'd4 : 6'd60; // clear king origin
                        wr_data <= 4'b0000;
                        castle_move_phase <= 2;
                    end else if (castle_move_phase == 2) begin // move phase 2 -- rook write
                        wr_en <= 1;
                        wr_addr <= current_turn ? (castle_side ? 6'd3 : 6'd5) : (castle_side ? 6'd59 : 6'd61);
                        wr_data <= current_turn ? 4'b1100 : 4'b0100; // rook
                        castle_move_phase <= 3;
                    end else begin // move phase 3 -- original rook clear
                        wr_en <= 1;
                        wr_addr <= current_turn ? (castle_side ? 6'd0 : 6'd7) : (castle_side ? 6'd56 : 6'd63);
                        wr_data <= 4'b0000;
                        castle_move_phase <= 0;

                        // set moved flags
                        if (current_turn) 
                            black_king_moved <= 1;
                        else 
                            white_king_moved <= 1;
                        if (current_turn) begin
                            if (castle_side) 
                                black_rook_qs_moved <= 1;
                            else 
                                black_rook_ks_moved <= 1;
                        end else begin
                            if (castle_side) 
                                white_rook_qs_moved <= 1;
                            else 
                                white_rook_ks_moved <= 1;
                        end
                        
                        current_turn <= ~current_turn; // flip turn
                        cursor_row <= current_turn ? 3'd6 : 3'd1; // init cursor
                        cursor_col <= 3'd4;
                        state <= IDLE;
                    end
                end

                // GAME_OVER state
                GAME_OVER: begin
                    // continue to enable cursor movement (essentially for no reason but better than frozen screen)
                    if (mcen_u && cursor_row > 0) cursor_row <= cursor_row - 1; // up
                    if (mcen_d && cursor_row < 7) cursor_row <= cursor_row + 1; // down
                    if (mcen_l && cursor_col > 0) cursor_col <= cursor_col - 1; // left
                    if (mcen_r && cursor_col < 7) cursor_col <= cursor_col + 1; // right

                    // must reset to go back to IDLE

                end
            endcase
        end
    end

endmodule