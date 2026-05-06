# fpga_chess
FPGA Chess Game

For Submission Purposes Layer 3 is the working and fully tested version, which is identical to main.
- Submission on 5/1

As of 5/5 (post submission) Layer 4 is also fully working and tested. Main is still layer 3.

Layer 4 was reconstructed from layer 5. There used to be only a layer 4 and not layer 5, which had checkmate detection and additional rules (castling, promotion, en passant). However, due to checkmate detection not working, the full implementation was branched off into layer 5, while layer 4 was reconstructed as a version with the working additional rules but not checkmate detection.

Layer Overview:
Main- Fully identical to Layer 3 (5/1 submission version)
Layer 5- Runs on FPGA with all features, but with errors surrounding checkmate detection (seemingly random premature checkmate, multiple winners, wrong winner, etc.)
Layer 4- Now (as of 5/5) runs on FPGA with all features except checkmate detection; was reconstructed but not tested at time of submission; no known bugs
Layer 3- Runs on FPGA with features up to check detection; no known bugs
Layer 2- Runs on FPGA with features up to sprites and move validation; no known bugs
Layer 1- Runs on FPGA with basic features (board rendering, piece select and movement, turn validation), no sprites; no known bugs
