/*

Top File

Marshall Graves & Sheel Shah -- FPGA Chess
Created: 4/14/26

Original file; loosely inspired by vga_top.v -- ee354 created 12:18:00 12/14/2017 by Yue (Julien) Niu 

*/

`timescale 1ns / 1ps

module vga_top(
	input ClkPort,
	input BtnC,
	input BtnU,
	input BtnR,
	input BtnL,
	input BtnD,
	
    output  QuadSpiFlashCS,

    //VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	
	//SSG signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

    // switches
    input Sw15, Sw14, Sw13, Sw12, Sw2, Sw1, Sw0, // Switches 15-12 for promotion and 2-0 for reset

    // leds
    output Ld3, Ld2, Ld1, Ld0 // Ld3 for piece_selected flag, Ld2 - Ld0 to show state- Ld2 is MOVING, Ld1 is PIECE_SELECTED, LD0 is IDLE
	
	);

    // reset
	wire Reset;
	assign Reset = Sw0 && Sw1 && Sw2;

    // vga wire inst
	wire bright;
	wire [9:0] hc, vc;
	wire [11:0] rgb;

    // SSD inst
	reg [4:0]  SSD;
	wire [4:0] SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  SSD_CATHODES;
	wire [2:0] ssdscan_clk; 
	
    // Clock division
	reg [27:0]	DIV_CLK;
	always @ (posedge ClkPort, posedge Reset)  
	begin : CLOCK_DIVIDER
      if (Reset)
			DIV_CLK <= 0;
	  else
			DIV_CLK <= DIV_CLK + 1'b1;
	end

    //------------------//
    //  Instantiations  //
    //------------------//

	assign QuadSpiFlashCS = 1'b1;

    // VGA controller
	vga_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));

    // Chess debouncers - 5, one for each button
    wire scen_c, mcen_u, mcen_d, mcen_l, mcen_r;
    chess_debouncer dbc(.CLK(ClkPort), .RESET(Reset), .PB(BtnC), .DPB(), .SCEN(scen_c), .MCEN(), .CCEN()); // center - SCEN only
	chess_debouncer dbu(.CLK(ClkPort), .RESET(Reset), .PB(BtnU), .DPB(), .SCEN(),       .MCEN(mcen_u), .CCEN()); // Up - MCEN only
	chess_debouncer dbr(.CLK(ClkPort), .RESET(Reset), .PB(BtnR), .DPB(), .SCEN(),       .MCEN(mcen_r), .CCEN()); // Right - MCEN only
	chess_debouncer dbl(.CLK(ClkPort), .RESET(Reset), .PB(BtnL), .DPB(), .SCEN(),       .MCEN(mcen_l), .CCEN()); // Left - MCEN only
	chess_debouncer dbd(.CLK(ClkPort), .RESET(Reset), .PB(BtnD), .DPB(), .SCEN(),       .MCEN(mcen_d), .CCEN()); // Down - MCEN only

    // Board memory
    wire [5:0] wr_addr;
	wire [3:0] wr_data;
	wire wr_en;
	wire [5:0] rd_addr_renderer;
	wire [3:0] rd_data_renderer;
    wire [5:0] rd_addr_fsm;
	wire [3:0] rd_data_fsm;
	wire [255:0] board_flat_out;
	board_mem bm(.clk(ClkPort), .reset(Reset), 
		.wr_addr(wr_addr), .wr_data(wr_data), .wr_en(wr_en), 
		.rd_addr_renderer(rd_addr_renderer), .rd_data_renderer(rd_data_renderer), 
		.rd_addr_fsm(rd_addr_fsm), .rd_data_fsm(rd_data_fsm),
		.board_flat_out(board_flat_out));

    // Game FSM
    wire [2:0] cursor_row, cursor_col;
	wire [2:0] sel_row, sel_col;
	wire piece_selected;
	wire current_turn;
	wire [1:0] state;
	wire error_flag; 
    assign rd_addr_fsm = cursor_row * 8 + cursor_col; // read address for lookups in the fsm is always the cursor position
	wire [3:0] shadow_baord [63:0]; // latched board state for check_2 detection
	game_fsm gf(
		.clk(ClkPort), .reset(Reset),
		.scen_c(scen_c), .mcen_u(mcen_u), .mcen_d(mcen_d), .mcen_l(mcen_l), .mcen_r(mcen_r),
		.rd_data_fsm(rd_data_fsm),
		.wr_addr(wr_addr), .wr_data(wr_data), .wr_en(wr_en),
		.cursor_row(cursor_row), .cursor_col(cursor_col),
		.sel_row(sel_row), .sel_col(sel_col),
		.piece_selected(piece_selected),
		.current_turn(current_turn),
		.state(state),
		.error_flag(error_flag),
    .valid(valid),
		.check_1(check_1), .check_2(check_2),
    .board_flat(board_flat_out), .shadow_board(shadow_board)
	);

    // VGA Renderer
	vga_renderer vr(
		.clk(ClkPort),
		.bright(bright), .hCount(hc), .vCount(vc),
		.rd_data_renderer(rd_data_renderer), .rd_addr_renderer(rd_addr_renderer),
		.cursor_row(cursor_row), .cursor_col(cursor_col),
		.sel_row(sel_row), .sel_col(sel_col),
		.piece_selected(piece_selected),
		.rgb(rgb),
		.error_flag(error_flag)
	);

	assign vgaR = rgb[11:8];
	assign vgaG = rgb[7:4];
	assign vgaB = rgb[3:0];

	// Move validator

	wire valid;
	wire [5:0] mv_src = {sel_row, sel_col}; // source (selected column and row)
	wire [5:0] mv_dst = {cursor_row, cursor_col}; // destination (current cursor and row)

	move_validator mv(
		.board_flat(board_flat_out),
		.src(mv_src),
		.dst(mv_dst),
		.valid(valid)
	);

	// Check detection

	// Check 1 -- current in check detection during IDLE
	wire check_1;
	check_detection cd1(
		.board(board_out),
		.src(mv_src),
		.dst(mv_dst),
		.check(check_1)
	);

	// Check 2 -- moving into check detection
	wire check_2;
	check_detection cd2(
		.board(shadow_board),
		.src(mv_src),
		.dst(mv_dst),
		.check(check_2)
	);
	
    //------------------//
    //     LED Code     //
    //------------------//
    
    // LED inst
	assign Ld4 = piece_selected;
	assign Ld3 = (state == 2'b11) ? 1'b1 : 1'b0;
	assign Ld2 = (state == 2'b10) ? 1'b1 : 1'b0;
	assign Ld1 = (state == 2'b01) ? 1'b1 : 1'b0;
	assign Ld0 = (state == 2'b00) ? 1'b1 : 1'b0;

	//------------------//
    //     SSD Code     //
    //------------------//

	/*
	
	SSD Display Messages:

	WHT___GO - when !current_turn (white's turn)
	BLK___GO - when current_turn (black's turn)
	ILLEGAL_ - if error_flash_ssd (a 2-sec display everytime a move is invalidated) (takes priority over everything)
	WHT__CHK - when !current_turn && check_1
	BLK__CHK - when current_turn && check_1

	*/

	// Error display timer
	reg [27:0] ssd_error_timer; // 2^28 / 100000000 = 2.684 sec

	always @(posedge ClkPort) begin
		if (error_flag)
			ssd_error_timer <= 28'd0;
		else if (ssd_error_timer < 28'd200000000) // times exactly 2 + 1/10^8 sec
			ssd_error_timer <= ssd_error_timer + 1;
	end

	wire error_flash_ssd = (ssd_error_timer < 28'd200000000);

    // Display messages with priority to move error
    assign SSD7 = error_flash_ssd ? 4'b0110: (current_turn ? 4'b0001 : 4'b1111); // I : (B : W)
	assign SSD6 = error_flash_ssd ? 4'b1000: (current_turn ? 4'b1000 : 4'b0101); // L : (L : H)
	assign SSD5 = error_flash_ssd ? 4'b1000: (current_turn ? 4'b0111 : 4'b1110); // L : (K : T)
	assign SSD4 = 4'b0011; // E -- blank if !error_flash_ssd
	assign SSD3 = 4'b0100; // G -- blank if !error_flash_ssd
	assign SSD2 = error_flash_ssd ? 4'b0000 : 4'b0010; // A : C -- blank if !(error_flash_ssd || check_1)
	assign SSD1 = error_flash_ssd ? 4'b1000: (check_1 ? 4'b0101 : 4'b0100); // L : (H : G)
	assign SSD0 = check_1 ? 4'0111 : 4'b1010; // K : O -- blank if error_flash_ssd
    
    /*
	Scan clock for the SSD display - all 8 SSDs
	100 MHz / 2^17 = 762.9 cycles/sec ==> frequency of DIV_CLK[16]
	100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	762.9 cycles/sec (1.31 ms per digit) --- all 8 digits are lit once every 10.5 ms
	*/

	assign ssdscan_clk = DIV_CLK[18:16];

    // Turn on anodes one by one at scan clock speed - fast clock makes it look like all are all on simultaneously
	assign An7 = !((ssdscan_clk[2]) && (ssdscan_clk[1]) && (ssdscan_clk[0])); // when ssdscan_clk = 111
	assign An6 = !((ssdscan_clk[2]) && (ssdscan_clk[1]) && ~(ssdscan_clk[0])); // when ssdscan_clk = 110
	assign An5 = !((ssdscan_clk[2]) && ~(ssdscan_clk[1]) && (ssdscan_clk[0])); // when ssdscan_clk = 101
	assign An4 = error_flash_ssd ? !((ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0])) : 1'b1; // when ssdscan_clk = 100 -- on if error_flash_ssd
	assign An3 = error_flash_ssd ? !(~(ssdscan_clk[2]) && (ssdscan_clk[1]) && (ssdscan_clk[0])) : 1'b1; // when ssdscan_clk = 011 -- on if error_flash_ssd
    assign An2 = (error_flash_ssd || check_1) ? !(~(ssdscan_clk[2]) && (ssdscan_clk[1]) && ~(ssdscan_clk[0])) : 1'b1; // when ssdscan_clk = 010 -- on if error_flash_ssd
	assign An1 = !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && (ssdscan_clk[0])); // when ssdscan_clk = 001
	assign An0 = error_flash_ssd ? 1'b1 : !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0])); // when ssdscan_clk = 000 -- off if error_flash_ssd
	
    // set full SSD equal (the 8 cathodes) to given SSD digit at the time in sync with when its anode is turned on (so that digit is displayed in the correct place)
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3, SSD4, SSD5, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
            3'b000: SSD = SSD0;
            3'b001: SSD = SSD1;
            3'b010: SSD = SSD2;
            3'b011: SSD = SSD3;
            3'b100: SSD = SSD4;
            3'b101: SSD = SSD5;
            3'b110: SSD = SSD6;
            3'b111: SSD = SSD7;
		endcase 
	end

	// Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)
            // SSD letter encodings for letters ABCEGHIKLNOPRTW which are the 16 letters used in SSD messages
			4'b0000: SSD_CATHODES = 8'b00010001; // A
			4'b0001: SSD_CATHODES = 8'b11000001; // B
			4'b0010: SSD_CATHODES = 8'b01100011; // C
			4'b0011: SSD_CATHODES = 8'b01100001; // E
			4'b0100: SSD_CATHODES = 8'b01000011; // G
			4'b0101: SSD_CATHODES = 8'b10010001; // H
			4'b0110: SSD_CATHODES = 8'b11110011; // I
			4'b0111: SSD_CATHODES = 8'b01010001; // K
			4'b1000: SSD_CATHODES = 8'b11100011; // L
			4'b1001: SSD_CATHODES = 8'b00010011; // N
			4'b1010: SSD_CATHODES = 8'b00000011; // O
			4'b1011: SSD_CATHODES = 8'b00110001; // P
			4'b1100: SSD_CATHODES = 8'b00110011; // R
			4'b1101: SSD_CATHODES = 8'b01001001; // S
			4'b1110: SSD_CATHODES = 8'b11100001; // T
			4'b1111: SSD_CATHODES = 8'b10101011; // W
			default: SSD_CATHODES = 8'b11111111; // default is all dark -- but all cases are covered anyway
		endcase
	end	
    
    // set cathodes
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

endmodule