#-----------------------------------------------------------------------
# author    : Golovachenko Victor
#------------------------------------------------------------------------
file delete -force -- work

vlog  ../timing_gen.v -sv +define+SIM_FSM

vlog  ./timing_gen_tb.sv -sv

vsim -t 1ps -novopt -lib work timing_gen_tb

#--------------------------
#View waveform
#--------------------------
do timing_gen_tb_wave.do

view wave
config wave -timelineunits us
view structure
view signals
run 5ms

#quit -force
