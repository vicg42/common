## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

vcom -work work ../../../lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../../lib/vicg/reduce_pack.vhd
vcom -work work ../../core_gen/bram_filter_core.vhd
vcom -work work ../../core_gen/bram_mirx.vhd
vcom -work work ../../core_gen/sim_fifo8x8bit.vhd
vcom -work work ../../core_gen/sim_fifo8x32bit.vhd
vcom -work work ../../core_gen/sim_fifo32x32bit.vhd
vcom -work work ../../core_gen/sim_bram8x8bit.vhd
vcom -work work ../../core_gen/sim_bram16x8bit.vhd
vcom -work work ../../core_gen/sim_bram16x16bit.vhd
vcom -work work ../../core_gen/sim_bram32x8bit.vhd
vcom -work work ../../core_gen/sim_bram32x16bit.vhd
vcom -work work ../../core_gen/sim_bram32x32bit.vhd

vcom -work work ../../vfilter_core_pkg.vhd
vcom -work work ../../vfilter_core.vhd

vcom -work work ../../vmirx_main.vhd
vcom -work work ../../vdebayer_main.vhd
vcom -work work ../../vsobel_main.vhd
vcom -work work ../../vmedian_main.vhd

vcom -work work ../testbanch/test_module_tb.vhd


vsim -t ps -L unisim work.test_module_tb
do test_module_tb_wave.do

run 1000ns

