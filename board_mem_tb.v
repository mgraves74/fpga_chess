/* 

Board Memory Testbench

Marshall Graves & Sheel Shah - FPGA Chess
Original File

*/

`timescale 1ns / 1ps

module board_mem_tb;

    // board mem inputs and outputs
    reg clk, reset, wr_en;
    reg [5:0] wr_addr, rd_addr_fsm, rd_addr_renderer;
    reg [3:0] wr_data;
    wire [3:0] rd_data_fsm, rd_data_renderer;

    // uut inst
    board_mem uut(
        .clk(clk),
        .reset(reset),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .rd_addr_fsm(rd_addr_fsm),
        .rd_data_fsm(rd_data_fsm),
        .rd_addr_renderer(rd_addr_renderer),
        .rd_data_renderer(rd_data_renderer)
    );

    always #5 clk = ~clk; // definte clock - every 10 ns --> 100 MHz

    integer i;
    integer errors; // counter for number of errors

    // task to check if board square is expected
    task check;
        input [5:0] addr;
        input [3:0] expected;
        begin
            rd_addr_fsm = addr;
            #1;
            if (rd_data_fsm !== expected) begin
                $display("FAIL addr=%0d expected=%b got=%b", addr, expected, rd_data_fsm);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 0;
        wr_en = 0;
        wr_addr = 0;
        wr_data = 0;
        rd_addr_fsm = 0;
        rd_addr_renderer = 0;
        errors = 0;

        reset = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;
        #1;

        // black pieces
        check(0,  4'b1100); // black rook
        check(1,  4'b1010); // black knight
        check(2,  4'b1011); // black bishop
        check(3,  4'b1101); // black queen
        check(4,  4'b1110); // black king
        check(5,  4'b1011); // black bishop
        check(6,  4'b1010); // black knight
        check(7,  4'b1100); // black rook

        // black pawns
        for (i = 8; i <= 15; i = i + 1)
            check(i, 4'b1001);

        // empty rows
        for (i = 16; i <= 47; i = i + 1)
            check(i, 4'b0000);

        // white pawns
        for (i = 48; i <= 55; i = i + 1)
            check(i, 4'b0001);

        // white pieces
        check(56, 4'b0100); // white rook
        check(57, 4'b0010); // white knight
        check(58, 4'b0011); // white bishop
        check(59, 4'b0101); // white queen
        check(60, 4'b0110); // white king
        check(61, 4'b0011); // white bishop
        check(62, 4'b0010); // white knight
        check(63, 4'b0100); // white rook

        // display the number fo initial position errors
        if (errors == 0)
            $display("SUCCESS");
        else
            $display("%0d errors found", errors);

        // write test -- moving the white king's pawn double
        wr_en = 1;
        wr_addr = 36;
        wr_data = 4'b0001;
        @(posedge clk); #1;
        wr_en = 1;
        wr_addr = 52;
        wr_data = 4'b0000;
        @(posedge clk); #1;
        wr_en = 0;
        #1;

        check(36, 4'b0001); // check if pawn at new destination
        check(52, 4'b0000); // check if original square cleared

        // To verify dual read capability
        rd_addr_fsm = 36;
        rd_addr_renderer = 52;
        #1;
        if (rd_data_fsm === 4'b0001 && rd_data_renderer === 4'b0000)
            $display("SUCCESS: Independence");
        else
            $display("Dual read conflict fsm=%b renderer=%b", rd_data_fsm, rd_data_renderer);
        $finish;

    end

endmodule