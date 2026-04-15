/* Button Debouncing State Machine file

Marshall Graves & Sheel Shah -- FPGA Chess
4/14/26

Based on ee354_debounce_DPB_SCEN_CCEN_MCEN_r1

*/

`timescale 1ns / 100ps

module chess_debouncer(CLK, RESET, PB, DPB, SCEN, MCEN, CCEN);

// inputs
input CLK, RESET;
input PB; // push button input

// outputs
output DPB; // debounced pulse - not used directly
output SCEN, MCEN, CCEN; // single step, multi step, continuous clock - only SCEN and MCEN used

parameter N_dc = 28; // 28-bit counter

(* fsm_encoding = "user" *) // to allow output encoding
reg [5:0] state; // state register init
reg [N_dc-1:0] debounce_count; // debounce counter init

assign {DPB, SCEN, MCEN, CCEN} = state[5:2]; // output coding OFL

// state encoding
localparam
    INI       = 6'b000000, // init state
    W84       = 6'b000001, // wait 84 ms
    SCEN_st   = 6'b111100, // first pulse
    WS        = 6'b100000, // wait for repeat
    MCEN_st   = 6'b101100, // repeat pulse
    CCEN_st   = 6'b100100, // between repeat pulses
    CCR       = 6'b100001, // counter clear on release
    WFCR      = 6'b100010; // wait for complete release

// debouncer state machine with async reset
always @(posedge CLK, posedge RESET) begin : State_Machine
    
    if (RESET) begin
        state <= INI;
        debounce_count <= 'bx;
    end

    else begin
        case (state)

            INI: begin // init debounce count
                debounce_count <= 0;
                if (PB)
                    state <= W84;
            end

            W84: begin // wait for 84 ms after PB
                debounce_count <= debounce_count + 1;
                if (!PB)
                    state <= INI;
                else if (debounce_count[N_dc-5])
                    state <= SCEN_st;
            end

            SCEN_st: begin // clear debounce count and produce single pulse
                debounce_count <= 0;
                state <= WS;
            end

            WS: begin // wait for repeat if still pressed 
                debounce_count <= debounce_count + 1;
                if (!PB)
                    state <= CCR;
                else if (debounce_count[N_dc-3])
                    state <= MCEN_st;
            end

            MCEN_st: begin // clear debounce count and produce repeating pulses
                debounce_count <= 0;
                state <= CCEN_st;
            end

            CCEN_st: begin // countinuous clock between pulses
                debounce_count <= debounce_count + 1;
                if (!PB)
                    state <= CCR;
                else if (debounce_count[N_dc-3])
                    state <= MCEN_st;
            end

            CCR: begin // since button no longer pressed, clear
                debounce_count <= 0;
                state <= WFCR;
            end

            WFCR: begin // wait for complete release (release debouncing)
                debounce_count <= debounce_count + 1;
                if (PB)
                    state <= WS;
                else if (debounce_count[N_dc-5])
                    state <= INI;
            end
        endcase
    end
end

endmodule