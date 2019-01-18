#-----------------------------------------------------------------------
#
# Engineer    : Golovachenko Victor
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../filter_core_5x5.v
vlog ./filter_core_5x5_tb.sv -sv +incdir+../


vsim -t 1ps -novopt -lib work filter_core_5x5_tb


do filter_core_5x5_tb_wave.do
view wave
view structure
view signals
run 1000ns

#quit -force
