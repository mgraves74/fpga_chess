/* 

Game FSM Testbench

Marshall Graves & Sheel Shah - FPGA Chess
Original File

*/

`timescale 1ns / 1ps

module game_fsm_tb;

    // fsm inputs and outputs
    reg clk, reset;
    reg scen_c, mcen_u, mcen_d, mcen_l, mcen_r;
    reg [3:0] rd_data_fsm;

    wire [5:0] wr_addr;
    wire [3:0] wr_data;
    wire wr_en;
    wire [2:0] cursor_row, cursor_col;
    wire [2:0] sel_row, sel_col;
    wire piece_selected;
    wire current_turn;
    wire [1:0] state;

    // uut inst
    game_fsm uut(
        .clk(clk),
        .reset(reset),
        .scen_c(scen_c),
        .mcen_u(mcen_u),
        .mcen_d(mcen_d),
        .mcen_l(mcen_l),
        .mcen_r(mcen_r),
        .rd_data_fsm(rd_data_fsm),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .cursor_row(cursor_row),
        .cursor_col(cursor_col),
        .sel_row(sel_row),
        .sel_col(sel_col),
        .piece_selected(piece_selected),
        .current_turn(current_turn),
        .state(state)
    );

    always #5 clk = ~clk; // define 100 MHz clock

    integer errors; // counter for errors

    // task for button pulse - center scen
    task pulse_c;
        begin
            scen_c = 1;
            @(posedge clk); #1;
            scen_c = 0;
            @(posedge clk); #1;
        end
    endtask

    // up mcen
    task pulse_u;
        begin
            mcen_u = 1;
            @(posedge clk); #1;
            mcen_u = 0;
            @(posedge clk); #1;
        end
    endtask

    // down mcen
    task pulse_d;
        begin
            mcen_d = 1;
            @(posedge clk); #1;
            mcen_d = 0;
            @(posedge clk); #1;
        end
    endtask

    // left mcen
    task pulse_l;
        begin
            mcen_l = 1;
            @(posedge clk); #1;
            mcen_l = 0;
            @(posedge clk); #1;
        end
    endtask

    // right mcen
    task pulse_r;
        begin
            mcen_r = 1;
            @(posedge clk); #1;
            mcen_r = 0;
            @(posedge clk); #1;
        end
    endtask

    // task to check the cursor's position
    task check_cursor;
        input [2:0] exp_row, exp_col; // expected rows and columns
        begin
            if (cursor_row !== exp_row || cursor_col !== exp_col) begin
                $display("FAIL cursor position: expected (%0d,%0d) got (%0d,%0d)", exp_row, exp_col, cursor_row, cursor_col);
                errors = errors + 1;
            end
        end
    endtask

    // task to check current state
    task check_state;
        input [1:0] exp_state; // expected state
        begin
            if (state !== exp_state) begin
                $display("FAIL state: expected %0d got %0d", exp_state, state);
                errors = errors + 1;
            end
        end
    endtask

    // task to check any signal
    task check_signal;
        input exp_val;
        input act_val;
        input [63:0] label; // error msg
        begin
            if (act_val !== exp_val) begin
                $display("FAIL %s: expected %0d got %0d", label, exp_val, act_val);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 0;
        scen_c = 0; mcen_u = 0; mcen_d = 0; mcen_l = 0; mcen_r = 0;
        rd_data_fsm = 4'b0000;
        errors = 0;

        // reset
        reset = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;
        #1;

        // check that reset resets to the intended initialization
        check_cursor(3'd6, 3'd4); // white king's pawn
        check_state(2'b00); // IDLE state
        check_signal(0, piece_selected, "piece_selected after reset"); // no piece selected
        check_signal(0, current_turn,   "current_turn after reset"); // white's turn

        // moving cursor a few times and then checking where it goes
        pulse_u; // up
        check_cursor(3'd5, 3'd4);
        pulse_u; // up
        check_cursor(3'd4, 3'd4);
        pulse_d; // down
        check_cursor(3'd5, 3'd4);
        pulse_l; // left
        check_cursor(3'd5, 3'd3); 
        pulse_r; // right
        check_cursor(3'd5, 3'd4);

        // boundary checks
        repeat(5) pulse_u; check_cursor(3'd0, 3'd4); // 5 times up to the boundary
        pulse_u; check_cursor(3'd0, 3'd4); // at boundary so nothing should happen

        repeat(7) pulse_d; check_cursor(3'd7, 3'd4); // 7 times down to boundary
        pulse_d; check_cursor(3'd7, 3'd4); // at boundary so nothing should happen

        repeat(4) pulse_l; check_cursor(3'd7, 3'd0); // 4 times left to bonundary
        pulse_l; check_cursor(3'd7, 3'd0); // at boundary so nothing should happen

        repeat(7) pulse_r; check_cursor(3'd7, 3'd7);  // 7 times left to boundary
        pulse_r; check_cursor(3'd7, 3'd7); // at boundary so nothing should happen

        reset = 1; 
        @(posedge clk); #1;
        reset = 0; #1;
         
        // select on empty square should stay IDLE
        rd_data_fsm = 4'b0000; // need to manually drive reads
        pulse_c;
        check_state(2'b00); // IDLE
        check_signal(0, piece_selected, "piece_selected when empty so fails");

        // if wrong color piece, stays IDLE
        rd_data_fsm = 4'b1001;
        pulse_c;
        check_state(2'b00); // IDLE
        check_signal(0, piece_selected, "piece selected when wrong color so fails");

        // select transitions to piece selected
        rd_data_fsm = 4'b0001;
        pulse_c;
        check_state(2'b01); // PIECE_SELECTED -- check new transition
        check_signal(1, piece_selected, "piece not selected when valid confirm so fails");
        if (sel_row !== cursor_row || sel_col !== cursor_col) begin
            $display("FAIL, no latching select from cursor: expected (%0d,%0d) got (%0d,%0d)", cursor_row, cursor_col, sel_row, sel_col);
            errors = errors + 1;
        end

        // checking cursor movement in piece selected state
        pulse_u; check_cursor(3'd5, 3'd4);
        check_state(2'b01);

        // checking selecting the same square returns to IDLE
        pulse_d; // back to original square
        rd_data_fsm = 4'b0001;
        pulse_c;
        check_state(2'b00); // IDLE
        check_signal(0, piece_selected, "piece still selected after deselect so fails");

        // full move sim: select piece, move to new square, verify writes and turn flip
        reset = 1; 
        @(posedge clk); #1; 
        reset = 0; #1;

        rd_data_fsm = 4'b0001;
        pulse_c;
        check_state(2'b01); // PIECE_SELECTED

        // move white king's pawn up by 2
        pulse_u;
        pulse_u;
        rd_data_fsm = 4'b0000;
        pulse_c;

        check_state(2'b10); // move to MOVING

        // move phase 0 check
        if (wr_en !== 1 || wr_addr !== 6'd36 || wr_data !== 4'b0001) begin
            $display("FAIL move phase 0: wr_en=%0d wr_addr=%0d wr_data=%b", wr_en, wr_addr, wr_data);
            errors = errors + 1;
        end

        // move phase 1 check
        @(posedge clk); #1;
        if (wr_en !== 1 || wr_addr !== 6'd52 || wr_data !== 4'b0000) begin
            $display("FAIL move phase 1: wr_en=%0d wr_addr=%0d wr_data=%b", wr_en, wr_addr, wr_data);
            errors = errors + 1;
        end

        @(posedge clk); #1;
        check_state(2'b00); // return to IDLE
        check_signal(0, piece_selected, "piece wtill selected after move"); // piece no longer selected
        check_signal(1, current_turn,   "current_turn not changed after move"); // should change to black
        check_cursor(3'd1, 3'd4); // should go to black's king's pawn

        // count of errors
        if (errors == 0)
            $display("PASS: all FSM tests passed");
        else
            $display("DONE WITH ERRORS: %0d errors found", errors);

        $finish;
    end

endmodule