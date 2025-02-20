//`define RELOADABLE    // Coefficients can be changed when FIR is off

(* use_dsp = "yes" *) module FIR_Filter  
#(  
    parameter TAPS = 49,
    parameter DATA_WIDTH = 16,                        
    parameter COEFF_WIDTH = 16                    
`ifdef RELOADABLE
    ,parameter ADDR_WIDTH = 6                              
`endif
)
(  
    input   wire                                         clk,        // Clock signal  
    input   wire                                         rst,        // Reset signal  
    input   wire signed  [DATA_WIDTH-1:0]                x,          // Input data  
    output  reg  signed  [DATA_WIDTH+COEFF_WIDTH-1:0]    y           // Output data  
`ifdef RELOADABLE
    ,input   wire                                        fir_en      // FIR enable signal
    ,input   wire        [ADDR_WIDTH-1:0]                wr_addr     // Write address for coefficient
    ,input   wire signed [COEFF_WIDTH-1:0]               wr_data       // Coefficient data
    ,input   wire                                        wr_en       // Write enable signal
`endif
);  

localparam SYM_TAPS = (TAPS+1)/2; // Half the number of taps

// Coefficients
`ifdef RELOADABLE
    integer j;
    reg signed [COEFF_WIDTH-1:0] COEFFS [0:SYM_TAPS-1]; // Register File for Coefficients
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (j = 0; j < SYM_TAPS; j = j + 1) begin
                COEFFS[j] <= 0;
            end
        end
        else begin
            if (wr_en && !fir_en) begin
                COEFFS[wr_addr] <= wr_data;
            end
        end
    end
`else
    localparam logic signed [COEFF_WIDTH-1:0] COEFFS [SYM_TAPS] = '{-36, 82, 122, 99, -20, -166, -204, -52, 213, 369, 221, -197, -572, -524, 50, 786, 1029, 351, -976, -1954, -1421, 1108, 4928, 8380, 9768};
`endif

reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] acc [0:TAPS-2];
integer i;

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        for (i = 0; i < TAPS-1; i = i + 1) begin
            acc[i] <= 0;
        end
        y <= 0;
    end
    else begin
`ifdef RELOADABLE
        if (fir_en) begin
            acc[0] <= x * COEFFS[0];
            for (i = 1; i < TAPS; i = i + 1) begin
                if (i == TAPS-1) begin
                    y <= acc[i-1] + (x * COEFFS[0]);
                end
                else if (i < SYM_TAPS)
                    acc[i] <= acc[i-1] + (x * COEFFS[i]);
                else
                    acc[i] <= acc[i-1] + (x * COEFFS[TAPS-i-1]);
            end
        end
`endif
        acc[0] <= x * COEFFS[0];
        for (i = 1; i < TAPS; i = i + 1) begin
            if (i == TAPS-1) begin
                y <= acc[i-1] + (x * COEFFS[0]);
            end
            else if (i < SYM_TAPS)
                acc[i] <= acc[i-1] + (x * COEFFS[i]);
            else
                acc[i] <= acc[i-1] + (x * COEFFS[TAPS-i-1]);
        end
    end
end


endmodule  

    