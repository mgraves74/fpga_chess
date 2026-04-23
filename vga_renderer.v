/*

VGA Renderer

Marshall Graves & Sheel Shah
Created: 4/14/26

Original file; loosely inspired by block_controller.v from VGA moving block demo -- ee354

*/

/*

Key Information:

VGA uses 12-bit colors: R, G, B where each is a 4-bit otion- 4096 total color options

Color mapping (currently not using sprite):
White
- Pawn: Bright white
- Knight: Bright green
- Bishop: Yellow
- Rook: Orange
- Queen: Magenta
- King: Bright red

Black
- Pawn: Gray
- Knight: Dark green
- Bishop: Dark yellow
- Rook: Dark orange
- Queen: Dark magenta
- King: Dark red

Cursor: 4-pixel yellow border drawn around square
Selected: 4-pixel green border drawn around square

*/

`timescale 1ns / 1ps

module vga_renderer(
    input bright,
    input [9:0] hCount, vCount,
    input [3:0] rd_data_renderer,
    input [2:0] cursor_row, cursor_col,
    input [2:0] sel_row, sel_col,
    input piece_selected,
    input error_flag,
    output reg [11:0] rgb,
    output [5:0] rd_addr_renderer
    );

    parameter BLACK = 12'b0000_0000_0000; // black color
    parameter WHITE = 12'b1111_1111_1111; // white color

    parameter LIGHT_SQ = 12'hEDD; // light square color
    parameter DARK_SQ  = 12'h842; // dark square color

    parameter CURSOR_COLOR = 12'hFF0; // cursor color
    parameter SELECTED_COLOR = 12'h0F0; // selected square color
    parameter ERROR_COLOR = 12'hF00 // red error color

    // Currently the pieces are represented by colors not sprites -- see color mapping in Key Information
    parameter PAWN_W   = 12'hFFF;
    parameter KNIGHT_W = 12'h0F0;
    parameter BISHOP_W = 12'hFF0;
    parameter ROOK_W   = 12'hF80;
    parameter QUEEN_W  = 12'hF0F;
    parameter KING_W   = 12'hF00;

    parameter PAWN_B   = 12'h888;
    parameter KNIGHT_B = 12'h060;
    parameter BISHOP_B = 12'h880;
    parameter ROOK_B   = 12'h840;
    parameter QUEEN_B  = 12'h808;
    parameter KING_B   = 12'h400;

    // Offset to start at beginning of visible area
    wire [9:0] x = hCount - 144;
    wire [9:0] y = vCount - 35;

    // creation of 8x8 grid with 80x60 pixel squares
    wire [2:0] sq_col = x / 80;
    wire [2:0] sq_row = y / 60;

    // creation of offset to detect if near border
    wire [6:0] sq_x = x % 80;
    wire [5:0] sq_y = y % 60;

    // for creation of checkered board (alternating between light and dark squares) -- for squares without pieces
    wire is_light_square = ~(sq_row[0] ^ sq_col[0]);

    wire on_border = (sq_x < 4) || (sq_x >= 76) || (sq_y < 4) || (sq_y >= 56); // detection of 4-pixel border

    // for highlighting of cursor and selected squares
    wire is_cursor_sq   = (sq_row == cursor_row) && (sq_col == cursor_col);
    wire is_selected_sq = piece_selected && (sq_row == sel_row) && (sq_col == sel_col); // piece_selected flag must also be true so doesn't stay highlighted after turn ends

    // error flash highlighting
    reg [24:0] vga_error_timer; // 2^25 / 100 MHz = ~0.3355 sec
    reg [2:0] dst_row_error; // destination row and column, but different from dst in move_validator because this is latched at a specific time specifically for the error functionality
    reg [2:0] dst_col_error;
    always @(posedge clk) begin
        if (error_flag) begin
            vga_error_timer <= 25'd0; // times exactly 0.2 + 1/10^8 sec
            dst_row_error <= cursor_row; // latch row and column at the start of the timer so that it doesn't change with any subsequent cursor move
            dst_col_error <= cursor_col;
        end else if (vga_error_timer < 25'd20000000)
                vga_error_timer <= vga_error_timer + 1;
    end

    wire error_flash_vga = (vga_error_timer < 25'd20000000);
    wire is_error_sq = (sq_row == dst_row_error) && (sq_col == dst_col_error); // error square if on the latched destination - remains even after timer finishes, but does not thing if error_flash_vga is 0

    // calculate current pixel's board memory address so that board_memory module can provide data at that pixel
    assign rd_addr_renderer = sq_row * 8 + sq_col;

    // read board memory
    wire [2:0] piece_type  = rd_data_renderer[2:0]; // piece type data is 3 LSB
    wire piece_color = rd_data_renderer[3]; // piece color data is 1 MSB

    // mapping board memory encodings to colors
    reg [11:0] piece_rgb;
    always @(*) begin
        case ({piece_color, piece_type})
            4'b0001: piece_rgb = PAWN_W;
            4'b0010: piece_rgb = KNIGHT_W;
            4'b0011: piece_rgb = BISHOP_W;
            4'b0100: piece_rgb = ROOK_W;
            4'b0101: piece_rgb = QUEEN_W;
            4'b0110: piece_rgb = KING_W;
            4'b1001: piece_rgb = PAWN_B;
            4'b1010: piece_rgb = KNIGHT_B;
            4'b1011: piece_rgb = BISHOP_B;
            4'b1100: piece_rgb = ROOK_B;
            4'b1101: piece_rgb = QUEEN_B;
            4'b1110: piece_rgb = KING_B;
            default: piece_rgb = is_light_square ? LIGHT_SQ : DARK_SQ; // squares without pieces
        endcase
    end

    // actual coloring of squares with priority
    always @(*) begin
        if (~bright)
            rgb = BLACK;
        else if (on_border && is_selected_sq)
            rgb = SELECTED_COLOR;
        else if (on_border && is_error_sq && error_flash_vga)
            rgb = ERROR_COLOR;
        else if (on_border && is_cursor_sq)
            rgb = CURSOR_COLOR;
        else if (piece_type != 3'b000)
            rgb = piece_rgb;
        else
            rgb = is_light_square ? LIGHT_SQ : DARK_SQ;
    end

endmodule