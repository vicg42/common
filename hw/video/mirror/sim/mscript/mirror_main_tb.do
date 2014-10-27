## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

vcom -work work ../../../../lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../../../lib/vicg/reduce_pack.vhd

vcom -work work ../../core_gen/mirx_bram.vhd
vcom -work work ../../vmirx_main.vhd
vcom -work work ../testbanch/vmirx_main_tb.vhd


vsim -t ps -L unisim work.vmirx_main_tb
#do bayer_main_tb_wave.do

run 1000ns

