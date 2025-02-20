
module FIR_Filter  
#(  
    parameter TAPS = 49,                                            // Number of taps  
    parameter DATA_WIDTH = 16,                                      // Data width  
    parameter COEFF_WIDTH = 16                                      // Coefficient width
)  
(  
    input   wire                                         clk,        // Clock signal  
    input   wire                                         rst,        // Reset signal  
    input   wire signed  [DATA_WIDTH-1:0]                x,          // Input data  
    output  reg  signed  [DATA_WIDTH+COEFF_WIDTH-1:0]    y           // Output data  
);  

    // Accumulator registers
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] acc [0:TAPS-2];
    integer i;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset all accumulators and output
            for (i = 0; i < TAPS-1; i = i + 1) begin
                acc[i] <= 0;
            end
            y <= 0;
        end
        else begin
            // Unrolled computation with hardcoded coefficients
            acc[0]  <= x * -36;   
            acc[1]  <= acc[0]  + (x * 82);  
            acc[2]  <= acc[1]  + (x * 122);  
            acc[3]  <= acc[2]  + (x * 99);  
            acc[4]  <= acc[3]  + (x * -20);  
            acc[5]  <= acc[4]  + (x * -166);  
            acc[6]  <= acc[5]  + (x * -204);  
            acc[7]  <= acc[6]  + (x * -52);  
            acc[8]  <= acc[7]  + (x * 213);  
            acc[9]  <= acc[8]  + (x * 369);  
            acc[10]  <= acc[9]  + (x * 221);  
            acc[11]  <= acc[10]  + (x * -197);  
            acc[12]  <= acc[11]  + (x * -572);  
            acc[13]  <= acc[12]  + (x * -524);  
            acc[14]  <= acc[13]  + (x * 50);  
            acc[15]  <= acc[14]  + (x * 786);  
            acc[16]  <= acc[15]  + (x * 1029);  
            acc[17]  <= acc[16]  + (x * 351);  
            acc[18]  <= acc[17]  + (x * -976);  
            acc[19]  <= acc[18]  + (x * -1954);  
            acc[20]  <= acc[19]  + (x * -1421);  
            acc[21]  <= acc[20]  + (x * 1108);  
            acc[22]  <= acc[21]  + (x * 4928);  
            acc[23]  <= acc[22]  + (x * 8380);  
            acc[24]  <= acc[23]  + (x * 9768);  
            acc[25]  <= acc[24]  + (x * 8380);  
            acc[26]  <= acc[25]  + (x * 4928);  
            acc[27]  <= acc[26]  + (x * 1108);  
            acc[28]  <= acc[27]  + (x * -1421);  
            acc[29]  <= acc[28]  + (x * -1954);  
            acc[30]  <= acc[29]  + (x * -976);  
            acc[31]  <= acc[30]  + (x * 351);  
            acc[32]  <= acc[31]  + (x * 1029);  
            acc[33]  <= acc[32]  + (x * 786);  
            acc[34]  <= acc[33]  + (x * 50);  
            acc[35]  <= acc[34]  + (x * -524);  
            acc[36]  <= acc[35]  + (x * -572);  
            acc[37]  <= acc[36]  + (x * -197);  
            acc[38]  <= acc[37]  + (x * 221);  
            acc[39]  <= acc[38]  + (x * 369);  
            acc[40]  <= acc[39]  + (x * 213);  
            acc[41]  <= acc[40]  + (x * -52);  
            acc[42]  <= acc[41]  + (x * -204);  
            acc[43]  <= acc[42]  + (x * -166);  
            acc[44]  <= acc[43]  + (x * -20);  
            acc[45]  <= acc[44]  + (x * 99);  
            acc[46]  <= acc[45]  + (x * 122);  
            acc[47]  <= acc[46]  + (x * 82);  

            y      <= acc[47] + (x * -36);
        end
    end

endmodule
