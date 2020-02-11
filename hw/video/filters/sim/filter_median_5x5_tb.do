#-----------------------------------------------------------------------
#
# author    : Golovachenko Victor
#
#------------------------------------------------------------------------
file delete -force -- work


vlog  ../bmp_io.sv -sv
vlog  ../filter_core_5x5.v
vlog  ../filter_median_5x5.v
vlog ./monitor.sv -sv +incdir+../
vlog  ./filter_median_5x5_tb.sv -sv +incdir+../

vsim  -t 1ps -novopt -lib work filter_median_5x5_tb


#--------------------------
#View waveform
#--------------------------
do filter_median_5x5_tb_wave.do

view wave
config wave -timelineunits us
view structure
view signals
run 5us

