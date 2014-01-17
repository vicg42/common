vlib work

vcom "../../../lib/vicg_common_pkg.vhd"

vcom "../../../timer/timer_v01.vhd"

vcom "../../fpga_test_01.vhd"

vcom "../testbanch/fpga_test_01_tb.vhd"
vsim -t 1ps   -lib work fpga_test_01_tb
do fpga_test_01_tb_wave.do
view wave
view structure
view signals
run 1000ns

