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
    output reg [5:0] wr_addr, // write board memory address (write to square on board)
    output reg [3:0] wr_data, // write board memory (piece encoding)
    output reg wr_en, // write enable
    output reg [2:0] cursor_row, // cursor current row (0-7)
    output reg [2:0] cursor_col, // cursor current column (0-7)
    output reg [2:0] sel_row, // selected row (0-7)
    output reg [2:0] sel_col, // selected column (0-7)
    output reg piece_selected, // piece selected flag
    output reg current_turn, // current turn flag - 0 for white's move, 1 for black's move
    output reg [1:0] state // 2 bit state encoding for 3 states, exposed for showing state on LEDs
    output reg error_flash // flag to indicate that an error has been produced from an invalidated move
    );

    // states 
    localparam IDLE = 2'b00;
    localparam PIECE_SELECTED = 2'b01;
    localparam MOVING = 2'b10;
     
    reg move_phase; // move phase flag for "moving" state (see below)
    reg [3:0] moving_piece; // register to store encoding of the moving piece

    wire [5:0] sel_addr = sel_row * 8 + sel_col; // board memory address of the first/source selected piece
    wire [5:0] dst_addr = cursor_row * 8 + cursor_col; // board memory address of second/destination selected piece

    always @(posedge clk, posedge reset) begin

        // reset conditions
        if (reset) begin
            state <= IDLE;
            cursor_row <= 3'd6; // init cursor to king's pawn
            cursor_col <= 3'd4;
            sel_row <= 3'd0; // init selected to 00 which is blacks rook, but it doesn't matter because no flag set anyway
            sel_col <= 3'd0;
            piece_selected <= 0; // flag inits
            current_turn <= 0;
            move_phase <= 0;
            moving_piece <= 4'b0000; // set moving piece to empty
            wr_en <= 0; // init disable write
            wr_addr <= 0;
            wr_data <= 0;
        end

        else begin

            wr_en <= 0; // always disable write at start

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
                            state <= IDLE;
                        end 
                        
                        // PIECE_SELECTED --> MOVING: if other square & if move valid
                        else if (valid)
                            state <= MOVING;

                        // Otherwise stay in PIECE_SELECTED (no press || (press && different square && !valid))

                        // if not valid set error flash flag
                        else if (!valid)
                            error_flash = 1;
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
                    end
                end

            endcase
        end
    end

endmodule