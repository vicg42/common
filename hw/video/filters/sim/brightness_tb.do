#-----------------------------------------------------------------------
# author    : Golovachenko Victor
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../brightness.v +define+SIM_DBG
vlog ./brightness_tb.sv -sv +incdir+../

vsim -t 1ps -novopt -lib work brightness_tb

do brightness_tb_wave.do
view wave
view structure
view signals
run 12  00ns

#quit -force
