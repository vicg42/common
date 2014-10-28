## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

vcom -work work ../../../lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../../lib/vicg/reduce_pack.vhd

vcom -work work ../../vfilter_core_pkg.vhd
vcom -work work ../../vfilter_core.vhd

vcom -work work ../../color_demosaic/core_gen/vbufpr.vhd
vcom -work work ../../color_demosaic/bayer_main.vhd

vcom -work work ../../mirror/core_gen/mirx_bram.vhd
vcom -work work ../../mirror/vmirx_main.vhd

vcom -work work ../testbanch/test_module_tb.vhd


vsim -t ps -L unisim work.test_module_tb
do test_module_tb_wave.do

run 1000ns

