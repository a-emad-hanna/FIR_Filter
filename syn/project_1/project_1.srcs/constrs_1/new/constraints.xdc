create_clock -period 32.552 -name clk [get_ports clk]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {clk}]

# Set Bank 0 voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Input Delays
set_input_delay -clock clk -max 2 [get_ports rst]
set_input_delay -clock clk -min 0 [get_ports rst]
set_input_delay -clock clk -max 2 [get_ports x]
set_input_delay -clock clk -min 0 [get_ports x]

# Output Delays
set_output_delay -clock clk -max 2 [get_ports y]
set_output_delay -clock clk -min 0 [get_ports y]


