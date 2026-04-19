`timescale 1ns / 1ps

module game_fsm (
    input clk,
    input reset,
    input scen_c,
    input mcen_u,
    input mcen_d,
    input mcen_l,
    input mcen_r,
    input [3:0] rd_data,
    output reg [5:0] wr_addr,
    output reg [3:0] wr_data,
    output reg wr_en,
    output reg [2:0] cursor_row,
    output reg [2:0] cursor_col,
    output reg [2:0] sel_row,
    output reg [2:0] sel_col,
    output reg piece_selected,
    output reg current_turn
);

    localparam IDLE = 2'b00;
    localparam PIECE_SELECTED = 2'b01;
    localparam MOVING  = 2'b10;

    reg [1:0] state;
    reg move_phase;
    reg [3:0] moving_piece;

    wire [5:0] sel_addr = sel_row * 8 + sel_col;
    wire [5:0] dst_addr = cursor_row * 8 + cursor_col;

    always @(posedge clk, posedge reset) begin

        if (reset) begin
            state <= IDLE;
            cursor_row <= 3'd6;
            cursor_col <= 3'd0;
            sel_row <= 3'd0;
            sel_col <= 3'd0;
            piece_selected <= 0;
            current_turn <= 0;
            move_phase <= 0;
            moving_piece <= 4'b0000;
            wr_en <= 0;
            wr_addr <= 0;
            wr_data <= 0;
        end

        else begin

            wr_en <= 0;

            case (state)

                IDLE: begin
                    if (mcen_u && cursor_row > 0) cursor_row <= cursor_row - 1;
                    if (mcen_d && cursor_row < 7) cursor_row <= cursor_row + 1;
                    if (mcen_l && cursor_col > 0) cursor_col <= cursor_col - 1;
                    if (mcen_r && cursor_col < 7) cursor_col <= cursor_col + 1;

                    if (scen_c && rd_data[2:0] != 3'b000 && rd_data[3] == current_turn) begin
                        sel_row <= cursor_row;
                        sel_col <= cursor_col;
                        moving_piece <= rd_data;
                        piece_selected <= 1;
                        state <= PIECE_SELECTED;
                    end
                end

                PIECE_SELECTED: begin
                    if (mcen_u && cursor_row > 0) cursor_row <= cursor_row - 1;
                    if (mcen_d && cursor_row < 7) cursor_row <= cursor_row + 1;
                    if (mcen_l && cursor_col > 0) cursor_col <= cursor_col - 1;
                    if (mcen_r && cursor_col < 7) cursor_col <= cursor_col + 1;

                    if (scen_c) begin
                        if (cursor_row == sel_row && cursor_col == sel_col) begin
                            piece_selected <= 0;
                            state <= IDLE;
                        end else begin
                            state <= MOVING;
                        end
                    end
                end

                MOVING: begin
                    if (move_phase == 0) begin
                        wr_en <= 1;
                        wr_addr <= dst_addr;
                        wr_data <= moving_piece;
                        move_phase <= 1;
                    end else begin
                        wr_en <= 1;
                        wr_addr <= sel_addr;
                        wr_data <= 4'b0000;
                        move_phase <= 0;
                        piece_selected <= 0;
                        current_turn <= ~current_turn;
                        cursor_row <= current_turn ? 3'd6 : 3'd1;
                        cursor_col <= 3'd0;
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule