#-----------------------------------------------------------------------
# author    : Golovachenko Victor
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../rgb_2_ycbcr.v
vlog ./monitor.sv -sv +incdir+../
vlog ./rgb_2_ycbcr_tb.sv -sv +incdir+../

vsim -t 1ps -novopt -lib work rgb_2_ycbcr_tb

do rgb_2_ycbcr_tb_wave.do
view wave
view structure
view signals
run 12  00ns

#quit -force
