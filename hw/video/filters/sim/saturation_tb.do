#-----------------------------------------------------------------------
# author    : Golovachenko Victor
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../saturation.v
vlog ./saturation_tb.sv -sv +incdir+../

vsim -t 1ps -novopt -lib work saturation_tb

do saturation_tb_wave.do
view wave
view structure
view signals
run 12  00ns

#quit -force
