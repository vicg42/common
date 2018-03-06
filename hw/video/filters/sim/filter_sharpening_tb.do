#-----------------------------------------------------------------------
# Engineer    : Golovachenko Victor
#
# Create Date : 10.10.2017 10:26:46
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../filter_core.v
vlog ../filter_sharpening.v
vlog ./filter_sharpening_tb.sv -sv


vsim -t 1ps -novopt -lib work filter_sharpening_tb


do filter_sharpening_tb_wave.do
view wave
view structure
view signals
run 1000ns

#quit -force
