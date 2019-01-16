#-----------------------------------------------------------------------
#
# Engineer    : Golovachenko Victor
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../bmp_io.sv -sv
vlog ../binning.v
vlog ./monitor.sv -sv +incdir+../
vlog ./binning_tb.sv -sv +incdir+../


vsim -t 1ps -novopt -lib work binning_tb


do binning_2x2_tb_wave.do
view wave
view structure
view signals
run 1000ns

#quit -force
