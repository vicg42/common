## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

vcom -work work ../../../../lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../vtest_gen.vhd
vcom -work work ../testbanch/vtest_gen_tb.vhd

# run the simulation
vsim -t ps -L unisim work.vtest_gen_tb
do vtest_gen_tb_wave.do

run 1000ns


