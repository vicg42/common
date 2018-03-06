## Delete existing libraries
file delete -force -- work

vlib work

# compile all of the files
vcom -work work ../../vga_gen.vhd
vcom -work work ../testbanch/vga_gen_tb.vhd

# run the simulation
vsim -t ps -L unisim work.vga_gen_tb
do vga_gen_tb_wave.do

run 1000ns


