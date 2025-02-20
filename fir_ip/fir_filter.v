module fir_top (
    input wire aclk,
    input wire s_axis_data_tvalid,
    input wire [15:0] s_axis_data_tdata,
    output wire s_axis_data_tready,
    output wire m_axis_data_tvalid,
    output wire [31:0] m_axis_data_tdata
);
        
    fir_compiler_0 your_instance_name (
        .aclk(aclk),                              // Clock input
        .s_axis_data_tvalid(s_axis_data_tvalid),  // Input data valid signal
        .s_axis_data_tready(s_axis_data_tready),  // Output data ready signal
        .s_axis_data_tdata(s_axis_data_tdata),    // Input data (16-bit)
        .m_axis_data_tvalid(m_axis_data_tvalid),  // Output data valid signal
        .m_axis_data_tdata(m_axis_data_tdata)     // Output data (32-bit)
    );

endmodule
