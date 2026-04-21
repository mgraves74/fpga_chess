/* 

Move Validator

Marshall Graves & Sheel Shah --- FPGA Chess
Created: 4/20/26

Original File

*/

/*

Key information:

Fully combinational module containing move validation logic

*/

`timescale 1ns / 1ps;

module move_validator (
    input  [3:0] board [0:63],
    input  [5:0] src,
    input  [5:0] dst,
    input        current_turn,
    output reg   valid
);

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

endmodule