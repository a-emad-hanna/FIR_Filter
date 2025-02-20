vlib work
vlib riviera

vlib riviera/xil_defaultlib

vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 \
"../../../../project_1.srcs/sources_1/ip/fir_compiler_0/fir_compiler_0_sim_netlist.v" \


vlog -work xil_defaultlib \
"glbl.v"

