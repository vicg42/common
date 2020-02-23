#-----------------------------------------------------------------------
# author    : Golovachenko Victor
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../mult_v2.v +define+SIM_DBG
vlog ./mult_v2_tb.sv -sv +incdir+../

vsim -t 1ps -novopt -lib work mult_v2_tb

do mult_v2_tb_wave.do
view wave
view structure
view signals
run 12  00ns

#quit -force
