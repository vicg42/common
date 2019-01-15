#-----------------------------------------------------------------------
#
# Engineer    : Golovachenko Victor
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../filter_core_3x3.v
vlog ../filter_blur.v
vlog ./monitor.sv -sv +incdir+../
vlog ./filter_blur_tb.sv -sv +incdir+../


vsim -t 1ps -novopt -lib work filter_blur_tb


do filter_blur_tb_wave.do
view wave
view structure
view signals
run 1000ns

#quit -force
