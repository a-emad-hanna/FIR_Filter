vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../../project_1.srcs/sources_1/ip/fir_compiler_0/fir_compiler_0_sim_netlist.v" \


vlog -work xil_defaultlib \
"glbl.v"

