## Delete existing libraries
file delete -force -- work

vlib work

vlog "c:/Xilinx/14.6/ISE_DS/ISE/verilog/src/glbl.v"

# compile all of the files
vcom -work work ../../../../lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../../../../../camera/ise/core_gen/ram_font.vhd
vcom -work work ../../char_screen.vhd
vcom -work work ../../vga_gen.vhd
vcom -work work ../testbanch/char_screen_tb.vhd

# run the simulation
vsim -t ps -L unisim work.char_screen_tb
do char_screen_tb_wave.do

run 5 us


