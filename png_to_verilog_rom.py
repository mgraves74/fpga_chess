# png_to_verilog_rom.py
# Converts 60x60 PNG chess piece images to Verilog ROM modules for FPGA synthesis
# Uses Block RAM inference via (* rom_style = "block" *) attribute
# 12-bit color: R[3:0] G[3:0] B[3:0]
# Transparent pixels masked to 12'b000000000000
#
# Requirements: pip install imageio Pillow

import imageio.v3 as iio
from PIL import Image
import os
import math

SPRITE_SIZE = 60  # 60x60 pixel sprites
ALPHA_THRESHOLD = 128  # below this alpha value -> transparent (masked to 0)

def generate_rom_verilog(name, img, out_dir):
    """Generate Verilog ROM module from RGBA PIL image.
    Transparent pixels (alpha < ALPHA_THRESHOLD) are masked to 0.
    """
    w, h = img.size
    row_bits = math.ceil(math.log2(h)) if h > 1 else 1
    col_bits = math.ceil(math.log2(w)) if w > 1 else 1
    addr_bits = row_bits + col_bits

    module_name = name + "_rom"
    file_path = os.path.join(out_dir, module_name + ".v")

    with open(file_path, 'w') as f:
        f.write(f"module {module_name}\n")
        f.write(f"\t(\n")
        f.write(f"\t\tinput wire clk,\n")
        f.write(f"\t\tinput wire [{row_bits-1}:0] row,\n")
        f.write(f"\t\tinput wire [{col_bits-1}:0] col,\n")
        f.write(f"\t\toutput reg [11:0] color_data\n")
        f.write(f"\t);\n\n")
        f.write(f"\t(* rom_style = \"block\" *)\n\n")
        f.write(f"\t//signal declaration\n")
        f.write(f"\treg [{row_bits-1}:0] row_reg;\n")
        f.write(f"\treg [{col_bits-1}:0] col_reg;\n\n")
        f.write(f"\talways @(posedge clk)\n")
        f.write(f"\t\tbegin\n")
        f.write(f"\t\trow_reg <= row;\n")
        f.write(f"\t\tcol_reg <= col;\n")
        f.write(f"\t\tend\n\n")
        f.write(f"\talways @*\n")
        f.write(f"\tcase ({{row_reg, col_reg}})\n")

        for y in range(h):
            for x in range(w):
                r, g, b, a = img.getpixel((x, y))

                case_val = format(y, 'b').zfill(row_bits) + format(x, 'b').zfill(col_bits)

                if a < ALPHA_THRESHOLD:
                    color_str = "000000000000"
                else:
                    r4 = (r >> 4) & 0xF
                    g4 = (g >> 4) & 0xF
                    b4 = (b >> 4) & 0xF
                    color_str = format(r4, 'b').zfill(4) + format(g4, 'b').zfill(4) + format(b4, 'b').zfill(4)

                f.write(f"\t\t{addr_bits}'b{case_val}: color_data = 12'b{color_str};\n")
            f.write("\n")

        f.write(f"\t\tdefault: color_data = 12'b000000000000;\n")
        f.write(f"\tendcase\nendmodule\n")

    return file_path


# ---- Main ----
if __name__ == "__main__":
    pieces = ['pawn', 'knight', 'bishop', 'rook', 'queen', 'king']
    colors = ['w', 'b']

    # Input directory containing 60x60 PNG files
    # Expected naming: pawn_w_60.png, pawn_b_60.png, knight_w_60.png, etc.
    png_dir = "./pieces_png"
    out_dir = "./sprite_roms"
    os.makedirs(out_dir, exist_ok=True)

    print(f"Generating {SPRITE_SIZE}x{SPRITE_SIZE} sprite ROMs from PNG files...")

    for piece in pieces:
        for color in colors:
            png_path = os.path.join(png_dir, f"{piece}_{color}_60.png")

            # Load with imageio to verify, then open with Pillow for pixel access
            raw = iio.imread(png_path)
            print(f"  {piece}_{color}: {raw.shape[1]}x{raw.shape[0]}, {raw.shape[2]} channels")

            img = Image.open(png_path).convert("RGBA")
            name = f"{piece}_{color}"
            fpath = generate_rom_verilog(name, img, out_dir)
            fsize = os.path.getsize(fpath)
            print(f"    -> {name}_rom.v ({fsize:,} bytes)")

    print(f"\nDone. {len(pieces) * len(colors)} ROM files in {out_dir}/")