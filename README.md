# fpga_chess
FPGA Chess Game

For Submission Purposes Layer 3 is the working and fully tested version, which is identical to main.

The features implemented in layer 4 are all working, however layer 4 is actually reconstructed from layer 5 (there used to be only a layer 4 and not layer 5, which had checkmate detection and additional rules (castling, promotion, en passant), however due to checkmate detection not working, the full implementation was branched off into layer 5, while layer 4 was reconstructed as a version with the working additional rules but not checkmate detection). However the new layer 4 has not been tested and may not work. Therefore layers 1-3 and 5 will synthesize (though 5 has known bugs), while layer 4 may not.