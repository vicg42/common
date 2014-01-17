vlib work

vcom "../../../lib/vicg_common_pkg.vhd"
vcom "../../time_gen.vhd"

vcom "../testbanch/time_gen_tb.vhd"
vsim -t 1ps   -lib work time_gen_tb
view wave
view structure
view signals
run 1000ns

