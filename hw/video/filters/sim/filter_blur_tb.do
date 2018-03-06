#-----------------------------------------------------------------------
# Engineer    : Golovachenko Victor
#
# Create Date : 10.10.2017 10:26:46
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../filter_core.v
vlog ../filter_blur.v
vlog ./filter_blur_tb.sv -sv


vsim -t 1ps -novopt -lib work filter_blur_tb


do filter_blur_tb_wave.do
view wave
view structure
view signals
run 1000ns

#quit -force
