#-----------------------------------------------------------------------
#
# Engineer    : Golovachenko Victor
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../binning_2x2.v
vlog ./monitor.sv -sv +incdir+../
vlog ./binning_2x2_tb.sv -sv +incdir+../


vsim -t 1ps -novopt -lib work binning_2x2_tb


do binning_2x2_tb_wave.do
view wave
view structure
view signals
run 1000ns

#quit -force
