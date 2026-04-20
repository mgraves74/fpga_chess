/* 

Board Memory

Marshall Graves & Sheel Shah --- FPGA Chess
Created: 4/14/26

Original File

*/

/*

Key Information:

Chess Piece Encoding:
4-bits: 0000

MSB: 0- white, 1- black

3 LSB - piece encodings:
000- empty
001- pawn
010- knight
011- bishop
100- rook
101- queen
110- king
111- not used

0000 & 1000 are the same
0111 & 1111 not used

Read Data Flow:
There are two sets of ports for read addr/data: one for the renderer and one for the fsm. The reason why there 
are two is because fsm and renderer need to read different data from memory at the same time, which works fine
because data reads are fully combinational.

Renderer Read Data Flow:
rd_addr_renderer is produced by the renderer module for every pixel it draws. When it draws a pixel it calculates 
the board address where that pixel lies. That address connects via the top to the board memory where it does a 
lookup to produce rd_data_renderer. rd_data renderer connects via the top back to the renderer where it used to 
determine piece type and color for the board coloring.

FSM Read Data Flow:
rd_addr_fsm is always equal to the position of the cursor (as assigned in the top). The board memory module does 
a lookup of this address to produce rd_data_fsm. rd_data_fsm connects via the top to the game_fsm where it is 
used to store the moving piece and to prvent a selected square from being empty of the wrong color.

*/

module board_mem (
    input clk,
    input reset,
    input [5:0] wr_addr, // write address -- 2^6 == 64 addresses
    input [3:0] wr_data, // write data -- 4 bit piece encoding data
    input wr_en, // write enable
    input [5:0] rd_addr_renderer, // read address for renderer
    output [3:0] rd_data_renderer, // read data for renderer
    input [5:0] rd_addr_fsm, // read address for fsm
    output [3:0] rd_data_fsm // read data for fsm
);

    reg [3:0] board [0:63]; // board memory init

    assign rd_data_renderer = board[rd_addr_renderer]; // read lookup functionality for the vga renderer
    assign rd_data_fsm = board[rd_addr_fsm]; // read lookup functionality for the fsm

    // write and reset/init functionality
    integer i;
    always @(posedge clk) begin
        // reset/init funcitonality
        if (reset) begin // synchronous reset
            for (i = 0; i < 64; i = i + 1) // blank out all 64 squares
                board[i] <= 4'b0000;

            board[0]  <= 4'b1100; // black rook
            board[1]  <= 4'b1010; // black knight
            board[2]  <= 4'b1011; // black bishop
            board[3]  <= 4'b1101; // black queen
            board[4]  <= 4'b1110; // black king
            board[5]  <= 4'b1011; // black bishop
            board[6]  <= 4'b1010; // black knight
            board[7]  <= 4'b1100; // black rook

            board[8]  <= 4'b1001; // black pawn
            board[9]  <= 4'b1001; // black pawn
            board[10] <= 4'b1001; // black pawn
            board[11] <= 4'b1001; // black pawn
            board[12] <= 4'b1001; // black pawn
            board[13] <= 4'b1001; // black pawn
            board[14] <= 4'b1001; // black pawn
            board[15] <= 4'b1001; // black pawn

            board[48] <= 4'b0001; // white pawn
            board[49] <= 4'b0001; // white pawn
            board[50] <= 4'b0001; // white pawn
            board[51] <= 4'b0001; // white pawn
            board[52] <= 4'b0001; // white pawn
            board[53] <= 4'b0001; // white pawn
            board[54] <= 4'b0001; // white pawn
            board[55] <= 4'b0001; // white pawn

            board[56] <= 4'b0100; // white rook
            board[57] <= 4'b0010; // white knight
            board[58] <= 4'b0011; // white bishop
            board[59] <= 4'b0101; // white queen
            board[60] <= 4'b0110; // white king
            board[61] <= 4'b0011; // white bishop
            board[62] <= 4'b0010; // white knight
            board[63] <= 4'b0100; // white rook

        end else if (wr_en) begin
            board[wr_addr] <= wr_data; // write functionality
        end
    end

endmodule