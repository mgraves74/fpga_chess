/*

VGA Renderer — Sprite ROM Version

Marshall Graves & Sheel Shah
Created: 4/14/26
Updated: 4/27/26 — replaced solid-color pieces with 60x60 sprite ROMs

Original file; loosely inspired by block_controller.v from VGA moving block demo -- ee354

*/

/*

Key Information:

VGA uses 12-bit colors: R, G, B where each is a 4-bit option — 4096 total color options

Pieces are now rendered using 60x60 pixel sprite ROMs stored in Block RAM.
Each ROM outputs 12-bit color data per pixel. Transparent pixels return 12'h000,
which causes the board background to show through.

Sprites are centered horizontally within each 80x60 square (10px padding each side).

Cursor: 4-pixel yellow border drawn around square
Selected: 4-pixel green border drawn around square

*/

`timescale 1ns / 1ps

module vga_renderer(
    input clk,
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

    parameter BLACK = 12'b0000_0000_0000;
    parameter WHITE = 12'b1111_1111_1111;

    parameter LIGHT_SQ = 12'hEDD;
    parameter DARK_SQ  = 12'h842;

    parameter CURSOR_COLOR = 12'hFF0;
    parameter SELECTED_COLOR = 12'h0F0;
    parameter ERROR_COLOR = 12'hF00;

    // =========================================================================
    // Pixel position and board square calculations
    // =========================================================================

    // Offset to start at beginning of visible area
    wire [9:0] x = hCount - 144;
    wire [9:0] y = vCount - 35;

    // Which board square this pixel belongs to
    wire [2:0] sq_col = x / 80;
    wire [2:0] sq_row = y / 60;

    // Pixel offset within the current square
    wire [6:0] sq_x = x % 80;
    wire [5:0] sq_y = y % 60;

    // Checkered board pattern
    wire is_light_square = ~(sq_row[0] ^ sq_col[0]);

    // 4-pixel border detection for cursor/selection highlighting
    wire on_border = (sq_x < 4) || (sq_x >= 76) || (sq_y < 4) || (sq_y >= 56);

    // Cursor and selection matching
    wire is_cursor_sq   = (sq_row == cursor_row) && (sq_col == cursor_col);
    wire is_selected_sq = piece_selected && (sq_row == sel_row) && (sq_col == sel_col);

    // =========================================================================
    // Error flash logic (unchanged from original)
    // =========================================================================

    reg [24:0] vga_error_timer;
    reg [2:0] dst_row_error;
    reg [2:0] dst_col_error;
    always @(posedge clk) begin
        if (error_flag) begin
            vga_error_timer <= 25'd0;
            dst_row_error <= cursor_row;
            dst_col_error <= cursor_col;
        end else if (vga_error_timer < 25'd20000000)
                vga_error_timer <= vga_error_timer + 1;
    end

    wire error_flash_vga = (vga_error_timer < 25'd20000000);
    wire is_error_sq = (sq_row == dst_row_error) && (sq_col == dst_col_error);

    // =========================================================================
    // Board memory read — tells us what piece is on this square
    // =========================================================================

    assign rd_addr_renderer = sq_row * 8 + sq_col;

    wire [2:0] piece_type  = rd_data_renderer[2:0];
    wire piece_color = rd_data_renderer[3];

    // =========================================================================
    // Sprite ROM coordinates
    // =========================================================================

    // Sprite is 60x60, centered in 80x60 square with 10px horizontal padding
    wire in_sprite_area = (sq_x >= 10) && (sq_x < 70);
    wire [5:0] sprite_col = sq_x - 10;  // 0-59 horizontal offset into sprite
    wire [5:0] sprite_row = sq_y;       // 0-59 vertical offset (no vertical padding)

    // =========================================================================
    // Sprite ROM instantiations — one per piece type (12 total)
    // All ROMs receive the same sprite_row/sprite_col address.
    // Only the output of the ROM matching the current square's piece is used.
    // =========================================================================

    wire [11:0] pawn_w_color, pawn_b_color;
    wire [11:0] knight_w_color, knight_b_color;
    wire [11:0] bishop_w_color, bishop_b_color;
    wire [11:0] rook_w_color, rook_b_color;
    wire [11:0] queen_w_color, queen_b_color;
    wire [11:0] king_w_color, king_b_color;

    pawn_w_rom pawn_w_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(pawn_w_color)
    );

    pawn_b_rom pawn_b_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(pawn_b_color)
    );

    knight_w_rom knight_w_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(knight_w_color)
    );

    knight_b_rom knight_b_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(knight_b_color)
    );

    bishop_w_rom bishop_w_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(bishop_w_color)
    );

    bishop_b_rom bishop_b_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(bishop_b_color)
    );

    rook_w_rom rook_w_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(rook_w_color)
    );

    rook_b_rom rook_b_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(rook_b_color)
    );

    queen_w_rom queen_w_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(queen_w_color)
    );

    queen_b_rom queen_b_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(queen_b_color)
    );

    king_w_rom king_w_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(king_w_color)
    );

    king_b_rom king_b_inst (
        .clk(clk),
        .row(sprite_row),
        .col(sprite_col),
        .color_data(king_b_color)
    );

    // =========================================================================
    // Sprite color mux — select the correct ROM output based on piece encoding
    // =========================================================================

    reg [11:0] sprite_rgb;
    always @(*) begin
        case ({piece_color, piece_type})
            4'b0001: sprite_rgb = pawn_w_color;
            4'b0010: sprite_rgb = knight_w_color;
            4'b0011: sprite_rgb = bishop_w_color;
            4'b0100: sprite_rgb = rook_w_color;
            4'b0101: sprite_rgb = queen_w_color;
            4'b0110: sprite_rgb = king_w_color;
            4'b1001: sprite_rgb = pawn_b_color;
            4'b1010: sprite_rgb = knight_b_color;
            4'b1011: sprite_rgb = bishop_b_color;
            4'b1100: sprite_rgb = rook_b_color;
            4'b1101: sprite_rgb = queen_b_color;
            4'b1110: sprite_rgb = king_b_color;
            default: sprite_rgb = 12'h000;
        endcase
    end

    // A sprite pixel is "visible" when we're inside the sprite area AND
    // the ROM returned a non-transparent color (not 12'h000)
    wire sprite_pixel_active = in_sprite_area && (sprite_rgb != 12'h000);

    // =========================================================================
    // Background color — checkered board
    // =========================================================================

    wire [11:0] bg_color = is_light_square ? LIGHT_SQ : DARK_SQ;

    // =========================================================================
    // Final pixel color with priority:
    //   1. Blanking (not bright) → black
    //   2. Selection border (green)
    //   3. Error border (red, flashing)
    //   4. Cursor border (yellow)
    //   5. Sprite pixel (from ROM, if non-transparent)
    //   6. Board background (checkered)
    // =========================================================================

    always @(*) begin
        if (~bright)
            rgb = BLACK;
        else if (on_border && is_selected_sq)
            rgb = SELECTED_COLOR;
        else if (on_border && is_error_sq && error_flash_vga)
            rgb = ERROR_COLOR;
        else if (on_border && is_cursor_sq)
            rgb = CURSOR_COLOR;
        else if (sprite_pixel_active)
            rgb = sprite_rgb;
        else
            rgb = bg_color;
    end

endmodule
