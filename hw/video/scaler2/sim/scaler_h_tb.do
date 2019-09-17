#-----------------------------------------------------------------------
# Engineer    : Golovachenko Victor
#
# Create Date : 18.05.2018 18:16:14
#
#------------------------------------------------------------------------
file delete -force -- work

vlib work

vlog ../src/scaler_coe.v
vlog ../src/scaler_h.v

vlog ./bmp_io.sv -sv
vlog ./monitor.sv -sv
vlog ./scaler_h_tb.sv -sv

vsim -t 1ps -novopt -lib work scaler_h_tb \

do scaler_h_tb_wave.do

#--------------------------
#View waveform
#--------------------------
view wave
config wave -timelineunits us
view structure
view signals
run 2us

#quit -force
