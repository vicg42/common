# set up the working directory
set work work
vlib work

# compile all of the files
vcom -work work ../../../lib/vicg/reduce_pack.vhd
vcom -work work ../../../lib/vicg/vicg_common_pkg.vhd
vcom -work work ../../spi_core_pkg.vhd
vcom -work work ../../spi_core.vhd
vcom -work work ../testbanch/spi_core_tb.vhd

# run the simulation
vsim -t ps -L unisim work.spi_core_tb
do spi_core_tb_wave.do

run 10000ns


