`timescale 1ns / 10ps

module FIR_Filter_tb;

    localparam TAPS = 49;                                       // Number of taps  
    localparam DATA_WIDTH = 16;                                 // Data width  
    localparam COEFF_WIDTH = 16;                                // Coefficient width 
    localparam clk_period = 32.552;                             // 30.72 MHz
    localparam cordic_clk_period = 10;                          // 100 MHz
    localparam signed PI_POS = 16'h6488;                        // 3.141592653589793
    //localparam signed PI_NEG = 16'h9B78;                        // -3.141592653589793

`ifdef RELOADABLE
    localparam ADDR_WIDTH = 6;                                  // Address width
    bit signed [COEFF_WIDTH-1:0] COEFFS [TAPS] = '{-36, 82, 122, 99, -20, -166, -204, -52, 213, 369, 221, -197, -572, -524, 50, 786, 1029, 351, -976, -1954, -1421, 1108, 4928, 8380, 9768};
`endif

// phase increment formula is: Fout = (Phase_inc * Fcordic * 2pi) / 2^15
    int PHASE_INC1;
    int PHASE_INC2;

// DUT Ports
    reg                                     clk_tb;
    reg                                     rst_tb;
    wire [DATA_WIDTH+COEFF_WIDTH-1:0]       y_tb;
`ifdef RELOADABLE
    reg                                     fir_en_tb;
    reg [ADDR_WIDTH-1:0]                    wr_addr_tb;
    reg signed [COEFF_WIDTH-1:0]            wr_data_tb;
    reg                                     wr_en_tb;
`endif


// Cordic 
    reg                                     cordic_clk;
    reg                                     phase_tvalid;
    reg signed [15:0]                       phase_2;
    reg signed [15:0]                       phase_1;
    wire                                    signal_2_tvalid;
    wire                                    signal_1_tvalid;
    wire signed [15:0]                      sin_2, cos_2;
    wire signed [15:0]                      sin_1, cos_1;
    reg  signed [15:0]                      noisy_signal;

cordic_0 cordic_2 (  
    .aclk(cordic_clk),
    .s_axis_phase_tvalid(phase_tvalid),
    .s_axis_phase_tdata(phase_2),
    .m_axis_dout_tvalid(signal_2_tvalid),
    .m_axis_dout_tdata({sin_2, cos_2})
);

cordic_0 cordic_1 ( 
    .aclk(cordic_clk),
    .s_axis_phase_tvalid(phase_tvalid),
    .s_axis_phase_tdata(phase_1),
    .m_axis_dout_tvalid(signal_1_tvalid),
    .m_axis_dout_tdata({sin_1, cos_1})
);


always @(posedge cordic_clk) begin
    phase_tvalid <= 1; // Set valid signal if needed

    // Phase 2 accumulation and wrapping
    if (phase_2 + PHASE_INC2 > PI_POS) begin
        phase_2 <= phase_2 + PHASE_INC2 - (2 * PI_POS);
    end
    else if (phase_2 + PHASE_INC2 < -PI_POS) begin
        phase_2 <= phase_2 + PHASE_INC2 + (2 * PI_POS);
    end
    else begin
        phase_2 <= phase_2 + PHASE_INC2;
    end

    // Phase 1 accumulation and wrapping
    if (phase_1 + PHASE_INC1 > PI_POS) begin
        phase_1 <= phase_1 + PHASE_INC1 - (2 * PI_POS);
    end
    else if (phase_1 + PHASE_INC1 < -PI_POS) begin
        phase_1 <= phase_1 + PHASE_INC1 + (2 * PI_POS);
    end
    else begin
        phase_1 <= phase_1 + PHASE_INC1;
    end
end

always @(posedge clk_tb) begin
    noisy_signal <= (sin_2 + sin_1);
end

////////////////////////////////////////////////////////
////////////////// initial block /////////////////////// 
////////////////////////////////////////////////////////

initial 
begin
    // Save Waveform
    $dumpfile("FIR.vcd");       
    $dumpvars; 

    // initialization
    initialize();

    // Reset
    #(clk_period)
    reset();

`ifdef RELOADABLE
    // Modify Coefficients
    #(clk_period)
    modify_coeffs(COEFFS);
    fir_en_tb = 1;
`endif

    // Test Case 1: Both pass
    PHASE_INC1 = (0.5 * 32768)/(2*3.1416 * 10); // 0.5 MHz
    PHASE_INC2 = (1 * 32768)/(2*3.1416 * 10); // 1 MHz
    #(2000*10)

    // Test Case 2: 1Mhz pass only
    PHASE_INC1 = (0.5 * 32768)/(2*3.1416 * 10); // 1 MHz
    PHASE_INC2 = (8 * 32768)/(2*3.1416 * 10); // 8 MHz
    #(2000*10)

    // Test Case 3: Both attenuated
    PHASE_INC1 = (6 * 32768)/(2*3.1416 * 10); // 6 MHz
    PHASE_INC2 = (7 * 32768)/(2*3.1416 * 10); // 7 MHz
    #(2000*10)

    $stop;
end  

////////////////////////////////////////////////////////
/////////////////////// TASKS //////////////////////////
////////////////////////////////////////////////////////

/////////////// Signals Initialization //////////////////

task initialize;
begin
    clk_tb = 0;
    rst_tb = 1;
    cordic_clk = 0;
    noisy_signal = 0;
    phase_tvalid = 0;
    phase_2 = 0;
    phase_1 = 0;

`ifdef RELOADABLE
    fir_en_tb = 0;
    wr_addr_tb = 0;
    wr_data_tb = 0;
    wr_en_tb = 0;
`endif

end
endtask

///////////////////////// RESET /////////////////////////

task reset;
begin
    rst_tb =  'b1;
    #(clk_period/2)
    rst_tb  = 'b0;
    #(clk_period)
    rst_tb  = 'b1;
end
endtask 

///////////////////// Modify Coeffs /////////////////////

`ifdef RELOADABLE
task modify_coeffs(input bit signed [15:0] coeffs_array [TAPS]); // Adjust bit width as needed
begin
    wr_en_tb = 1;
    for (int i = 0; i < TAPS; i = i + 1) begin
        wr_addr_tb = i;
        wr_data_tb = coeffs_array[i]; // Use input array instead of COEFFS
        #(clk_period);
    end
    #(clk_period);
    wr_en_tb = 0;
end
endtask
`endif


////////////////////////////////////////////////////////
////////////////// Clock Generator  ////////////////////
////////////////////////////////////////////////////////

always #(clk_period/2) clk_tb = ~clk_tb;
always #(cordic_clk_period/2) cordic_clk = ~cordic_clk;

////////////////////////////////////////////////////////
/////////////////// DUT Instantation ///////////////////
////////////////////////////////////////////////////////

FIR_Filter #(TAPS, DATA_WIDTH, COEFF_WIDTH) DUT (
    .clk(clk_tb),
    .rst(rst_tb),
`ifdef RELOADABLE
    .wr_addr(wr_addr_tb),
    .wr_data(wr_data_tb),
    .wr_en(wr_en_tb),
    .fir_en(fir_en_tb),
`endif
    .x(noisy_signal),
    .y(y_tb)
);

endmodule
